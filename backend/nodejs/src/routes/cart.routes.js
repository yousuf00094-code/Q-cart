const { Router } = require('express');
const { body, param } = require('express-validator');
const ctrl     = require('../controllers/cart.controller');
const { authenticate } = require('../middleware/auth');
const validate = require('../middleware/validate');

const router = Router();
router.use(authenticate);

// GET /v1/cart
router.get('/', ctrl.getCart);

// POST /v1/cart/items
router.post('/items',
  body('product_id').isUUID(),
  body('quantity').isInt({ min: 1 }),
  validate,
  ctrl.addItem
);

// PUT /v1/cart/items/:itemId
router.put('/items/:itemId',
  param('itemId').isUUID(),
  body('quantity').isInt({ min: 0 }),
  validate,
  ctrl.updateItem
);

// DELETE /v1/cart/items/:itemId
router.delete('/items/:itemId',
  param('itemId').isUUID(),
  validate,
  ctrl.removeItem
);

// DELETE /v1/cart
router.delete('/', ctrl.clearCart);

// POST /v1/cart/merge  (merge guest/local cart after login)
router.post('/merge',
  body('items').isArray({ min: 1 }),
  body('items.*.product_id').isUUID(),
  body('items.*.quantity').isInt({ min: 1 }),
  validate,
  ctrl.mergeCart
);

module.exports = router;
