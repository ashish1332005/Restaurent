const mongoose = require('mongoose');

const restaurantSchema = new mongoose.Schema({
    name: {
        type: String,
        required: [true, 'Please add a restaurant name']
    },
    logo: {
        type: String,
        default: 'no-logo.png'
    },
    ownerId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
        default: null
    },
    subscriptionPlan: {
        type: String,
        enum: ['Basic', 'Pro', 'Premium', 'Enterprise'],
        default: 'Basic'
    },
    subscriptionStatus: {
        type: String,
        enum: ['Pending Payment', 'Trial', 'Active', 'Expired', 'Suspended', 'Cancelled'],
        default: 'Pending Payment'
    },
    subscriptionExpiresAt: {
        type: Date,
        default: null
    },
    orderRadiusMeters: {
        type: Number,
        default: 100,
        min: 10,
        max: 1000
    },
    geoLocation: {
        latitude: { type: Number, default: null },
        longitude: { type: Number, default: null }
    },
    menuBranding: {
        primaryColor: { type: String, default: '#FF4D0A' },
        secondaryColor: { type: String, default: '#16A34A' },
        accentColor: { type: String, default: '#F59E0B' },
        menuHeaderText: { type: String, default: 'Fresh food, made for your table' }
    },
    settings: {
        currency: { type: String, default: 'USD' },
        taxRate: { type: Number, default: 0 },
        theme: { type: String, default: 'light' }
    },
    isActive: {
        type: Boolean,
        default: false
    }
}, {
    timestamps: true
});

module.exports = mongoose.model('Restaurant', restaurantSchema);

