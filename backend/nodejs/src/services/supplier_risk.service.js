const { query } = require('../config/database');
const RiskModel = require('../models/supplier_risk.model');

const computeRiskScore = async (supplierId) => {
  let score = 0;
  const factors = [];

  // ── Factor 1: Cancellation / return rate (up to 30 pts) ───────────────────
  const { rows: orderRows } = await query(
    `SELECT
       COUNT(*) FILTER (WHERE o.status NOT IN ('cancelled','refunded')) AS fulfilled,
       COUNT(*) FILTER (WHERE o.status IN  ('cancelled','refunded'))    AS cancelled,
       COUNT(*)                                                          AS total
     FROM order_items oi
     JOIN orders o ON o.id = oi.order_id
     WHERE oi.supplier_id = $1
       AND o.created_at >= NOW() - INTERVAL '90 days'`,
    [supplierId]
  );

  const total     = parseInt(orderRows[0].total,     10);
  const cancelled = parseInt(orderRows[0].cancelled, 10);
  const cancelPct = total > 0 ? (cancelled / total) * 100 : 0;
  const cancelTarget = 5.0;

  if (cancelPct > cancelTarget && total >= 5) {
    const pts = Math.min(30, Math.round((cancelPct - cancelTarget) * 3));
    score += pts;
    factors.push({
      label:    `High cancellation/return rate (${cancelPct.toFixed(1)}%)`,
      actual:   parseFloat(cancelPct.toFixed(1)),
      target:   cancelTarget,
      severity: cancelPct > 10 ? 'critical' : 'warning',
    });
  }

  // ── Factor 2: Average product rating (up to 25 pts) ───────────────────────
  const { rows: ratingRows } = await query(
    `SELECT COALESCE(AVG(r.rating), 5) AS avg_rating, COUNT(*) AS cnt
     FROM reviews r
     JOIN products p ON p.id = r.product_id
     WHERE p.supplier_id = $1 AND r.is_approved = TRUE`,
    [supplierId]
  );

  const avgRating    = parseFloat(ratingRows[0].avg_rating);
  const ratingCount  = parseInt(ratingRows[0].cnt, 10);
  const ratingTarget = 4.0;

  if (avgRating < ratingTarget && ratingCount >= 5) {
    const pts = Math.min(25, Math.round((ratingTarget - avgRating) * 15));
    score += pts;
    factors.push({
      label:    `Below-target average rating (${avgRating.toFixed(1)} / 5)`,
      actual:   parseFloat(avgRating.toFixed(1)),
      target:   ratingTarget,
      severity: avgRating < 3.0 ? 'critical' : 'warning',
    });
  }

  // ── Factor 3: On-time delivery rate (up to 25 pts) ────────────────────────
  const { rows: shipRows } = await query(
    `SELECT
       COUNT(*) FILTER (
         WHERE delivered_at IS NOT NULL
           AND (estimated_delivery IS NULL OR delivered_at <= estimated_delivery)
       ) AS on_time,
       COUNT(*) FILTER (
         WHERE delivered_at IS NOT NULL
           AND estimated_delivery IS NOT NULL
           AND delivered_at > estimated_delivery
       ) AS late,
       COUNT(*) FILTER (WHERE status = 'delivered') AS total_delivered
     FROM shipments
     WHERE supplier_id = $1
       AND created_at >= NOW() - INTERVAL '90 days'`,
    [supplierId]
  );

  const delivered  = parseInt(shipRows[0].total_delivered, 10);
  const lateCount  = parseInt(shipRows[0].late, 10);
  const onTimePct  = delivered > 0 ? ((delivered - lateCount) / delivered) * 100 : 100;
  const onTimeTarget = 95.0;

  if (onTimePct < onTimeTarget && delivered >= 3) {
    const pts = Math.min(25, Math.round((onTimeTarget - onTimePct) * 1.5));
    score += pts;
    factors.push({
      label:    `Low on-time delivery rate (${onTimePct.toFixed(1)}%)`,
      actual:   parseFloat(onTimePct.toFixed(1)),
      target:   onTimeTarget,
      severity: onTimePct < 80 ? 'critical' : 'warning',
    });
  }

  // ── Factor 4: Inventory fill rate (up to 20 pts) ──────────────────────────
  const { rows: invRows } = await query(
    `SELECT
       COUNT(*) FILTER (WHERE i.quantity = 0 OR i.id IS NULL) AS out_of_stock,
       COUNT(*)                                                AS total
     FROM products p
     LEFT JOIN inventory i ON i.product_id = p.id
     WHERE p.supplier_id = $1 AND p.is_active = TRUE`,
    [supplierId]
  );

  const totalProducts = parseInt(invRows[0].total,        10);
  const outOfStock    = parseInt(invRows[0].out_of_stock, 10);
  const fillPct       = totalProducts > 0 ? ((totalProducts - outOfStock) / totalProducts) * 100 : 100;
  const fillTarget    = 90.0;

  if (fillPct < fillTarget && totalProducts >= 5) {
    const pts = Math.min(20, Math.round((fillTarget - fillPct) * 1.5));
    score += pts;
    factors.push({
      label:    `Low inventory fill rate (${fillPct.toFixed(1)}%)`,
      actual:   parseFloat(fillPct.toFixed(1)),
      target:   fillTarget,
      severity: fillPct < 70 ? 'critical' : 'warning',
    });
  }

  score = Math.min(100, score);

  const risk_level =
    score >= 60 ? 'high'   :
    score >= 35 ? 'medium' :
    score >= 15 ? 'low'    : 'minimal';

  return RiskModel.upsert(supplierId, { score, risk_level, factors });
};

module.exports = { computeRiskScore };
