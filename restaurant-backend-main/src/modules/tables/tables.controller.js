const Table = require('../../models/Table.model');

exports.createTable = async (req, res, next) => {
    try {
        const table = await Table.create(req.body);
        res.status(201).json({ success: true, data: table });
    } catch (error) {
        next(error);
    }
};

exports.getTables = async (req, res, next) => {
    try {
        let query = {};
        if (req.query.branchId) {
            query.branchId = req.query.branchId;
        } else if (req.user.branchId) {
            query.branchId = req.user.branchId;
        }

        const tables = await Table.find(query);
        res.status(200).json({ success: true, count: tables.length, data: tables });
    } catch (error) {
        next(error);
    }
};

exports.updateTableStatus = async (req, res, next) => {
    try {
        const table = await Table.findByIdAndUpdate(req.params.id, { status: req.body.status }, {
            new: true,
            runValidators: true
        });
        
        // Notify clients about table change
        const io = require('../../services/socket.service').getIo();
        io.to(`branch_${table.branchId}`).emit('tableStatusChanged', table);

        res.status(200).json({ success: true, data: table });
    } catch (error) {
        next(error);
    }
};
