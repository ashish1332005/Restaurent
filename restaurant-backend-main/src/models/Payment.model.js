const mongoose = require('mongoose');

const paymentSchema = new mongoose.Schema({
    restaurantId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Restaurant',
        required: true,
        index: true
    },
    subscriptionId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Subscription',
        required: true
    },
    amount: {
        type: Number,
        required: true,
        min: 0
    },
    currency: {
        type: String,
        default: 'INR',
        trim: true
    },
    status: {
        type: String,
        enum: ['Created', 'Paid', 'Failed', 'Refunded'],
        default: 'Created',
        index: true
    },
    provider: {
        type: String,
        enum: ['Manual', 'Razorpay', 'Stripe'],
        default: 'Manual'
    },
    providerPaymentId: {
        type: String,
        trim: true,
        default: ''
    },
    paymentMethod: {
        type: String,
        enum: ['Cash', 'Card', 'UPI', 'Wallet', 'NetBanking', 'Manual'],
        default: 'Manual'
    },
    paidAt: {
        type: Date,
        default: null
    }
}, {
    timestamps: true
});

module.exports = mongoose.model('Payment', paymentSchema);