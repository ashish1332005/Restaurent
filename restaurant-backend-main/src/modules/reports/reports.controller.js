const Order = require('../../models/Order.model');

exports.getSalesOverview = async (req, res, next) => {
    try {
        const { startDate, endDate } = req.query;
        let query = { branchId: req.user.branchId, status: 'Paid' };
        
        if (startDate && endDate) {
            query.createdAt = { $gte: new Date(startDate), $lte: new Date(endDate) };
        }

        const orders = await Order.find(query);
        const totalSales = orders.reduce((sum, order) => sum + order.total, 0);
        const totalOrders = orders.length;

        res.status(200).json({ success: true, data: { totalSales, totalOrders } });
    } catch (error) {
        next(error);
    }
};
