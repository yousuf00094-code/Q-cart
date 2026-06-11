'use strict';

const { query } = require('../config/database');
const ProductModel = require('../models/product.model');
const { AppError } = require('../middleware/errorHandler');
const { parsePagination, buildMeta } = require('../utils/pagination');
const { getSupplierIdForUser } = require('../services/supplier_analytics.service');

const resolveSupplier = async (userId) => {
  const id = await getSupplierIdForUser(userId);
  if (!id) throw new AppError('No active supplier account found.', 403, 'FORBIDDEN');
  return id;
};

// GET /v1/supplier/products
const products = async (req, res, next) => {
  try {
    const supplierId = await resolveSupplier(req.user.id);
    const { page, limit, offset } = parsePagination(req.query);
    const { status, search } = req.query;

    const result = await ProductModel.list({
      supplierId,
      limit,
      offset,
      isActive: status === 'active' ? true : status === 'inactive' ? false : undefined,
      search: search || undefined,
    });

    res.json({
      data: result.rows,
      meta: buildMeta(result.total, page, limit),
    });
  } catch (err) { next(err); }
};

// GET /v1/supplier/orders
const orders = async (req, res, next) => {
  try {
    const supplierId = await resolveSupplier(req.user.id);
    const { page, limit, offset } = parsePagination(req.query);
    const { status } = req.query;

    const conditions = ['oi.supplier_id = $1'];
    const values = [supplierId];
    let idx = 2;

    if (status) { conditions.push(`o.status = $${idx++}`); values.push(status); }

    const where = `WHERE ${conditions.join(' AND ')}`;

    const [countRes, dataRes] = await Promise.all([
      query(
        `SELECT COUNT(DISTINCT o.id)
           FROM orders o
           JOIN order_items oi ON oi.order_id = o.id
           ${where}`,
        values
      ),
      query(
        `SELECT o.id, o.order_number, o.status, o.total, o.created_at,
                COUNT(oi.id)      AS item_count,
                u.full_name       AS customer_name
           FROM orders o
           JOIN order_items oi ON oi.order_id = o.id
           JOIN users u ON u.id = o.user_id
           ${where}
         GROUP BY o.id, u.full_name
         ORDER BY o.created_at DESC
         LIMIT $${idx} OFFSET $${idx + 1}`,
        [...values, limit, offset]
      ),
    ]);

    res.json({
      data: dataRes.rows,
      meta: buildMeta(parseInt(countRes.rows[0].count, 10), page, limit),
    });
  } catch (err) { next(err); }
};

// GET /v1/supplier/inventory
const inventory = async (req, res, next) => {
  try {
    const supplierId = await resolveSupplier(req.user.id);
    const { page, limit, offset } = parsePagination(req.query);
    const { search, low_stock } = req.query;

    const conditions = ['p.supplier_id = $1'];
    const values = [supplierId];
    let idx = 2;

    if (low_stock === 'true') {
      conditions.push(`(COALESCE(i.quantity, 0) - COALESCE(i.reserved, 0)) <= COALESCE(i.reorder_point, 0)`);
    }
    if (search) {
      conditions.push(`(p.name ILIKE $${idx} OR p.sku ILIKE $${idx})`);
      values.push(`%${search}%`);
      idx++;
    }

    const where = `WHERE ${conditions.join(' AND ')}`;

    const [countRes, dataRes] = await Promise.all([
      query(
        `SELECT COUNT(*)
           FROM products p
           LEFT JOIN inventory i ON i.product_id = p.id
           ${where}`,
        values
      ),
      query(
        `SELECT p.id, p.name, p.sku, p.price, p.is_active,
                COALESCE(i.quantity, 0)                         AS quantity,
                COALESCE(i.reserved, 0)                         AS reserved,
                COALESCE(i.reorder_point, 0)                    AS reorder_point,
                COALESCE(i.quantity - i.reserved, 0)            AS available
           FROM products p
           LEFT JOIN inventory i ON i.product_id = p.id
           ${where}
         ORDER BY available ASC
         LIMIT $${idx} OFFSET $${idx + 1}`,
        [...values, limit, offset]
      ),
    ]);

    res.json({
      data: dataRes.rows,
      meta: buildMeta(parseInt(countRes.rows[0].count, 10), page, limit),
    });
  } catch (err) { next(err); }
};

module.exports = { products, orders, inventory };
