const PayoutModel = require('../models/supplier_payout.model');
const { AppError } = require('../middleware/errorHandler');
const { parsePagination, buildMeta } = require('../utils/pagination');
const { getSupplierIdForUser } = require('../services/supplier_analytics.service');

const list = async (req, res, next) => {
  try {
    const supplierId = await getSupplierIdForUser(req.user.id);
    if (!supplierId) throw new AppError('No active supplier account found.', 403, 'FORBIDDEN');

    const { page, limit, offset } = parsePagination(req.query);
    const { rows, total } = await PayoutModel.listBySupplier(supplierId, {
      limit, offset, status: req.query.status,
    });

    res.json({ data: rows, meta: buildMeta(total, page, limit) });
  } catch (err) { next(err); }
};

const getOne = async (req, res, next) => {
  try {
    const payout = await PayoutModel.findById(req.params.id);
    if (!payout) throw new AppError('Payout not found.', 404, 'NOT_FOUND');

    if (req.user.role !== 'admin') {
      const supplierId = await getSupplierIdForUser(req.user.id);
      if (payout.supplier_id !== supplierId) {
        throw new AppError('Access denied.', 403, 'FORBIDDEN');
      }
    }

    const items = await PayoutModel.getItems(payout.id);
    res.json({ data: { ...payout, items } });
  } catch (err) { next(err); }
};

const listAll = async (req, res, next) => {
  try {
    const { page, limit, offset } = parsePagination(req.query);
    const { rows, total } = await PayoutModel.listAll({
      limit, offset,
      status: req.query.status,
      supplier_id: req.query.supplier_id,
    });
    res.json({ data: rows, meta: buildMeta(total, page, limit) });
  } catch (err) { next(err); }
};

module.exports = { list, getOne, listAll };
