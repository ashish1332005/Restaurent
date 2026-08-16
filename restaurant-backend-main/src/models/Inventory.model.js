const mongoose = require('mongoose');

const inventorySchema = new mongoose.Schema({
    branchId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Branch',
        required: true
    },
    ingredientName: {
        type: String,
        required: true,
        trim: true,
        minlength: 2,
        maxlength: 100
    },
    quantity: {
        type: Number,
        required: true,
        min: 0
    },
    unit: {
        type: String,
        required: true,
        trim: true,
        maxlength: 20
    },
    threshold: {
        type: Number,
        default: 10,
        min: 0
    }
}, {
    timestamps: true
});

inventorySchema.index({ branchId: 1, ingredientName: 1 }, { unique: true });

module.exports = mongoose.model('Inventory', inventorySchema);