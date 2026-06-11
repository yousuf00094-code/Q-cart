const { withTransaction, query } = require('../config/database');
const OrderModel     = require('../models/order.model');
const ProductModel   = require('../models/product.model');
const InventoryModel = require('../models/inventory.model');
const CouponModel    = require('../models/coupon.model');
const { AppError }   = require('../middleware/errorHandler');

const DELIVERY_FEE      = 15.00;
const FREE_DELIVERY_MIN = 200.00;

const applyDiscount = (coupon, subtotal) => {
  if (!coupon) return 0;
  let discount = coupon.discount_type === 'percentage'
    ? subtotal * (coupon.discount_value / 100)
    : parseFloat(coupon.discount_value);
  if (coupon.max_discount_amount) {
    discount = Math.min(discount, parseFloat(coupon.max_discount_amount));
  }
  return parseFloat(discount.toFixed(2));
};

// Batch-fetch all products in one query to avoid N+1 round trips
const validateCartItems = async (items) => {
  const productIds = [...new Set(items.map((i) => i.product_id))];

  const products = await ProductModel.findManyByIds(productIds);
  const productMap = new Map(products.map((p) => [p.id, p]));

  const outOfStock = [];
  const resolved   = [];

  for (const item of items) {
    const product = productMap.get(item.product_id);
    if (!product || !product.is_active) {
      throw new AppError(`Product ${item.product_id} is not available.`, 422, 'PRODUCT_UNAVAILABLE');
    }
    if (product.available_quantity < item.quantity) {
      outOfStock.push({ product_id: item.product_id, available: product.available_quantity });
    }
    resolved.push({ ...item, product });
  }

  if (outOfStock.length) {
    throw new AppError('Some items are out of stock.', 409, 'INSUFFICIENT_STOCK', { out_of_stock_items: outOfStock });
  }
  return resolved;
};

const estimate = async ({ items, couponCode }) => {
  const resolved = await validateCartItems(items);
  const subtotal  = resolved.reduce((s, i) => s + i.product.price * i.quantity, 0);

  let coupon = null;
  if (couponCode) {
    coupon = await CouponModel.findByCode(couponCode);
    if (!coupon || !coupon.is_active) throw new AppError('Coupon code is invalid.', 422, 'COUPON_INVALID');
    if (coupon.valid_until && new Date(coupon.valid_until) < new Date())
      throw new AppError('Coupon has expired.', 422, 'COUPON_EXPIRED');
    if (coupon.usage_limit && coupon.usage_count >= coupon.usage_limit)
      throw new AppError('Coupon usage limit reached.', 422, 'COUPON_USAGE_EXCEEDED');
    if (subtotal < parseFloat(coupon.min_order_amount))
      throw new AppError(`Minimum order of QAR ${coupon.min_order_amount} required.`, 422, 'ORDER_BELOW_MINIMUM');
  }

  const discount    = applyDiscount(coupon, subtotal);
  const deliveryFee = subtotal - discount >= FREE_DELIVERY_MIN ? 0 : DELIVERY_FEE;
  const total       = parseFloat((subtotal - discount + deliveryFee).toFixed(2));

  return { subtotal, discount_amount: discount, delivery_fee: deliveryFee, total,
    coupon_applied: !!coupon, free_delivery: deliveryFee === 0 };
};

