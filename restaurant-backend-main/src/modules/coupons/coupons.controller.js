const mongoose = require('mongoose');
const Coupon = require('../../models/Coupon.model');

const allowed = ['branchId', 'code', 'description', 'discountType', 'discountValue', 'maxDiscount', 'minOrder', 'usageLimit', 'startsAt', 'expiresAt', 'isActive'];
const cleanBody = body => Object.fromEntries(allowed.filter(key => body[key] !== undefined).map(key => [key, body[key]]));
const scope = user => ({ restaurantId: user.restaurantId, ...(user.branchId ? { $or: [{ branchId: null }, { branchId: user.branchId }] } : {}) });

exports.getAvailableCoupons = async (req, res, next) => {
    try {
        const now = new Date();
        const publicScope = {};
        if (req.query.restaurantId) {
            if (!mongoose.isValidObjectId(req.query.restaurantId)) return res.status(400).json({ success: false, message: 'Invalid restaurant id' });
            publicScope.restaurantId = req.query.restaurantId;
        }
        if (req.query.branchId) {
            if (!mongoose.isValidObjectId(req.query.branchId)) return res.status(400).json({ success: false, message: 'Invalid branch id' });
            publicScope.$or = [{ branchId: null }, { branchId: req.query.branchId }];
        }
        const coupons = await Coupon.find({
            ...publicScope, isActive: true, startsAt: { $lte: now }, expiresAt: { $gte: now },
            $expr: { $or: [{ $eq: ['$usageLimit', null] }, { $lt: ['$usedCount', '$usageLimit'] }] }
        }).select('code description discountType discountValue maxDiscount minOrder startsAt expiresAt').sort({ discountValue: -1 }).lean();
        res.json({ success: true, count: coupons.length, data: coupons });
    } catch (error) { next(error); }
};

exports.getAdminCoupons = async (req, res, next) => {
    try {
        const coupons = await Coupon.find(scope(req.user)).select('+usedCount').sort({ createdAt: -1 }).lean();
        res.json({ success: true, count: coupons.length, data: coupons });
    } catch (error) { next(error); }
};

exports.createCoupon = async (req, res, next) => {
    try {
        if (!req.user.restaurantId) return res.status(403).json({ success: false, message: 'Restaurant scope is required' });
        const data = cleanBody(req.body);
        if (new Date(data.expiresAt) <= new Date(data.startsAt)) return res.status(400).json({ success: false, message: 'Expiry must be after start date' });
        if (data.discountType === 'percentage' && data.discountValue > 100) return res.status(400).json({ success: false, message: 'Percentage cannot exceed 100' });
        data.restaurantId = req.user.restaurantId;
        data.createdBy = req.user.id;
        if (data.branchId && String(data.branchId) !== String(req.user.branchId) && req.user.role.name !== 'Restaurant Admin') return res.status(403).json({ success: false, message: 'Invalid branch scope' });
        const coupon = await Coupon.create(data);
        res.status(201).json({ success: true, data: coupon });
    } catch (error) { next(error); }
};

exports.updateCoupon = async (req, res, next) => {
    try {
        if (!mongoose.isValidObjectId(req.params.id)) return res.status(400).json({ success: false, message: 'Invalid coupon id' });
        const updates = cleanBody(req.body);
        if (req.user.role.name !== 'Restaurant Admin') delete updates.branchId;
        const coupon = await Coupon.findOneAndUpdate({ _id: req.params.id, ...scope(req.user) }, updates, { new: true, runValidators: true });
        if (!coupon) return res.status(404).json({ success: false, message: 'Coupon not found' });
        res.json({ success: true, data: coupon });
    } catch (error) { next(error); }
};

exports.deleteCoupon = async (req, res, next) => {
    try {
        if (!mongoose.isValidObjectId(req.params.id)) return res.status(400).json({ success: false, message: 'Invalid coupon id' });
        const coupon = await Coupon.findOneAndDelete({ _id: req.params.id, ...scope(req.user) });
        if (!coupon) return res.status(404).json({ success: false, message: 'Coupon not found' });
        res.json({ success: true, data: {} });
    } catch (error) { next(error); }
};
