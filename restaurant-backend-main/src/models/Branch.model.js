const mongoose = require('mongoose');

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
    timezone: {
        type: String,
        default: 'UTC'
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
