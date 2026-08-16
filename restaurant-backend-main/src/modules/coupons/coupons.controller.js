const mongoose = require('mongoose');
const Coupon = require('../../models/Coupon.model');
const Branch = require('../../models/Branch.model');
const { assertBranchAccess, isSuperAdmin } = require('../../utils/access-scope');

const allowed = ['branchId', 'code', 'description', 'discountType', 'discountValue', 'maxDiscount', 'minOrder', 'usageLimit', 'startsAt', 'expiresAt', 'isActive'];
const cleanBody = (body) => Object.fromEntries(allowed.filter((key) => body[key] !== undefined).map((key) => [key, body[key]]));
const scope = (user) => {
    if (isSuperAdmin(user)) return {};
    const query = { restaurantId: user.restaurantId };
    if (user.branchId && user.role?.name !== 'Restaurant Admin') query.$or = [{ branchId: null }, { branchId: user.branchId }];
    return query;
};

const validateCouponData = (data) => {
    const code = String(data.code || '').trim().toUpperCase();
    const description = String(data.description || '').trim();
    const startsAt = new Date(data.startsAt);
    const expiresAt = new Date(data.expiresAt);
    const discountValue = Number(data.discountValue);
    const minOrder = Number(data.minOrder ?? 0);
    const maxDiscount = data.maxDiscount === null || data.maxDiscount === undefined ? null : Number(data.maxDiscount);
    const usageLimit = data.usageLimit === null || data.usageLimit === undefined ? null : Number(data.usageLimit);
    if (!/^[A-Z0-9_-]{3,24}$/.test(code)) return 'Coupon code must be 3-24 letters, numbers, hyphens or underscores';
    if (!description || description.length > 180) return 'Please provide a valid coupon description';
    if (!['flat', 'percentage'].includes(data.discountType)) return 'Invalid discount type';
    if (!Number.isFinite(discountValue) || discountValue <= 0) return 'Please provide a valid discount value';
    if (data.discountType === 'percentage' && discountValue > 100) return 'Percentage cannot exceed 100';
    if (!Number.isFinite(minOrder) || minOrder < 0) return 'Please provide a valid minimum order amount';
    if (maxDiscount !== null && (!Number.isFinite(maxDiscount) || maxDiscount <= 0)) return 'Please provide a valid maximum discount';
    if (usageLimit !== null && (!Number.isInteger(usageLimit) || usageLimit < 1)) return 'Please provide a valid usage limit';
    if (Number.isNaN(startsAt.getTime()) || Number.isNaN(expiresAt.getTime()) || expiresAt <= startsAt) return 'Expiry must be after start date';
    data.code = code;
    data.description = description;
    data.discountValue = discountValue;
    data.minOrder = minOrder;
    data.maxDiscount = maxDiscount;
    data.usageLimit = usageLimit;
    data.startsAt = startsAt;
    data.expiresAt = expiresAt;
    return null;
};

exports.getAvailableCoupons = async (req, res, next) => {
    try {
        if (!mongoose.isValidObjectId(req.query.restaurantId) || !mongoose.isValidObjectId(req.query.branchId)) return res.status(400).json({ success: false, message: 'restaurantId and branchId are required' });
        const branch = await Branch.findOne({ _id: req.query.branchId, restaurantId: req.query.restaurantId, isActive: true }).lean();
        if (!branch) return res.status(404).json({ success: false, message: 'Restaurant branch not found' });
        const now = new Date();
        const coupons = await Coupon.find({ restaurantId: req.query.restaurantId, $or: [{ branchId: null }, { branchId: branch._id }], isActive: true, startsAt: { $lte: now }, expiresAt: { $gte: now }, $expr: { $or: [{ $eq: ['$usageLimit', null] }, { $lt: ['$usedCount', '$usageLimit'] }] } }).select('code description discountType discountValue maxDiscount minOrder startsAt expiresAt').sort({ discountValue: -1 }).lean();
        res.json({ success: true, count: coupons.length, data: coupons });
    } catch (error) { next(error); }
};

exports.getAdminCoupons = async (req, res, next) => {
    try {
        const branchId = req.query.branchId || req.user.branchId;
        if (branchId) await assertBranchAccess(req.user, branchId);
        const query = scope(req.user);
        if (branchId) query.$or = [{ branchId: null }, { branchId }];
        const coupons = await Coupon.find(query).select('+usedCount').sort({ createdAt: -1 }).lean();
        res.json({ success: true, count: coupons.length, data: coupons });
    } catch (error) { next(error); }
};

exports.createCoupon = async (req, res, next) => {
    try {
        if (!req.user.restaurantId) return res.status(403).json({ success: false, message: 'Restaurant scope is required' });
        const data = cleanBody(req.body);
        if (req.user.role?.name !== 'Restaurant Admin') data.branchId = req.user.branchId;
        if (data.branchId) await assertBranchAccess(req.user, data.branchId);
        const validationError = validateCouponData(data);
        if (validationError) return res.status(400).json({ success: false, message: validationError });
        const coupon = await Coupon.create({ ...data, restaurantId: req.user.restaurantId, createdBy: req.user.id });
        res.status(201).json({ success: true, data: coupon });
    } catch (error) { next(error); }
};

exports.updateCoupon = async (req, res, next) => {
    try {
        if (!mongoose.isValidObjectId(req.params.id)) return res.status(400).json({ success: false, message: 'Invalid coupon id' });
        const coupon = await Coupon.findOne({ _id: req.params.id, ...scope(req.user) });
        if (!coupon) return res.status(404).json({ success: false, message: 'Coupon not found' });
        const updates = cleanBody(req.body);
        if (req.user.role?.name !== 'Restaurant Admin') delete updates.branchId;
        if (updates.branchId) await assertBranchAccess(req.user, updates.branchId);
        const candidate = { ...coupon.toObject(), ...updates };
        const validationError = validateCouponData(candidate);
        if (validationError) return res.status(400).json({ success: false, message: validationError });
        Object.assign(coupon, updates, { code: candidate.code, description: candidate.description, discountValue: candidate.discountValue, minOrder: candidate.minOrder, maxDiscount: candidate.maxDiscount, usageLimit: candidate.usageLimit, startsAt: candidate.startsAt, expiresAt: candidate.expiresAt });
        await coupon.save();
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