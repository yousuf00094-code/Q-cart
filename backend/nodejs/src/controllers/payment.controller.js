'use strict';

const { query } = require('../config/database');
const { AppError } = require('../middleware/errorHandler');
const { sendOrderNotification } = require('../utils/notifications');

// ── In-memory pending payments store (replace with DB table in production) ──
// Map<invoiceId, { userId, addressId, couponCode, cartSnapshot, createdAt }>
const _pending = new Map();

// ── QPay API helper ──────────────────────────────────────────────────────────
const QPAY_BASE = process.env.QPAY_BASE_URL || 'https://sandbox-merchant.qpay.com/v2';
let _qpayToken = null;
let _qpayTokenExpiry = 0;

async function _qpayAuth() {
  if (_qpayToken && Date.now() < _qpayTokenExpiry - 30_000) return _qpayToken;
  const clientId = process.env.QPAY_CLIENT_ID;
  const clientSecret = process.env.QPAY_CLIENT_SECRET;
  if (!clientId || !clientSecret) throw new AppError('QPay credentials not configured', 503, 'PAYMENT_UNAVAILABLE');

  const creds = Buffer.from(`${clientId}:${clientSecret}`).toString('base64');
  const res = await fetch(`${QPAY_BASE}/auth/token`, {
    method: 'POST',
    headers: { Authorization: `Basic ${creds}`, 'Content-Type': 'application/json' },
  });
  if (!res.ok) throw new AppError('QPay authentication failed', 502, 'PAYMENT_AUTH_FAILED');
  const data = await res.json();
  _qpayToken = data.access_token;
  _qpayTokenExpiry = Date.now() + (data.expires_in || 3600) * 1000;
  return _qpayToken;
}

async function _qpayCreateInvoice(amount, description, callbackUrl) {
  const token = await _qpayAuth();
  const body = {
    invoice_code:   process.env.QPAY_INVOICE_CODE,
    sender_name:    'Q Cart',
    amount:         parseFloat(amount.toFixed(2)),
    currency:       'QAR',
    general_description: description,
    callback_url:   callbackUrl || `${process.env.BASE_URL}/v1/payment/callback`,
    success_url:    process.env.QPAY_SUCCESS_REDIRECT || 'qcart://payment/success',
    failure_url:    process.env.QPAY_FAILURE_REDIRECT || 'qcart://payment/failure',
  };
  const res = await fetch(`${QPAY_BASE}/invoice`, {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${token}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify(body),
  });
  if (!res.ok) {
    const err = await res.json().catch(() => ({}));
    throw new AppError(err.message || 'QPay invoice creation failed', 502, 'PAYMENT_INVOICE_FAILED');
  }
  return res.json();
}

async function _qpayCheckPayment(invoiceId) {
  const token = await _qpayAuth();
  const res = await fetch(
    `${QPAY_BASE}/payment/check?object_type=INVOICE&object_id=${invoiceId}`,
    { headers: { Authorization: `Bearer ${token}` } }
  );
  if (!res.ok) return null;
  return res.json();
}

// ── POST /v1/payment/initiate ────────────────────────────────────────────────
const initiate = async (req, res, next) => {
  try {
    const userId = req.user.id;
    const { address_id, coupon_code } = req.body;

    // Load cart for amount calculation
    const cartRes = await query(
      `SELECT ci.id, ci.quantity, p.price, p.name
         FROM cart_items ci
         JOIN cart c ON c.id = ci.cart_id
         JOIN products p ON p.id = ci.product_id
        WHERE c.user_id = $1`,
      [userId]
    );
    if (!cartRes.rows.length) throw new AppError('Cart is empty', 422, 'EMPTY_CART');

    const subtotal = cartRes.rows.reduce((s, r) => s + parseFloat(r.price) * r.quantity, 0);
    const delivery = subtotal >= 200 ? 0 : 15;
    let discount = 0;

    if (coupon_code) {
      const cpn = await query(
        `SELECT type, value FROM coupons WHERE code = $1 AND is_active = TRUE
           AND (expires_at IS NULL OR expires_at > NOW())`,
        [coupon_code.toUpperCase()]
      );
      if (cpn.rows.length) {
        const { type, value } = cpn.rows[0];
        discount = type === 'percentage' ? subtotal * (parseFloat(value) / 100) : parseFloat(value);
      }
    }

    const total = Math.max(0, subtotal + delivery - discount);

    const invoice = await _qpayCreateInvoice(total, 'Q Cart Order');

    _pending.set(invoice.invoice_id, {
      userId,
      addressId: address_id,
      couponCode: coupon_code || null,
      cartSnapshot: cartRes.rows,
      subtotal,
      delivery,
      discount,
      total,
      createdAt: Date.now(),
    });

    res.json({
      data: {
        invoice_id:  invoice.invoice_id,
        payment_url: invoice.qpay_payment_url,
        qr_image:    invoice.qpay_qr_image || null,
        amount:      total,
      },
    });
  } catch (err) { next(err); }
};

