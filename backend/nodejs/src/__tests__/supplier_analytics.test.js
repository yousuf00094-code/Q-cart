'use strict';

jest.mock('../config/database', () => ({ query: jest.fn() }));
const { query } = require('../config/database');

const {
  getSupplierIdForUser,
  getDashboardKpis,
  getDailyRevenue,
  getTopProducts,
  getOrderStatusBreakdown,
} = require('../services/supplier_analytics.service');

afterEach(() => jest.clearAllMocks());

describe('getSupplierIdForUser', () => {
  it('returns supplier id when active supplier exists', async () => {
    query.mockResolvedValueOnce({ rows: [{ id: 'sup-001' }] });
    const id = await getSupplierIdForUser('usr-001');
    expect(id).toBe('sup-001');
    expect(query).toHaveBeenCalledWith(
      expect.stringContaining("status = 'active'"),
      ['usr-001']
    );
  });

  it('returns null when no active supplier found', async () => {
    query.mockResolvedValueOnce({ rows: [] });
    expect(await getSupplierIdForUser('usr-002')).toBeNull();
  });
});

describe('getDashboardKpis', () => {
  it('returns shaped KPI object with all required fields', async () => {
    query
      .mockResolvedValueOnce({
        rows: [{
          total_orders: '10', orders_mtd: '3',
          revenue_all_time: '5000.00', revenue_mtd: '1200.50',
          avg_order_value: '500.00', active_products: '5',
          cancelled_orders: '1', total_orders_incl_cancelled: '11',
        }],
      })
      .mockResolvedValueOnce({ rows: [{ avg_rating: '4.50', review_count: '20' }] });

    const kpis = await getDashboardKpis('sup-001');
    expect(kpis.total_orders).toBe(10);
    expect(kpis.orders_mtd).toBe(3);
    expect(kpis.revenue_mtd).toBe(1200.5);
    expect(kpis.avg_rating).toBe(4.5);
    expect(kpis.review_count).toBe(20);
    expect(typeof kpis.cancellation_rate).toBe('number');
  });

  it('calculates cancellation_rate correctly', async () => {
    query
      .mockResolvedValueOnce({
        rows: [{
          total_orders: '9', orders_mtd: '2',
          revenue_all_time: '1000', revenue_mtd: '200',
          avg_order_value: '100', active_products: '3',
          cancelled_orders: '1', total_orders_incl_cancelled: '10',
        }],
      })
      .mockResolvedValueOnce({ rows: [{ avg_rating: '4', review_count: '5' }] });

    const kpis = await getDashboardKpis('sup-001');
    // 1 cancelled out of 10 total = 10.0%
    expect(kpis.cancellation_rate).toBe(10.0);
  });
});

describe('getDailyRevenue', () => {
  it('passes supplier id and day count as parameters', async () => {
    const rows = [{ date: '2024-06-01', revenue: '500', orders: '3' }];
    query.mockResolvedValueOnce({ rows });

    const result = await getDailyRevenue('sup-001', 7);
    expect(result).toEqual(rows);
    expect(query).toHaveBeenCalledWith(expect.any(String), ['sup-001', 7]);
  });
});

describe('getTopProducts', () => {
  it('returns products and passes limit', async () => {
    const rows = [{ id: 'p-1', name: 'Widget', revenue: '3000', units_sold: '15' }];
    query.mockResolvedValueOnce({ rows });

    const result = await getTopProducts('sup-001', 5);
    expect(result).toEqual(rows);
    expect(query).toHaveBeenCalledWith(expect.any(String), ['sup-001', 5]);
  });
});

describe('getOrderStatusBreakdown', () => {
  it('groups orders by status', async () => {
    const rows = [
      { status: 'delivered', count: '8' },
      { status: 'cancelled', count: '2' },
    ];
    query.mockResolvedValueOnce({ rows });
    const result = await getOrderStatusBreakdown('sup-001');
    expect(result).toEqual(rows);
  });
});
