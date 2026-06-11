const { query } = require('../config/database');

const SAFE_COLUMNS = `
  p.id, p.name, p.slug, p.short_description, p.description, p.sku, p.barcode,
  p.price, p.compare_at_price, p.weight_grams, p.images, p.attributes, p.tags,
  p.is_active, p.is_featured, p.average_rating, p.review_count, p.total_sold,
  p.created_at, p.updated_at,
  c.id   AS category_id,   c.name AS category_name,   c.slug AS category_slug,
  s.id   AS supplier_id,   s.name AS supplier_name,
  COALESCE(i.quantity - i.reserved, 0) AS available_quantity,
  COALESCE(i.quantity, 0) AS stock_quantity`;

const findById = async (id) => {
  const { rows } = await query(
    `SELECT ${SAFE_COLUMNS}
       FROM products p
       LEFT JOIN categories  c ON c.id = p.category_id
       LEFT JOIN suppliers   s ON s.id = p.supplier_id
       LEFT JOIN inventory   i ON i.product_id = p.id
      WHERE p.id = $1`,
    [id]
  );
  return rows[0] || null;
};

// Batch fetch multiple products by ID — used by checkout to avoid N+1 queries
const findManyByIds = async (ids) => {
  if (!ids.length) return [];
  const { rows } = await query(
    `SELECT ${SAFE_COLUMNS}
       FROM products p
       LEFT JOIN categories  c ON c.id = p.category_id
       LEFT JOIN suppliers   s ON s.id = p.supplier_id
       LEFT JOIN inventory   i ON i.product_id = p.id
      WHERE p.id = ANY($1::uuid[])`,
    [ids]
  );
  return rows;
};

const findBySlug = async (slug) => {
  const { rows } = await query(
    `SELECT ${SAFE_COLUMNS}
       FROM products p
       LEFT JOIN categories  c ON c.id = p.category_id
       LEFT JOIN suppliers   s ON s.id = p.supplier_id
       LEFT JOIN inventory   i ON i.product_id = p.id
      WHERE p.slug = $1`,
    [slug]
  );
  return rows[0] || null;
};

// cursor: { id, created_at } from decodeCursor — when present, uses keyset
// pagination instead of OFFSET. Fetch limit+1 rows so the caller can detect
// whether a next page exists without running a separate COUNT query.
const list = async ({ limit, offset, cursor, categoryId, supplierId, search,
  minPrice, maxPrice, minRating, inStock, isActive, isFeatured, sort }) => {
  const conditions = [];
  const values = [];
  let idx = 1;

  if (isActive !== undefined) { conditions.push(`p.is_active = $${idx++}`); values.push(isActive); }
  if (isFeatured) { conditions.push(`p.is_featured = TRUE`); }
  if (categoryId) { conditions.push(`p.category_id = $${idx++}`); values.push(categoryId); }
  if (supplierId) { conditions.push(`p.supplier_id = $${idx++}`); values.push(supplierId); }
  if (minPrice !== undefined) { conditions.push(`p.price >= $${idx++}`); values.push(minPrice); }
  if (maxPrice !== undefined) { conditions.push(`p.price <= $${idx++}`); values.push(maxPrice); }
  if (minRating !== undefined) { conditions.push(`p.average_rating >= $${idx++}`); values.push(minRating); }
  if (inStock) { conditions.push(`COALESCE(i.quantity - i.reserved, 0) > 0`); }
  if (search) {
    conditions.push(`(p.name ILIKE $${idx} OR p.sku ILIKE $${idx} OR $${idx} = ANY(p.tags))`);
    values.push(`%${search}%`);
    idx++;
  }

  const orderMap = {
    price_asc:       'p.price ASC, p.id ASC',
    price_desc:      'p.price DESC, p.id DESC',
    rating_desc:     'p.average_rating DESC, p.id DESC',
    sold_desc:       'p.total_sold DESC, p.id DESC',
    created_at_desc: 'p.created_at DESC, p.id DESC',
  };
  const orderBy = orderMap[sort] || 'p.created_at DESC, p.id DESC';

  // Cursor mode: no OFFSET, no COUNT — O(1) pagination regardless of page depth
  if (cursor) {
    conditions.push(
      `(p.created_at < $${idx}::timestamptz OR ` +
      `(p.created_at = $${idx}::timestamptz AND p.id < $${idx + 1}::uuid))`
    );
    values.push(cursor.created_at, cursor.id);
    idx += 2;

    const where = conditions.length ? `WHERE ${conditions.join(' AND ')}` : '';
    const { rows } = await query(
      `SELECT ${SAFE_COLUMNS}
         FROM products p
         LEFT JOIN categories  c ON c.id = p.category_id
         LEFT JOIN suppliers   s ON s.id = p.supplier_id
         LEFT JOIN inventory   i ON i.product_id = p.id
       ${where}
       ORDER BY ${orderBy}
       LIMIT $${idx}`,
      [...values, limit + 1] // fetch one extra to detect next page
    );
    return { rows, total: null, cursorMode: true };
  }

  // Offset mode (used by admin endpoints that need total counts)
  const where = conditions.length ? `WHERE ${conditions.join(' AND ')}` : '';
  const countRes = await query(
    `SELECT COUNT(*) FROM products p LEFT JOIN inventory i ON i.product_id = p.id ${where}`,
    values
  );
  const { rows } = await query(
    `SELECT ${SAFE_COLUMNS}
       FROM products p
       LEFT JOIN categories  c ON c.id = p.category_id
       LEFT JOIN suppliers   s ON s.id = p.supplier_id
       LEFT JOIN inventory   i ON i.product_id = p.id
     ${where}
     ORDER BY ${orderBy}
     LIMIT $${idx} OFFSET $${idx + 1}`,
    [...values, limit, offset]
  );
  return { rows, total: parseInt(countRes.rows[0].count, 10), cursorMode: false };
};

