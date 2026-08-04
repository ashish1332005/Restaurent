const request = require('supertest');
const app = require('../src/app');

describe('Auth API Integration Tests', () => {
  it('should return 400 for login without credentials', async () => {
    const res = await request(app).post('/api/v1/auth/login').send({});
    expect(res.statusCode).toEqual(400);
    expect(res.body.success).toBe(false);
  });

  it('should return 400 for google customer auth without tokens', async () => {
    const res = await request(app).post('/api/v1/auth/google/customer').send({});
    expect(res.statusCode).toEqual(400);
    expect(res.body.success).toBe(false);
  });
});
