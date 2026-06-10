const WishlistModel = require('../models/wishlist.model');
const ProductModel  = require('../models/product.model');
const { parsePagination, buildMeta } = require('../utils/pagination');
const { AppError } = require('../middleware/errorHandler');

const list = async (req, res, next) => {
  try {
    const { page, limit, offset } = parsePagination(req.query);
    const { rows, total } = await WishlistModel.findByUser(req.user.id, { limit, offset });
    res.json({ data: rows, meta: buildMeta(total, page, limit) });
  } catch (err) { next(err); }
};

const add = async (req, res, next) => {
  try {
    const product = await ProductModel.findById(req.body.product_id);
    if (!product || !product.is_active)
      throw new AppError('Product not found.', 404, 'NOT_FOUND');
    const item = await WishlistModel.add(req.user.id, req.body.product_id);
    res.status(201).json({ data: item || { message: 'Already in wishlist.' } });
  } catch (err) { next(err); }
};

const remove = async (req, res, next) => {
  try {
    const deleted = await WishlistModel.remove(req.user.id, req.params.productId);
    if (!deleted) throw new AppError('Item not found in wishlist.', 404, 'NOT_FOUND');
    res.status(204).send();
  } catch (err) { next(err); }
};

const clear = async (req, res, next) => {
  try {
    await WishlistModel.clear(req.user.id);
    res.status(204).send();
  } catch (err) { next(err); }
};

module.exports = { list, add, remove, clear };
