const mongoose = require('mongoose');

const invoiceSchema = new mongoose.Schema({
    orderId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Order',
        required: true,
        unique: true
    },
    paymentMethod: {
        type: String,
        enum: ['Cash', 'Card', 'UPI', 'Wallet', 'Split'],
        required: true
    },
    transactionId: String,
    splitPayments: [{
        paymentMethod: { type: String, enum: ['Cash', 'Card', 'UPI', 'Wallet'], required: true },
        amount: { type: Number, required: true, min: 0.01 },
        transactionId: { type: String, default: '' }
    }],
    amount: {
        type: Number,
        required: true
    },
    status: {
        type: String,
        enum: ['Paid', 'Refunded', 'Failed'],
        default: 'Paid'
    },
    cashierId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User'
    }
}, {
    timestamps: true
});

module.exports = mongoose.model('Invoice', invoiceSchema);