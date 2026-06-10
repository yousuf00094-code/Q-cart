const { query } = require('../config/database');

const findByUser = async (userId, { limit, offset }) => {
  const countRes = await query(
    'SELECT COUNT(*) FROM wishlist WHERE user_id = $1', [userId]
  );
  const { rows } = await query(
    `SELECT w.id, w.added_at,
            p.id AS product_id, p.name, p.slug, p.price, p.compare_at_price,
            p.images, p.average_rating, p.review_count,
            COALESCE(i.quantity - i.reserved, 0) AS available_quantity
       FROM wishlist w
       JOIN products p ON p.id = w.product_id
       LEFT JOIN inventory i ON i.product_id = p.id
      WHERE w.user_id = $1
     ORDER BY w.added_at DESC
     LIMIT $2 OFFSET $3`,
    [userId, limit, offset]
  );
  return { rows, total: parseInt(countRes.rows[0].count, 10) };
};

const add = async (userId, productId) => {
  const { rows } = await query(
    `INSERT INTO wishlist (user_id, product_id)
     VALUES ($1, $2)
     ON CONFLICT (user_id, product_id) DO NOTHING
     RETURNING id, added_at`,
    [userId, productId]
  );
  return rows[0] || null;
};

const remove = async (userId, productId) => {
  const { rowCount } = await query(
    'DELETE FROM wishlist WHERE user_id = $1 AND product_id = $2',
    [userId, productId]
  );
  return rowCount > 0;
};

const exists = async (userId, productId) => {
  const { rows } = await query(
    'SELECT 1 FROM wishlist WHERE user_id = $1 AND product_id = $2',
    [userId, productId]
  );
  return rows.length > 0;
};

const clear = async (userId) => {
  await query('DELETE FROM wishlist WHERE user_id = $1', [userId]);
};

module.exports = { findByUser, add, remove, exists, clear };
