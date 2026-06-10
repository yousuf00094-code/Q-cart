const { Router } = require('express');
const { body, param } = require('express-validator');
const ctrl = require('../controllers/inventory.controller');
const { authenticate, authorize } = require('../middleware/auth');
const validate = require('../middleware/validate');

const router = Router();
router.use(authenticate, authorize('admin', 'supplier'));

router.get('/', ctrl.list);
router.get('/alerts', ctrl.alerts);
router.get('/:productId', param('productId').isUUID(), validate, ctrl.getOne);

router.post('/:productId/adjust', authorize('admin'),
  param('productId').isUUID(),
  body('txn_type').isIn(['restock','adjustment','return','damage']),
  body('quantity_delta').isInt(),
  validate, ctrl.adjust
);

router.get('/:productId/transactions', authorize('admin'),
  param('productId').isUUID(), validate, ctrl.getTransactions
);

module.exports = router;
