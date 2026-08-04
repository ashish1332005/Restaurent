const mongoose = require('mongoose');

const categorySchema = new mongoose.Schema({
    restaurantId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Restaurant',
        required: true
    },
    branchId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Branch',
        default: null // null if category is shared across all branches
    },
    name: {
        type: String,
        required: [true, 'Please add a category name']
    },
    image: {
        type: String,
        default: 'default-category.png'
    },
    order: {
        type: Number,
        default: 0
    },
    isActive: {
        type: Boolean,
        default: true
    }
}, {
    timestamps: true
});

module.exports = mongoose.model('Category', categorySchema);
