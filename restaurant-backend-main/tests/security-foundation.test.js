const { errorHandler } = require('../src/middlewares/error.middleware');
const { PLAN_LIMITS } = require('../src/middlewares/plan-limits.middleware');

const createResponse = () => ({
  statusCode: 200,
  status: jest.fn(function setStatus(code) { this.statusCode = code; return this; }),
  json: jest.fn()
});

describe('Security foundation', () => {
  const originalEnvironment = process.env.NODE_ENV;

  afterEach(() => {
    process.env.NODE_ENV = originalEnvironment;
  });

  it('preserves application-defined authorization status codes', () => {
    const response = createResponse();
    const error = new Error('Branch access denied');
    error.statusCode = 403;
    errorHandler(error, {}, response, jest.fn());
    expect(response.status).toHaveBeenCalledWith(403);
    expect(response.json).toHaveBeenCalledWith(expect.objectContaining({ success: false, message: 'Branch access denied' }));
  });

  it('converts duplicate database values into conflict responses', () => {
    const response = createResponse();
    const error = { code: 11000, keyPattern: { phone: 1 }, message: 'duplicate' };
    errorHandler(error, {}, response, jest.fn());
    expect(response.status).toHaveBeenCalledWith(409);
    expect(response.json).toHaveBeenCalledWith(expect.objectContaining({ success: false, message: 'phone already exists' }));
  });

  it('does not expose internal failures in production', () => {
    process.env.NODE_ENV = 'production';
    const response = createResponse();
    errorHandler(new Error('database password leaked'), {}, response, jest.fn());
    expect(response.status).toHaveBeenCalledWith(500);
    expect(response.json).toHaveBeenCalledWith({ success: false, message: 'Internal server error' });
  });

  it('defines monotonically increasing SaaS plan limits', () => {
    expect(PLAN_LIMITS.Basic.branches).toBeLessThanOrEqual(PLAN_LIMITS.Pro.branches);
    expect(PLAN_LIMITS.Pro.staff).toBeLessThanOrEqual(PLAN_LIMITS.Premium.staff);
    expect(PLAN_LIMITS.Premium.tables).toBeLessThanOrEqual(PLAN_LIMITS.Enterprise.tables);
  });
});