const ReviewModel   = require('../models/review.model');
const ReviewService = require('../services/review.service');
const { parsePagination, buildMeta } = require('../utils/pagination');
const { AppError } = require('../middleware/errorHandler');

const list = async (req, res, next) => {
  try {
    const { page, limit, offset } = parsePagination(req.query);
    const { rows, total, stats } = await ReviewModel.listByProduct(req.params.productId, {
      limit, offset,
      rating: req.query.rating ? parseInt(req.query.rating, 10) : undefined,
      sort: req.query.sort,
    });
    res.json({ data: rows, meta: { ...buildMeta(total, page, limit), ...stats } });
  } catch (err) { next(err); }
};

const create = async (req, res, next) => {
  try {
    const review = await ReviewService.createReview({
      productId: req.params.productId,
      userId: req.user.id,
      orderId: req.body.order_id,
      rating: req.body.rating,
      title: req.body.title,
      body: req.body.body,
      images: req.body.images,
    });
    res.status(201).json({ data: review });
  } catch (err) { next(err); }
};

const update = async (req, res, next) => {
  try {
    const review = await ReviewModel.findById(req.params.id);
    if (!review) throw new AppError('Review not found.', 404, 'NOT_FOUND');
    if (review.user_id !== req.user.id && req.user.role !== 'admin')
      throw new AppError('Forbidden.', 403, 'FORBIDDEN');

    const daysSince = (Date.now() - new Date(review.created_at).getTime()) / 86400000;
    if (daysSince > 30 && req.user.role !== 'admin')
      throw new AppError('Reviews can only be edited within 30 days.', 403, 'EDIT_WINDOW_CLOSED');

    const updated = await ReviewModel.update(req.params.id, req.body);
    res.json({ data: updated });
  } catch (err) { next(err); }
};

const remove = async (req, res, next) => {
  try {
    const review = await ReviewModel.findById(req.params.id);
    if (!review) throw new AppError('Review not found.', 404, 'NOT_FOUND');
    if (review.user_id !== req.user.id && req.user.role !== 'admin')
      throw new AppError('Forbidden.', 403, 'FORBIDDEN');
    await ReviewModel.remove(req.params.id);
    res.status(204).send();
  } catch (err) { next(err); }
};

const helpful = async (req, res, next) => {
  try {
    const result = await ReviewModel.incrementHelpful(req.params.id);
    if (!result) throw new AppError('Review not found.', 404, 'NOT_FOUND');
    res.json({ data: result });
  } catch (err) { next(err); }
};

const reply = async (req, res, next) => {
  try {
    const result = await ReviewModel.setReply(req.params.id, req.body.reply);
    if (!result) throw new AppError('Review not found.', 404, 'NOT_FOUND');
    res.json({ data: result });
  } catch (err) { next(err); }
};

module.exports = { list, create, update, remove, helpful, reply };
