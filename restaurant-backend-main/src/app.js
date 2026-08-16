const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const path = require('path');
const rateLimit = require('express-rate-limit');
require('dotenv').config();

const { errorHandler, notFound } = require('./middlewares/error.middleware');

const app = express();
if (process.env.NODE_ENV === 'production') app.set('trust proxy', 1);

const allowedOrigins = (process.env.CORS_ORIGIN || '*')
    .split(',')
    .map((origin) => origin.trim())
    .filter(Boolean);
const corsOptions = {
    origin: allowedOrigins.includes('*') ? '*' : allowedOrigins,
    credentials: !allowedOrigins.includes('*')
};

// Security Middlewares
app.use(helmet());
app.use(cors(corsOptions));
// Express 5 exposes req.query as a getter, so mutating sanitizers crash while
// trying to assign it. Reject operator/dotted keys without mutating requests.
const hasUnsafeMongoKey = (value) => {
    if (!value || typeof value !== 'object') return false;
    return Object.entries(value).some(([key, child]) =>
        key.startsWith('$') || key.includes('.') || hasUnsafeMongoKey(child)
    );
};
// Rate limiting
const limiter = rateLimit({
    windowMs: 15 * 60 * 1000, // 15 minutes
    max: 100, // limit each IP to 100 requests per windowMs
    message: 'Too many requests from this IP, please try again later.'
});
app.use('/api', limiter);

// Razorpay requires the untouched raw request bytes for HMAC verification.
app.post('/api/v1/payments/razorpay/webhook', express.raw({ type: 'application/json', limit: '256kb' }), require('./modules/payments/razorpay-webhook.controller').handleRazorpayWebhook);

// Parsing
app.use(express.json({ limit: '10kb' }));
app.use(express.urlencoded({ extended: true, limit: '10kb' }));
app.use((req, res, next) => {
    if (hasUnsafeMongoKey(req.body) || hasUnsafeMongoKey(req.query) || hasUnsafeMongoKey(req.params)) {
        return res.status(400).json({ success: false, message: 'Invalid request fields' });
    }
    next();
});

// Logging
if (process.env.NODE_ENV === 'development') {
    app.use(morgan('dev'));
}

// Routes
app.use('/uploads', express.static(path.resolve(__dirname, '../uploads'), {
    fallthrough: false,
    maxAge: process.env.NODE_ENV === 'production' ? '7d' : 0
}));
app.use('/api/v1/uploads', require('./modules/uploads/upload.routes'));
app.use('/api/v1/auth', require('./modules/auth/auth.routes'));
app.use('/api/v1/restaurants', require('./modules/restaurants/restaurant.routes'));
app.use('/api/v1/users', require('./modules/users/users.routes'));
app.use('/api/v1/menu', require('./modules/menu/menu.routes'));
app.use('/api/v1/tables', require('./modules/tables/tables.routes'));
app.use('/api/v1/orders', require('./modules/orders/orders.routes'));
app.use('/api/v1/inventory', require('./modules/inventory/inventory.routes'));
app.use('/api/v1/reports', require('./modules/reports/reports.routes'));
app.use('/api/v1/coupons', require('./modules/coupons/coupons.routes'));
app.use('/api/v1/qr', require('./modules/qr/qr.routes'));
app.use('/api/v1/payments', require('./modules/payments/payments.routes'));
app.use('/api/v1/platform', require('./modules/platform/platform.routes'));
app.use('/api/v1/service-requests', require('./modules/service-requests/service-requests.routes'));
app.use('/api/v1/attendance', require('./modules/attendance/attendance.routes'));

app.get('/health', (req, res) => res.status(200).json({ success: true, status: 'ok', uptimeSeconds: Math.floor(process.uptime()) }));
app.get('/ready', (req, res) => {
    const mongoose = require('mongoose');
    const ready = mongoose.connection.readyState === 1;
    res.status(ready ? 200 : 503).json({ success: ready, status: ready ? 'ready' : 'not_ready' });
});
// Base Route
app.get('/', (req, res) => {
    res.status(200).json({
        success: true,
        message: 'Welcome to Enterprise Restaurant Automation API'
    });
});

// Error Handling
app.use(notFound);
app.use(errorHandler);

module.exports = app;







