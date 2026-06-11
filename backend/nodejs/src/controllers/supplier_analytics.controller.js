const AnalyticsService = require('../services/supplier_analytics.service');
const { AppError } = require('../middleware/errorHandler');

const resolveSupplier = async (req) => {
  const id = await AnalyticsService.getSupplierIdForUser(req.user.id);
  if (!id) throw new AppError('No active supplier account found.', 403, 'FORBIDDEN');
  return id;
};

const dashboard = async (req, res, next) => {
  try {
    let supplierId;
    if (req.user.role === 'admin' && req.query.supplier_id) {
      supplierId = req.query.supplier_id;
    } else {
      supplierId = await resolveSupplier(req);
    }

    const [kpis, orderStatusBreakdown] = await Promise.all([
      AnalyticsService.getDashboardKpis(supplierId),
      AnalyticsService.getOrderStatusBreakdown(supplierId),
    ]);

    res.json({ data: { kpis, order_status_breakdown: orderStatusBreakdown } });
  } catch (err) { next(err); }
};

const revenue = async (req, res, next) => {
  try {
    const supplierId = await resolveSupplier(req);
    const days = Math.min(365, Math.max(7, parseInt(req.query.days || '30', 10)));
    const series = await AnalyticsService.getDailyRevenue(supplierId, days);
    res.json({ data: series, meta: { days } });
  } catch (err) { next(err); }
};

const topProducts = async (req, res, next) => {
  try {
    const supplierId = await resolveSupplier(req);
    const limit = Math.min(20, Math.max(1, parseInt(req.query.limit || '10', 10)));
    const products = await AnalyticsService.getTopProducts(supplierId, limit);
    res.json({ data: products });
  } catch (err) { next(err); }
};

module.exports = { dashboard, revenue, topProducts };
