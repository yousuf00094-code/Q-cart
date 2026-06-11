const { query } = require('../config/database');

const findById = async (id) => {
  const { rows } = await query('SELECT * FROM addresses WHERE id = $1', [id]);
  return rows[0] || null;
};

const findByUser = async (userId) => {
  const { rows } = await query(
    `SELECT * FROM addresses
      WHERE user_id = $1
     ORDER BY is_default DESC, created_at DESC`,
    [userId]
  );
  return rows;
};

const findDefault = async (userId) => {
  const { rows } = await query(
    'SELECT * FROM addresses WHERE user_id = $1 AND is_default = TRUE LIMIT 1',
    [userId]
  );
  return rows[0] || null;
};

const create = async (userId, data) => {
  // If this is the user's first address, make it default automatically
  const { rows: existing } = await query(
    'SELECT id FROM addresses WHERE user_id = $1 LIMIT 1',
    [userId]
  );
  const makeDefault = existing.length === 0 ? true : !!data.is_default;

  // Clear other defaults first if needed
  if (makeDefault) {
    await query(
      'UPDATE addresses SET is_default = FALSE WHERE user_id = $1',
      [userId]
    );
  }

  const { rows } = await query(
    `INSERT INTO addresses
       (user_id, label, first_name, last_name, phone,
        address_line1, address_line2, city, state, country,
        postal_code, latitude, longitude, is_default)
     VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14)
     RETURNING *`,
    [
      userId,
      data.label || 'Home',
      data.first_name,
      data.last_name,
      data.phone || null,
      data.address_line1,
      data.address_line2 || null,
      data.city,
      data.state || null,
      data.country || 'QA',
      data.postal_code || null,
      data.latitude  || null,
      data.longitude || null,
      makeDefault,
    ]
  );
  return rows[0];
};

const update = async (id, userId, data) => {
  const allowed = ['label','first_name','last_name','phone','address_line1',
    'address_line2','city','state','country','postal_code','latitude','longitude'];
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

  values.push(id, userId);
  const { rows } = await query(
    `UPDATE addresses SET ${sets.join(', ')} WHERE id = $${idx} AND user_id = $${idx + 1} RETURNING *`,
    values
  );
  return rows[0] || null;
};

const setDefault = async (id, userId) => {
  // Clear all defaults for this user then set the new one
  await query('UPDATE addresses SET is_default = FALSE WHERE user_id = $1', [userId]);
  const { rows } = await query(
    'UPDATE addresses SET is_default = TRUE WHERE id = $1 AND user_id = $2 RETURNING *',
    [id, userId]
  );
  return rows[0] || null;
};

const remove = async (id, userId) => {
  const addr = await findById(id);
  if (!addr) return false;

  const { rowCount } = await query(
    'DELETE FROM addresses WHERE id = $1 AND user_id = $2',
    [id, userId]
  );

  // If we deleted the default, promote the most recent remaining address
  if (rowCount && addr.is_default) {
    await query(
      `UPDATE addresses SET is_default = TRUE
        WHERE id = (
          SELECT id FROM addresses WHERE user_id = $1 ORDER BY created_at DESC LIMIT 1
        )`,
      [userId]
    );
  }

  return rowCount > 0;
};

module.exports = { findById, findByUser, findDefault, create, update, setDefault, remove };
