const socketIo = require('socket.io');

let io;

module.exports = {
    init: (server) => {
        io = socketIo(server, {
            cors: {
                origin: "*",
                methods: ["GET", "POST"]
            }
        });

        io.on('connection', (socket) => {
            console.log(`Socket connected: ${socket.id}`);
            
            // Join a specific room based on branchId for branch-level events
            socket.on('joinBranch', (branchId) => {
                socket.join(`branch_${branchId}`);
                console.log(`Socket ${socket.id} joined branch_${branchId}`);
            });

            socket.on('disconnect', () => {
                console.log(`Socket disconnected: ${socket.id}`);
            });
        });

        return io;
    },
    getIo: () => {
        if (!io) {
            throw new Error('Socket.io not initialized');
        }
        return io;
    }
};
