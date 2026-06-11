'use strict';

jest.mock('../config/database', () => ({ query: jest.fn() }));
const { query } = require('../config/database');
const PayoutModel = require('../models/supplier_payout.model');

afterEach(() => jest.clearAllMocks());

describe('PayoutModel.findById', () => {
  it('returns payout with supplier name when found', async () => {
    const row = { id: 'pay-001', supplier_id: 'sup-001', net_amount: '5000', supplier_name: 'Acme Corp' };
    query.mockResolvedValueOnce({ rows: [row] });
    expect(await PayoutModel.findById('pay-001')).toEqual(row);
    expect(query).toHaveBeenCalledWith(
      expect.stringContaining('supplier_payouts sp'),
      ['pay-001']
    );
  });

  it('returns null when not found', async () => {
    query.mockResolvedValueOnce({ rows: [] });
    expect(await PayoutModel.findById('pay-999')).toBeNull();
  });
});

describe('PayoutModel.listBySupplier', () => {
  it('returns paginated rows and total', async () => {
    query
      .mockResolvedValueOnce({ rows: [{ count: '3' }] })
      .mockResolvedValueOnce({ rows: [{ id: 'pay-001' }, { id: 'pay-002' }] });

    const result = await PayoutModel.listBySupplier('sup-001', { limit: 10, offset: 0 });
    expect(result.total).toBe(3);
    expect(result.rows).toHaveLength(2);
  });

  it('adds status filter when provided', async () => {
    query.mockResolvedValueOnce({ rows: [{ count: '1' }] }).mockResolvedValueOnce({ rows: [] });
    await PayoutModel.listBySupplier('sup-001', { limit: 10, offset: 0, status: 'paid' });
    const [sql, params] = query.mock.calls[0];
    expect(sql).toContain('status');
    expect(params).toContain('paid');
  });

  it('does not add status filter when status is undefined', async () => {
    query.mockResolvedValueOnce({ rows: [{ count: '0' }] }).mockResolvedValueOnce({ rows: [] });
    await PayoutModel.listBySupplier('sup-001', { limit: 10, offset: 0 });
    const [sql] = query.mock.calls[0];
    expect(sql).not.toContain('status');
  });
});

describe('PayoutModel.getItems', () => {
  it('returns ordered line items for a payout', async () => {
    const items = [
      { id: 'i-1', payout_id: 'pay-001', order_number: 'QC-100001', net: '450' },
      { id: 'i-2', payout_id: 'pay-001', order_number: 'QC-100002', net: '800' },
    ];
    query.mockResolvedValueOnce({ rows: items });
    const result = await PayoutModel.getItems('pay-001');
    expect(result).toEqual(items);
    expect(query).toHaveBeenCalledWith(
      expect.stringContaining('supplier_payout_items'),
      ['pay-001']
    );
  });
});

describe('PayoutModel.listAll (admin)', () => {
  it('returns all payouts with supplier names', async () => {
    query
      .mockResolvedValueOnce({ rows: [{ count: '10' }] })
      .mockResolvedValueOnce({ rows: [{ id: 'pay-001', supplier_name: 'ACME' }] });

    const result = await PayoutModel.listAll({ limit: 24, offset: 0 });
    expect(result.total).toBe(10);
    expect(result.rows[0].supplier_name).toBe('ACME');
  });

  it('filters by supplier_id when provided', async () => {
    query.mockResolvedValueOnce({ rows: [{ count: '2' }] }).mockResolvedValueOnce({ rows: [] });
    await PayoutModel.listAll({ limit: 24, offset: 0, supplier_id: 'sup-001' });
    const [sql, params] = query.mock.calls[0];
    expect(sql).toContain('supplier_id');
    expect(params).toContain('sup-001');
  });
});
