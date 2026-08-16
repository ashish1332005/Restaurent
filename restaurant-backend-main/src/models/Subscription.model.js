const mongoose = require('mongoose');

const subscriptionSchema = new mongoose.Schema({
    restaurantId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Restaurant',
        required: true,
        index: true
    },
    plan: {
        type: String,
        enum: ['Basic', 'Pro', 'Premium', 'Enterprise'],
        required: true
    },
    status: {
        type: String,
        enum: ['Pending Payment', 'Trial', 'Active', 'Expired', 'Suspended', 'Cancelled'],
        default: 'Pending Payment',
        index: true
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
    startsAt: {
        type: Date,
        default: null
    },
    expiresAt: {
        type: Date,
        default: null
    },
    provider: {
        type: String,
        enum: ['Manual', 'Razorpay', 'Stripe'],
        default: 'Manual'
    },
    providerSubscriptionId: {
        type: String,
        trim: true,
        default: ''
    }
}, {
    timestamps: true
});

module.exports = mongoose.model('Subscription', subscriptionSchema);