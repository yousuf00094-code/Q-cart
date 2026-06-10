const AuthService = require('../services/auth.service');

const COOKIE_OPTS = {
  httpOnly: true,
  secure: process.env.NODE_ENV === 'production',
  sameSite: 'strict',
  maxAge: 7 * 24 * 60 * 60 * 1000,
};

const register = async (req, res, next) => {
  try {
    const { user, accessToken, refreshToken } = await AuthService.register(req.body);
    res.cookie('refresh_token', refreshToken, COOKIE_OPTS);
    res.status(201).json({ data: { user, access_token: accessToken, expires_in: 900 } });
  } catch (err) { next(err); }
};

const login = async (req, res, next) => {
  try {
    const { user, accessToken, refreshToken } = await AuthService.login(req.body);
    res.cookie('refresh_token', refreshToken, COOKIE_OPTS);
    res.json({ data: { user, access_token: accessToken, expires_in: 900 } });
  } catch (err) { next(err); }
};

const refresh = async (req, res, next) => {
  try {
    const { accessToken, refreshToken } = await AuthService.refresh(req.cookies?.refresh_token);
    res.cookie('refresh_token', refreshToken, COOKIE_OPTS);
    res.json({ data: { access_token: accessToken, expires_in: 900 } });
  } catch (err) { next(err); }
};

const logout = async (req, res, next) => {
  try {
    await AuthService.logout(req.user.id);
    res.clearCookie('refresh_token');
    res.status(204).send();
  } catch (err) { next(err); }
};

const forgotPassword = async (req, res, next) => {
  try {
    await AuthService.forgotPassword(req.body.email);
    res.status(202).json({ data: { message: 'If that email exists, a reset link has been sent.' } });
  } catch (err) { next(err); }
};

const resetPassword = async (req, res, next) => {
  try {
    await AuthService.resetPassword(req.body.token, req.body.password);
    res.json({ data: { message: 'Password updated successfully.' } });
  } catch (err) { next(err); }
};

module.exports = { register, login, refresh, logout, forgotPassword, resetPassword };
