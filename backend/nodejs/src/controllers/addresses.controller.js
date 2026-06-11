const AddressModel = require('../models/address.model');
const { AppError } = require('../middleware/errorHandler');

const list = async (req, res, next) => {
  try {
    const addresses = await AddressModel.findByUser(req.user.id);
    res.json({ data: addresses });
  } catch (err) { next(err); }
};

const getOne = async (req, res, next) => {
  try {
    const address = await AddressModel.findById(req.params.id);
    if (!address) throw new AppError('Address not found.', 404, 'NOT_FOUND');
    if (address.user_id !== req.user.id) throw new AppError('Forbidden.', 403, 'FORBIDDEN');
    res.json({ data: address });
  } catch (err) { next(err); }
};

const create = async (req, res, next) => {
  try {
    const address = await AddressModel.create(req.user.id, req.body);
    res.status(201).json({ data: address });
  } catch (err) { next(err); }
};

const update = async (req, res, next) => {
  try {
    const existing = await AddressModel.findById(req.params.id);
    if (!existing) throw new AppError('Address not found.', 404, 'NOT_FOUND');
    if (existing.user_id !== req.user.id) throw new AppError('Forbidden.', 403, 'FORBIDDEN');

    const updated = await AddressModel.update(req.params.id, req.user.id, req.body);
    res.json({ data: updated });
  } catch (err) { next(err); }
};

const setDefault = async (req, res, next) => {
  try {
    const existing = await AddressModel.findById(req.params.id);
    if (!existing) throw new AppError('Address not found.', 404, 'NOT_FOUND');
    if (existing.user_id !== req.user.id) throw new AppError('Forbidden.', 403, 'FORBIDDEN');

    const updated = await AddressModel.setDefault(req.params.id, req.user.id);
    res.json({ data: updated });
  } catch (err) { next(err); }
};

const remove = async (req, res, next) => {
  try {
    const existing = await AddressModel.findById(req.params.id);
    if (!existing) throw new AppError('Address not found.', 404, 'NOT_FOUND');
    if (existing.user_id !== req.user.id) throw new AppError('Forbidden.', 403, 'FORBIDDEN');

    await AddressModel.remove(req.params.id, req.user.id);
    res.status(204).send();
  } catch (err) { next(err); }
};

module.exports = { list, getOne, create, update, setDefault, remove };
