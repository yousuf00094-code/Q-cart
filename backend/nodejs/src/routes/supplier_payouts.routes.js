const { Router } = require('express');
const { param, query } = require('express-validator');
const ctrl = require('../controllers/supplier_payouts.controller');
const { authenticate, authorize } = require('../middleware/auth');
const validate = require('../middleware/validate');

const router = Router();

// GET /v1/supplier/payouts?status=paid
// Supplier's own payout periods.
router.get(
  '/',
  authenticate,
  authorize('supplier'),
  query('status').optional().isIn(['pending', 'processing', 'paid', 'failed', 'on_hold']),
  validate,
  ctrl.list
);

// GET /v1/supplier/payouts/:id
// Single payout with order-level line items.
router.get(
  '/:id',
  authenticate,
  authorize('supplier', 'admin'),
  param('id').isUUID(),
  validate,
  ctrl.getOne
);

module.exports = router;
