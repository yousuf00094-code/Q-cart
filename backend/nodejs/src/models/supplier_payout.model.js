const { query } = require('../config/database');

const findById = async (id) => {
  const { rows } = await query(
    `SELECT sp.*, s.name AS supplier_name
     FROM supplier_payouts sp
     JOIN suppliers s ON s.id = sp.supplier_id
     WHERE sp.id = $1`,
    [id]
  );
  return rows[0] || null;
};

const listBySupplier = async (supplierId, { limit, offset, status }) => {
  const conditions = ['sp.supplier_id = $1'];
  const values = [supplierId];
  let idx = 2;

  if (status) {
    conditions.push(`sp.status = $${idx++}`);
    values.push(status);
  }

  const where = `WHERE ${conditions.join(' AND ')}`;

  const [countRes, dataRes] = await Promise.all([
    query(`SELECT COUNT(*) FROM supplier_payouts sp ${where}`, values),
    query(
      `SELECT sp.*
       FROM supplier_payouts sp
       ${where}
       ORDER BY sp.period_from DESC
       LIMIT $${idx} OFFSET $${idx + 1}`,
      [...values, limit, offset]
    ),
  ]);

  return { rows: dataRes.rows, total: parseInt(countRes.rows[0].count, 10) };
};

const getItems = async (payoutId) => {
  const { rows } = await query(
    `SELECT spi.*, o.status AS order_status
     FROM supplier_payout_items spi
     LEFT JOIN orders o ON o.id = spi.order_id
     WHERE spi.payout_id = $1
     ORDER BY spi.created_at DESC`,
    [payoutId]
  );
  return rows;
};

const listAll = async ({ limit, offset, status, supplier_id }) => {
  const conditions = [];
  const values = [];
  let idx = 1;

  if (status) {
    conditions.push(`sp.status = $${idx++}`);
    values.push(status);
  }
  if (supplier_id) {
    conditions.push(`sp.supplier_id = $${idx++}`);
    values.push(supplier_id);
  }

  const where = conditions.length ? `WHERE ${conditions.join(' AND ')}` : '';

  const [countRes, dataRes] = await Promise.all([
    query(`SELECT COUNT(*) FROM supplier_payouts sp ${where}`, values),
    query(
      `SELECT sp.*, s.name AS supplier_name
       FROM supplier_payouts sp
       JOIN suppliers s ON s.id = sp.supplier_id
       ${where}
       ORDER BY sp.period_from DESC
       LIMIT $${idx} OFFSET $${idx + 1}`,
      [...values, limit, offset]
    ),
  ]);

  return { rows: dataRes.rows, total: parseInt(countRes.rows[0].count, 10) };
};

module.exports = { findById, listBySupplier, getItems, listAll };
