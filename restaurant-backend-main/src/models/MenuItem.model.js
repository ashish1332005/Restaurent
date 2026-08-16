const mongoose = require('mongoose');

const variantSchema = new mongoose.Schema({
    name: { type: String, required: true, trim: true, maxlength: 80 },
    nameHi: { type: String, trim: true, maxlength: 80 },
    price: { type: Number, required: true, min: 0 },
    sku: { type: String, trim: true, maxlength: 80 }
}, { _id: false });

const modifierSchema = new mongoose.Schema({
    name: { type: String, required: true, trim: true, maxlength: 80 },
    nameHi: { type: String, trim: true, maxlength: 80 },
    price: { type: Number, default: 0, min: 0 }
}, { _id: false });

const thaliItemSchema = new mongoose.Schema({
    name: { type: String, required: true, trim: true, maxlength: 100 },
    nameHi: { type: String, trim: true, maxlength: 100 },
    quantity: { type: Number, required: true, min: 0.01, max: 1000 },
    unit: { type: String, required: true, trim: true, maxlength: 30 },
    refillPolicy: { type: String, enum: ['None', 'Limited', 'Unlimited'], default: 'None' },
    refillLimit: { type: Number, min: 1, max: 100, default: null },
    extraServingPrice: { type: Number, min: 0, max: 100000, default: 0 },
    isRequired: { type: Boolean, default: true },
    replacementAllowed: { type: Boolean, default: false }
}, { _id: true });

const thaliConfigSchema = new mongoose.Schema({
    serviceType: { type: String, enum: ['Limited', 'Unlimited'], default: 'Limited' },
    dineInOnly: { type: Boolean, default: true },
    servingDurationMinutes: { type: Number, min: 10, max: 300, default: 60 },
    includedItems: { type: [thaliItemSchema], default: [] }
}, { _id: false });

const availabilityScheduleSchema = new mongoose.Schema({
    days: {
        type: [String],
        enum: ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'],
        default: []
    },
    startTime: { type: String, match: [/^([01]\d|2[0-3]):[0-5]\d$/, 'Invalid start time'] },
    endTime: { type: String, match: [/^([01]\d|2[0-3]):[0-5]\d$/, 'Invalid end time'] }
}, { _id: false });

const recipeIngredientSchema = new mongoose.Schema({
    inventoryId: { type: mongoose.Schema.Types.ObjectId, ref: 'Inventory', required: true },
    quantityPerServing: { type: Number, required: true, min: 0.0001 }
}, { _id: false });

const menuItemSchema = new mongoose.Schema({
    branchId: { type: mongoose.Schema.Types.ObjectId, ref: 'Branch', required: true },
    categoryId: { type: mongoose.Schema.Types.ObjectId, ref: 'Category', required: true },
    subCategoryId: { type: mongoose.Schema.Types.ObjectId, ref: 'Category' },
    itemType: {
        type: String,
        enum: ['Single Item', 'Combo', 'Thali', 'Buffet', 'Customizable Meal'],
        default: 'Single Item'
    },
    name: { type: String, required: [true, 'Menu item name is required'], trim: true, maxlength: 120 },
    nameHi: { type: String, trim: true, maxlength: 120 },
    description: { type: String, trim: true, maxlength: 1000 },
    descriptionHi: { type: String, trim: true, maxlength: 1000 },
    basePrice: { type: Number, required: true, min: 0, max: 1000000 },
    displayOrder: { type: Number, default: 0, min: 0, max: 1000000 },
    variants: [variantSchema],
    modifiers: [modifierSchema],
    image: String,
    imageUrl: { type: String, trim: true, maxlength: 1000 },
    isVeg: { type: Boolean, default: true },
    spiceLevel: {
        type: String,
        enum: ['None', 'Mild', 'Medium', 'Hot', 'Extra Hot'],
        default: 'None'
    },
    dietaryTags: {
        type: [String],
        enum: ['Vegan', 'Jain', 'Gluten-Free', 'Dairy-Free', 'Nut-Free', 'High-Protein'],
        default: []
    },
    allergens: {
        type: [String],
        enum: ['Milk', 'Nuts', 'Gluten', 'Soy', 'Egg', 'Sesame'],
        default: []
    },
    isAvailable: { type: Boolean, default: true },
    publishStatus: {
        type: String,
        enum: ['Draft', 'Published', 'Scheduled'],
        default: 'Published',
        index: true
    },
    publishAt: {
        type: Date,
        default: null,
        validate: {
            validator(value) {
                return this.publishStatus !== 'Scheduled' || value instanceof Date;
            },
            message: 'Scheduled menu items require a publish date'
        }
    },
    isFeatured: { type: Boolean, default: false },
    isPopular: { type: Boolean, default: false },
    preparationTime: { type: Number, min: 0, max: 1440 },
    thaliConfig: { type: thaliConfigSchema, default: undefined },
    availabilitySchedule: { type: availabilityScheduleSchema, default: undefined },
    recipe: [recipeIngredientSchema],
    nutritionalInfo: { calories: Number, protein: Number, carbs: Number, fat: Number },
    discount: { type: Number, default: 0, min: 0, max: 100 },
    taxRate: { type: Number, default: 5, min: 0, max: 100 }
}, { timestamps: true });

menuItemSchema.pre('validate', function validateMealConfiguration() {
    const reject = (path, message) => {
        const error = new mongoose.Error.ValidationError(this);
        error.addError(path, new mongoose.Error.ValidatorError({ message }));
        throw error;
    };
    const ensureUnique = (entries, path, label) => {
        const names = entries.map((entry) => String(entry.name || '').trim().toLowerCase());
        if (new Set(names).size !== names.length) reject(path, `${label} names must be unique`);
    };
    ensureUnique(this.variants || [], 'variants', 'Variant');
    ensureUnique(this.modifiers || [], 'modifiers', 'Add-on');
    const skus = (this.variants || [])
        .map((entry) => String(entry.sku || '').trim().toLowerCase())
        .filter(Boolean);
    if (new Set(skus).size !== skus.length) reject('variants', 'Variant SKUs must be unique');

    if (this.itemType !== 'Thali') return;
    if (!this.thaliConfig || this.thaliConfig.includedItems.length === 0) {
        reject('thaliConfig.includedItems', 'A thali must include at least one item');
    }
    for (const [index, item] of this.thaliConfig.includedItems.entries()) {
        if (item.refillPolicy === 'Limited' && !item.refillLimit) {
            reject(
                `thaliConfig.includedItems.${index}.refillLimit`,
                'Limited refill items require a refill limit'
            );
        }
        if (item.refillPolicy !== 'Limited') item.refillLimit = null;
    }
});module.exports = mongoose.model('MenuItem', menuItemSchema);