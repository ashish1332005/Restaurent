const http = require('http');
const mongoose = require('mongoose');
const { validateEnv } = require('./src/config/env');
const { port } = validateEnv();
const app = require('./src/app');
const { connectDB } = require('./src/config/db');
const socketService = require('./src/services/socket.service');
const server = http.createServer(app);
socketService.init(server);
let shuttingDown = false;
const shutdown = (signal) => {
    if (shuttingDown) return;
    shuttingDown = true;
    console.log(`${signal} received. Closing server gracefully.`);
    server.close(async () => {
        try { await mongoose.disconnect(); } finally { process.exit(0); }
    });
    setTimeout(() => process.exit(1), 10000).unref();
};
connectDB().then(() => {
    server.listen(port, () => console.log(`Server running in ${process.env.NODE_ENV || 'development'} mode on port ${port}`));
}).catch((error) => {
    console.error(`Failed to start server: ${error.message}`);
    process.exit(1);
});
process.on('SIGTERM', () => shutdown('SIGTERM'));
process.on('SIGINT', () => shutdown('SIGINT'));
process.on('unhandledRejection', (error) => { console.error('Unhandled rejection:', error); shutdown('unhandledRejection'); });
process.on('uncaughtException', (error) => { console.error('Uncaught exception:', error); shutdown('uncaughtException'); });