// ── POST /v1/payment/verify ──────────────────────────────────────────────────
const verify = async (req, res, next) => {
  try {
    const { invoice_id } = req.body;
    const pending = _pending.get(invoice_id);
    if (!pending) throw new AppError('Payment session not found or expired', 404, 'NOT_FOUND');

    const status = await _qpayCheckPayment(invoice_id);
    const isPaid = status?.payment_status === 'PAID' ||
                   (Array.isArray(status?.rows) && status.rows.some(r => r.payment_status === 'PAID'));
    if (!isPaid) return res.status(402).json({ error: { code: 'PAYMENT_PENDING', message: 'Payment has not been completed yet.' } });

    const order = await _createOrderFromPending(pending);
    _pending.delete(invoice_id);
    res.json({ data: order });
  } catch (err) { next(err); }
};

// ── POST /v1/payment/callback (QPay webhook) ─────────────────────────────────
const callback = async (req, res, next) => {
  try {
    const { invoice_id, payment_status } = req.body;
    if (payment_status !== 'PAID') return res.json({ received: true });

    const pending = _pending.get(invoice_id);
    if (!pending) return res.json({ received: true });

    await _createOrderFromPending(pending);
    _pending.delete(invoice_id);
    res.json({ received: true });
  } catch (err) {
    console.error('[payment] callback error:', err.message);
    res.json({ received: true }); // always 200 to QPay
  }
};

// ── Shared order creation ────────────────────────────────────────────────────
async function _createOrderFromPending(pending) {
  const { userId, addressId, cartSnapshot, subtotal, delivery, discount, total } = pending;
  const orderNumber = `QC-${Date.now().toString().slice(-6)}`;

  const orderRes = await query(
    `INSERT INTO orders (user_id, address_id, order_number, status, subtotal, delivery_fee, discount, total, payment_method, created_at, updated_at)
     VALUES ($1,$2,$3,'pending',$4,$5,$6,$7,'qpay',NOW(),NOW())
     RETURNING id, order_number, status, total, created_at`,
    [userId, addressId, orderNumber, subtotal, delivery, discount, total]
  );
  const order = orderRes.rows[0];

  await Promise.all(cartSnapshot.map(item =>
    query(
      `INSERT INTO order_items (order_id, product_id, quantity, unit_price, total_price)
       VALUES ($1,$2,$3,$4,$5)`,
      [order.id, item.product_id || item.id, item.quantity, item.price, item.price * item.quantity]
    )
  ));

  await query(`DELETE FROM cart_items WHERE cart_id IN (SELECT id FROM cart WHERE user_id=$1)`, [userId]);

  await sendOrderNotification(userId, order.order_number, 'pending');

  return order;
}

// ── PATCH /v1/users/me/fcm-token ────────────────────────────────────────────
const saveFcmToken = async (req, res, next) => {
  try {
    const { token } = req.body;
    if (!token) throw new AppError('Token required', 422, 'VALIDATION_ERROR');
    await query(`UPDATE users SET fcm_token=$1 WHERE id=$2`, [token, req.user.id]);
    res.json({ data: { saved: true } });
  } catch (err) { next(err); }
};

module.exports = { initiate, verify, callback, saveFcmToken };
