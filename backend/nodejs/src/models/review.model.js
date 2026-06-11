const { query } = require('../config/database');

const findById = async (id) => {
  const { rows } = await query('SELECT * FROM reviews WHERE id = $1', [id]);
  return rows[0] || null;
};

const findByProductAndUser = async (productId, userId, orderId) => {
  // NULL != NULL in SQL, so we can't use `= $3` when orderId is null
  const { rows } = orderId
    ? await query(
        'SELECT id FROM reviews WHERE product_id = $1 AND user_id = $2 AND order_id = $3',
        [productId, userId, orderId]
      )
    : await query(
        'SELECT id FROM reviews WHERE product_id = $1 AND user_id = $2 AND order_id IS NULL',
        [productId, userId]
      );
  return rows[0] || null;
};

const listByProduct = async (productId, { limit, offset, rating, sort }) => {
  const conditions = ['r.product_id = $1', 'r.is_approved = TRUE'];
  const values = [productId];
  let idx = 2;

  if (rating) { conditions.push(`r.rating = $${idx++}`); values.push(rating); }

  const orderMap = {
    recent: 'r.created_at DESC',
    helpful: 'r.helpful_count DESC',
    highest: 'r.rating DESC',
    lowest: 'r.rating ASC',
  };
  const orderBy = orderMap[sort] || 'r.created_at DESC';
  const where = `WHERE ${conditions.join(' AND ')}`;

  const countRes = await query(`SELECT COUNT(*) FROM reviews r ${where}`, values);

  const { rows: stats } = await query(
    `SELECT ROUND(AVG(rating)::NUMERIC,2) AS avg_rating,
            COUNT(*) FILTER (WHERE rating = 5) AS r5,
            COUNT(*) FILTER (WHERE rating = 4) AS r4,
            COUNT(*) FILTER (WHERE rating = 3) AS r3,
            COUNT(*) FILTER (WHERE rating = 2) AS r2,
            COUNT(*) FILTER (WHERE rating = 1) AS r1
       FROM reviews WHERE product_id = $1 AND is_approved = TRUE`,
    [productId]
  );

  const { rows } = await query(
    `SELECT r.id, r.rating, r.title, r.body, r.images, r.is_verified,
            r.helpful_count, r.reply, r.replied_at, r.created_at,
            u.id AS user_id, u.full_name, u.avatar_url
       FROM reviews r
       JOIN users u ON u.id = r.user_id
       ${where}
     ORDER BY ${orderBy}
     LIMIT $${idx} OFFSET $${idx + 1}`,
    [...values, limit, offset]
  );

  return { rows, total: parseInt(countRes.rows[0].count, 10), stats: stats[0] };
};

const create = async ({ productId, userId, orderId, rating, title, body, images, isVerified }) => {
  const { rows } = await query(
    `INSERT INTO reviews
       (product_id, user_id, order_id, rating, title, body, images, is_verified, is_approved)
     VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9)
     RETURNING id, rating, title, body, created_at`,
    [productId, userId, orderId || null, rating, title || null, body || null,
     images || [], isVerified || false,
     true] // auto-approve; add admin moderation queue via PATCH /reviews/:id/approve when needed
  );
  return rows[0];
};

const update = async (id, { rating, title, body, images }) => {
  const { rows } = await query(
    `UPDATE reviews SET rating = $1, title = $2, body = $3, images = $4
     WHERE id = $5 RETURNING id, rating, title, body, updated_at`,
    [rating, title || null, body || null, images || [], id]
  );
  return rows[0] || null;
};

const remove = async (id) => {
  const { rowCount } = await query('DELETE FROM reviews WHERE id = $1', [id]);
  return rowCount > 0;
};

const incrementHelpful = async (id) => {
  const { rows } = await query(
    'UPDATE reviews SET helpful_count = helpful_count + 1 WHERE id = $1 RETURNING helpful_count',
    [id]
  );
  return rows[0];
};

const setReply = async (id, reply) => {
  const { rows } = await query(
    `UPDATE reviews SET reply = $1, replied_at = NOW() WHERE id = $2
     RETURNING id, reply, replied_at`,
    [reply, id]
  );
  return rows[0] || null;
};

module.exports = { findById, findByProductAndUser, listByProduct, create, update, remove, incrementHelpful, setReply };
