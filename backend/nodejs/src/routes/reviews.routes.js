const { Router } = require('express');
const { body, param } = require('express-validator');
const ctrl = require('../controllers/reviews.controller');
const { authenticate, authorize } = require('../middleware/auth');
const validate = require('../middleware/validate');

const router = Router();

router.patch('/:id', authenticate,
  param('id').isUUID(),
  body('rating').optional().isInt({ min: 1, max: 5 }),
  validate, ctrl.update
);
router.delete('/:id', authenticate, param('id').isUUID(), validate, ctrl.remove);
router.post('/:id/helpful', authenticate, param('id').isUUID(), validate, ctrl.helpful);
router.post('/:id/reply', authenticate, authorize('admin', 'supplier'),
  param('id').isUUID(),
  body('reply').notEmpty(),
  validate, ctrl.reply
);

module.exports = router;
