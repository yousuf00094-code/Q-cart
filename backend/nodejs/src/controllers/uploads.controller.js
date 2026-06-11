'use strict';

const path = require('path');

const uploadImage = (req, res) => {
  if (!req.file) {
    return res.status(422).json({
      error: { code: 'NO_FILE', message: 'No image file was provided.' },
    });
  }

  const baseUrl = process.env.BASE_URL || `http://localhost:${process.env.PORT || 3000}`;
  const url = `${baseUrl}/uploads/images/${req.file.filename}`;

  res.status(201).json({
    data: {
      url,
      filename: req.file.filename,
      originalname: req.file.originalname,
      mimetype: req.file.mimetype,
      size: req.file.size,
    },
  });
};

module.exports = { uploadImage };
