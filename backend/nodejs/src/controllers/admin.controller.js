const { query } = require('../config/database');
const InventoryModel = require('../models/inventory.model');
const { parsePagination, buildMeta } = require('../utils/pagination');

// ── Dashboard Overview ────────────────────────────────────────────────────────

const getDashboard = async (req, res, next) => {
  try {
    const [revenueRes, ordersRes, usersRes, productsRes, lowStockRes] = await Promise.all([
      query(`
        SELECT
          COALESCE(SUM(total), 0)                     AS revenue_total,
          COALESCE(SUM(CASE WHEN created_at >= NOW() - INTERVAL '30 days'
                            THEN total END), 0)       AS revenue_mtd,
          COALESCE(SUM(CASE WHEN created_at >= NOW() - INTERVAL '7 days'
                            THEN total END), 0)       AS revenue_7d,
          COALESCE(SUM(CASE WHEN created_at >= NOW() - INTERVAL '1 day'
                            THEN total END), 0)       AS revenue_today
        FROM orders
        WHERE status NOT IN ('cancelled', 'refunded')
      `),
      query(`
        SELECT
          COUNT(*)                                                   AS total,
          COUNT(*) FILTER (WHERE status = 'pending')                AS pending,
          COUNT(*) FILTER (WHERE status = 'confirmed')              AS confirmed,
          COUNT(*) FILTER (WHERE status = 'processing')             AS processing,
          COUNT(*) FILTER (WHERE status = 'out_for_delivery')       AS out_for_delivery,
          COUNT(*) FILTER (WHERE status = 'delivered')              AS delivered,
          COUNT(*) FILTER (WHERE created_at >= NOW() - INTERVAL '1 day') AS today
        FROM orders
      `),
      query(`
        SELECT
          COUNT(*)                                                    AS total,
          COUNT(*) FILTER (WHERE role = 'customer')                  AS customers,
          COUNT(*) FILTER (WHERE role = 'supplier')                  AS suppliers,
          COUNT(*) FILTER (WHERE created_at >= NOW() - INTERVAL '30 days') AS new_mtd
        FROM users
        WHERE is_active = TRUE
      `),
      query(`
        SELECT
          COUNT(*)                                  AS total,
          COUNT(*) FILTER (WHERE is_active = TRUE)  AS active,
          COUNT(*) FILTER (WHERE is_featured = TRUE) AS featured
        FROM products
      `),
      InventoryModel.getLowStockAlerts(),
    ]);

    res.json({
      data: {
        revenue:   revenueRes.rows[0],
        orders:    ordersRes.rows[0],
        users:     usersRes.rows[0],
        products:  productsRes.rows[0],
        low_stock_count: lowStockRes.length,
      },
    });
  } catch (err) { next(err); }
};

// ── Revenue Report ────────────────────────────────────────────────────────────

const getRevenueReport = async (req, res, next) => {
  try {
    const { period = 'daily', days = '30' } = req.query;

    const truncMap = { daily: 'day', weekly: 'week', monthly: 'month' };
    const trunc = truncMap[period] || 'day';
    const numDays = Math.min(Math.max(parseInt(days, 10) || 30, 1), 365);

    const { rows } = await query(
      `SELECT
         DATE_TRUNC($1, created_at)     AS period,
         COUNT(*)                       AS order_count,
         COALESCE(SUM(total), 0)        AS revenue,
         COALESCE(SUM(discount_amount), 0) AS discounts_given,
         COALESCE(SUM(delivery_fee), 0) AS delivery_fees
       FROM orders
       WHERE created_at >= NOW() - ($2 || ' days')::INTERVAL
         AND status NOT IN ('cancelled', 'refunded')
       GROUP BY 1
       ORDER BY 1`,
      [trunc, numDays]
    );

    res.json({ data: rows });
  } catch (err) { next(err); }
};

// ── Top Products ──────────────────────────────────────────────────────────────

const getTopProducts = async (req, res, next) => {
  try {
    const limit = Math.min(parseInt(req.query.limit, 10) || 10, 50);
    const { days = '30' } = req.query;
    const numDays = Math.min(parseInt(days, 10) || 30, 365);

    const { rows } = await query(
      `SELECT
         oi.product_id,
         oi.product_name,
         oi.product_sku,
         SUM(oi.quantity)          AS units_sold,
         SUM(oi.total_price)       AS revenue,
         COUNT(DISTINCT oi.order_id) AS order_count,
         p.average_rating,
         p.images
       FROM order_items oi
       JOIN orders o ON o.id = oi.order_id
       LEFT JOIN products p ON p.id = oi.product_id
       WHERE o.created_at >= NOW() - ($1 || ' days')::INTERVAL
         AND o.status NOT IN ('cancelled', 'refunded')
       GROUP BY oi.product_id, oi.product_name, oi.product_sku,
                p.average_rating, p.images
       ORDER BY units_sold DESC
       LIMIT $2`,
      [numDays, limit]
    );

    res.json({ data: rows });
  } catch (err) { next(err); }
};

