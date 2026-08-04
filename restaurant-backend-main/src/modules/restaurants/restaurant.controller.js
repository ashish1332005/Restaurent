const Restaurant = require('../../models/Restaurant.model');
const Branch = require('../../models/Branch.model');

exports.createRestaurant = async (req, res, next) => {
    try {
        req.body.ownerId = req.user.id; // from auth middleware
        const restaurant = await Restaurant.create(req.body);
        res.status(201).json({ success: true, data: restaurant });
    } catch (error) {
        next(error);
    }
};

exports.getRestaurants = async (req, res, next) => {
    try {
        const query = req.user.restaurantId ? { _id: req.user.restaurantId } : {};
        const restaurants = await Restaurant.find(query);
        res.status(200).json({ success: true, count: restaurants.length, data: restaurants });
    } catch (error) {
        next(error);
    }
};

exports.createBranch = async (req, res, next) => {
    try {
        req.body.restaurantId = req.params.restaurantId;
        const branch = await Branch.create(req.body);
        res.status(201).json({ success: true, data: branch });
    } catch (error) {
        next(error);
    }
};

exports.getBranches = async (req, res, next) => {
    try {
        const query = { restaurantId: req.params.restaurantId };
        if (req.user.branchId) query._id = req.user.branchId; // Limit to their branch if applicable
        
        const branches = await Branch.find(query);
        res.status(200).json({ success: true, count: branches.length, data: branches });
    } catch (error) {
        next(error);
    }
};
