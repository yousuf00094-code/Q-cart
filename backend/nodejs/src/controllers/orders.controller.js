const OrderModel   = require('../models/order.model');
const OrderService = require('../services/order.service');
const { parsePagination, buildMeta } = require('../utils/pagination');
const { AppError } = require('../middleware/errorHandler');

const list = async (req, res, next) => {
  try {
    const { page, limit, offset } = parsePagination(req.query);
    const isAdmin = req.user.role === 'admin';
    const { rows, total } = await OrderModel.list({
      userId: req.user.id, limit, offset,
      status: req.query.status, isAdmin,
    });
    res.json({ data: rows, meta: buildMeta(total, page, limit) });
  } catch (err) { next(err); }
};

const getOne = async (req, res, next) => {
  try {
    const order = await OrderModel.findById(req.params.id);
    if (!order) throw new AppError('Order not found.', 404, 'NOT_FOUND');
    if (req.user.role !== 'admin' && order.user_id !== req.user.id)
      throw new AppError('Forbidden.', 403, 'FORBIDDEN');
    res.json({ data: order });
  } catch (err) { next(err); }
};

const checkout = async (req, res, next) => {
  try {
    const { address_id, payment_method, items, coupon_code, notes } = req.body;
    const order = await OrderService.placeOrder({
      userId: req.user.id,
      addressId: address_id,
      couponCode: coupon_code,
      paymentMethod: payment_method,
      items, notes,
    });
    res.status(201).json({ data: order });
  } catch (err) { next(err); }
};

const estimate = async (req, res, next) => {
  try {
    const result = await OrderService.estimate(req.body);
    res.json({ data: result });
  } catch (err) { next(err); }
};

const cancel = async (req, res, next) => {
  try {
    const isAdmin = req.user.role === 'admin';
    const order = await OrderService.cancel(
      req.params.id, req.user.id, req.body.reason, isAdmin
    );
    res.json({ data: order });
  } catch (err) { next(err); }
};

const updateStatus = async (req, res, next) => {
  try {
    const order = await OrderModel.updateStatus(req.params.id, req.body.status, req.body);
    if (!order) throw new AppError('Order not found.', 404, 'NOT_FOUND');
    res.json({ data: order });
  } catch (err) { next(err); }
};

module.exports = { list, getOne, checkout, estimate, cancel, updateStatus };
