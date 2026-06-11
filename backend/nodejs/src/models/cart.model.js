const { query, withTransaction } = require('../config/database');

// Resolves or creates the persistent cart for a user
const getOrCreate = async (userId) => {
  const { rows } = await query(
    `INSERT INTO carts (user_id)
     VALUES ($1)
     ON CONFLICT (user_id) DO UPDATE SET updated_at = NOW()
     RETURNING id, user_id, updated_at`,
    [userId]
  );
  return rows[0];
};

const getWithItems = async (userId) => {
  const cart = await getOrCreate(userId);

  const { rows } = await query(
    `SELECT ci.id, ci.quantity, ci.added_at,
            p.id          AS product_id,
            p.name        AS product_name,
            p.slug        AS product_slug,
            p.sku         AS product_sku,
            p.price,
            p.compare_at_price,
            p.images,
            p.is_active,
            COALESCE(i.quantity - i.reserved, 0) AS available_quantity,
            s.name        AS supplier_name
       FROM cart_items ci
       JOIN products     p ON p.id = ci.product_id
       LEFT JOIN inventory i ON i.product_id = p.id
       LEFT JOIN suppliers s ON s.id = p.supplier_id
      WHERE ci.cart_id = $1
     ORDER BY ci.added_at ASC`,
    [cart.id]
  );

  const subtotal = rows.reduce((sum, item) => {
    return sum + parseFloat(item.price) * item.quantity;
  }, 0);

  return {
    id: cart.id,
    user_id: cart.user_id,
    updated_at: cart.updated_at,
    items: rows,
    item_count: rows.reduce((n, i) => n + i.quantity, 0),
    subtotal: parseFloat(subtotal.toFixed(2)),
  };
};

const addItem = async (userId, productId, quantity) => {
  const cart = await getOrCreate(userId);

  // Upsert: if item already in cart, add to quantity
  const { rows } = await query(
    `INSERT INTO cart_items (cart_id, product_id, quantity)
     VALUES ($1, $2, $3)
     ON CONFLICT (cart_id, product_id)
     DO UPDATE SET quantity = cart_items.quantity + $3,
                   updated_at = NOW()
     RETURNING id, cart_id, product_id, quantity`,
    [cart.id, productId, quantity]
  );

  // Bump cart updated_at
  await query('UPDATE carts SET updated_at = NOW() WHERE id = $1', [cart.id]);
  return rows[0];
};

const updateItem = async (userId, itemId, quantity) => {
  const cart = await getOrCreate(userId);

  if (quantity <= 0) {
    return removeItem(userId, itemId);
  }

  const { rows } = await query(
    `UPDATE cart_items
        SET quantity = $1, updated_at = NOW()
      WHERE id = $2 AND cart_id = $3
     RETURNING id, product_id, quantity`,
    [quantity, itemId, cart.id]
  );

  if (rows.length) {
    await query('UPDATE carts SET updated_at = NOW() WHERE id = $1', [cart.id]);
  }

  return rows[0] || null;
};

const removeItem = async (userId, itemId) => {
  const cart = await getOrCreate(userId);

  const { rowCount } = await query(
    'DELETE FROM cart_items WHERE id = $1 AND cart_id = $2',
    [itemId, cart.id]
  );

  if (rowCount) {
    await query('UPDATE carts SET updated_at = NOW() WHERE id = $1', [cart.id]);
  }

  return rowCount > 0;
};

const clear = async (userId) => {
  const cart = await getOrCreate(userId);
  await query('DELETE FROM cart_items WHERE cart_id = $1', [cart.id]);
  await query('UPDATE carts SET updated_at = NOW() WHERE id = $1', [cart.id]);
};

// Merge a list of items (e.g. from localStorage) into the user's server cart
const mergeItems = async (userId, items) => {
  return withTransaction(async (client) => {
    const cartRow = await getOrCreate(userId);
    for (const item of items) {
      await client.query(
        `INSERT INTO cart_items (cart_id, product_id, quantity)
         VALUES ($1, $2, $3)
         ON CONFLICT (cart_id, product_id)
         DO UPDATE SET quantity = GREATEST(cart_items.quantity, $3),
                       updated_at = NOW()`,
        [cartRow.id, item.product_id, item.quantity]
      );
    }
    await client.query('UPDATE carts SET updated_at = NOW() WHERE id = $1', [cartRow.id]);
    return getWithItems(userId);
  });
};

const findItem = async (cartId, itemId) => {
  const { rows } = await query(
    'SELECT * FROM cart_items WHERE id = $1 AND cart_id = $2',
    [itemId, cartId]
  );
  return rows[0] || null;
};

module.exports = { getOrCreate, getWithItems, addItem, updateItem, removeItem, clear, mergeItems, findItem };
