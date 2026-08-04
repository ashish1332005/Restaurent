const Category = require('../../models/Category.model');
const MenuItem = require('../../models/MenuItem.model');

// Categories
exports.createCategory = async (req, res, next) => {
    try {
        req.body.restaurantId = req.user.restaurantId;
        const category = await Category.create(req.body);
        res.status(201).json({ success: true, data: category });
    } catch (error) {
        next(error);
    }
};

exports.getCategories = async (req, res, next) => {
    try {
        const categories = await Category.find({ restaurantId: req.user.restaurantId });
        res.status(200).json({ success: true, data: categories });
    } catch (error) {
        next(error);
    }
};

// Menu Items
exports.createMenuItem = async (req, res, next) => {
    try {
        const menuItem = await MenuItem.create(req.body);
        res.status(201).json({ success: true, data: menuItem });
    } catch (error) {
        next(error);
    }
};

exports.getMenuItems = async (req, res, next) => {
    try {
        let query = {};
        if (req.query.branchId) query.branchId = req.query.branchId;
        if (req.query.categoryId) query.categoryId = req.query.categoryId;

        const menuItems = await MenuItem.find(query).populate('categoryId', 'name');
        res.status(200).json({ success: true, count: menuItems.length, data: menuItems });
    } catch (error) {
        next(error);
    }
};
