const Inventory = require('../../models/Inventory.model');

exports.getInventory = async (req, res, next) => {
    try {
        const query = { branchId: req.user.branchId };
        const inventory = await Inventory.find(query);
        res.status(200).json({ success: true, count: inventory.length, data: inventory });
    } catch (error) {
        next(error);
    }
};

exports.updateStock = async (req, res, next) => {
    try {
        const { ingredientName, quantity, unit, threshold } = req.body;
        const inventory = await Inventory.findOneAndUpdate(
            { branchId: req.user.branchId, ingredientName },
            { $inc: { quantity: quantity }, unit, threshold },
            { new: true, upsert: true, runValidators: true }
        );
        
        // Alert if below threshold
        if (inventory.quantity <= inventory.threshold) {
            const io = require('../../services/socket.service').getIo();
            io.to(`branch_${req.user.branchId}`).emit('inventoryAlert', inventory);
        }

        res.status(200).json({ success: true, data: inventory });
    } catch (error) {
        next(error);
    }
};
