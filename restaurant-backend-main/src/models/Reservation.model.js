const mongoose = require('mongoose');

const reservationSchema = new mongoose.Schema({
    branchId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Branch',
        required: true
    },
    userId: {
        type: mongoose.Schema.Types.ObjectId, // The customer who booked it
        ref: 'User',
        required: true
    },
    tableId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Table'
    },
    date: {
        type: Date,
        required: true
    },
    timeSlot: {
        type: String, // e.g., '19:00 - 21:00'
        required: true
    },
    guests: {
        type: Number,
        required: true
    },
    status: {
        type: String,
        enum: ['Pending', 'Confirmed', 'Completed', 'Cancelled'],
        default: 'Pending'
    },
    specialRequests: String
}, {
    timestamps: true
});

module.exports = mongoose.model('Reservation', reservationSchema);
