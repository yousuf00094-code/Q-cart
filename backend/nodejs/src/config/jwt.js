const jwt = require('jsonwebtoken');

const ACCESS_SECRET  = process.env.JWT_ACCESS_SECRET;
const REFRESH_SECRET = process.env.JWT_REFRESH_SECRET;
const ACCESS_EXPIRY  = process.env.JWT_ACCESS_EXPIRY  || '15m';
const REFRESH_EXPIRY = process.env.JWT_REFRESH_EXPIRY || '7d';

// Fail fast at startup — a missing/weak secret is a critical misconfiguration
if (!ACCESS_SECRET || ACCESS_SECRET.length < 32) {
  throw new Error('JWT_ACCESS_SECRET must be set and be at least 32 characters long');
}
if (!REFRESH_SECRET || REFRESH_SECRET.length < 32) {
  throw new Error('JWT_REFRESH_SECRET must be set and be at least 32 characters long');
}

const signAccess = (payload) =>
  jwt.sign(payload, ACCESS_SECRET, { expiresIn: ACCESS_EXPIRY });

const signRefresh = (payload) =>
  jwt.sign(payload, REFRESH_SECRET, { expiresIn: REFRESH_EXPIRY });

const verifyAccess = (token) =>
  jwt.verify(token, ACCESS_SECRET);

const verifyRefresh = (token) =>
  jwt.verify(token, REFRESH_SECRET);

const decodeToken = (token) =>
  jwt.decode(token);

module.exports = { signAccess, signRefresh, verifyAccess, verifyRefresh, decodeToken };
