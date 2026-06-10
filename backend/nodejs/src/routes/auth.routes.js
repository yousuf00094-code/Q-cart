const { Router } = require('express');
const { body } = require('express-validator');
const ctrl = require('../controllers/auth.controller');
const { authenticate } = require('../middleware/auth');
const { authLimiter } = require('../middleware/rateLimiter');
const validate = require('../middleware/validate');

const router = Router();

router.post('/register', authLimiter,
  body('full_name').trim().notEmpty().withMessage('Full name is required'),
  body('email').isEmail().normalizeEmail().withMessage('Valid email required'),
  body('phone').optional().isMobilePhone().withMessage('Valid phone number required'),
  body('password').isLength({ min: 8 }).withMessage('Password must be at least 8 characters'),
  validate, ctrl.register
);

router.post('/login', authLimiter,
  body('email').isEmail().normalizeEmail(),
  body('password').notEmpty(),
  validate, ctrl.login
);

router.post('/refresh', ctrl.refresh);
router.post('/logout', authenticate, ctrl.logout);

router.post('/forgot-password', authLimiter,
  body('email').isEmail().normalizeEmail(),
  validate, ctrl.forgotPassword
);

router.post('/reset-password',
  body('token').notEmpty(),
  body('password').isLength({ min: 8 }),
  validate, ctrl.resetPassword
);

module.exports = router;
