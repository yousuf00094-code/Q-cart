const { query } = require('../config/database');

const findById = async (id) => {
  const { rows } = await query('SELECT * FROM categories WHERE id = $1', [id]);
  return rows[0] || null;
};

const findBySlug = async (slug) => {
  const { rows } = await query('SELECT * FROM categories WHERE slug = $1', [slug]);
  return rows[0] || null;
};

const listRoots = async (includeInactive = false) => {
  const conditions = ['c.parent_id IS NULL'];
  if (!includeInactive) conditions.push('c.is_active = TRUE');
  const where = `WHERE ${conditions.join(' AND ')}`;

  const { rows } = await query(
    `SELECT c.*,
            COUNT(DISTINCT p.id) FILTER (WHERE p.is_active = TRUE) AS product_count
       FROM categories c
       LEFT JOIN products p ON p.category_id = c.id
       ${where}
     GROUP BY c.id
     ORDER BY c.sort_order, c.name`
  );
  return rows;
};

const listChildren = async (parentId) => {
  const { rows } = await query(
    `SELECT c.*,
            COUNT(DISTINCT p.id) FILTER (WHERE p.is_active = TRUE) AS product_count
       FROM categories c
       LEFT JOIN products p ON p.category_id = c.id
      WHERE c.parent_id = $1
     GROUP BY c.id
     ORDER BY c.sort_order, c.name`,
    [parentId]
  );
  return rows;
};

const create = async ({ name, slug, description, image_url, parent_id, sort_order }) => {
  const { rows } = await query(
    `INSERT INTO categories (name, slug, description, image_url, parent_id, sort_order)
     VALUES ($1,$2,$3,$4,$5,$6) RETURNING *`,
    [name, slug, description || null, image_url || null, parent_id || null, sort_order || 0]
  );
  return rows[0];
};

const update = async (id, data) => {
  const allowed = ['name','slug','description','image_url','parent_id','sort_order','is_active'];
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
    `UPDATE categories SET ${sets.join(', ')} WHERE id = $${idx} RETURNING *`,
    values
  );
  return rows[0] || null;
};

const remove = async (id) => {
  const { rowCount } = await query('DELETE FROM categories WHERE id = $1', [id]);
  return rowCount > 0;
};

// Fetch children for multiple parents in a single query — used by the
// categories list endpoint to eliminate the N+1 query pattern.
const listChildrenBatch = async (parentIds) => {
  if (!parentIds.length) return [];
  const { rows } = await query(
    `SELECT c.*,
            COUNT(DISTINCT p.id) FILTER (WHERE p.is_active = TRUE) AS product_count
       FROM categories c
       LEFT JOIN products p ON p.category_id = c.id
      WHERE c.parent_id = ANY($1::uuid[])
     GROUP BY c.id
     ORDER BY c.sort_order, c.name`,
    [parentIds]
  );
  return rows;
};

module.exports = { findById, findBySlug, listRoots, listChildren, listChildrenBatch, create, update, remove };
