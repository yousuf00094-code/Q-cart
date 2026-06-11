const { Router } = require('express');
const { body, param } = require('express-validator');
const ctrl = require('../controllers/coupons.controller');
const { authenticate, authorize, optionalAuth } = require('../middleware/auth');
const { couponLimiter } = require('../middleware/rateLimiter');
const validate = require('../middleware/validate');

const router = Router();

router.post('/validate', couponLimiter, optionalAuth,
  body('code').notEmpty(),
  body('order_amount').isFloat({ min: 0 }),
  validate, ctrl.validate
);

router.use(authenticate, authorize('admin'));

router.get('/', ctrl.list);
router.post('/',
  body('code').notEmpty().toUpperCase(),
  body('discount_type').isIn(['percentage','fixed']),
  body('discount_value').isFloat({ min: 0.01 }),
  validate, ctrl.create
);
router.put('/:id', param('id').isUUID(), validate, ctrl.update);
router.delete('/:id', param('id').isUUID(), validate, ctrl.remove);

module.exports = router;
