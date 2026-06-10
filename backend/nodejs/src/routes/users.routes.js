const { Router } = require('express');
const { body, param } = require('express-validator');
const ctrl = require('../controllers/users.controller');
const { authenticate, authorize } = require('../middleware/auth');
const validate = require('../middleware/validate');

const router = Router();
router.use(authenticate);

router.get('/me', ctrl.getMe);
router.patch('/me',
  body('full_name').optional().trim().notEmpty(),
  body('phone').optional().isMobilePhone(),
  validate, ctrl.updateMe
);
router.put('/me/password',
  body('current_password').notEmpty(),
  body('new_password').isLength({ min: 8 }),
  validate, ctrl.changePassword
);

// Admin
router.get('/', authorize('admin'), ctrl.listUsers);
router.get('/:id', authorize('admin'), param('id').isUUID(), validate, ctrl.getUser);
router.patch('/:id/status', authorize('admin'),
  param('id').isUUID(),
  body('is_active').isBoolean(),
  validate, ctrl.setUserStatus
);

module.exports = router;
