const { Router } = require('express');
const { body, param } = require('express-validator');
const ctrl = require('../controllers/products.controller');
const reviewCtrl = require('../controllers/reviews.controller');
const { authenticate, authorize, optionalAuth } = require('../middleware/auth');
const validate = require('../middleware/validate');

const router = Router();

router.get('/', optionalAuth, ctrl.list);
router.get('/:id', optionalAuth, param('id').isUUID(), validate, ctrl.getOne);

// Reviews sub-resource
router.get('/:productId/reviews',
  param('productId').isUUID(), validate, reviewCtrl.list
);
router.post('/:productId/reviews', authenticate,
  param('productId').isUUID(),
  body('rating').isInt({ min: 1, max: 5 }),
  validate, reviewCtrl.create
);

// Admin / Supplier write operations
router.post('/', authenticate, authorize('admin', 'supplier'),
  body('name').notEmpty(),
  body('category_id').isUUID(),
  body('price').isFloat({ min: 0 }),
  validate, ctrl.create
);
router.put('/:id', authenticate, authorize('admin', 'supplier'),
  param('id').isUUID(), validate, ctrl.update
);
router.delete('/:id', authenticate, authorize('admin'),
  param('id').isUUID(), validate, ctrl.remove
);

module.exports = router;
