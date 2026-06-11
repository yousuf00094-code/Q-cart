const { Router } = require('express');

const router = Router();

router.use('/auth',       require('./auth.routes'));
router.use('/uploads',    require('./uploads.routes'));
router.use('/users',      require('./users.routes'));
router.use('/addresses',  require('./addresses.routes'));
router.use('/products',   require('./products.routes'));
router.use('/categories', require('./categories.routes'));
router.use('/suppliers',  require('./suppliers.routes'));
router.use('/cart',       require('./cart.routes'));
router.use('/orders',     require('./orders.routes'));
router.use('/inventory',  require('./inventory.routes'));
router.use('/reviews',    require('./reviews.routes'));
router.use('/wishlist',   require('./wishlist.routes'));
router.use('/coupons',    require('./coupons.routes'));
router.use('/admin',      require('./admin.routes'));
router.use('/payment',    require('./payment.routes'));

// ── Supplier-scoped APIs ───────────────────────────────────────────────────
router.use('/supplier/analytics', require('./supplier_analytics.routes'));
router.use('/supplier/ratings',   require('./supplier_ratings.routes'));
router.use('/supplier/payouts',   require('./supplier_payouts.routes'));
router.use('/supplier/shipments', require('./shipments.routes'));
router.use('/supplier',           require('./supplier_portal.routes'));

// ── Admin supplier risk scores ─────────────────────────────────────────────
router.use('/admin/supplier-risk', require('./supplier_risk.routes'));

router.get('/health', (req, res) =>
  res.json({ status: 'ok', timestamp: new Date().toISOString(), version: '1.0.0' })
);

module.exports = router;
