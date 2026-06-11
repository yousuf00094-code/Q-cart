const { Router } = require('express');
const { query: queryValidator } = require('express-validator');
const ctrl = require('../controllers/admin.controller');
const { authenticate, authorize } = require('../middleware/auth');
const validate = require('../middleware/validate');

const router = Router();
router.use(authenticate, authorize('admin'));

// GET /v1/admin/dashboard
router.get('/dashboard', ctrl.getDashboard);

// GET /v1/admin/revenue?period=daily&days=30
router.get('/revenue',
  queryValidator('period').optional().isIn(['daily', 'weekly', 'monthly']),
  queryValidator('days').optional().isInt({ min: 1, max: 365 }),
  validate,
  ctrl.getRevenueReport
);

// GET /v1/admin/products/top?limit=10&days=30
router.get('/products/top',
  queryValidator('limit').optional().isInt({ min: 1, max: 50 }),
  queryValidator('days').optional().isInt({ min: 1, max: 365 }),
  validate,
  ctrl.getTopProducts
);

// GET /v1/admin/customers?sort=spend&days=30&page=1
router.get('/customers',
  queryValidator('sort').optional().isIn(['spend', 'orders']),
  queryValidator('days').optional().isInt({ min: 1, max: 365 }),
  validate,
  ctrl.getCustomerStats
);

// GET /v1/admin/inventory/alerts
router.get('/inventory/alerts', ctrl.getLowStockAlerts);

// GET /v1/admin/activity?limit=20
router.get('/activity',
  queryValidator('limit').optional().isInt({ min: 1, max: 50 }),
  validate,
  ctrl.getActivityFeed
);

// GET /v1/admin/suppliers/payouts?days=30  — summary widget for admin dashboard
router.get('/suppliers/payouts',
  queryValidator('days').optional().isInt({ min: 1, max: 365 }),
  validate,
  ctrl.getSupplierPayoutSummary
);

// GET /v1/admin/payouts?status=paid&supplier_id=<uuid>  — full paginated payout list
const payoutsCtrl = require('../controllers/supplier_payouts.controller');
router.get('/payouts',
  queryValidator('status').optional().isIn(['pending', 'processing', 'paid', 'failed', 'on_hold']),
  queryValidator('supplier_id').optional().isUUID(),
  validate,
  payoutsCtrl.listAll
);

module.exports = router;
