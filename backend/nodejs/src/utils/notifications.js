'use strict';

// Firebase Admin SDK — initialised lazily so the app starts without credentials
// in development. Set FIREBASE_SERVICE_ACCOUNT_KEY (JSON string) in production.
let _app = null;
let _messaging = null;

function _init() {
  if (_messaging) return _messaging;
  const admin = require('firebase-admin');
  if (!process.env.FIREBASE_SERVICE_ACCOUNT_KEY) {
    console.warn('[notifications] FIREBASE_SERVICE_ACCOUNT_KEY not set — push disabled');
    return null;
  }
  if (!_app) {
    const serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT_KEY);
    _app = admin.initializeApp({
      credential: admin.credential.cert(serviceAccount),
    });
  }
  _messaging = admin.messaging(_app);
  return _messaging;
}

const TEMPLATES = {
  order_placed: (orderNumber) => ({
    title: 'Order Placed 🛍️',
    body: `Your order #${orderNumber} has been confirmed!`,
  }),
  order_processing: (orderNumber) => ({
    title: 'Order Processing ⚙️',
    body: `Your order #${orderNumber} is being prepared.`,
  }),
  order_out_for_delivery: (orderNumber) => ({
    title: 'Out for Delivery 🚚',
    body: `Your order #${orderNumber} is on its way!`,
  }),
  order_delivered: (orderNumber) => ({
    title: 'Order Delivered ✅',
    body: `Your order #${orderNumber} has been delivered. Enjoy!`,
  }),
  order_cancelled: (orderNumber) => ({
    title: 'Order Cancelled',
    body: `Your order #${orderNumber} has been cancelled.`,
  }),
  promotional: (title, body) => ({ title, body }),
};

async function sendToToken(fcmToken, type, ...args) {
  const messaging = _init();
  if (!messaging || !fcmToken) return;

  const { title, body } = (TEMPLATES[type] || TEMPLATES.promotional)(...args);

  try {
    await messaging.send({
      token: fcmToken,
      notification: { title, body },
      android: { priority: 'high', notification: { channelId: 'orders' } },
      apns: { payload: { aps: { sound: 'default', badge: 1 } } },
    });
  } catch (err) {
    // Token may be stale — log but don't throw
    console.error('[notifications] send failed:', err.message);
  }
}

async function sendOrderNotification(userId, orderNumber, status) {
  const { query } = require('../config/database');
  try {
    const res = await query('SELECT fcm_token FROM users WHERE id = $1', [userId]);
    const token = res.rows[0]?.fcm_token;
    if (!token) return;

    const typeMap = {
      pending:          'order_placed',
      processing:       'order_processing',
      out_for_delivery: 'order_out_for_delivery',
      delivered:        'order_delivered',
      cancelled:        'order_cancelled',
    };
    const type = typeMap[status];
    if (type) await sendToToken(token, type, orderNumber);
  } catch (err) {
    console.error('[notifications] sendOrderNotification failed:', err.message);
  }
}

module.exports = { sendToToken, sendOrderNotification };
