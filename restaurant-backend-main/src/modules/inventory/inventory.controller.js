const Inventory = require('../../models/Inventory.model');
const InventoryMovement = require('../../models/InventoryMovement.model');
const { assertBranchAccess, isSuperAdmin } = require('../../utils/access-scope');

const getRequestedBranchId = (req) => req.body?.branchId || req.query?.branchId || req.user.branchId;

const emitInventoryAlert = (branchId, inventory) => {
    try {
        const io = require('../../services/socket.service').getIo();
        io.to(`branch_${branchId}`).emit('inventoryAlert', inventory);
    } catch (_) {
        // Inventory persistence must not depend on the realtime server.
    }
};

exports.getInventory = async (req, res, next) => {
    try {
        const branchId = getRequestedBranchId(req);
        if (!branchId && !isSuperAdmin(req.user)) return res.status(400).json({ success: false, message: 'branchId is required' });
        if (branchId) await assertBranchAccess(req.user, branchId);
        const inventory = await Inventory.find(branchId ? { branchId } : {}).sort({ ingredientName: 1 });
        res.status(200).json({ success: true, count: inventory.length, data: inventory });
    } catch (error) {
        next(error);
    }
};

exports.updateStock = async (req, res, next) => {
    try {
        const branchId = getRequestedBranchId(req);
        await assertBranchAccess(req.user, branchId);
        const ingredientName = String(req.body.ingredientName || '').trim();
        const quantityDelta = Number(req.body.quantityDelta ?? req.body.quantity);
        const unit = req.body.unit === undefined ? undefined : String(req.body.unit).trim();
        const threshold = req.body.threshold === undefined ? undefined : Number(req.body.threshold);
        if (ingredientName.length < 2 || ingredientName.length > 100) return res.status(400).json({ success: false, message: 'Please provide a valid ingredient name' });
        if (!Number.isFinite(quantityDelta) || quantityDelta === 0 || Math.abs(quantityDelta) > 1000000) return res.status(400).json({ success: false, message: 'Please provide a valid stock adjustment' });
        if (unit !== undefined && (!unit || unit.length > 20)) return res.status(400).json({ success: false, message: 'Please provide a valid unit' });
        if (threshold !== undefined && (!Number.isFinite(threshold) || threshold < 0)) return res.status(400).json({ success: false, message: 'Please provide a valid threshold' });

        const existing = await Inventory.findOne({ branchId, ingredientName });
        if (!existing && quantityDelta < 0) return res.status(409).json({ success: false, message: 'Stock cannot go below zero' });
        if (!existing && !unit) return res.status(400).json({ success: false, message: 'unit is required for a new inventory item' });
        const requestedType = String(req.body.type || '').trim();
        const inferredType = quantityDelta > 0 ? (existing ? 'Purchase' : 'Opening') : 'Usage';
        const movementType = requestedType || inferredType;
        if (!['Opening', 'Purchase', 'Usage', 'Wastage', 'Correction'].includes(movementType)) return res.status(400).json({ success: false, message: 'Invalid inventory movement type' });
        if (['Purchase', 'Opening'].includes(movementType) && quantityDelta < 0) return res.status(400).json({ success: false, message: `${movementType} quantity must increase stock` });
        if (['Usage', 'Wastage'].includes(movementType) && quantityDelta > 0) return res.status(400).json({ success: false, message: `${movementType} quantity must reduce stock` });

        const set = {};
        if (unit !== undefined) set.unit = unit;
        if (threshold !== undefined) set.threshold = threshold;
        let inventory;
        if (quantityDelta < 0) {
            inventory = await Inventory.findOneAndUpdate({ branchId, ingredientName, quantity: { $gte: Math.abs(quantityDelta) } }, { $inc: { quantity: quantityDelta }, $set: set }, { new: true, runValidators: true });
            if (!inventory) return res.status(409).json({ success: false, message: 'Stock cannot go below zero' });
        } else {
            inventory = await Inventory.findOneAndUpdate({ branchId, ingredientName }, { $inc: { quantity: quantityDelta }, $set: set, $setOnInsert: { branchId, ingredientName, unit, threshold: threshold ?? 10 } }, { new: true, upsert: true, runValidators: true, setDefaultsOnInsert: true });
        }
        await InventoryMovement.create({ branchId, inventoryId: inventory._id, ingredientName: inventory.ingredientName, type: movementType, quantityDelta, balanceAfter: inventory.quantity, unit: inventory.unit, reason: String(req.body.reason || '').trim().slice(0, 250), createdBy: req.user._id });
        if (inventory.quantity <= inventory.threshold) emitInventoryAlert(branchId, inventory);
        res.status(200).json({ success: true, data: inventory });
    } catch (error) {
        next(error);
    }
};
exports.getMovements = async (req, res, next) => {
    try {
        const branchId = getRequestedBranchId(req);
        if (!branchId && !isSuperAdmin(req.user)) return res.status(400).json({ success: false, message: 'branchId is required' });
        if (branchId) await assertBranchAccess(req.user, branchId);
        const query = branchId ? { branchId } : {};
        if (req.query.inventoryId) query.inventoryId = req.query.inventoryId;
        const records = await InventoryMovement.find(query).populate('createdBy', 'name').sort({ createdAt: -1 }).limit(300).lean();
        res.status(200).json({ success: true, count: records.length, data: records });
    } catch (error) { next(error); }
};
