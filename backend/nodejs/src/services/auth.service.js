const crypto = require('crypto');
const bcrypt = require('bcryptjs');
const UserModel = require('../models/user.model');
const { signAccess, signRefresh, verifyRefresh } = require('../config/jwt');
const { hash, verify } = require('../utils/password');
const { AppError } = require('../middleware/errorHandler');

const buildTokens = (user) => ({
  accessToken: signAccess({ sub: user.id, role: user.role }),
  refreshToken: signRefresh({ sub: user.id }),
});

const register = async ({ full_name, email, phone, password }) => {
  const existing = await UserModel.findByEmail(email);
  if (existing) throw new AppError('An account with this email already exists.', 409, 'CONFLICT');

  const password_hash = await hash(password);
  const user = await UserModel.create({ full_name, email, phone, password_hash });

  const tokens = buildTokens(user);
  const refreshHash = await bcrypt.hash(tokens.refreshToken, 10);
  await UserModel.updateRefreshToken(user.id, refreshHash);

  return { user, ...tokens };
};

const login = async ({ email, password }) => {
  const user = await UserModel.findByEmail(email);
  if (!user) throw new AppError('Invalid email or password.', 401, 'INVALID_CREDENTIALS');
  if (!user.is_active) throw new AppError('Account is suspended. Please contact support.', 403, 'ACCOUNT_SUSPENDED');

  const valid = await verify(password, user.password_hash);
  if (!valid) throw new AppError('Invalid email or password.', 401, 'INVALID_CREDENTIALS');

  const tokens = buildTokens(user);
  const refreshHash = await bcrypt.hash(tokens.refreshToken, 10);
  await UserModel.updateRefreshToken(user.id, refreshHash);

  const { password_hash, refresh_token_hash, ...safeUser } = user;
  return { user: safeUser, ...tokens };
};

const refresh = async (refreshToken) => {
  if (!refreshToken) throw new AppError('Refresh token required.', 401, 'UNAUTHORIZED');

  let payload;
  try {
    payload = verifyRefresh(refreshToken);
  } catch {
    throw new AppError('Invalid or expired refresh token.', 401, 'UNAUTHORIZED');
  }

  const { rows: userRows } = await require('../config/database').query(
    'SELECT * FROM users WHERE id = $1', [payload.sub]
  );
  const user = userRows[0];
  if (!user || !user.refresh_token_hash) throw new AppError('Session invalidated.', 401, 'UNAUTHORIZED');

  const valid = await bcrypt.compare(refreshToken, user.refresh_token_hash);
  if (!valid) throw new AppError('Invalid refresh token.', 401, 'UNAUTHORIZED');

  const tokens = buildTokens(user);
  const refreshHash = await bcrypt.hash(tokens.refreshToken, 10);
  await UserModel.updateRefreshToken(user.id, refreshHash);

  return tokens;
};

const logout = async (userId) => {
  await UserModel.clearRefreshToken(userId);
};

const forgotPassword = async (email) => {
  const user = await UserModel.findByEmail(email);
  if (!user) return; // Silently ignore to prevent enumeration

  const token = crypto.randomBytes(32).toString('hex');
  const expires = new Date(Date.now() + parseInt(process.env.RESET_TOKEN_EXPIRY_MS || '3600000', 10));
  const tokenHash = crypto.createHash('sha256').update(token).digest('hex');

  await require('../config/database').query(
    `UPDATE users SET password_reset_token = $1, password_reset_expires = $2 WHERE id = $3`,
    [tokenHash, expires, user.id]
  );

  // In production: send email with token. Returned here for testing.
  return { token, email: user.email };
};

const resetPassword = async (token, newPassword) => {
  const tokenHash = crypto.createHash('sha256').update(token).digest('hex');
  const { rows } = await require('../config/database').query(
    `SELECT id FROM users
     WHERE password_reset_token = $1
       AND password_reset_expires > NOW()`,
    [tokenHash]
  );
  if (!rows.length) throw new AppError('Reset token is invalid or has expired.', 400, 'INVALID_TOKEN');

  const password_hash = await hash(newPassword);
  await require('../config/database').query(
    `UPDATE users SET password_hash = $1,
            password_reset_token = NULL, password_reset_expires = NULL
     WHERE id = $2`,
    [password_hash, rows[0].id]
  );
  await UserModel.clearRefreshToken(rows[0].id);
};

module.exports = { register, login, refresh, logout, forgotPassword, resetPassword };
