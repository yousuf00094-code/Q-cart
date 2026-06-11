'use strict';

jest.mock('../config/database', () => ({ query: jest.fn() }));
const { query } = require('../config/database');
const { apply } = require('../controllers/suppliers.controller');

const mockRes = () => {
  const res = {};
  res.status = jest.fn().mockReturnValue(res);
  res.json = jest.fn().mockReturnValue(res);
  return res;
};

afterEach(() => jest.clearAllMocks());

describe('POST /v1/suppliers/apply', () => {
  it('creates a pending_approval supplier and returns 201', async () => {
    query.mockResolvedValueOnce({
      rows: [{ id: 'sup-uuid', status: 'pending_approval' }],
    });

    const req = {
      body: {
        business_name: 'Doha Tech LLC',
        email: 'apply@dohatech.qa',
        phone: '+97412345678',
        cr_number: 'CR-12345',
        category: 'Electronics',
      },
    };
    const res = mockRes();
    const next = jest.fn();

    await apply(req, res, next);

    expect(res.status).toHaveBeenCalledWith(201);
    expect(res.json).toHaveBeenCalledWith(
      expect.objectContaining({
        data: expect.objectContaining({ status: 'pending_approval' }),
        message: expect.any(String),
      })
    );
    expect(next).not.toHaveBeenCalled();
  });

  it('returns 409 when email already exists', async () => {
    const dupErr = new Error('duplicate');
    dupErr.code = '23505';
    query.mockRejectedValueOnce(dupErr);

    const req = { body: { business_name: 'Dup', email: 'dup@test.qa' } };
    const res = mockRes();

    await apply(req, res, jest.fn());

    expect(res.status).toHaveBeenCalledWith(409);
    expect(res.json).toHaveBeenCalledWith(
      expect.objectContaining({
        error: expect.objectContaining({ code: 'EMAIL_EXISTS' }),
      })
    );
  });

  it('passes unexpected errors to next()', async () => {
    const err = new Error('DB timeout');
    query.mockRejectedValueOnce(err);

    const req = { body: { business_name: 'X', email: 'x@x.qa' } };
    const next = jest.fn();
    await apply(req, mockRes(), next);

    expect(next).toHaveBeenCalledWith(err);
  });
});
