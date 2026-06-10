const CouponModel = require('../models/coupon.model');
const { parsePagination, buildMeta } = require('../utils/pagination');
const { AppError } = require('../middleware/errorHandler');

const list = async (req, res, next) => {
  try {
    const { page, limit, offset } = parsePagination(req.query);
    const isActive = req.query.is_active !== undefined
      ? req.query.is_active === 'true' : undefined;
    const { rows, total } = await CouponModel.list({ limit, offset, isActive });
    res.json({ data: rows, meta: buildMeta(total, page, limit) });
  } catch (err) { next(err); }
};

const create = async (req, res, next) => {
  try {
    const coupon = await CouponModel.create(req.body);
    res.status(201).json({ data: coupon });
  } catch (err) { next(err); }
};

const update = async (req, res, next) => {
  try {
    const existing = await CouponModel.findById(req.params.id);
    if (!existing) throw new AppError('Coupon not found.', 404, 'NOT_FOUND');
    const updated = await CouponModel.update(req.params.id, req.body);
    res.json({ data: updated });
  } catch (err) { next(err); }
};

const remove = async (req, res, next) => {
  try {
    const deleted = await CouponModel.remove(req.params.id);
    if (!deleted) throw new AppError('Coupon not found.', 404, 'NOT_FOUND');
    res.status(204).send();
  } catch (err) { next(err); }
};

const validate = async (req, res, next) => {
  try {
    const { code, order_amount } = req.body;
    const coupon = await CouponModel.findByCode(code);

    if (!coupon || !coupon.is_active)
      throw new AppError('Coupon code is invalid.', 422, 'COUPON_INVALID');
    if (coupon.valid_until && new Date(coupon.valid_until) < new Date())
      throw new AppError('Coupon has expired.', 422, 'COUPON_EXPIRED');
    if (coupon.usage_limit && coupon.usage_count >= coupon.usage_limit)
      throw new AppError('Coupon usage limit reached.', 422, 'COUPON_USAGE_EXCEEDED');
    if (parseFloat(order_amount) < parseFloat(coupon.min_order_amount))
      throw new AppError(`Minimum order of QAR ${coupon.min_order_amount} required.`, 422, 'ORDER_BELOW_MINIMUM');

    if (req.user) {
      const used = await CouponModel.countUserUsage(coupon.id, req.user.id);
      if (used >= coupon.per_user_limit)
        throw new AppError('You have already used this coupon.', 422, 'COUPON_ALREADY_USED');
    }

    const amount = parseFloat(order_amount);
    let discount = coupon.discount_type === 'percentage'
      ? amount * (coupon.discount_value / 100)
      : parseFloat(coupon.discount_value);
    if (coupon.max_discount_amount) discount = Math.min(discount, parseFloat(coupon.max_discount_amount));

    res.json({ data: { valid: true, discount_amount: parseFloat(discount.toFixed(2)),
      coupon: { code: coupon.code, discount_type: coupon.discount_type, discount_value: coupon.discount_value } } });
  } catch (err) { next(err); }
};

module.exports = { list, create, update, remove, validate };
