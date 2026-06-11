const { Router } = require('express');
const { query } = require('express-validator');
const ctrl = require('../controllers/supplier_analytics.controller');
const { authenticate, authorize } = require('../middleware/auth');
const validate = require('../middleware/validate');

const router = Router();

// GET /v1/supplier/analytics
// Returns KPIs + order-status breakdown for the authenticated supplier.
// Admins may pass ?supplier_id=<uuid> to inspect any supplier.
router.get(
  '/',
  authenticate,
  authorize('supplier', 'admin'),
  query('supplier_id').optional().isUUID(),
  validate,
  ctrl.dashboard
);

// GET /v1/supplier/analytics/revenue?days=30
// Daily revenue time-series for the past N days (7–365).
router.get(
  '/revenue',
  authenticate,
  authorize('supplier', 'admin'),
  query('days').optional().isInt({ min: 7, max: 365 }),
  validate,
  ctrl.revenue
);

// GET /v1/supplier/analytics/top-products?limit=10
// Top N products by revenue.
router.get(
  '/top-products',
  authenticate,
  authorize('supplier', 'admin'),
  query('limit').optional().isInt({ min: 1, max: 20 }),
  validate,
  ctrl.topProducts
);

module.exports = router;
