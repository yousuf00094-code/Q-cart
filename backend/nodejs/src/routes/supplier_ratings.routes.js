const { Router } = require('express');
const { param, body, query } = require('express-validator');
const ctrl = require('../controllers/supplier_ratings.controller');
const { authenticate, authorize } = require('../middleware/auth');
const validate = require('../middleware/validate');

const router = Router();

// GET /v1/supplier/ratings?rating=5&product_id=<uuid>&replied=false
// Paginated list of reviews for the authenticated supplier's products.
router.get(
  '/',
  authenticate,
  authorize('supplier', 'admin'),
  query('rating').optional().isInt({ min: 1, max: 5 }),
  query('product_id').optional().isUUID(),
  query('replied').optional().isIn(['true', 'false']),
  validate,
  ctrl.list
);

// GET /v1/supplier/ratings/summary
// Aggregate stats: avg rating, star distribution, reply rate.
router.get(
  '/summary',
  authenticate,
  authorize('supplier', 'admin'),
  ctrl.summary
);

// POST /v1/supplier/ratings/:id/reply
// Supplier posts a public reply to a review.
router.post(
  '/:id/reply',
  authenticate,
  authorize('supplier'),
  param('id').isUUID(),
  body('reply').notEmpty().withMessage('Reply text is required.').isLength({ max: 1000 }),
  validate,
  ctrl.reply
);

module.exports = router;
