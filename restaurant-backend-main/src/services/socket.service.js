const socketIo = require('socket.io');
const jwt = require('jsonwebtoken');
const mongoose = require('mongoose');
const User = require('../models/User.model');
const Branch = require('../models/Branch.model');

let io;

const allowedOrigins = (process.env.CORS_ORIGIN || '*').split(',').map((origin) => origin.trim()).filter(Boolean);
const isSuperAdmin = (user) => user?.role?.name === 'Super Admin';

const getToken = (socket) => {
    const authToken = socket.handshake.auth?.token;
    const header = socket.handshake.headers?.authorization;
    if (authToken) return String(authToken).replace(/^Bearer\s+/i, '');
    if (header) return String(header).replace(/^Bearer\s+/i, '');
    return null;
};

const canJoinBranch = async (user, branchId) => {
    if (!mongoose.isValidObjectId(branchId)) return false;
    if (isSuperAdmin(user)) return Boolean(await Branch.exists({ _id: branchId, isActive: true }));
    const branch = await Branch.findById(branchId).select('restaurantId isActive').lean();
    if (!branch || !branch.isActive || !user.restaurantId || String(branch.restaurantId) !== String(user.restaurantId)) return false;
    return !user.branchId || String(user.branchId) === String(branch._id);
};

module.exports = {
    init: (server) => {
        io = socketIo(server, {
            cors: {
                origin: allowedOrigins.includes('*') ? '*' : allowedOrigins,
                methods: ['GET', 'POST'],
                credentials: !allowedOrigins.includes('*')
            }
        });

        io.use(async (socket, next) => {
            try {
                const token = getToken(socket);
                const tableCode = socket.handshake.auth?.tableCode || socket.handshake.query?.tableCode;

                if (token) {
                    const decoded = jwt.verify(token, process.env.JWT_SECRET);
                    const user = await User.findById(decoded.id).populate('role');
                    if (user && user.status === 'Active' && user.role) {
                        socket.user = user;
                        return next();
                    }
                }

                if (tableCode) {
                    socket.isCustomer = true;
                    socket.tableCode = String(tableCode).trim();
                    return next();
                }

                return next(new Error('Authentication required'));
            } catch (_) {
                next(new Error('Authentication required'));
            }
        });

        io.on('connection', (socket) => {
            socket.on('joinBranch', async (branchId, callback) => {
                try {
                    if (!socket.user || !await canJoinBranch(socket.user, branchId)) {
                        const payload = { success: false, message: 'Branch access denied' };
                        if (typeof callback === 'function') callback(payload);
                        return socket.emit('socketError', payload);
                    }
                    const room = `branch_${branchId}`;
                    socket.join(room);
                    if (typeof callback === 'function') callback({ success: true, room });
                } catch (_) {
                    const payload = { success: false, message: 'Unable to join branch' };
                    if (typeof callback === 'function') callback(payload);
                    socket.emit('socketError', payload);
                }
            });

            socket.on('joinTable', async (data, callback) => {
                try {
                    const code = (typeof data === 'string' ? data : data?.tableCode) || socket.tableCode;
                    const Table = require('../models/Table.model');
                    const { hashTableQrToken } = require('../utils/table-qr');
                    const table = await Table.findOne({ qrTokenHash: hashTableQrToken(code), qrTokenActive: true }).lean();
                    if (!table) {
                        const payload = { success: false, message: 'Table not found' };
                        if (typeof callback === 'function') callback(payload);
                        return socket.emit('socketError', payload);
                    }
                    const room = `table_${table._id}`;
                    socket.join(room);
                    if (typeof callback === 'function') callback({ success: true, room, tableId: table._id });
                } catch (_) {
                    const payload = { success: false, message: 'Unable to join table' };
                    if (typeof callback === 'function') callback(payload);
                    socket.emit('socketError', payload);
                }
            });
        });

        return io;
    },
    getIo: () => {
        if (!io) throw new Error('Socket.io not initialized');
        return io;
    }
};