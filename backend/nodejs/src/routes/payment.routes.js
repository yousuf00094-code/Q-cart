'use strict';

const { Router } = require('express');
const { body } = require('express-validator');
const ctrl = require('../controllers/payment.controller');
const { authenticate } = require('../middleware/auth');
const validate = require('../middleware/validate');

const router = Router();

// POST /v1/payment/initiate — authenticated, initiates QPay invoice
router.post('/initiate',
  authenticate,
  body('address_id').isUUID(),
  body('coupon_code').optional().isString().trim(),
  validate,
  ctrl.initiate
);

// POST /v1/payment/verify — authenticated, checks payment status + creates order
router.post('/verify',
  authenticate,
  body('invoice_id').notEmpty(),
  validate,
  ctrl.verify
);

// POST /v1/payment/callback — public, QPay webhook (no auth — verified by invoice_id)
router.post('/callback', ctrl.callback);

// PATCH /v1/users/me/fcm-token — store FCM device token
router.patch('/fcm-token',
  authenticate,
  body('token').notEmpty(),
  validate,
  ctrl.saveFcmToken
);

module.exports = router;
