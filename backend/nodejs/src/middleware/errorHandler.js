const logger = require('../utils/logger');

const errorHandler = (err, req, res, next) => {
  logger.error({
    message: err.message,
    stack: err.stack,
    url: req.originalUrl,
    method: req.method,
    ip: req.ip,
  });

  // PostgreSQL errors
  if (err.code === '23505') {
    const field = err.detail?.match(/\((.+?)\)/)?.[1] ?? 'field';
    return res.status(409).json({
      error: { code: 'CONFLICT', message: `A record with this ${field} already exists.` },
    });
  }
  if (err.code === '23503') {
    return res.status(409).json({
      error: { code: 'REFERENCE_ERROR', message: 'Referenced resource does not exist.' },
    });
  }
  if (err.code === '23514') {
    return res.status(422).json({
      error: { code: 'CONSTRAINT_VIOLATION', message: err.message },
    });
  }

  // Application errors with explicit status
  if (err.statusCode) {
    return res.status(err.statusCode).json({
      error: { code: err.code || 'APP_ERROR', message: err.message, details: err.details },
    });
  }

  // Fallback
  const isDev = process.env.NODE_ENV === 'development';
  return res.status(500).json({
    error: {
      code: 'INTERNAL_SERVER_ERROR',
      message: 'Something went wrong. Please try again later.',
      ...(isDev && { stack: err.stack }),
    },
  });
};

class AppError extends Error {
  constructor(message, statusCode = 500, code = 'APP_ERROR', details = null) {
    super(message);
    this.statusCode = statusCode;
    this.code = code;
    this.details = details;
  }
}

module.exports = { errorHandler, AppError };
