'use strict';

jest.mock('../config/database', () => ({ query: jest.fn() }));
const { query } = require('../config/database');
const ShipmentModel = require('../models/shipment.model');

afterEach(() => jest.clearAllMocks());

describe('ShipmentModel.findById', () => {
  it('returns shipment when found', async () => {
    const row = { id: 'ship-001', order_id: 'ord-001', status: 'in_transit' };
    query.mockResolvedValueOnce({ rows: [row] });
    expect(await ShipmentModel.findById('ship-001')).toEqual(row);
  });

  it('returns null when not found', async () => {
    query.mockResolvedValueOnce({ rows: [] });
    expect(await ShipmentModel.findById('ship-999')).toBeNull();
  });
});

describe('ShipmentModel.create', () => {
  it('inserts and returns the created shipment', async () => {
    const created = { id: 'ship-002', order_id: 'ord-001', supplier_id: 'sup-001', status: 'pending' };
    query.mockResolvedValueOnce({ rows: [created] });

    const result = await ShipmentModel.create({ order_id: 'ord-001', supplier_id: 'sup-001' });
    expect(result).toEqual(created);
    expect(query).toHaveBeenCalledWith(
      expect.stringContaining('INSERT INTO shipments'),
      expect.any(Array)
    );
  });

  it('passes null for optional fields when omitted', async () => {
    query.mockResolvedValueOnce({ rows: [{ id: 'ship-003' }] });
    await ShipmentModel.create({ order_id: 'ord-002', supplier_id: 'sup-001' });

    const args = query.mock.calls[0][1];
    // carrier and tracking_number should be null
    expect(args[2]).toBeNull(); // carrier
    expect(args[3]).toBeNull(); // tracking_number
  });
});

describe('ShipmentModel.update', () => {
  it('builds SET clause only from provided fields', async () => {
    query.mockResolvedValueOnce({ rows: [{ id: 'ship-001', status: 'delivered' }] });
    const result = await ShipmentModel.update('ship-001', { status: 'delivered' });
    expect(result.status).toBe('delivered');
    const sql = query.mock.calls[0][0];
    expect(sql).toContain('status =');
    expect(sql).not.toContain('carrier =');
  });

  it('calls findById when no fields to update', async () => {
    query.mockResolvedValueOnce({ rows: [{ id: 'ship-001' }] });
    await ShipmentModel.update('ship-001', {});
    // Should have called a SELECT (findById), not an UPDATE
    expect(query.mock.calls[0][0]).toContain('SELECT');
  });
});

describe('ShipmentModel.addEvent', () => {
  it('inserts event with correct parameters', async () => {
    const event = { id: 'evt-001', shipment_id: 'ship-001', status: 'picked_up' };
    query.mockResolvedValueOnce({ rows: [event] });

    const result = await ShipmentModel.addEvent('ship-001', {
      status: 'picked_up',
      location: 'Warehouse, Doha',
    });
    expect(result).toEqual(event);
    expect(query).toHaveBeenCalledWith(
      expect.stringContaining('INSERT INTO shipment_events'),
      expect.arrayContaining(['ship-001', 'picked_up'])
    );
  });
});

describe('ShipmentModel.listBySupplier', () => {
  it('returns rows and total', async () => {
    query
      .mockResolvedValueOnce({ rows: [{ count: '5' }] })
      .mockResolvedValueOnce({ rows: [{ id: 'ship-001' }, { id: 'ship-002' }] });

    const result = await ShipmentModel.listBySupplier('sup-001', { limit: 10, offset: 0 });
    expect(result.total).toBe(5);
    expect(result.rows).toHaveLength(2);
  });

  it('appends status WHERE clause when status provided', async () => {
    query.mockResolvedValueOnce({ rows: [{ count: '1' }] }).mockResolvedValueOnce({ rows: [] });
    await ShipmentModel.listBySupplier('sup-001', { limit: 10, offset: 0, status: 'delivered' });
    const [sql, params] = query.mock.calls[0];
    expect(sql).toContain('status');
    expect(params).toContain('delivered');
  });
});
