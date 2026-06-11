const { Router } = require('express');
const { param, body, query } = require('express-validator');
const ctrl = require('../controllers/shipments.controller');
const { authenticate, authorize } = require('../middleware/auth');
const validate = require('../middleware/validate');

const VALID_STATUSES = ['pending', 'picked_up', 'in_transit', 'out_for_delivery', 'delivered', 'failed', 'returned'];

const router = Router();

// GET /v1/supplier/shipments?status=in_transit
// Supplier's shipments, optionally filtered by status.
router.get(
  '/',
  authenticate,
  authorize('supplier', 'admin'),
  query('status').optional().isIn(VALID_STATUSES),
  validate,
  ctrl.list
);

// GET /v1/supplier/shipments/:id
// Single shipment with full event timeline.
router.get(
  '/:id',
  authenticate,
  authorize('supplier', 'admin', 'customer'),
  param('id').isUUID(),
  validate,
  ctrl.getOne
);

// POST /v1/supplier/shipments
// Create a shipment record for an order.
router.post(
  '/',
  authenticate,
  authorize('supplier', 'admin'),
  body('order_id').isUUID(),
  body('carrier').optional().isString().isLength({ max: 100 }),
  body('tracking_number').optional().isString().isLength({ max: 200 }),
  body('estimated_delivery').optional().isISO8601(),
  body('notes').optional().isString().isLength({ max: 1000 }),
  validate,
  ctrl.create
);

// PATCH /v1/supplier/shipments/:id
// Update carrier, tracking number, or status.
router.patch(
  '/:id',
  authenticate,
  authorize('supplier', 'admin'),
  param('id').isUUID(),
  body('carrier').optional().isString().isLength({ max: 100 }),
  body('tracking_number').optional().isString().isLength({ max: 200 }),
  body('status').optional().isIn(VALID_STATUSES),
  body('shipped_at').optional().isISO8601(),
  body('estimated_delivery').optional().isISO8601(),
  body('delivered_at').optional().isISO8601(),
  body('notes').optional().isString().isLength({ max: 1000 }),
  validate,
  ctrl.update
);

// POST /v1/supplier/shipments/:id/events
// Append a new tracking event to the timeline.
router.post(
  '/:id/events',
  authenticate,
  authorize('supplier', 'admin'),
  param('id').isUUID(),
  body('status').notEmpty().isString().isLength({ max: 100 }),
  body('location').optional().isString().isLength({ max: 200 }),
  body('description').optional().isString().isLength({ max: 500 }),
  body('occurred_at').optional().isISO8601(),
  validate,
  ctrl.addEvent
);

module.exports = router;
