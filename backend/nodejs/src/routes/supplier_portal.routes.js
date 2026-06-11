'use strict';

const { Router } = require('express');
const { body, param, query: queryValidator } = require('express-validator');
const ctrl = require('../controllers/supplier_portal.controller');
const { authenticate, authorize } = require('../middleware/auth');
const validate = require('../middleware/validate');

const router = Router();
router.use(authenticate, authorize('supplier'));

router.get('/products',
  queryValidator('page').optional().isInt({ min: 1 }),
  queryValidator('limit').optional().isInt({ min: 1, max: 100 }),
  queryValidator('status').optional().isIn(['active', 'inactive']),
  validate,
  ctrl.products
);

router.get('/orders',
  queryValidator('page').optional().isInt({ min: 1 }),
  queryValidator('limit').optional().isInt({ min: 1, max: 100 }),
  queryValidator('status').optional().isIn(['pending', 'confirmed', 'processing', 'out_for_delivery', 'delivered', 'cancelled', 'refunded']),
  validate,
  ctrl.orders
);

router.get('/inventory',
  queryValidator('page').optional().isInt({ min: 1 }),
  queryValidator('limit').optional().isInt({ min: 1, max: 100 }),
  queryValidator('low_stock').optional().isBoolean(),
  validate,
  ctrl.inventory
);

router.patch('/orders/:id/status',
  param('id').isUUID(),
  body('status').isIn(['processing', 'out_for_delivery', 'delivered']),
  validate,
  ctrl.updateOrderStatus
);

router.post('/inventory/:productId/adjust',
  param('productId').isUUID(),
  body('quantity_delta').isInt(),
  validate,
  ctrl.adjustInventory
);

router.post('/products',
  body('name').notEmpty(),
  body('category_id').isUUID(),
  body('price').isFloat({ min: 0 }),
  validate,
  ctrl.submitProduct
);

module.exports = router;
