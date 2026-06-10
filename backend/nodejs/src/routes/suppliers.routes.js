const { Router } = require('express');
const { body, param } = require('express-validator');
const ctrl = require('../controllers/suppliers.controller');
const { authenticate, authorize } = require('../middleware/auth');
const validate = require('../middleware/validate');

const router = Router();

router.get('/', ctrl.list);
router.get('/:id', param('id').isUUID(), validate, ctrl.getOne);

router.post('/', authenticate, authorize('admin'),
  body('name').notEmpty(),
  body('email').isEmail().normalizeEmail(),
  validate, ctrl.create
);
router.put('/:id', authenticate, authorize('admin'),
  param('id').isUUID(), validate, ctrl.update
);
router.patch('/:id/status', authenticate, authorize('admin'),
  param('id').isUUID(),
  body('status').isIn(['active', 'inactive', 'pending_approval']),
  validate, ctrl.setStatus
);

module.exports = router;
