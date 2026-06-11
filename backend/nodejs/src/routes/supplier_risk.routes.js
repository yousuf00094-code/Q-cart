const { Router } = require('express');
const { param, query } = require('express-validator');
const ctrl = require('../controllers/supplier_risk.controller');
const { authenticate, authorize } = require('../middleware/auth');
const validate = require('../middleware/validate');

const router = Router();

// GET /v1/admin/supplier-risk?risk_level=high
// All suppliers ordered by risk score (highest first).
router.get(
  '/',
  authenticate,
  authorize('admin'),
  query('risk_level').optional().isIn(['minimal', 'low', 'medium', 'high']),
  validate,
  ctrl.listAll
);

// GET /v1/admin/supplier-risk/:supplier_id
// Risk details + factor breakdown for one supplier.
router.get(
  '/:supplier_id',
  authenticate,
  authorize('admin'),
  param('supplier_id').isUUID(),
  validate,
  ctrl.getOne
);

// POST /v1/admin/supplier-risk/:supplier_id/recompute
// Trigger on-demand risk score recalculation from live DB data.
router.post(
  '/:supplier_id/recompute',
  authenticate,
  authorize('admin'),
  param('supplier_id').isUUID(),
  validate,
  ctrl.recompute
);

module.exports = router;
