const ProductModel = require('../models/product.model');
const { parsePagination, buildMeta } = require('../utils/pagination');
const { AppError } = require('../middleware/errorHandler');

const slugify = (str) =>
  str.toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/^-|-$/g, '');

const list = async (req, res, next) => {
  try {
    const { page, limit, offset } = parsePagination(req.query);
    const isAdmin = req.user?.role === 'admin';

    const { rows, total } = await ProductModel.list({
      limit, offset,
      categoryId: req.query.category_id,
      supplierId: req.query.supplier_id,
      search: req.query.q,
      minPrice: req.query.min_price ? parseFloat(req.query.min_price) : undefined,
      maxPrice: req.query.max_price ? parseFloat(req.query.max_price) : undefined,
      minRating: req.query.rating ? parseFloat(req.query.rating) : undefined,
      inStock: req.query.in_stock === 'true',
      isActive: isAdmin ? (req.query.is_active !== undefined ? req.query.is_active === 'true' : undefined) : true,
      isFeatured: req.query.featured === 'true',
      sort: req.query.sort,
    });
    res.json({ data: rows, meta: buildMeta(total, page, limit) });
  } catch (err) { next(err); }
};

const getOne = async (req, res, next) => {
  try {
    const product = await ProductModel.findById(req.params.id);
    if (!product) throw new AppError('Product not found.', 404, 'NOT_FOUND');
    if (!product.is_active && req.user?.role !== 'admin')
      throw new AppError('Product not found.', 404, 'NOT_FOUND');
    // Strip cost_price from non-admin responses
    if (req.user?.role !== 'admin') delete product.cost_price;
    res.json({ data: product });
  } catch (err) { next(err); }
};

const create = async (req, res, next) => {
  try {
    const data = { ...req.body };
    if (!data.slug) data.slug = slugify(data.name);
    const product = await ProductModel.create(data);
    res.status(201).json({ data: product });
  } catch (err) { next(err); }
};

const update = async (req, res, next) => {
  try {
    const product = await ProductModel.findById(req.params.id);
    if (!product) throw new AppError('Product not found.', 404, 'NOT_FOUND');
    const updated = await ProductModel.update(req.params.id, req.body);
    res.json({ data: updated });
  } catch (err) { next(err); }
};

const remove = async (req, res, next) => {
  try {
    const deleted = await ProductModel.remove(req.params.id);
    if (!deleted) throw new AppError('Product not found.', 404, 'NOT_FOUND');
    res.status(204).send();
  } catch (err) { next(err); }
};

module.exports = { list, getOne, create, update, remove };
