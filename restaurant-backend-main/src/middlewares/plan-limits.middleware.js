const Restaurant = require('../models/Restaurant.model');
const Branch = require('../models/Branch.model');
const Table = require('../models/Table.model');
const User = require('../models/User.model');

const PLAN_LIMITS = Object.freeze({
    Basic: { branches: 1, staff: 10, tables: 20 },
    Pro: { branches: 3, staff: 40, tables: 60 },
    Premium: { branches: 10, staff: 150, tables: 200 },
    Enterprise: { branches: 100, staff: 1000, tables: 2000 }
});

const countUsage = async (restaurantId, resource) => {
    if (resource === 'branches') return Branch.countDocuments({ restaurantId, isActive: true });
    if (resource === 'staff') return User.countDocuments({ restaurantId, status: { $ne: 'Suspended' } });
    if (resource === 'tables') {
        const branchIds = await Branch.find({ restaurantId, isActive: true }).distinct('_id');
        return Table.countDocuments({ branchId: { $in: branchIds } });
    }
    throw new Error(`Unknown plan resource: ${resource}`);
};

const enforcePlanLimit = (resource) => async (req, res, next) => {
    try {
        if (req.user?.role?.name === 'Super Admin') return next();
        const restaurant = req.restaurant || await Restaurant.findById(req.user?.restaurantId).lean();
        if (!restaurant) return res.status(403).json({ success: false, message: 'Restaurant scope is required' });
        const limits = PLAN_LIMITS[restaurant.subscriptionPlan] || PLAN_LIMITS.Basic;
        const limit = limits[resource];
        const usage = await countUsage(restaurant._id, resource);
        if (usage >= limit) return res.status(403).json({ success: false, message: `${restaurant.subscriptionPlan} plan limit reached for ${resource}`, code: 'PLAN_LIMIT_REACHED', data: { resource, limit, usage } });
        req.planLimits = { ...limits, usage: { [resource]: usage } };
        next();
    } catch (error) {
        next(error);
    }
};

module.exports = { PLAN_LIMITS, enforcePlanLimit };