const rateLimit = require('express-rate-limit');
const RedisStore = require('rate-limit-redis');
const { getClient } = require('../config/redis');

// Build a Redis-backed store when REDIS_URL is configured; falls back to
// in-memory store otherwise. In-memory is per-process — always use Redis
// in any multi-container (ECS) deployment.
const makeStore = () => {
  const redis = getClient();
  if (!redis) return undefined; // express-rate-limit uses MemoryStore by default
  return new RedisStore({
    sendCommand: (...args) => redis.call(...args),
  });
};

const defaultLimiter = rateLimit({
  windowMs: parseInt(process.env.RATE_LIMIT_WINDOW_MS || '60000', 10),
  max: parseInt(process.env.RATE_LIMIT_MAX || '300', 10),
  store: makeStore(),
  standardHeaders: true,
  legacyHeaders: false,
  message: { error: { code: 'RATE_LIMITED', message: 'Too many requests. Please try again later.' } },
});

const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: parseInt(process.env.AUTH_RATE_LIMIT_MAX || '10', 10),
  store: makeStore(),
  standardHeaders: true,
  legacyHeaders: false,
  message: { error: { code: 'RATE_LIMITED', message: 'Too many authentication attempts. Please try again in 15 minutes.' } },
});

// Coupon /validate is public and brute-force-able — keep it tight
const couponLimiter = rateLimit({
  windowMs: 60 * 1000,
  max: 20,
  store: makeStore(),
  standardHeaders: true,
  legacyHeaders: false,
  message: { error: { code: 'RATE_LIMITED', message: 'Too many coupon validation attempts. Please slow down.' } },
});

module.exports = { defaultLimiter, authLimiter, couponLimiter };
