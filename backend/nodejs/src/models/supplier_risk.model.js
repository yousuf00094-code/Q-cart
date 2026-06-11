const { query } = require('../config/database');

const findBySupplierId = async (supplierId) => {
  const { rows } = await query(
    `SELECT srs.*, s.name AS supplier_name, s.status AS supplier_status, s.email AS supplier_email
     FROM supplier_risk_scores srs
     JOIN suppliers s ON s.id = srs.supplier_id
     WHERE srs.supplier_id = $1`,
    [supplierId]
  );
  return rows[0] || null;
};

const listAll = async ({ limit, offset, risk_level }) => {
  const conditions = [];
  const values = [];
  let idx = 1;

  if (risk_level) {
    conditions.push(`srs.risk_level = $${idx++}`);
    values.push(risk_level);
  }

  const where = conditions.length ? `WHERE ${conditions.join(' AND ')}` : '';

  const [countRes, dataRes] = await Promise.all([
    query(`SELECT COUNT(*) FROM supplier_risk_scores srs ${where}`, values),
    query(
      `SELECT srs.*, s.name AS supplier_name, s.status AS supplier_status, s.email AS supplier_email
       FROM supplier_risk_scores srs
       JOIN suppliers s ON s.id = srs.supplier_id
       ${where}
       ORDER BY srs.score DESC
       LIMIT $${idx} OFFSET $${idx + 1}`,
      [...values, limit, offset]
    ),
  ]);

  return { rows: dataRes.rows, total: parseInt(countRes.rows[0].count, 10) };
};

const upsert = async (supplierId, { score, risk_level, factors }) => {
  const { rows } = await query(
    `INSERT INTO supplier_risk_scores (supplier_id, score, risk_level, factors, computed_at)
     VALUES ($1, $2, $3, $4, NOW())
     ON CONFLICT (supplier_id) DO UPDATE
       SET score       = EXCLUDED.score,
           risk_level  = EXCLUDED.risk_level,
           factors     = EXCLUDED.factors,
           computed_at = NOW(),
           updated_at  = NOW()
     RETURNING *`,
    [supplierId, score, risk_level, JSON.stringify(factors)]
  );
  return rows[0];
};

module.exports = { findBySupplierId, listAll, upsert };
