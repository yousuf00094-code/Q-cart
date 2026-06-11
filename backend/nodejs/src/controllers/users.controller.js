const UserModel  = require('../models/user.model');
const { verify, hash } = require('../utils/password');
const { parsePagination, buildMeta } = require('../utils/pagination');
const { AppError } = require('../middleware/errorHandler');

const getMe = async (req, res, next) => {
  try {
    const user = await UserModel.findById(req.user.id);
    const { password_hash, refresh_token_hash, ...safe } = user;
    res.json({ data: safe });
  } catch (err) { next(err); }
};

const updateMe = async (req, res, next) => {
  try {
    const updated = await UserModel.update(req.user.id, req.body);
    res.json({ data: updated });
  } catch (err) { next(err); }
};

const changePassword = async (req, res, next) => {
  try {
    const { rows } = await require('../config/database').query(
      'SELECT password_hash FROM users WHERE id = $1', [req.user.id]
    );
    if (!rows.length) throw new AppError('User not found.', 404, 'NOT_FOUND');
    const valid = await verify(req.body.current_password, rows[0].password_hash);
    if (!valid) throw new AppError('Current password is incorrect.', 400, 'WRONG_PASSWORD');
    const password_hash = await hash(req.body.new_password);
    await UserModel.updatePassword(req.user.id, password_hash);
    res.json({ data: { message: 'Password changed successfully.' } });
  } catch (err) { next(err); }
};

// Admin
const listUsers = async (req, res, next) => {
  try {
    const { page, limit, offset } = parsePagination(req.query);
    const { rows, total } = await UserModel.list({
      limit, offset, role: req.query.role, search: req.query.q,
    });
    res.json({ data: rows, meta: buildMeta(total, page, limit) });
  } catch (err) { next(err); }
};

const getUser = async (req, res, next) => {
  try {
    const user = await UserModel.findById(req.params.id);
    if (!user) throw new AppError('User not found.', 404, 'NOT_FOUND');
    const { password_hash, refresh_token_hash, ...safe } = user;
    res.json({ data: safe });
  } catch (err) { next(err); }
};

const setUserStatus = async (req, res, next) => {
  try {
    const result = await UserModel.setStatus(req.params.id, req.body.is_active);
    if (!result) throw new AppError('User not found.', 404, 'NOT_FOUND');
    res.json({ data: result });
  } catch (err) { next(err); }
};

module.exports = { getMe, updateMe, changePassword, listUsers, getUser, setUserStatus };
