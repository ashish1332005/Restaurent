const mongoose = require('mongoose');

const savedCardSchema = new mongoose.Schema(
    {
        label: {
            type: String,
            trim: true,
            default: 'Saved Card'
        },
        brand: {
            type: String,
            trim: true,
            default: 'Card'
        },
        last4: {
            type: String,
            trim: true,
            default: ''
        },
        expiryMonth: {
            type: String,
            trim: true,
            default: ''
        },
        expiryYear: {
            type: String,
            trim: true,
            default: ''
        }
    },
    { _id: false }
);

const customerProfileSchema = new mongoose.Schema(
    {
        demoKey: {
            type: String,
            required: true,
            unique: true,
            index: true,
            trim: true
        },
        name: {
            type: String,
            required: true,
            trim: true
        },
        email: {
            type: String,
            default: '',
            trim: true
        },
        phone: {
            type: String,
            default: '',
            trim: true
        },
        address: {
            type: String,
            default: '',
            trim: true
        },
        savedCards: {
            type: [savedCardSchema],
            default: []
        }
    },
    {
        timestamps: true
    }
);

module.exports = mongoose.model('CustomerProfile', customerProfileSchema);
