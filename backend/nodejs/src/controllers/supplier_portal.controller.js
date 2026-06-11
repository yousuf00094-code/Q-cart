'use strict';

const { query } = require('../config/database');
const ProductModel = require('../models/product.model');
const InventoryModel = require('../models/inventory.model');
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

// PATCH /v1/supplier/orders/:id/status
const updateOrderStatus = async (req, res, next) => {
  try {
    const supplierId = await resolveSupplier(req.user.id);
    const { id } = req.params;
    const { status } = req.body;

    // Verify this order contains items from this supplier and fetch current status
    const check = await query(
      `SELECT o.status AS current_status
         FROM orders o
         JOIN order_items oi ON oi.order_id = o.id
        WHERE oi.supplier_id = $1 AND o.id = $2
        LIMIT 1`,
      [supplierId, id]
    );
    if (!check.rows.length) {
      throw new AppError('Order not found.', 404, 'NOT_FOUND');
    }

    const currentStatus = check.rows[0].current_status;

    // Suppliers may only cancel orders that have not yet shipped
    if (status === 'cancelled') {
      const cancellable = ['pending', 'confirmed', 'processing'];
      if (!cancellable.includes(currentStatus)) {
        throw new AppError(
          'Orders that have already shipped cannot be cancelled by the supplier.',
          422, 'INVALID_TRANSITION'
        );
      }
    }

    const result = await query(
      `UPDATE orders SET status = $1, updated_at = NOW() WHERE id = $2
       RETURNING id, order_number, status, updated_at`,
      [status, id]
    );
    res.json({ data: result.rows[0] });
  } catch (err) { next(err); }
};

// POST /v1/supplier/inventory/:productId/adjust
const adjustInventory = async (req, res, next) => {
  try {
    const supplierId = await resolveSupplier(req.user.id);
    const { productId } = req.params;
    const { quantity_delta, notes } = req.body;

    // Verify the product belongs to this supplier
    const check = await query(
      `SELECT id FROM products WHERE id = $1 AND supplier_id = $2`,
      [productId, supplierId]
    );
    if (check.rows.length === 0) {
      throw new AppError('Product not found.', 404, 'NOT_FOUND');
    }

    const updated = await InventoryModel.adjust(null, productId, quantity_delta);
    if (!updated) {
      throw new AppError('Inventory record not found. Ensure the product has been stocked.', 404, 'NOT_FOUND');
    }
    res.json({ data: { product_id: productId, quantity: updated.quantity, notes } });
  } catch (err) { next(err); }
};

// POST /v1/supplier/products
const submitProduct = async (req, res, next) => {
  try {
    const supplierId = await resolveSupplier(req.user.id);
    const slug = req.body.name
      ? req.body.name.toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/^-|-$/g, '')
      : undefined;
    const product = await ProductModel.create({
      ...req.body,
      supplier_id: supplierId,
      slug: req.body.slug || slug,
      is_active: false, // starts pending admin review
    });
    res.status(201).json({ data: product });
  } catch (err) { next(err); }
};

module.exports = { products, orders, inventory, updateOrderStatus, adjustInventory, submitProduct };
