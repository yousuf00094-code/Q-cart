const { Router } = require('express');
const { body, param } = require('express-validator');
const ctrl     = require('../controllers/addresses.controller');
const { authenticate } = require('../middleware/auth');
const validate = require('../middleware/validate');

const router = Router();
router.use(authenticate);

// GET /v1/addresses
router.get('/', ctrl.list);

// GET /v1/addresses/:id
router.get('/:id', param('id').isUUID(), validate, ctrl.getOne);

// POST /v1/addresses
router.post('/',
  body('first_name').trim().notEmpty(),
  body('last_name').trim().notEmpty(),
  body('address_line1').trim().notEmpty(),
  body('city').trim().notEmpty(),
  body('phone').optional().isMobilePhone(),
  body('is_default').optional().isBoolean(),
  validate,
  ctrl.create
);

// PUT /v1/addresses/:id
router.put('/:id',
  param('id').isUUID(),
  body('first_name').optional().trim().notEmpty(),
  body('last_name').optional().trim().notEmpty(),
  body('address_line1').optional().trim().notEmpty(),
  body('city').optional().trim().notEmpty(),
  validate,
  ctrl.update
);

// PATCH /v1/addresses/:id/default
router.patch('/:id/default',
  param('id').isUUID(),
  validate,
  ctrl.setDefault
);

// DELETE /v1/addresses/:id
router.delete('/:id', param('id').isUUID(), validate, ctrl.remove);

module.exports = router;
