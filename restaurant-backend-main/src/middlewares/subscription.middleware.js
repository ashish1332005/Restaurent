const Restaurant = require('../models/Restaurant.model');

const ACTIVE_STATUSES = new Set(['Active', 'Trial']);

const requireActiveSubscription = async (req, res, next) => {
    try {
        if (req.user?.role?.name === 'Super Admin' && !req.body.restaurantId && !req.params.restaurantId) {
            return next();
        }
        const restaurantId = req.user?.restaurantId || req.body.restaurantId || req.params.restaurantId;
        if (!restaurantId) {
            return res.status(403).json({ success: false, message: 'Restaurant scope is required' });
        }

        const restaurant = await Restaurant.findById(restaurantId).lean();
        const now = new Date();
        const isExpired = restaurant?.subscriptionExpiresAt && new Date(restaurant.subscriptionExpiresAt) < now;

        if (!restaurant || !restaurant.isActive || !ACTIVE_STATUSES.has(restaurant.subscriptionStatus) || isExpired) {
            return res.status(402).json({
                success: false,
                message: 'Restaurant subscription is not active. Please complete or renew payment.'
            });
        }

        req.restaurant = restaurant;
        next();
    } catch (error) {
        next(error);
    }
};

module.exports = { requireActiveSubscription };