const mongoose = require('mongoose');

const tableSchema = new mongoose.Schema({
    branchId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Branch',
        required: true
    },
    name: {
        type: String,
        required: [true, 'Please add a table name or number']
    },
    capacity: {
        type: Number,
        required: [true, 'Please specify table seating capacity']
    },
    status: {
        type: String,
        enum: ['Available', 'Occupied', 'Reserved', 'Cleaning'],
        default: 'Available'
    },
    qrCode: String,
    // Floor plan layout coordinates
    positionX: { type: Number, default: 0 },
    positionY: { type: Number, default: 0 },
    width: { type: Number, default: 100 },
    height: { type: Number, default: 100 },
    shape: {
        type: String,
        enum: ['Rectangle', 'Circle'],
        default: 'Rectangle'
    }
}, {
    timestamps: true
});

module.exports = mongoose.model('Table', tableSchema);
