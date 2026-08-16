const mongoose = require('mongoose');
const Branch = require('../models/Branch.model');
const Restaurant = require('../models/Restaurant.model');

const isSuperAdmin = (user) => user?.role?.name === 'Super Admin';

const assertRestaurantAccess = async (user, restaurantId) => {
    if (!mongoose.isValidObjectId(restaurantId)) {
        const error = new Error('Invalid restaurant id');
        error.statusCode = 400;
        throw error;
    }
    const restaurant = await Restaurant.findById(restaurantId).lean();
    if (!restaurant) {
        const error = new Error('Restaurant not found');
        error.statusCode = 404;
        throw error;
    }
    if (!isSuperAdmin(user) && (!user?.restaurantId || String(user.restaurantId) !== String(restaurant._id))) {
        const error = new Error('Restaurant is outside your scope');
        error.statusCode = 403;
        throw error;
    }
    return restaurant;
};

const assertBranchAccess = async (user, branchId) => {
    if (!mongoose.isValidObjectId(branchId)) {
        const error = new Error('Invalid branch id');
        error.statusCode = 400;
        throw error;
    }
    const branch = await Branch.findById(branchId).select('restaurantId isActive').lean();
    if (!branch) {
        const error = new Error('Branch not found');
        error.statusCode = 404;
        throw error;
    }
    if (!isSuperAdmin(user)) {
        if (!user?.restaurantId || String(branch.restaurantId) !== String(user.restaurantId)) {
            const error = new Error('Branch is outside your restaurant');
            error.statusCode = 403;
            throw error;
        }
        if (user.branchId && user.role?.name !== 'Restaurant Admin' && String(branch._id) !== String(user.branchId)) {
            const error = new Error('Branch is outside your assigned scope');
            error.statusCode = 403;
            throw error;
        }
    }
    return branch;
};

module.exports = { assertBranchAccess, assertRestaurantAccess, isSuperAdmin };