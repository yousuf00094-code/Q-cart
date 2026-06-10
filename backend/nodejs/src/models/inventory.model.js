const { query } = require('../config/database');

const findByProductId = async (productId) => {
  const { rows } = await query(
    `SELECT i.*, p.name AS product_name, p.sku, s.name AS supplier_name
       FROM inventory i
       JOIN products p ON p.id = i.product_id
       LEFT JOIN suppliers s ON s.id = p.supplier_id
      WHERE i.product_id = $1`,
    [productId]
  );
  return rows[0] || null;
};

const list = async ({ limit, offset, lowStock, search }) => {
  const conditions = [];
  const values = [];
  let idx = 1;

  if (lowStock) { conditions.push(`i.quantity - i.reserved <= i.reorder_point`); }
  if (search) {
    conditions.push(`(p.name ILIKE $${idx} OR p.sku ILIKE $${idx})`);
    values.push(`%${search}%`);
    idx++;
  }

  const where = conditions.length ? `WHERE ${conditions.join(' AND ')}` : '';
  const countRes = await query(
    `SELECT COUNT(*) FROM inventory i JOIN products p ON p.id = i.product_id ${where}`,
    values
  );
  const { rows } = await query(
    `SELECT i.*, p.name AS product_name, p.sku,
            (i.quantity - i.reserved) AS available,
            s.name AS supplier_name
       FROM inventory i
       JOIN products p ON p.id = i.product_id
       LEFT JOIN suppliers s ON s.id = p.supplier_id
       ${where}
     ORDER BY (i.quantity - i.reserved) ASC
     LIMIT $${idx} OFFSET $${idx + 1}`,
    [...values, limit, offset]
  );
  return { rows, total: parseInt(countRes.rows[0].count, 10) };
};

const upsert = async (productId, quantity) => {
  const { rows } = await query(
    `INSERT INTO inventory (product_id, quantity)
     VALUES ($1, $2)
     ON CONFLICT (product_id) DO UPDATE SET quantity = $2, updated_at = NOW()
     RETURNING *`,
    [productId, quantity]
  );
  return rows[0];
};

const adjust = async (client, productId, delta) => {
  const db = client || query;
  const fn = client
    ? (t, v) => client.query(t, v)
    : query;

  const { rows } = await fn(
    `UPDATE inventory
        SET quantity = GREATEST(0, quantity + $1),
            updated_at = NOW()
      WHERE product_id = $2
     RETURNING quantity`,
    [delta, productId]
  );
  return rows[0];
};

const logTransaction = async (client, { productId, txnType, quantityDelta, quantityAfter, referenceId, notes, createdBy }) => {
  const fn = client
    ? (t, v) => client.query(t, v)
    : query;
  const { rows } = await fn(
    `INSERT INTO inventory_transactions
       (product_id, txn_type, quantity_delta, quantity_after, reference_id, notes, created_by)
     VALUES ($1,$2,$3,$4,$5,$6,$7) RETURNING id`,
    [productId, txnType, quantityDelta, quantityAfter, referenceId || null, notes || null, createdBy || null]
  );
  return rows[0];
};

const getTransactions = async (productId, { limit, offset, txnType }) => {
  const conditions = ['product_id = $1'];
  const values = [productId];
  let idx = 2;

  if (txnType) { conditions.push(`txn_type = $${idx++}`); values.push(txnType); }

  const where = `WHERE ${conditions.join(' AND ')}`;
  const countRes = await query(
    `SELECT COUNT(*) FROM inventory_transactions ${where}`, values
  );
  const { rows } = await query(
    `SELECT it.*, u.full_name AS created_by_name
       FROM inventory_transactions it
       LEFT JOIN users u ON u.id = it.created_by
       ${where}
     ORDER BY it.created_at DESC
     LIMIT $${idx} OFFSET $${idx + 1}`,
    [...values, limit, offset]
  );
  return { rows, total: parseInt(countRes.rows[0].count, 10) };
};

const getLowStockAlerts = async () => {
  const { rows } = await query(
    `SELECT i.product_id, p.name AS product_name, p.sku,
            i.quantity, i.reserved, i.reorder_point, i.reorder_qty,
            (i.quantity - i.reserved) AS available,
            s.id AS supplier_id, s.name AS supplier_name
       FROM inventory i
       JOIN products p ON p.id = i.product_id
       LEFT JOIN suppliers s ON s.id = p.supplier_id
      WHERE (i.quantity - i.reserved) <= i.reorder_point
        AND p.is_active = TRUE
     ORDER BY available ASC`
  );
  return rows;
};

module.exports = { findByProductId, list, upsert, adjust, logTransaction, getTransactions, getLowStockAlerts };
