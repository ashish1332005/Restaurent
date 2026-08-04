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
        required: true
    },
    subscriptionPlan: {
        type: String,
        enum: ['Basic', 'Pro', 'Enterprise'],
        default: 'Basic'
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
        default: true
    }
}, {
    timestamps: true
});

module.exports = mongoose.model('Restaurant', restaurantSchema);

