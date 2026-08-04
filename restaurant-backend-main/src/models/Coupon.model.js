const mongoose = require('mongoose');

const couponSchema = new mongoose.Schema({
    restaurantId: { type: mongoose.Schema.Types.ObjectId, ref: 'Restaurant', required: true, index: true },
    branchId: { type: mongoose.Schema.Types.ObjectId, ref: 'Branch', default: null, index: true },
    code: { type: String, required: true, trim: true, uppercase: true, minlength: 3, maxlength: 24 },
    description: { type: String, required: true, trim: true, maxlength: 180 },
    discountType: { type: String, enum: ['flat', 'percentage'], required: true },
    discountValue: { type: Number, required: true, min: 1 },
    maxDiscount: { type: Number, default: null, min: 1 },
    minOrder: { type: Number, default: 0, min: 0 },
    usageLimit: { type: Number, default: null, min: 1 },
    usedCount: { type: Number, default: 0, min: 0, select: false },
    startsAt: { type: Date, required: true },
    expiresAt: { type: Date, required: true, index: true },
    isActive: { type: Boolean, default: true, index: true },
    createdBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true, select: false }
}, { timestamps: true });

couponSchema.index({ restaurantId: 1, code: 1 }, { unique: true });

module.exports = mongoose.model('Coupon', couponSchema);
