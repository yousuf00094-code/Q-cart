const { Router } = require('express');
const { body, param } = require('express-validator');
const ctrl = require('../controllers/categories.controller');
const { authenticate, authorize, optionalAuth } = require('../middleware/auth');
const validate = require('../middleware/validate');

const router = Router();

router.get('/', optionalAuth, ctrl.list);
router.get('/:slug', ctrl.getOne);

router.post('/', authenticate, authorize('admin'),
  body('name').notEmpty(),
  body('slug').notEmpty().matches(/^[a-z0-9-]+$/),
  validate, ctrl.create
);
router.put('/:id', authenticate, authorize('admin'),
  param('id').isUUID(), validate, ctrl.update
);
router.delete('/:id', authenticate, authorize('admin'),
  param('id').isUUID(), validate, ctrl.remove
);

module.exports = router;
