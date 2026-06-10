const { Router } = require('express');
const { body, param } = require('express-validator');
const ctrl = require('../controllers/orders.controller');
const { authenticate, authorize } = require('../middleware/auth');
const validate = require('../middleware/validate');

const router = Router();
router.use(authenticate);

router.get('/', ctrl.list);
router.get('/:id', param('id').isUUID(), validate, ctrl.getOne);

router.post('/checkout',
  body('address_id').isUUID(),
  body('payment_method').isIn(['card','cash_on_delivery','apple_pay','google_pay','qpay']),
  body('items').isArray({ min: 1 }),
  body('items.*.product_id').isUUID(),
  body('items.*.quantity').isInt({ min: 1 }),
  validate, ctrl.checkout
);

router.post('/estimate',
  body('items').isArray({ min: 1 }),
  body('items.*.product_id').isUUID(),
  body('items.*.quantity').isInt({ min: 1 }),
  validate, ctrl.estimate
);

router.post('/:id/cancel', param('id').isUUID(), validate, ctrl.cancel);

// Admin
router.patch('/:id/status', authorize('admin'),
  param('id').isUUID(),
  body('status').isIn(['confirmed','processing','packed','out_for_delivery','delivered','cancelled','refunded']),
  validate, ctrl.updateStatus
);

module.exports = router;
