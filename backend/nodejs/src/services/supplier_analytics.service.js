const { query } = require('../config/database');

const getSupplierIdForUser = async (userId) => {
  const { rows } = await query(
    `SELECT id FROM suppliers WHERE user_id = $1 AND status = 'active'`,
    [userId]
  );
  return rows[0]?.id || null;
};

const getDashboardKpis = async (supplierId) => {
  const { rows } = await query(
    `SELECT
       COUNT(DISTINCT o.id) FILTER (
         WHERE o.status NOT IN ('cancelled','refunded')
       ) AS total_orders,
       COUNT(DISTINCT o.id) FILTER (
         WHERE o.status NOT IN ('cancelled','refunded')
           AND DATE_TRUNC('month', o.created_at) = DATE_TRUNC('month', NOW())
       ) AS orders_mtd,
       COALESCE(SUM(oi.total_price) FILTER (
         WHERE o.status NOT IN ('cancelled','refunded')
       ), 0) AS revenue_all_time,
       COALESCE(SUM(oi.total_price) FILTER (
         WHERE o.status NOT IN ('cancelled','refunded')
           AND DATE_TRUNC('month', o.created_at) = DATE_TRUNC('month', NOW())
       ), 0) AS revenue_mtd,
       COALESCE(AVG(oi.unit_price) FILTER (
         WHERE o.status NOT IN ('cancelled','refunded')
       ), 0) AS avg_order_value,
       COUNT(DISTINCT oi.product_id) AS active_products,
       COUNT(DISTINCT o.id) FILTER (
         WHERE o.status IN ('cancelled','refunded')
       ) AS cancelled_orders,
       COUNT(DISTINCT o.id) AS total_orders_incl_cancelled
     FROM order_items oi
     JOIN orders o ON o.id = oi.order_id
     WHERE oi.supplier_id = $1`,
    [supplierId]
  );

  const kpi = rows[0];

  const { rows: ratingRows } = await query(
    `SELECT
       COALESCE(AVG(r.rating), 0) AS avg_rating,
       COUNT(r.id)                AS review_count
     FROM reviews r
     JOIN products p ON p.id = r.product_id
     WHERE p.supplier_id = $1 AND r.is_approved = TRUE`,
    [supplierId]
  );

  const totalIncl = parseInt(kpi.total_orders_incl_cancelled, 10);
  const cancelled = parseInt(kpi.cancelled_orders, 10);

  return {
    total_orders:      parseInt(kpi.total_orders, 10),
    orders_mtd:        parseInt(kpi.orders_mtd, 10),
    revenue_all_time:  parseFloat(kpi.revenue_all_time),
    revenue_mtd:       parseFloat(kpi.revenue_mtd),
    avg_order_value:   parseFloat(parseFloat(kpi.avg_order_value).toFixed(2)),
    active_products:   parseInt(kpi.active_products, 10),
    avg_rating:        parseFloat(parseFloat(ratingRows[0].avg_rating).toFixed(2)),
    review_count:      parseInt(ratingRows[0].review_count, 10),
    cancellation_rate: totalIncl > 0
      ? parseFloat(((cancelled / totalIncl) * 100).toFixed(1))
      : 0,
  };
};

const getDailyRevenue = async (supplierId, days = 30) => {
  const { rows } = await query(
    `SELECT
       DATE_TRUNC('day', o.created_at)::DATE AS date,
       COALESCE(SUM(oi.total_price), 0)      AS revenue,
       COUNT(DISTINCT o.id)                  AS orders
     FROM order_items oi
     JOIN orders o ON o.id = oi.order_id
     WHERE oi.supplier_id = $1
       AND o.status NOT IN ('cancelled','refunded')
       AND o.created_at >= NOW() - ($2 || ' days')::INTERVAL
     GROUP BY 1
     ORDER BY 1 ASC`,
    [supplierId, days]
  );
  return rows;
};

const getTopProducts = async (supplierId, limit = 10) => {
  const { rows } = await query(
    `SELECT
       p.id,
       p.name,
       p.sku,
       p.average_rating,
       p.review_count,
       COALESCE(SUM(oi.total_price), 0) AS revenue,
       COALESCE(SUM(oi.quantity),    0) AS units_sold
     FROM order_items oi
     JOIN products p ON p.id = oi.product_id
     JOIN orders   o ON o.id = oi.order_id
     WHERE oi.supplier_id = $1
       AND o.status NOT IN ('cancelled','refunded')
     GROUP BY p.id
     ORDER BY revenue DESC
     LIMIT $2`,
    [supplierId, limit]
  );
  return rows;
};

const getOrderStatusBreakdown = async (supplierId) => {
  const { rows } = await query(
    `SELECT o.status, COUNT(DISTINCT o.id) AS count
     FROM order_items oi
     JOIN orders o ON o.id = oi.order_id
     WHERE oi.supplier_id = $1
       AND o.created_at >= NOW() - INTERVAL '90 days'
     GROUP BY o.status
     ORDER BY count DESC`,
    [supplierId]
  );
  return rows;
};

module.exports = {
  getSupplierIdForUser,
  getDashboardKpis,
  getDailyRevenue,
  getTopProducts,
  getOrderStatusBreakdown,
};
