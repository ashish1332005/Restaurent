const Table = require('../../models/Table.model');
const TableSession = require('../../models/TableSession.model');
const { assertBranchAccess, isSuperAdmin } = require('../../utils/access-scope');
const { createTableQrToken } = require('../../utils/table-qr');

const getRequestedBranchId = (req) => req.body?.branchId || req.query?.branchId || req.user.branchId;

exports.createTable = async (req, res, next) => {
    try {
        const branchId = getRequestedBranchId(req);
        await assertBranchAccess(req.user, branchId);
        const qr = createTableQrToken();
        const table = await Table.create({
            branchId,
            name: req.body.name,
            capacity: req.body.capacity,
            positionX: req.body.positionX,
            positionY: req.body.positionY,
            width: req.body.width,
            height: req.body.height,
            shape: req.body.shape,
            qrTokenHash: qr.tokenHash,
            qrTokenCreatedAt: new Date(),
            qrTokenActive: true
        });
        res.status(201).json({ success: true, data: { ...table.toObject(), qrToken: qr.token } });
    } catch (error) {
        next(error);
    }
};

exports.getTables = async (req, res, next) => {
    try {
        const branchId = getRequestedBranchId(req);
        if (!branchId && !isSuperAdmin(req.user)) {
            return res.status(400).json({ success: false, message: 'branchId is required' });
        }
        if (branchId) await assertBranchAccess(req.user, branchId);
        const tables = await Table.find(branchId ? { branchId } : {});
        res.status(200).json({ success: true, count: tables.length, data: tables });
    } catch (error) {
        next(error);
    }
};

exports.updateTableStatus = async (req, res, next) => {
    try {
        const existing = await Table.findById(req.params.id).select('branchId');
        if (!existing) return res.status(404).json({ success: false, message: 'Table not found' });
        await assertBranchAccess(req.user, existing.branchId);
        const table = await Table.findByIdAndUpdate(req.params.id, { status: req.body.status }, { new: true, runValidators: true });
        const io = require('../../services/socket.service').getIo();
        io.to(`branch_${table.branchId}`).emit('tableStatusChanged', table);
        res.status(200).json({ success: true, data: table });
    } catch (error) {
        next(error);
    }
};
exports.rotateTableQr = async (req, res, next) => {
    try {
        const table = await Table.findById(req.params.id).select('+qrTokenHash branchId name');
        if (!table) return res.status(404).json({ success: false, message: 'Table not found' });
        await assertBranchAccess(req.user, table.branchId);
        const qr = createTableQrToken();
        table.qrTokenHash = qr.tokenHash;
        table.qrTokenCreatedAt = new Date();
        table.qrTokenActive = true;
        await table.save();
        res.status(200).json({ success: true, data: { tableId: table._id, tableName: table.name, qrToken: qr.token, rotatedAt: table.qrTokenCreatedAt } });
    } catch (error) {
        next(error);
    }
};
exports.setTableQrActive = async (req, res, next) => {
    try {
        if (typeof req.body.isActive !== 'boolean') return res.status(400).json({ success: false, message: 'isActive must be a boolean' });
        const table = await Table.findById(req.params.id).select('branchId name qrTokenActive');
        if (!table) return res.status(404).json({ success: false, message: 'Table not found' });
        await assertBranchAccess(req.user, table.branchId);
        table.qrTokenActive = req.body.isActive;
        await table.save();
        res.status(200).json({ success: true, data: { tableId: table._id, tableName: table.name, qrTokenActive: table.qrTokenActive } });
    } catch (error) {
        next(error);
    }
};
exports.updateTable = async (req, res, next) => {
    try {
        const table = await Table.findById(req.params.id);
        if (!table) return res.status(404).json({ success: false, message: 'Table not found' });
        await assertBranchAccess(req.user, table.branchId);
        const updates = {};
        for (const key of ['name', 'capacity', 'positionX', 'positionY', 'width', 'height', 'shape']) if (req.body[key] !== undefined) updates[key] = req.body[key];
        const updated = await Table.findByIdAndUpdate(table._id, updates, { new: true, runValidators: true });
        res.status(200).json({ success: true, data: updated });
    } catch (error) { next(error); }
};

exports.deleteTable = async (req, res, next) => {
    try {
        const table = await Table.findById(req.params.id);
        if (!table) return res.status(404).json({ success: false, message: 'Table not found' });
        await assertBranchAccess(req.user, table.branchId);
        if (table.status !== 'Available') return res.status(409).json({ success: false, message: 'Only an available table can be deleted' });
        if (await TableSession.exists({ tableId: table._id, status: 'Active' })) return res.status(409).json({ success: false, message: 'Close the active customer session before deleting this table' });
        await table.deleteOne();
        res.status(200).json({ success: true, message: 'Table deleted' });
    } catch (error) { next(error); }
};