// ── Customer Stats ────────────────────────────────────────────────────────────

const getCustomerStats = async (req, res, next) => {
  try {
    const { page, limit, offset } = parsePagination(req.query);
    const { sort = 'spend', days = '30' } = req.query;
    const numDays = Math.min(parseInt(days, 10) || 30, 365);

    const orderCol = sort === 'orders' ? 'order_count' : 'total_spend';

    const countRes = await query(
      `SELECT COUNT(DISTINCT user_id) FROM orders
        WHERE created_at >= NOW() - ($1 || ' days')::INTERVAL
          AND status NOT IN ('cancelled', 'refunded')`,
      [numDays]
    );

    const { rows } = await query(
      `SELECT
         u.id, u.full_name, u.email, u.created_at,
         COUNT(o.id)            AS order_count,
         COALESCE(SUM(o.total), 0) AS total_spend,
         MAX(o.created_at)      AS last_order_at,
         AVG(o.total)           AS avg_order_value
       FROM users u
       JOIN orders o ON o.user_id = u.id
       WHERE o.created_at >= NOW() - ($1 || ' days')::INTERVAL
         AND o.status NOT IN ('cancelled', 'refunded')
         AND u.role = 'customer'
       GROUP BY u.id
       ORDER BY ${orderCol} DESC
       LIMIT $2 OFFSET $3`,
      [numDays, limit, offset]
    );

    res.json({
      data: rows,
      meta: buildMeta(parseInt(countRes.rows[0].count, 10), page, limit),
    });
  } catch (err) { next(err); }
};

// ── Low Stock Alerts ──────────────────────────────────────────────────────────

const getLowStockAlerts = async (req, res, next) => {
  try {
    const alerts = await InventoryModel.getLowStockAlerts();
    res.json({ data: alerts });
  } catch (err) { next(err); }
};

// ── Recent Activity Feed ──────────────────────────────────────────────────────

const getActivityFeed = async (req, res, next) => {
  try {
    const limit = Math.min(parseInt(req.query.limit, 10) || 20, 50);

    const { rows } = await query(
      `(SELECT 'order' AS type, o.id, o.order_number AS ref,
                u.full_name AS actor, o.total AS amount,
                o.status, o.created_at
          FROM orders o JOIN users u ON u.id = o.user_id
         ORDER BY o.created_at DESC LIMIT $1)
        UNION ALL
        (SELECT 'review' AS type, r.id, p.name AS ref,
                u.full_name AS actor, r.rating::NUMERIC AS amount,
                CASE WHEN r.is_approved THEN 'approved' ELSE 'pending' END AS status,
                r.created_at
          FROM reviews r
          JOIN users u ON u.id = r.user_id
          JOIN products p ON p.id = r.product_id
         ORDER BY r.created_at DESC LIMIT $1)
       ORDER BY created_at DESC LIMIT $1`,
      [limit]
    );

    res.json({ data: rows });
  } catch (err) { next(err); }
};

// ── Supplier Payouts Summary ──────────────────────────────────────────────────

const getSupplierPayoutSummary = async (req, res, next) => {
  try {
    const { days = '30' } = req.query;
    const numDays = Math.min(parseInt(days, 10) || 30, 365);

    const { rows } = await query(
      `SELECT
         s.id AS supplier_id,
         s.name AS supplier_name,
         COUNT(DISTINCT o.id)                  AS order_count,
         COALESCE(SUM(oi.total_price), 0)      AS gross_revenue,
         COALESCE(SUM(oi.total_price) * 0.10, 0) AS commission,
         COALESCE(SUM(oi.total_price) * 0.90, 0) AS net_payout
       FROM suppliers s
       JOIN order_items oi ON oi.supplier_id = s.id
       JOIN orders o ON o.id = oi.order_id
       WHERE o.created_at >= NOW() - ($1 || ' days')::INTERVAL
         AND o.status NOT IN ('cancelled', 'refunded')
       GROUP BY s.id
       ORDER BY gross_revenue DESC`,
      [numDays]
    );

    res.json({ data: rows });
  } catch (err) { next(err); }
};

module.exports = {
  getDashboard,
  getRevenueReport,
  getTopProducts,
  getCustomerStats,
  getLowStockAlerts,
  getActivityFeed,
  getSupplierPayoutSummary,
};
