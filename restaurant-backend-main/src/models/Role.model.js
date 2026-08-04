const mongoose = require('mongoose');

const roleSchema = new mongoose.Schema({
    name: {
        type: String,
        required: true,
        enum: ['Super Admin', 'Restaurant Admin', 'Manager', 'Cashier', 'Kitchen', 'Waiter', 'Customer']
    },
    permissions: [{
        type: String // e.g., 'read:orders', 'write:menu', 'manage:staff'
    }],
    isSystemRole: {
        type: Boolean,
        default: true
    },
    restaurantId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Restaurant',
        default: null // Null for system wide roles, specific ID for custom roles
    }
}, {
    timestamps: true
});

module.exports = mongoose.model('Role', roleSchema);
