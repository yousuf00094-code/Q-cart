const { query } = require('../config/database');

const findById = async (id) => {
  const { rows } = await query(
    `SELECT s.*, COUNT(p.id) AS product_count
       FROM suppliers s
       LEFT JOIN products p ON p.supplier_id = s.id AND p.is_active = TRUE
      WHERE s.id = $1
     GROUP BY s.id`,
    [id]
  );
  return rows[0] || null;
};

const list = async ({ limit, offset, status, search }) => {
  const conditions = [];
  const values = [];
  let idx = 1;

  if (status) { conditions.push(`s.status = $${idx++}`); values.push(status); }
  if (search) {
    conditions.push(`(s.name ILIKE $${idx} OR s.email ILIKE $${idx})`);
    values.push(`%${search}%`);
    idx++;
  }

  const where = conditions.length ? `WHERE ${conditions.join(' AND ')}` : '';
  const countRes = await query(`SELECT COUNT(*) FROM suppliers s ${where}`, values);
  const { rows } = await query(
    `SELECT s.*, COUNT(p.id) AS product_count
       FROM suppliers s
       LEFT JOIN products p ON p.supplier_id = s.id AND p.is_active = TRUE
       ${where}
     GROUP BY s.id
     ORDER BY s.created_at DESC
     LIMIT $${idx} OFFSET $${idx + 1}`,
    [...values, limit, offset]
  );
  return { rows, total: parseInt(countRes.rows[0].count, 10) };
};

const create = async ({ name, email, phone, address, contact_person, logo_url }) => {
  const { rows } = await query(
    `INSERT INTO suppliers (name, email, phone, address, contact_person, logo_url)
     VALUES ($1,$2,$3,$4,$5,$6) RETURNING *`,
    [name, email.toLowerCase(), phone || null, address || null, contact_person || null, logo_url || null]
  );
  return rows[0];
};

const update = async (id, data) => {
  const allowed = ['name','email','phone','address','contact_person','logo_url','status','notes'];
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
    `UPDATE suppliers SET ${sets.join(', ')} WHERE id = $${idx} RETURNING *`,
    values
  );
  return rows[0] || null;
};

const setStatus = async (id, status) => {
  const { rows } = await query(
    'UPDATE suppliers SET status = $1 WHERE id = $2 RETURNING id, status',
    [status, id]
  );
  return rows[0] || null;
};

module.exports = { findById, list, create, update, setStatus };
