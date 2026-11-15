const mongoose = require('mongoose');
const { isValidTimeZone } = require('../utils/menu-availability');

const branchSchema = new mongoose.Schema({
    restaurantId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Restaurant',
        required: true
    },
    name: {
        type: String,
        required: [true, 'Please add a branch name']
    },
    location: {
        address: String,
        city: String,
        state: String,
        zipcode: String,
        country: String
    },
    contact: {
        phone: String,
        email: String
    },
    gstNumber: {
        type: String,
        trim: true,
        default: ''
    },
    fssaiNumber: {
        type: String,
        trim: true,
        default: ''
    },
    invoiceHeader: {
        type: String,
        trim: true,
        default: ''
    },
    invoiceFooter: {
        type: String,
        trim: true,
        default: 'Thank you! Please visit again.'
    },
    upiId: {
        type: String,
        trim: true,
        default: ''
    },
    googleReviewUrl: {
        type: String,
        trim: true,
        default: ''
    },
    wifiPassword: {
        type: String,
        trim: true,
        default: ''
    },
    timezone: {
        type: String,
        trim: true,
        default: 'Asia/Kolkata',
        validate: {
            validator: isValidTimeZone,
            message: 'Invalid IANA timezone'
        }
    },
    isActive: {
        type: Boolean,
        default: true
    }
}, {
    timestamps: true
});

// Compound index to ensure branch names are unique within a restaurant
branchSchema.index({ restaurantId: 1, name: 1 }, { unique: true });

module.exports = mongoose.model('Branch', branchSchema);
