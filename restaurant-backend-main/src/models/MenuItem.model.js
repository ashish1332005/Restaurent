const mongoose = require('mongoose');

const variantSchema = new mongoose.Schema({
    name: { type: String, required: true }, // e.g., 'Small', 'Large'
    price: { type: Number, required: true },
    sku: String
});

const modifierSchema = new mongoose.Schema({
    name: { type: String, required: true }, // e.g., 'Extra Cheese', 'No Onion'
    price: { type: Number, default: 0 }
});

const menuItemSchema = new mongoose.Schema({
    branchId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Branch',
        required: true
    },
    categoryId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Category',
        required: true
    },
    subCategoryId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Category' // optional
    },
    name: {
        type: String,
        required: [true, 'Menu item name is required']
    },
    description: String,
    basePrice: {
        type: Number,
        required: true
    },
    variants: [variantSchema],
    modifiers: [modifierSchema],
    image: String,
    isVeg: { type: Boolean, default: true },
    isAvailable: { type: Boolean, default: true },
    isFeatured: { type: Boolean, default: false },
    isPopular: { type: Boolean, default: false },
    preparationTime: Number, // in minutes
    nutritionalInfo: {
        calories: Number,
        protein: Number,
        carbs: Number,
        fat: Number
    },
    discount: {
        type: Number,
        default: 0
    },
    taxRate: {
        type: Number, // e.g., 5, 12, 18
        default: 5
    }
}, {
    timestamps: true
});

module.exports = mongoose.model('MenuItem', menuItemSchema);
