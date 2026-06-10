const InventoryModel = require('../models/inventory.model');
const { parsePagination, buildMeta } = require('../utils/pagination');
const { AppError } = require('../middleware/errorHandler');

const list = async (req, res, next) => {
  try {
    const { page, limit, offset } = parsePagination(req.query);
    const { rows, total } = await InventoryModel.list({
      limit, offset,
      lowStock: req.query.low_stock === 'true',
      search: req.query.q,
    });
    res.json({ data: rows, meta: buildMeta(total, page, limit) });
  } catch (err) { next(err); }
};

const getOne = async (req, res, next) => {
  try {
    const item = await InventoryModel.findByProductId(req.params.productId);
    if (!item) throw new AppError('Inventory record not found.', 404, 'NOT_FOUND');
    res.json({ data: item });
  } catch (err) { next(err); }
};

const adjust = async (req, res, next) => {
  try {
    const { txn_type, quantity_delta, notes } = req.body;
    const current = await InventoryModel.findByProductId(req.params.productId);
    if (!current) throw new AppError('Product inventory not found.', 404, 'NOT_FOUND');

    const updated = await InventoryModel.adjust(null, req.params.productId, quantity_delta);
    await InventoryModel.logTransaction(null, {
      productId: req.params.productId,
      txnType: txn_type,
      quantityDelta: quantity_delta,
      quantityAfter: updated.quantity,
      notes,
      createdBy: req.user.id,
    });
    res.json({ data: { ...current, quantity: updated.quantity } });
  } catch (err) { next(err); }
};

const getTransactions = async (req, res, next) => {
  try {
    const { page, limit, offset } = parsePagination(req.query);
    const { rows, total } = await InventoryModel.getTransactions(req.params.productId, {
      limit, offset, txnType: req.query.txn_type,
    });
    res.json({ data: rows, meta: buildMeta(total, page, limit) });
  } catch (err) { next(err); }
};

const alerts = async (req, res, next) => {
  try {
    const rows = await InventoryModel.getLowStockAlerts();
    res.json({ data: rows });
  } catch (err) { next(err); }
};

module.exports = { list, getOne, adjust, getTransactions, alerts };
