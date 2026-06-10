const { query, withTransaction } = require('../config/database');

const findById = async (id) => {
  const { rows } = await query(
    `SELECT o.*,
            JSON_AGG(JSON_BUILD_OBJECT(
              'id', oi.id, 'product_id', oi.product_id, 'product_name', oi.product_name,
              'product_sku', oi.product_sku, 'product_image', oi.product_image,
              'quantity', oi.quantity, 'unit_price', oi.unit_price,
              'total_price', oi.total_price, 'is_reviewed', oi.is_reviewed,
              'supplier_id', oi.supplier_id
            ) ORDER BY oi.id) AS items
       FROM orders o
       LEFT JOIN order_items oi ON oi.order_id = o.id
      WHERE o.id = $1
     GROUP BY o.id`,
    [id]
  );
  return rows[0] || null;
};

const findByNumber = async (order_number) => {
  const { rows } = await query('SELECT id FROM orders WHERE order_number = $1', [order_number]);
  return rows[0] || null;
};

const list = async ({ userId, limit, offset, status, isAdmin }) => {
  const conditions = [];
  const values = [];
  let idx = 1;

  if (!isAdmin) { conditions.push(`o.user_id = $${idx++}`); values.push(userId); }
  if (status)   { conditions.push(`o.status = $${idx++}`); values.push(status); }

  const where = conditions.length ? `WHERE ${conditions.join(' AND ')}` : '';
  const countRes = await query(`SELECT COUNT(*) FROM orders o ${where}`, values);
  const { rows } = await query(
    `SELECT o.id, o.order_number, o.status, o.payment_method, o.payment_status,
            o.subtotal, o.discount_amount, o.delivery_fee, o.total,
            o.estimated_delivery, o.delivered_at, o.created_at,
            COUNT(oi.id) AS item_count,
            u.full_name AS customer_name, u.email AS customer_email
       FROM orders o
       JOIN users u ON u.id = o.user_id
       LEFT JOIN order_items oi ON oi.order_id = o.id
       ${where}
     GROUP BY o.id, u.full_name, u.email
     ORDER BY o.created_at DESC
     LIMIT $${idx} OFFSET $${idx + 1}`,
    [...values, limit, offset]
  );
  return { rows, total: parseInt(countRes.rows[0].count, 10) };
};

const create = async (client, { userId, addressId, couponId, paymentMethod,
  subtotal, discountAmount, deliveryFee, total, notes, estimatedDelivery, addressSnapshot }) => {
  const { rows } = await client.query(
    `INSERT INTO orders
       (user_id, address_id, coupon_id, payment_method, subtotal,
        discount_amount, delivery_fee, total, notes, estimated_delivery, address_snapshot)
     VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11)
     RETURNING id, order_number, status, payment_status, total, estimated_delivery`,
    [userId, addressId, couponId || null, paymentMethod,
     subtotal, discountAmount || 0, deliveryFee || 0, total,
     notes || null, estimatedDelivery || null, JSON.stringify(addressSnapshot)]
  );
  return rows[0];
};

const insertItems = async (client, orderId, items) => {
  for (const item of items) {
    await client.query(
      `INSERT INTO order_items
         (order_id, product_id, supplier_id, product_name, product_sku, product_image,
          quantity, unit_price, total_price)
       VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9)`,
      [orderId, item.product_id, item.supplier_id || null,
       item.product_name, item.product_sku || null, item.product_image || null,
       item.quantity, item.unit_price, item.unit_price * item.quantity]
    );
  }
};

const updateStatus = async (id, status, extra = {}) => {
  const sets = ['status = $1'];
  const values = [status, id];
  let idx = 3;

  if (status === 'delivered') { sets.push(`delivered_at = NOW()`); }
  if (status === 'cancelled') {
    sets.push(`cancelled_at = NOW()`);
    if (extra.reason) { sets.push(`cancellation_reason = $${idx++}`); values.splice(idx - 2, 0, extra.reason); }
  }

  const { rows } = await query(
    `UPDATE orders SET ${sets.join(', ')} WHERE id = $2 RETURNING id, order_number, status`,
    values
  );
  return rows[0] || null;
};

const updatePaymentStatus = async (id, paymentStatus, paymentReference) => {
  const { rows } = await query(
    `UPDATE orders SET payment_status = $1, payment_reference = $2
     WHERE id = $3 RETURNING id, payment_status`,
    [paymentStatus, paymentReference || null, id]
  );
  return rows[0] || null;
};

module.exports = { findById, findByNumber, list, create, insertItems, updateStatus, updatePaymentStatus };
