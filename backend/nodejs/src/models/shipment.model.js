const { query } = require('../config/database');

const COLS = `
  s.id, s.order_id, s.supplier_id, s.carrier, s.tracking_number,
  s.status, s.shipped_at, s.estimated_delivery, s.delivered_at,
  s.notes, s.created_at, s.updated_at,
  o.order_number, u.full_name AS customer_name
`;

const findById = async (id) => {
  const { rows } = await query(
    `SELECT ${COLS}
     FROM shipments s
     JOIN orders o ON o.id = s.order_id
     JOIN users  u ON u.id = o.user_id
     WHERE s.id = $1`,
    [id]
  );
  return rows[0] || null;
};

const getEvents = async (shipmentId) => {
  const { rows } = await query(
    `SELECT id, shipment_id, status, location, description, occurred_at
     FROM shipment_events
     WHERE shipment_id = $1
     ORDER BY occurred_at ASC`,
    [shipmentId]
  );
  return rows;
};

const listBySupplier = async (supplierId, { limit, offset, status }) => {
  const conditions = ['s.supplier_id = $1'];
  const values = [supplierId];
  let idx = 2;

  if (status) {
    conditions.push(`s.status = $${idx++}`);
    values.push(status);
  }

  const where = `WHERE ${conditions.join(' AND ')}`;

  const [countRes, dataRes] = await Promise.all([
    query(`SELECT COUNT(*) FROM shipments s ${where}`, values),
    query(
      `SELECT ${COLS}
       FROM shipments s
       JOIN orders o ON o.id = s.order_id
       JOIN users  u ON u.id = o.user_id
       ${where}
       ORDER BY s.created_at DESC
       LIMIT $${idx} OFFSET $${idx + 1}`,
      [...values, limit, offset]
    ),
  ]);

  return { rows: dataRes.rows, total: parseInt(countRes.rows[0].count, 10) };
};

const create = async (data) => {
  const { rows } = await query(
    `INSERT INTO shipments
       (order_id, supplier_id, carrier, tracking_number, status, shipped_at, estimated_delivery, notes)
     VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
     RETURNING *`,
    [
      data.order_id,
      data.supplier_id,
      data.carrier || null,
      data.tracking_number || null,
      data.status || 'pending',
      data.shipped_at || null,
      data.estimated_delivery || null,
      data.notes || null,
    ]
  );
  return rows[0];
};

const update = async (id, data) => {
  const allowed = [
    'carrier', 'tracking_number', 'status',
    'shipped_at', 'estimated_delivery', 'delivered_at', 'notes',
  ];
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
    `UPDATE shipments SET ${sets.join(', ')} WHERE id = $${idx} RETURNING *`,
    values
  );
  return rows[0] || null;
};

const addEvent = async (shipmentId, { status, location, description, occurred_at }) => {
  const { rows } = await query(
    `INSERT INTO shipment_events (shipment_id, status, location, description, occurred_at)
     VALUES ($1, $2, $3, $4, $5)
     RETURNING *`,
    [
      shipmentId,
      status,
      location || null,
      description || null,
      occurred_at ? new Date(occurred_at) : new Date(),
    ]
  );
  return rows[0];
};

module.exports = { findById, getEvents, listBySupplier, create, update, addEvent };
