const { query, withTransaction } = require('../config/database');

const findById = async (id) => {
  const { rows } = await query(
    `SELECT id, full_name, email, phone, role, avatar_url,
            is_email_verified, is_active, last_login_at, created_at, updated_at
       FROM users WHERE id = $1`,
    [id]
  );
  return rows[0] || null;
};

const findByEmail = async (email) => {
  const { rows } = await query(
    'SELECT * FROM users WHERE email = $1',
    [email.toLowerCase()]
  );
  return rows[0] || null;
};

const create = async ({ full_name, email, phone, password_hash, role = 'customer' }) => {
  const { rows } = await query(
    `INSERT INTO users (full_name, email, phone, password_hash, role)
     VALUES ($1, $2, $3, $4, $5)
     RETURNING id, full_name, email, phone, role, is_email_verified, created_at`,
    [full_name, email.toLowerCase(), phone || null, password_hash, role]
  );
  return rows[0];
};

const update = async (id, fields) => {
  const allowed = ['full_name', 'phone', 'avatar_url'];
  const sets = [];
  const values = [];
  let idx = 1;

  for (const key of allowed) {
    if (fields[key] !== undefined) {
      sets.push(`${key} = $${idx++}`);
      values.push(fields[key]);
    }
  }
  if (!sets.length) return findById(id);

  values.push(id);
  const { rows } = await query(
    `UPDATE users SET ${sets.join(', ')} WHERE id = $${idx}
     RETURNING id, full_name, email, phone, role, avatar_url, is_email_verified, updated_at`,
    values
  );
  return rows[0] || null;
};

const updatePassword = async (id, password_hash) => {
  await query('UPDATE users SET password_hash = $1 WHERE id = $2', [password_hash, id]);
};

const updateRefreshToken = async (id, refresh_token_hash) => {
  await query(
    'UPDATE users SET refresh_token_hash = $1, last_login_at = NOW() WHERE id = $2',
    [refresh_token_hash, id]
  );
};

const clearRefreshToken = async (id) => {
  await query('UPDATE users SET refresh_token_hash = NULL WHERE id = $1', [id]);
};

const setStatus = async (id, is_active) => {
  const { rows } = await query(
    'UPDATE users SET is_active = $1 WHERE id = $2 RETURNING id, is_active',
    [is_active, id]
  );
  return rows[0] || null;
};

const verifyEmail = async (id) => {
  await query('UPDATE users SET is_email_verified = TRUE WHERE id = $1', [id]);
};

const list = async ({ limit, offset, role, search }) => {
  const conditions = [];
  const values = [];
  let idx = 1;

  if (role) { conditions.push(`role = $${idx++}`); values.push(role); }
  if (search) {
    conditions.push(`(full_name ILIKE $${idx} OR email ILIKE $${idx})`);
    values.push(`%${search}%`);
    idx++;
  }

  const where = conditions.length ? `WHERE ${conditions.join(' AND ')}` : '';
  const countRes = await query(`SELECT COUNT(*) FROM users ${where}`, values);
  const { rows } = await query(
    `SELECT id, full_name, email, phone, role, is_active, created_at
       FROM users ${where}
      ORDER BY created_at DESC
      LIMIT $${idx} OFFSET $${idx + 1}`,
    [...values, limit, offset]
  );
  return { rows, total: parseInt(countRes.rows[0].count, 10) };
};

module.exports = { findById, findByEmail, create, update, updatePassword,
  updateRefreshToken, clearRefreshToken, setStatus, verifyEmail, list };
