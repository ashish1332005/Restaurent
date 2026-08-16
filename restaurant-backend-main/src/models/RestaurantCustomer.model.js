const mongoose = require('mongoose');

const dishStatSchema = new mongoose.Schema({
    menuItemId: { type: mongoose.Schema.Types.ObjectId, ref: 'MenuItem', required: true },
    name: { type: String, required: true, trim: true },
    quantity: { type: Number, required: true, min: 1 }
}, { _id: false });

const restaurantCustomerSchema = new mongoose.Schema({
    restaurantId: { type: mongoose.Schema.Types.ObjectId, ref: 'Restaurant', required: true, index: true },
    phone: { type: String, required: true, trim: true },
    name: { type: String, required: true, trim: true, maxlength: 80 },
    firstVisitAt: { type: Date, required: true },
    lastVisitAt: { type: Date, required: true, index: true },
    lastBranchId: { type: mongoose.Schema.Types.ObjectId, ref: 'Branch', default: null },
    paidOrderCount: { type: Number, default: 0, min: 0 },
    totalSpending: { type: Number, default: 0, min: 0 },
    averageBill: { type: Number, default: 0, min: 0 },
    itemStats: { type: [dishStatSchema], default: [] },
    favoriteDish: { type: String, default: '' },
    favoriteDishQuantity: { type: Number, default: 0, min: 0 }
}, { timestamps: true });

restaurantCustomerSchema.index({ restaurantId: 1, phone: 1 }, { unique: true });

module.exports = mongoose.model('RestaurantCustomer', restaurantCustomerSchema);