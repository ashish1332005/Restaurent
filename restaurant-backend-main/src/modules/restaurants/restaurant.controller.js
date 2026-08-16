const Restaurant = require('../../models/Restaurant.model');
const Branch = require('../../models/Branch.model');
const { assertRestaurantAccess, isSuperAdmin } = require('../../utils/access-scope');

exports.createRestaurant = async (req, res, next) => {
    try {
        const restaurant = await Restaurant.create({
            name: req.body.name,
            logo: req.body.logo,
            ownerId: req.user.id,
            subscriptionPlan: req.body.subscriptionPlan,
            subscriptionStatus: req.body.subscriptionStatus,
            subscriptionExpiresAt: req.body.subscriptionExpiresAt,
            orderRadiusMeters: req.body.orderRadiusMeters,
            geoLocation: req.body.geoLocation,
            menuBranding: req.body.menuBranding,
            settings: req.body.settings,
            isActive: req.body.isActive
        });
        res.status(201).json({ success: true, data: restaurant });
    } catch (error) {
        next(error);
    }
};

exports.getRestaurants = async (req, res, next) => {
    try {
        const query = isSuperAdmin(req.user) ? {} : { _id: req.user.restaurantId };
        const restaurants = await Restaurant.find(query);
        res.status(200).json({ success: true, count: restaurants.length, data: restaurants });
    } catch (error) {
        next(error);
    }
};

exports.createBranch = async (req, res, next) => {
    try {
        const restaurant = await assertRestaurantAccess(req.user, req.params.restaurantId);
        const branch = await Branch.create({
            restaurantId: restaurant._id,
            name: req.body.name,
            location: req.body.location,
            contact: req.body.contact,
            timezone: req.body.timezone,
            isActive: req.body.isActive
        });
        res.status(201).json({ success: true, data: branch });
    } catch (error) {
        next(error);
    }
};

exports.getBranches = async (req, res, next) => {
    try {
        const restaurant = await assertRestaurantAccess(req.user, req.params.restaurantId);
        const query = { restaurantId: restaurant._id };
        const roleName = req.user.role?.name;
        if (req.user.branchId && !isSuperAdmin(req.user) && roleName !== 'Restaurant Admin') query._id = req.user.branchId;
        const branches = await Branch.find(query);
        res.status(200).json({ success: true, count: branches.length, data: branches });
    } catch (error) {
        next(error);
    }
};
exports.updateRestaurantSettings = async (req, res, next) => {
    try {
        const restaurant = await assertRestaurantAccess(req.user, req.params.restaurantId);
        const updates = {};
        if (req.body.name !== undefined) {
            const name = String(req.body.name).trim();
            if (name.length < 2 || name.length > 120) return res.status(400).json({ success:false, message:'Invalid restaurant name' });
            updates.name = name;
        }
        if (req.body.logo !== undefined) updates.logo = String(req.body.logo).trim().slice(0,500);
        if (req.body.orderRadiusMeters !== undefined) {
            const radius = Number(req.body.orderRadiusMeters);
            if (!Number.isFinite(radius) || radius < 10 || radius > 1000) return res.status(400).json({ success:false, message:'Order radius must be between 10 and 1000 metres' });
            updates.orderRadiusMeters = radius;
        }
        if (req.body.geoLocation !== undefined) {
            if (req.body.geoLocation?.latitude === null || req.body.geoLocation?.latitude === undefined || req.body.geoLocation?.longitude === null || req.body.geoLocation?.longitude === undefined) return res.status(400).json({ success:false, message:'Restaurant coordinates are required' });
            const latitude = Number(req.body.geoLocation.latitude), longitude = Number(req.body.geoLocation.longitude);
            if (!Number.isFinite(latitude) || latitude < -90 || latitude > 90 || !Number.isFinite(longitude) || longitude < -180 || longitude > 180) return res.status(400).json({ success:false, message:'Invalid restaurant coordinates' });
            updates.geoLocation = { latitude, longitude };
        }
        if (req.body.settings !== undefined) {
            const currency = String(req.body.settings?.currency || restaurant.settings?.currency || 'INR').trim().toUpperCase();
            const taxRate = Number(req.body.settings?.taxRate ?? restaurant.settings?.taxRate ?? 0);
            if (!/^[A-Z]{3}$/.test(currency) || !Number.isFinite(taxRate) || taxRate < 0 || taxRate > 100) return res.status(400).json({ success:false, message:'Invalid currency or tax rate' });
            updates.settings = { ...restaurant.settings?.toObject?.(), currency, taxRate, theme:'light' };
        }
        if (req.body.menuBranding !== undefined) {
            const color = /^#[0-9A-Fa-f]{6}$/;
            const branding = req.body.menuBranding || {};
            for (const key of ['primaryColor','secondaryColor','accentColor']) if (branding[key] !== undefined && !color.test(String(branding[key]))) return res.status(400).json({ success:false, message:`Invalid ${key}` });
            updates.menuBranding = { ...restaurant.menuBranding?.toObject?.(), ...branding, menuHeaderText:String(branding.menuHeaderText ?? restaurant.menuBranding?.menuHeaderText ?? '').trim().slice(0,120) };
        }
        const updated = await Restaurant.findByIdAndUpdate(restaurant._id, updates, { new:true, runValidators:true });
        res.json({ success:true, data:updated });
    } catch(error){ next(error); }
};

exports.updateBranchSettings = async (req, res, next) => {
    try {
        const branch = await assertBranchAccess(req.user, req.params.branchId);
        const updates = {};
        if (req.body.name !== undefined) { const name=String(req.body.name).trim(); if(name.length<2||name.length>120)return res.status(400).json({success:false,message:'Invalid branch name'}); updates.name=name; }
        if (req.body.location !== undefined) updates.location = { address:String(req.body.location?.address||'').trim().slice(0,200), city:String(req.body.location?.city||'').trim().slice(0,80), state:String(req.body.location?.state||'').trim().slice(0,80), zipcode:String(req.body.location?.zipcode||'').trim().slice(0,20), country:String(req.body.location?.country||'').trim().slice(0,80) };
        if (req.body.contact !== undefined) updates.contact = { phone:String(req.body.contact?.phone||'').replace(/[^0-9+]/g,'').slice(0,16), email:String(req.body.contact?.email||'').trim().toLowerCase().slice(0,120) };
        if (req.body.timezone !== undefined) { const timezone=String(req.body.timezone).trim(); try { Intl.DateTimeFormat('en-US',{timeZone:timezone}); } catch(_){ return res.status(400).json({success:false,message:'Invalid timezone'}); } updates.timezone=timezone; }
        const updated = await Branch.findByIdAndUpdate(branch._id, updates, { new:true, runValidators:true });
        res.json({ success:true, data:updated });
    } catch(error){ next(error); }
};

