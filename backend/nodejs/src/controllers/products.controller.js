const ProductModel = require('../models/product.model');
const { parsePagination, buildMeta, parseCursorPagination, buildCursorMeta } = require('../utils/pagination');
const { query } = require('../config/database');
const { AppError } = require('../middleware/errorHandler');

const slugify = (str) =>
  str.toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/^-|-$/g, '');

const list = async (req, res, next) => {
  try {
    const isAdmin = req.user?.role === 'admin';

    // Use cursor pagination when ?cursor= is present; fall back to offset for
    // admin pages that need a total count.
    const useCursor = !!req.query.cursor || (!isAdmin && !req.query.page);

    const filters = {
      categoryId: req.query.category_id,
      supplierId: req.query.supplier_id,
      search:     req.query.q,
      minPrice:   req.query.min_price  ? parseFloat(req.query.min_price)  : undefined,
      maxPrice:   req.query.max_price  ? parseFloat(req.query.max_price)  : undefined,
      minRating:  req.query.rating     ? parseFloat(req.query.rating)     : undefined,
      inStock:    req.query.in_stock   === 'true',
      isActive:   isAdmin ? (req.query.is_active !== undefined ? req.query.is_active === 'true' : undefined) : true,
      isFeatured: req.query.featured   === 'true',
      sort:       req.query.sort,
    };

    if (useCursor) {
      const { limit, cursor } = parseCursorPagination(req.query);
      const { rows } = await ProductModel.list({ ...filters, limit, cursor });
      const { data, meta } = buildCursorMeta(rows, limit);
      return res.json({ data, meta });
    }

    const { page, limit, offset } = parsePagination(req.query);
    const { rows, total } = await ProductModel.list({ ...filters, limit, offset });
    res.json({ data: rows, meta: buildMeta(total, page, limit) });
  } catch (err) { next(err); }
};

const getOne = async (req, res, next) => {
  try {
    const product = await ProductModel.findById(req.params.id);
    if (!product) throw new AppError('Product not found.', 404, 'NOT_FOUND');
    if (!product.is_active && req.user?.role !== 'admin')
      throw new AppError('Product not found.', 404, 'NOT_FOUND');
    // cost_price is internal — never expose it outside admin context
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

    // Suppliers may only edit products they own
    if (req.user.role === 'supplier') {
      const { rows } = await query(
        'SELECT id FROM suppliers WHERE user_id = $1 AND status = $2',
        [req.user.id, 'active']
      );
      if (!rows.length) {
        throw new AppError('No active supplier account found for this user.', 403, 'FORBIDDEN');
      }
      if (product.supplier_id !== rows[0].id) {
        throw new AppError('You can only edit products that belong to your supplier account.', 403, 'FORBIDDEN');
      }
    }

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
