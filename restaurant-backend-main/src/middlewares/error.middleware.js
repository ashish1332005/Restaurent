const notFound = (req, res, next) => {
    const error = new Error(`Not Found - ${req.originalUrl}`);
    error.statusCode = 404;
    next(error);
};

const getValidationMessage = (error) => Object.values(error.errors || {})
    .map((entry) => entry.message)
    .filter(Boolean)
    .join('; ') || 'Invalid request data';

const errorHandler = (err, req, res, next) => {
    let statusCode = Number(err.statusCode || err.status || (res.statusCode >= 400 ? res.statusCode : 500));
    let message = err.message || 'Internal server error';

    if (err.name === 'CastError') {
        statusCode = 400;
        message = `Invalid ${err.path}`;
    } else if (err.name === 'ValidationError') {
        statusCode = 400;
        message = getValidationMessage(err);
    } else if (err.code === 11000) {
        statusCode = 409;
        const field = Object.keys(err.keyPattern || {})[0] || 'value';
        message = `${field} already exists`;
    } else if (err.name === 'JsonWebTokenError' || err.name === 'TokenExpiredError') {
        statusCode = 401;
        message = 'Not authorized to access this route';
    } else if (err.type === 'entity.parse.failed') {
        statusCode = 400;
        message = 'Invalid JSON request body';
    }

    if (!Number.isInteger(statusCode) || statusCode < 400 || statusCode > 599) statusCode = 500;
    if (statusCode >= 500 && process.env.NODE_ENV === 'production') message = 'Internal server error';

    res.status(statusCode).json({
        success: false,
        message,
        ...(process.env.NODE_ENV === 'production' ? {} : { stack: err.stack })
    });
};

module.exports = { notFound, errorHandler };