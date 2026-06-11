const { query } = require('../config/database');
const { AppError } = require('../middleware/errorHandler');
const { parsePagination, buildMeta } = require('../utils/pagination');
const { getSupplierIdForUser } = require('../services/supplier_analytics.service');

const list = async (req, res, next) => {
  try {
    const supplierId = await getSupplierIdForUser(req.user.id);
    if (!supplierId) throw new AppError('No active supplier account found.', 403, 'FORBIDDEN');

    const { page, limit, offset } = parsePagination(req.query);
    const conditions = ['p.supplier_id = $1', 'r.is_approved = TRUE'];
    const values = [supplierId];
    let idx = 2;

    if (req.query.rating) {
      conditions.push(`r.rating = $${idx++}`);
      values.push(parseInt(req.query.rating, 10));
    }
    if (req.query.product_id) {
      conditions.push(`r.product_id = $${idx++}`);
      values.push(req.query.product_id);
    }
    if (req.query.replied === 'true') {
      conditions.push('r.reply IS NOT NULL');
    } else if (req.query.replied === 'false') {
      conditions.push('r.reply IS NULL');
    }

    const where = `WHERE ${conditions.join(' AND ')}`;

    const [countRes, dataRes] = await Promise.all([
      query(
        `SELECT COUNT(*)
         FROM reviews r
         JOIN products p ON p.id = r.product_id
         ${where}`,
        values
      ),
      query(
        `SELECT r.*, p.name AS product_name, u.full_name AS reviewer_name
         FROM reviews r
         JOIN products p ON p.id = r.product_id
         JOIN users    u ON u.id = r.user_id
         ${where}
         ORDER BY r.created_at DESC
         LIMIT $${idx} OFFSET $${idx + 1}`,
        [...values, limit, offset]
      ),
    ]);

    res.json({
      data: dataRes.rows,
      meta: buildMeta(parseInt(countRes.rows[0].count, 10), page, limit),
    });
  } catch (err) { next(err); }
};

const summary = async (req, res, next) => {
  try {
    const supplierId = await getSupplierIdForUser(req.user.id);
    if (!supplierId) throw new AppError('No active supplier account found.', 403, 'FORBIDDEN');

    const { rows } = await query(
      `SELECT
         COALESCE(AVG(r.rating), 0)                              AS avg_rating,
         COUNT(r.id)                                             AS total_reviews,
         COUNT(r.id) FILTER (WHERE r.rating = 5)                AS five_star,
         COUNT(r.id) FILTER (WHERE r.rating = 4)                AS four_star,
         COUNT(r.id) FILTER (WHERE r.rating = 3)                AS three_star,
         COUNT(r.id) FILTER (WHERE r.rating = 2)                AS two_star,
         COUNT(r.id) FILTER (WHERE r.rating = 1)                AS one_star,
         COUNT(r.id) FILTER (WHERE r.reply IS NOT NULL)         AS replied_count,
         COUNT(r.id) FILTER (WHERE r.reply IS NULL)             AS pending_reply_count
       FROM reviews r
       JOIN products p ON p.id = r.product_id
       WHERE p.supplier_id = $1 AND r.is_approved = TRUE`,
      [supplierId]
    );

    res.json({ data: rows[0] });
  } catch (err) { next(err); }
};

const reply = async (req, res, next) => {
  try {
    const supplierId = await getSupplierIdForUser(req.user.id);
    if (!supplierId) throw new AppError('No active supplier account found.', 403, 'FORBIDDEN');

    const { rows: check } = await query(
      `SELECT r.id FROM reviews r
       JOIN products p ON p.id = r.product_id
       WHERE r.id = $1 AND p.supplier_id = $2`,
      [req.params.id, supplierId]
    );
    if (!check.length) throw new AppError('Review not found.', 404, 'NOT_FOUND');

    const { rows } = await query(
      `UPDATE reviews SET reply = $1, replied_at = NOW() WHERE id = $2 RETURNING *`,
      [req.body.reply, req.params.id]
    );

    res.json({ data: rows[0] });
  } catch (err) { next(err); }
};

module.exports = { list, summary, reply };
