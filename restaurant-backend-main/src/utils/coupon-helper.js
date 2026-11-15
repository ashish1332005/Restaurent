const Coupon = require('../models/Coupon.model');

const validateAndCalculateCoupon = async ({ couponCode, restaurantId, branchId, subTotal }) => {
    const code = String(couponCode || '').trim().toUpperCase();
    if (!code) {
        return { discount: 0, coupon: null };
    }

    const now = new Date();
    const query = {
        restaurantId,
        code,
        isActive: true,
        startsAt: { $lte: now },
        expiresAt: { $gte: now }
    };
    if (branchId) {
        query.$or = [{ branchId: null }, { branchId }];
    }

    const coupon = await Coupon.findOne(query).select('+usedCount');
    if (!coupon) {
        const error = new Error('Invalid or expired coupon code');
        error.statusCode = 400;
        throw error;
    }

    if (coupon.usageLimit !== null && coupon.usedCount >= coupon.usageLimit) {
        const error = new Error('Coupon usage limit has been reached');
        error.statusCode = 400;
        throw error;
    }

    const orderAmount = Number(subTotal || 0);
    if (orderAmount < Number(coupon.minOrder || 0)) {
        const error = new Error(`Minimum order of ₹${coupon.minOrder} is required for coupon ${code}`);
        error.statusCode = 400;
        throw error;
    }

    let discount = 0;
    if (coupon.discountType === 'flat') {
        discount = Math.min(Number(coupon.discountValue || 0), orderAmount);
    } else if (coupon.discountType === 'percentage') {
        discount = (orderAmount * Number(coupon.discountValue || 0)) / 100;
        if (coupon.maxDiscount !== null && discount > Number(coupon.maxDiscount)) {
            discount = Number(coupon.maxDiscount);
        }
    }

    discount = Math.round(discount * 100) / 100;
    return { discount, coupon };
};

const recordCouponUsage = async (couponId, session) => {
    if (!couponId) return;
    const updateOptions = session ? { session } : {};
    await Coupon.findByIdAndUpdate(couponId, { $inc: { usedCount: 1 } }, updateOptions);
};

module.exports = {
    validateAndCalculateCoupon,
    recordCouponUsage
};
