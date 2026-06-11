'use strict';

const { uploadImage } = require('../controllers/uploads.controller');

const mockRes = () => {
  const res = {};
  res.status = jest.fn().mockReturnValue(res);
  res.json = jest.fn().mockReturnValue(res);
  return res;
};

describe('POST /v1/uploads/images', () => {
  it('returns 201 with url when file is present', () => {
    process.env.BASE_URL = 'http://localhost:3000';
    const req = {
      file: {
        filename: 'abc123.jpg',
        originalname: 'photo.jpg',
        mimetype: 'image/jpeg',
        size: 204800,
      },
    };
    const res = mockRes();
    uploadImage(req, res);

    expect(res.status).toHaveBeenCalledWith(201);
    expect(res.json).toHaveBeenCalledWith(
      expect.objectContaining({
        data: expect.objectContaining({
          url: 'http://localhost:3000/uploads/images/abc123.jpg',
          filename: 'abc123.jpg',
        }),
      })
    );
  });

  it('returns 422 when no file is uploaded', () => {
    const req = { file: undefined };
    const res = mockRes();
    uploadImage(req, res);

    expect(res.status).toHaveBeenCalledWith(422);
    expect(res.json).toHaveBeenCalledWith(
      expect.objectContaining({
        error: expect.objectContaining({ code: 'NO_FILE' }),
      })
    );
  });
});