const placeOrder = async ({ userId, addressId, couponCode, paymentMethod, items, notes }) => {
  // Pre-validate outside the transaction (no row locks) for a fast early exit
  const resolved = await validateCartItems(items);

  return withTransaction(async (client) => {
    // Lock inventory rows to prevent overselling under concurrent requests.
    // Any other concurrent checkout for the same products will wait here.
    const productIds = resolved.map((r) => r.product.id);
    await client.query(
      'SELECT id FROM inventory WHERE product_id = ANY($1::uuid[]) FOR UPDATE',
      [productIds]
    );

    // Re-check stock with the locked rows (values may have changed since pre-check)
    for (const r of resolved) {
      const { rows: inv } = await client.query(
        'SELECT COALESCE(quantity - reserved, 0) AS available FROM inventory WHERE product_id = $1',
        [r.product.id]
      );
      const available = inv[0]?.available ?? 0;
      if (available < r.quantity) {
        throw new AppError(
          `Insufficient stock for "${r.product.name}".`,
          409,
          'INSUFFICIENT_STOCK',
          { product_id: r.product.id, available }
        );
      }
    }

    const subtotal = resolved.reduce((s, i) => s + parseFloat(i.product.price) * i.quantity, 0);

    let coupon = null;
    if (couponCode) {
      coupon = await CouponModel.findByCode(couponCode);
      if (!coupon || !coupon.is_active) throw new AppError('Coupon code is invalid.', 422, 'COUPON_INVALID');
      const userUsage = await CouponModel.countUserUsage(coupon.id, userId);
      if (userUsage >= coupon.per_user_limit)
        throw new AppError('You have already used this coupon.', 422, 'COUPON_ALREADY_USED');
    }

    const discount    = applyDiscount(coupon, subtotal);
    const deliveryFee = subtotal - discount >= FREE_DELIVERY_MIN ? 0 : DELIVERY_FEE;
    const total       = parseFloat((subtotal - discount + deliveryFee).toFixed(2));

    const { rows: addrRows } = await client.query(
      'SELECT * FROM addresses WHERE id = $1 AND user_id = $2', [addressId, userId]
    );
    if (!addrRows.length) throw new AppError('Address not found.', 404, 'NOT_FOUND');

    const estimatedDelivery = new Date(Date.now() + 45 * 60 * 1000);

    const order = await OrderModel.create(client, {
      userId, addressId, couponId: coupon?.id || null,
      paymentMethod, subtotal, discountAmount: discount,
      deliveryFee, total, notes, estimatedDelivery,
      addressSnapshot: addrRows[0],
    });

    const orderItems = resolved.map((i) => ({
      product_id:    i.product.id,
      supplier_id:   i.product.supplier_id,
      product_name:  i.product.name,
      product_sku:   i.product.sku,
      product_image: i.product.images?.[0]?.url || null,
      quantity:      i.quantity,
      unit_price:    parseFloat(i.product.price),
    }));

    await OrderModel.insertItems(client, order.id, orderItems);

    // Deduct inventory and write audit trail
    for (const item of resolved) {
      const updated = await InventoryModel.adjust(client, item.product.id, -item.quantity);
      await InventoryModel.logTransaction(client, {
        productId:     item.product.id,
        txnType:       'sale',
        quantityDelta: -item.quantity,
        quantityAfter: updated?.quantity ?? 0,
        referenceId:   order.id,
      });
      await client.query(
        'UPDATE products SET total_sold = total_sold + $1 WHERE id = $2',
        [item.quantity, item.product.id]
      );
    }

    if (coupon) await CouponModel.incrementUsage(coupon.id, client);

    await client.query(
      `UPDATE orders SET status = 'confirmed', payment_status = 'paid' WHERE id = $1`,
      [order.id]
    );

    // Clear the cart now that the order is placed
    await client.query(
      `DELETE FROM cart_items
        WHERE cart_id = (SELECT id FROM carts WHERE user_id = $1)`,
      [userId]
    );

    return { ...order, status: 'confirmed', payment_status: 'paid',
      total: total.toFixed(2), estimated_delivery: estimatedDelivery };
  });
};

const cancel = async (orderId, userId, reason, isAdmin) => {
  const order = await OrderModel.findById(orderId);
  if (!order) throw new AppError('Order not found.', 404, 'NOT_FOUND');
  if (!isAdmin && order.user_id !== userId) throw new AppError('Forbidden.', 403, 'FORBIDDEN');

  const cancellable = ['pending', 'confirmed'];
  if (!cancellable.includes(order.status))
    throw new AppError('Order cannot be cancelled at this stage.', 409, 'ORDER_NOT_CANCELLABLE');

  return withTransaction(async (client) => {
    const { rows } = await client.query(
      `UPDATE orders
          SET status = 'cancelled', cancelled_at = NOW(), cancellation_reason = $2
        WHERE id = $1
       RETURNING id, order_number, status`,
      [orderId, reason || null]
    );

    // Restore inventory for each item in the cancelled order
    const items = (order.items || []).filter((i) => i && i.product_id);
    for (const item of items) {
      const updated = await InventoryModel.adjust(client, item.product_id, item.quantity);
      await InventoryModel.logTransaction(client, {
        productId:     item.product_id,
        txnType:       'return',
        quantityDelta: item.quantity,
        quantityAfter: updated?.quantity ?? 0,
        referenceId:   orderId,
        notes:         `Order ${order.order_number} cancelled`,
      });
    }

    return rows[0];
  });
};

module.exports = { estimate, placeOrder, cancel };
