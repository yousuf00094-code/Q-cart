const { query } = require('../config/database');

const findById = async (id) => {
  const { rows } = await query('SELECT * FROM coupons WHERE id = $1', [id]);
  return rows[0] || null;
};

const findByCode = async (code) => {
  const { rows } = await query(
    'SELECT * FROM coupons WHERE UPPER(code) = UPPER($1)', [code]
  );
  return rows[0] || null;
};

const list = async ({ limit, offset, isActive }) => {
  const conditions = [];
  const values = [];
  let idx = 1;

  if (isActive !== undefined) { conditions.push(`is_active = $${idx++}`); values.push(isActive); }

  const where = conditions.length ? `WHERE ${conditions.join(' AND ')}` : '';
  const countRes = await query(`SELECT COUNT(*) FROM coupons ${where}`, values);
  const { rows } = await query(
    `SELECT * FROM coupons ${where}
     ORDER BY created_at DESC
     LIMIT $${idx} OFFSET $${idx + 1}`,
    [...values, limit, offset]
  );
  return { rows, total: parseInt(countRes.rows[0].count, 10) };
};

const create = async (data) => {
  const { rows } = await query(
    `INSERT INTO coupons
       (code, description, discount_type, discount_value, min_order_amount,
        max_discount_amount, usage_limit, per_user_limit, is_active, valid_from, valid_until)
     VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11)
     RETURNING *`,
    [
      data.code.toUpperCase(), data.description || null,
      data.discount_type, data.discount_value,
      data.min_order_amount || 0, data.max_discount_amount || null,
      data.usage_limit || null, data.per_user_limit || 1,
      data.is_active !== false,
      data.valid_from || new Date(),
      data.valid_until || null,
    ]
  );
  return rows[0];
};

const update = async (id, data) => {
  const allowed = ['description','discount_type','discount_value','min_order_amount',
    'max_discount_amount','usage_limit','per_user_limit','is_active','valid_from','valid_until'];
  const sets = [];
  const values = [];
  let idx = 1;

  for (const key of allowed) {
    if (data[key] !== undefined) {
      sets.push(`${key} = $${idx++}`);
      values.push(data[key]);
    }
  }
  if (!sets.length) return findById(id);

  values.push(id);
  const { rows } = await query(
    `UPDATE coupons SET ${sets.join(', ')} WHERE id = $${idx} RETURNING *`,
    values
  );
  return rows[0] || null;
};

const remove = async (id) => {
  const { rowCount } = await query('DELETE FROM coupons WHERE id = $1', [id]);
  return rowCount > 0;
};

const incrementUsage = async (id, client) => {
  const fn = client ? (t, v) => client.query(t, v) : query;
  await fn('UPDATE coupons SET usage_count = usage_count + 1 WHERE id = $1', [id]);
};

const countUserUsage = async (couponId, userId) => {
  const { rows } = await query(
    `SELECT COUNT(*) FROM orders
     WHERE coupon_id = $1 AND user_id = $2
       AND status NOT IN ('cancelled','refunded')`,
    [couponId, userId]
  );
  return parseInt(rows[0].count, 10);
};

module.exports = { findById, findByCode, list, create, update, remove, incrementUsage, countUserUsage };
