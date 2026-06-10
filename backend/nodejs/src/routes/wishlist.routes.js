const { Router } = require('express');
const { body, param } = require('express-validator');
const ctrl = require('../controllers/wishlist.controller');
const { authenticate } = require('../middleware/auth');
const validate = require('../middleware/validate');

const router = Router();
router.use(authenticate);

router.get('/', ctrl.list);
router.post('/', body('product_id').isUUID(), validate, ctrl.add);
router.delete('/', ctrl.clear);
router.delete('/:productId', param('productId').isUUID(), validate, ctrl.remove);

module.exports = router;
