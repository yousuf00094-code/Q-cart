'use strict';

const { Router } = require('express');
const { query: queryValidator } = require('express-validator');
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

module.exports = router;
