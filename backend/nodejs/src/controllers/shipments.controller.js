const ShipmentModel = require('../models/shipment.model');
const { AppError } = require('../middleware/errorHandler');
const { parsePagination, buildMeta } = require('../utils/pagination');
const { getSupplierIdForUser } = require('../services/supplier_analytics.service');

const list = async (req, res, next) => {
  try {
    const supplierId = await getSupplierIdForUser(req.user.id);
    if (!supplierId) throw new AppError('No active supplier account found.', 403, 'FORBIDDEN');

    const { page, limit, offset } = parsePagination(req.query);
    const { rows, total } = await ShipmentModel.listBySupplier(supplierId, {
      limit, offset, status: req.query.status,
    });

    res.json({ data: rows, meta: buildMeta(total, page, limit) });
  } catch (err) { next(err); }
};

const getOne = async (req, res, next) => {
  try {
    const shipment = await ShipmentModel.findById(req.params.id);
    if (!shipment) throw new AppError('Shipment not found.', 404, 'NOT_FOUND');

    if (req.user.role !== 'admin') {
      const supplierId = await getSupplierIdForUser(req.user.id);
      if (shipment.supplier_id !== supplierId) {
        throw new AppError('Access denied.', 403, 'FORBIDDEN');
      }
    }

    const events = await ShipmentModel.getEvents(shipment.id);
    res.json({ data: { ...shipment, events } });
  } catch (err) { next(err); }
};

const create = async (req, res, next) => {
  try {
    const supplierId = await getSupplierIdForUser(req.user.id);
    if (!supplierId) throw new AppError('No active supplier account found.', 403, 'FORBIDDEN');

    const shipment = await ShipmentModel.create({ ...req.body, supplier_id: supplierId });
    res.status(201).json({ data: shipment });
  } catch (err) { next(err); }
};

const update = async (req, res, next) => {
  try {
    const existing = await ShipmentModel.findById(req.params.id);
    if (!existing) throw new AppError('Shipment not found.', 404, 'NOT_FOUND');

    if (req.user.role !== 'admin') {
      const supplierId = await getSupplierIdForUser(req.user.id);
      if (existing.supplier_id !== supplierId) {
        throw new AppError('Access denied.', 403, 'FORBIDDEN');
      }
    }

    const updated = await ShipmentModel.update(req.params.id, req.body);
    res.json({ data: updated });
  } catch (err) { next(err); }
};

const addEvent = async (req, res, next) => {
  try {
    const existing = await ShipmentModel.findById(req.params.id);
    if (!existing) throw new AppError('Shipment not found.', 404, 'NOT_FOUND');

    if (req.user.role !== 'admin') {
      const supplierId = await getSupplierIdForUser(req.user.id);
      if (existing.supplier_id !== supplierId) {
        throw new AppError('Access denied.', 403, 'FORBIDDEN');
      }
    }

    const event = await ShipmentModel.addEvent(existing.id, req.body);
    res.status(201).json({ data: event });
  } catch (err) { next(err); }
};

module.exports = { list, getOne, create, update, addEvent };
