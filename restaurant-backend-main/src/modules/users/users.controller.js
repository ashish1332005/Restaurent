const User = require('../../models/User.model');
const Role = require('../../models/Role.model');

// @desc    Get all users (staff) for a branch/restaurant
// @route   GET /api/v1/users
exports.getUsers = async (req, res, next) => {
    try {
        let query = {};
        if (req.user.restaurantId) query.restaurantId = req.user.restaurantId;
        if (req.query.branchId) query.branchId = req.query.branchId;

        const users = await User.find(query).populate('role', 'name');
        res.status(200).json({ success: true, count: users.length, data: users });
    } catch (error) {
        next(error);
    }
};

// @desc    Create new user (staff)
// @route   POST /api/v1/users
exports.createUser = async (req, res, next) => {
    try {
        // Enforce assigning to the same restaurant as the admin
        if (req.user.restaurantId) {
            req.body.restaurantId = req.user.restaurantId;
        }
        
        const user = await User.create(req.body);
        res.status(201).json({ success: true, data: user });
    } catch (error) {
        next(error);
    }
};

// @desc    Update user
// @route   PUT /api/v1/users/:id
exports.updateUser = async (req, res, next) => {
    try {
        const user = await User.findByIdAndUpdate(req.params.id, req.body, {
            new: true,
            runValidators: true
        });
        res.status(200).json({ success: true, data: user });
    } catch (error) {
        next(error);
    }
};
