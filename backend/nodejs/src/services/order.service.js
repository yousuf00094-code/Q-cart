const { withTransaction, query } = require('../config/database');
const OrderModel    = require('../models/order.model');
const ProductModel  = require('../models/product.model');
const InventoryModel = require('../models/inventory.model');
const CouponModel   = require('../models/coupon.model');
const { AppError }  = require('../middleware/errorHandler');

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

const validateCartItems = async (items) => {
  const outOfStock = [];
  const resolved = [];

  for (const item of items) {
    const product = await ProductModel.findById(item.product_id);
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
  const subtotal = resolved.reduce((s, i) => s + i.product.price * i.quantity, 0);

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

  const discount = applyDiscount(coupon, subtotal);
  const deliveryFee = subtotal - discount >= FREE_DELIVERY_MIN ? 0 : DELIVERY_FEE;
  const total = parseFloat((subtotal - discount + deliveryFee).toFixed(2));

  return { subtotal, discount_amount: discount, delivery_fee: deliveryFee, total,
    coupon_applied: !!coupon, free_delivery: deliveryFee === 0 };
};

const placeOrder = async ({ userId, addressId, couponCode, paymentMethod, items, notes }) => {
  return withTransaction(async (client) => {
    const resolved = await validateCartItems(items);
    const subtotal = resolved.reduce((s, i) => s + i.product.price * i.quantity, 0);

    let coupon = null;
    if (couponCode) {
      coupon = await CouponModel.findByCode(couponCode);
      if (!coupon || !coupon.is_active) throw new AppError('Coupon code is invalid.', 422, 'COUPON_INVALID');
      const userUsage = await CouponModel.countUserUsage(coupon.id, userId);
      if (userUsage >= coupon.per_user_limit)
        throw new AppError('You have already used this coupon.', 422, 'COUPON_ALREADY_USED');
    }

    const discount = applyDiscount(coupon, subtotal);
    const deliveryFee = subtotal - discount >= FREE_DELIVERY_MIN ? 0 : DELIVERY_FEE;
    const total = parseFloat((subtotal - discount + deliveryFee).toFixed(2));

    const { rows: addrRows } = await client.query(
      'SELECT * FROM addresses WHERE id = $1 AND user_id = $2', [addressId, userId]
    );
    if (!addrRows.length) throw new AppError('Address not found.', 404, 'NOT_FOUND');
    const address = addrRows[0];

    const estimatedDelivery = new Date(Date.now() + 45 * 60 * 1000);

    const order = await OrderModel.create(client, {
      userId, addressId, couponId: coupon?.id || null,
      paymentMethod, subtotal, discountAmount: discount,
      deliveryFee, total, notes, estimatedDelivery,
      addressSnapshot: address,
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

    // Deduct inventory
    for (const item of resolved) {
      await InventoryModel.adjust(client, item.product_id, -item.quantity);
      await InventoryModel.logTransaction(client, {
        productId: item.product_id,
        txnType: 'sale',
        quantityDelta: -item.quantity,
        quantityAfter: item.product.available_quantity - item.quantity,
        referenceId: order.id,
      });
      await client.query(
        'UPDATE products SET total_sold = total_sold + $1 WHERE id = $2',
        [item.quantity, item.product_id]
      );
    }

    if (coupon) await CouponModel.incrementUsage(coupon.id, client);

    await client.query(
      `UPDATE orders SET status = 'confirmed', payment_status = 'paid' WHERE id = $1`,
      [order.id]
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

  return OrderModel.updateStatus(orderId, 'cancelled', { reason });
};

module.exports = { estimate, placeOrder, cancel };