const create = async (data) => {
  const { rows } = await query(
    `INSERT INTO products
       (category_id, supplier_id, name, slug, description, short_description,
        sku, barcode, price, compare_at_price, cost_price, weight_grams,
        images, attributes, tags, is_active, is_featured)
     VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15,$16,$17)
     RETURNING id, name, slug, sku, price, is_active, created_at`,
    [
      data.category_id, data.supplier_id || null, data.name, data.slug,
      data.description || null, data.short_description || null,
      data.sku || null, data.barcode || null, data.price,
      data.compare_at_price || null, data.cost_price || null,
      data.weight_grams || null,
      JSON.stringify(data.images || []),
      JSON.stringify(data.attributes || {}),
      data.tags || [],
      data.is_active !== false, data.is_featured || false,
    ]
  );
  return rows[0];
};

const update = async (id, data) => {
  const allowed = ['category_id','supplier_id','name','slug','description',
    'short_description','sku','barcode','price','compare_at_price','cost_price',
    'weight_grams','images','attributes','tags','is_active','is_featured'];
  const sets = [];
  const values = [];
  let idx = 1;

  for (const key of allowed) {
    if (data[key] !== undefined) {
      sets.push(`${key} = $${idx++}`);
      const v = (key === 'images' || key === 'attributes') ? JSON.stringify(data[key]) : data[key];
      values.push(v);
    }
  }
  if (!sets.length) return findById(id);

  values.push(id);
  const { rows } = await query(
    `UPDATE products SET ${sets.join(', ')} WHERE id = $${idx} RETURNING id, name, slug, updated_at`,
    values
  );
  return rows[0] || null;
};

const remove = async (id) => {
  const { rowCount } = await query('DELETE FROM products WHERE id = $1', [id]);
  return rowCount > 0;
};

const incrementSold = async (id, qty, client) => {
  const fn = client
    ? (t, v) => client.query(t, v)
    : (t, v) => query(t, v);
  await fn('UPDATE products SET total_sold = total_sold + $1 WHERE id = $2', [qty, id]);
};

module.exports = { findById, findManyByIds, findBySlug, list, create, update, remove, incrementSold };
