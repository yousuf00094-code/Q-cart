const RiskModel = require('../models/supplier_risk.model');
const { computeRiskScore } = require('../services/supplier_risk.service');
const { AppError } = require('../middleware/errorHandler');
const { parsePagination, buildMeta } = require('../utils/pagination');

const listAll = async (req, res, next) => {
  try {
    const { page, limit, offset } = parsePagination(req.query);
    const { rows, total } = await RiskModel.listAll({
      limit, offset, risk_level: req.query.risk_level,
    });
    res.json({ data: rows, meta: buildMeta(total, page, limit) });
  } catch (err) { next(err); }
};

const getOne = async (req, res, next) => {
  try {
    const risk = await RiskModel.findBySupplierId(req.params.supplier_id);
    if (!risk) throw new AppError('Risk score not found for this supplier.', 404, 'NOT_FOUND');
    res.json({ data: risk });
  } catch (err) { next(err); }
};

const recompute = async (req, res, next) => {
  try {
    const risk = await computeRiskScore(req.params.supplier_id);
    res.json({ data: risk });
  } catch (err) { next(err); }
};

module.exports = { listAll, getOne, recompute };
