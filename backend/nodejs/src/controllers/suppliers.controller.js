const SupplierModel = require('../models/supplier.model');
const { parsePagination, buildMeta } = require('../utils/pagination');
const { AppError } = require('../middleware/errorHandler');

const list = async (req, res, next) => {
  try {
    const { page, limit, offset } = parsePagination(req.query);
    const { rows, total } = await SupplierModel.list({
      limit, offset, status: req.query.status, search: req.query.q,
    });
    res.json({ data: rows, meta: buildMeta(total, page, limit) });
  } catch (err) { next(err); }
};

const getOne = async (req, res, next) => {
  try {
    const supplier = await SupplierModel.findById(req.params.id);
    if (!supplier) throw new AppError('Supplier not found.', 404, 'NOT_FOUND');
    res.json({ data: supplier });
  } catch (err) { next(err); }
};

const create = async (req, res, next) => {
  try {
    const supplier = await SupplierModel.create(req.body);
    res.status(201).json({ data: supplier });
  } catch (err) { next(err); }
};

const update = async (req, res, next) => {
  try {
    const existing = await SupplierModel.findById(req.params.id);
    if (!existing) throw new AppError('Supplier not found.', 404, 'NOT_FOUND');
    const updated = await SupplierModel.update(req.params.id, req.body);
    res.json({ data: updated });
  } catch (err) { next(err); }
};

const setStatus = async (req, res, next) => {
  try {
    const result = await SupplierModel.setStatus(req.params.id, req.body.status);
    if (!result) throw new AppError('Supplier not found.', 404, 'NOT_FOUND');
    res.json({ data: result });
  } catch (err) { next(err); }
};

// POST /v1/suppliers/apply — public, no auth required
const apply = async (req, res, next) => {
  try {
    const { business_name, email, phone, cr_number, category } = req.body;
    const notes = [
      cr_number ? `CR: ${cr_number}` : null,
      category  ? `Category: ${category}` : null,
    ].filter(Boolean).join(' | ') || null;

    const supplier = await SupplierModel.create({
      name: business_name,
      email,
      phone: phone || null,
      notes,
    });
    res.status(201).json({
      data: { id: supplier.id, status: supplier.status },
      message: 'Application submitted. Our team will review it within 2 business days.',
    });
  } catch (err) {
    if (err.code === '23505') {
      return res.status(409).json({
        error: { code: 'EMAIL_EXISTS', message: 'An application with this email already exists.' },
      });
    }
    next(err);
  }
};

module.exports = { list, getOne, create, update, setStatus, apply };
