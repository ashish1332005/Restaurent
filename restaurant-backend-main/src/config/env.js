const dotenv = require('dotenv');
dotenv.config();
const validateEnv = () => {
  const errors = [];
  const production = process.env.NODE_ENV === 'production';
  if (!process.env.MONGO_URI || /USER:PASSWORD|cluster\.example/i.test(process.env.MONGO_URI)) errors.push('MONGO_URI must be configured');
  if (!process.env.JWT_SECRET || process.env.JWT_SECRET.length < 32 || /replace|secret/i.test(process.env.JWT_SECRET)) errors.push('JWT_SECRET must be a strong value of at least 32 characters');
  if (!process.env.JWT_EXPIRE) errors.push('JWT_EXPIRE is required (example: 7d)');
  const port = Number(process.env.PORT || 5000);
  if (!Number.isInteger(port) || port < 1 || port > 65535) errors.push('PORT must be between 1 and 65535');
  if (production && (!process.env.CORS_ORIGIN || process.env.CORS_ORIGIN.trim() === '*')) errors.push('CORS_ORIGIN must list the production frontend origin');
  if (process.env.RAZORPAY_ENABLED === 'true' && (!process.env.RAZORPAY_KEY_ID || !process.env.RAZORPAY_KEY_SECRET || !process.env.RAZORPAY_WEBHOOK_SECRET)) errors.push('RAZORPAY_KEY_ID, RAZORPAY_KEY_SECRET and RAZORPAY_WEBHOOK_SECRET are required when Razorpay is enabled');
  if (errors.length) throw new Error(`Environment validation failed: ${errors.join('; ')}`);
  return { port, production };
};
module.exports = { validateEnv };
