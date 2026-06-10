const { verifyAccess } = require('../config/jwt');
const { query } = require('../config/database');

const authenticate = async (req, res, next) => {
  try {
    const authHeader = req.headers.authorization;
    if (!authHeader?.startsWith('Bearer ')) {
      return res.status(401).json({ error: { code: 'UNAUTHORIZED', message: 'Access token required.' } });
    }

    const token = authHeader.slice(7);
    const payload = verifyAccess(token);

    const { rows } = await query(
      'SELECT id, email, role, is_active FROM users WHERE id = $1',
      [payload.sub]
    );

    if (!rows.length || !rows[0].is_active) {
      return res.status(401).json({ error: { code: 'UNAUTHORIZED', message: 'User not found or deactivated.' } });
    }

    req.user = rows[0];
    next();
  } catch (err) {
    if (err.name === 'TokenExpiredError') {
      return res.status(401).json({ error: { code: 'TOKEN_EXPIRED', message: 'Access token has expired.' } });
    }
    return res.status(401).json({ error: { code: 'UNAUTHORIZED', message: 'Invalid access token.' } });
  }
};

const authorize = (...roles) => (req, res, next) => {
  if (!roles.includes(req.user?.role)) {
    return res.status(403).json({ error: { code: 'FORBIDDEN', message: 'Insufficient permissions.' } });
  }
  next();
};

const optionalAuth = async (req, res, next) => {
  try {
    const authHeader = req.headers.authorization;
    if (authHeader?.startsWith('Bearer ')) {
      const token = authHeader.slice(7);
      const payload = verifyAccess(token);
      const { rows } = await query(
        'SELECT id, email, role, is_active FROM users WHERE id = $1',
        [payload.sub]
      );
      if (rows.length && rows[0].is_active) req.user = rows[0];
    }
  } catch (_) { /* ignore */ }
  next();
};

module.exports = { authenticate, authorize, optionalAuth };
