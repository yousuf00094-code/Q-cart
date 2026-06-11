'use strict';

const { Router } = require('express');
const ctrl = require('../controllers/uploads.controller');
const upload = require('../middleware/upload');
const { authenticate } = require('../middleware/auth');

const router = Router();

// POST /v1/uploads/images  — authenticated suppliers and admins only
router.post(
  '/images',
  authenticate,
  upload.single('image'),
  ctrl.uploadImage
);

module.exports = router;
