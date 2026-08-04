const Order = require('../../models/Order.model');
const Table = require('../../models/Table.model');
const socketService = require('../../services/socket.service');

exports.createOrder = async (req, res, next) => {
    try {
        req.body.userId = req.user.id;
        req.body.branchId = req.user.branchId || req.body.branchId;

        const order = await Order.create(req.body);
        
        // If Dine-In, update table status to Occupied
        if (order.tableId) {
            await Table.findByIdAndUpdate(order.tableId, { status: 'Occupied' });
        }

        // Realtime integration
        const io = socketService.getIo();
        io.to(`branch_${order.branchId}`).emit('newOrder', order);

        res.status(201).json({ success: true, data: order });
    } catch (error) {
        next(error);
    }
};

exports.getOrders = async (req, res, next) => {
    try {
        const query = { branchId: req.user.branchId };
        if (req.user.role?.name === 'Customer') query.userId = req.user.id;
        if (req.query.status) query.status = req.query.status; // e.g., 'Pending' for Kitchen
        
        const orders = await Order.find(query)
            .populate('tableId', 'name')
            .populate('userId', 'name role')
            .populate('items.menuItem', 'name');
            
        res.status(200).json({ success: true, count: orders.length, data: orders });
    } catch (error) {
        next(error);
    }
};

exports.updateOrderStatus = async (req, res, next) => {
    try {
        const order = await Order.findByIdAndUpdate(req.params.id, { status: req.body.status }, {
            new: true,
            runValidators: true
        });

        const io = socketService.getIo();
        io.to(`branch_${order.branchId}`).emit('orderUpdated', order);

        res.status(200).json({ success: true, data: order });
    } catch (error) {
        next(error);
    }
};
