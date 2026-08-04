const mongoose = require('mongoose');

const inventorySchema = new mongoose.Schema({
    branchId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Branch',
        required: true
    },
    ingredientName: {
        type: String,
        required: true
    },
    quantity: {
        type: Number,
        required: true
    },
    unit: {
        type: String,
        required: true // e.g., 'kg', 'L', 'units'
    },
    threshold: {
        type: Number, // Low stock alert threshold
        default: 10
    }
}, {
    timestamps: true
});

module.exports = mongoose.model('Inventory', inventorySchema);
