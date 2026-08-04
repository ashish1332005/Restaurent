const http = require('http');
const app = require('./src/app');
const { connectDB } = require('./src/config/db');
const socketService = require('./src/services/socket.service');

const PORT = process.env.PORT || 5000;

const server = http.createServer(app);

// Initialize Socket.io
socketService.init(server);

connectDB().then(() => {
    server.listen(PORT, () => {
        console.log(`Server running in ${process.env.NODE_ENV} mode on port ${PORT}`);
    });
}).catch((error) => {
    console.error(`Failed to connect to database: ${error.message}`);
    process.exit(1);
});
