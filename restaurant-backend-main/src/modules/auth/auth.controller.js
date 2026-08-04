const User = require('../../models/User.model');
const Order = require('../../models/Order.model');
const CustomerProfile = require('../../models/CustomerProfile.model');
const Role = require('../../models/Role.model');
const Restaurant = require('../../models/Restaurant.model');
const Branch = require('../../models/Branch.model');
const https = require('https');
const crypto = require('crypto');

const CUSTOMER_ROLE_NAME = 'Customer';

const normalizeDigits = (value) => String(value || '').replace(/\D/g, '');
const normalizeEmail = (value) => String(value || '').trim().toLowerCase();

const mapUserResponse = (user, roleName) => ({
    _id: user._id,
    name: user.name,
    email: user.email || '',
    phone: user.phone || '',
    address: user.address || '',
    avatarUrl: user.avatarUrl || '',
    role: roleName,
    restaurantId: user.restaurantId,
    branchId: user.branchId
});

const resolveCustomerScope = async () => {
    const role = await Role.findOne({ name: CUSTOMER_ROLE_NAME });
    if (!role) {
        const error = new Error('Customer registration is not configured');
        error.statusCode = 503;
        throw error;
    }

    const restaurantQuery = process.env.DEFAULT_RESTAURANT_ID
        ? { _id: process.env.DEFAULT_RESTAURANT_ID, isActive: true }
        : { isActive: true };
    const restaurants = await Restaurant.find(restaurantQuery).limit(2);
    if (restaurants.length !== 1) {
        const error = new Error('Restaurant registration scope is not configured');
        error.statusCode = 503;
        throw error;
    }

    const restaurant = restaurants[0];
    const branchQuery = process.env.DEFAULT_BRANCH_ID
        ? {
            _id: process.env.DEFAULT_BRANCH_ID,
            restaurantId: restaurant._id,
            isActive: true
        }
        : { restaurantId: restaurant._id, isActive: true };
    const branch = await Branch.findOne(branchQuery);
    if (!branch) {
        const error = new Error('Restaurant branch is not configured');
        error.statusCode = 503;
        throw error;
    }

    return { role, restaurant, branch };
};

const fetchJson = (url, headers = {}) => new Promise((resolve, reject) => {
    const request = https.get(
        url,
        { headers },
        (response) => {
            let body = '';
            response.on('data', (chunk) => {
                body += chunk;
            });
            response.on('end', () => {
                try {
                    const payload = body ? JSON.parse(body) : {};
                    if ((response.statusCode || 500) >= 400) {
                        const message =
                            payload.error_description ||
                            payload.error ||
                            `Google request failed with status ${response.statusCode}`;
                        return reject(new Error(message));
                    }
                    return resolve(payload);
                } catch (error) {
                    return reject(error);
                }
            });
        }
    );

    request.on('error', reject);
});

const toBoolean = (value) => value === true || value === 'true';

const verifyGoogleCustomer = async ({ idToken, accessToken }) => {
    const googleClientId = String(process.env.GOOGLE_CLIENT_ID || '').trim();
    if (!googleClientId) {
        const error = new Error('Google Sign-In is not configured on the server');
        error.statusCode = 503;
        throw error;
    }
    let profile = null;
    let idTokenError = null;

    if (idToken) {
        try {
            const payload = await fetchJson(
                `https://oauth2.googleapis.com/tokeninfo?id_token=${encodeURIComponent(idToken)}`
            );
            if (payload.aud !== googleClientId) {
                throw new Error('Google client ID does not match this app');
            }
            profile = {
                googleId: payload.sub,
                email: normalizeEmail(payload.email),
                name: String(payload.name || '').trim(),
                avatarUrl: String(payload.picture || '').trim(),
                emailVerified: toBoolean(payload.email_verified)
            };
        } catch (error) {
            idTokenError = error;
        }
    }

    if (!profile && accessToken) {
        const payload = await fetchJson(
            'https://www.googleapis.com/oauth2/v3/userinfo',
            { Authorization: `Bearer ${accessToken}` }
        );
        profile = {
            googleId: payload.sub,
            email: normalizeEmail(payload.email),
            name: String(payload.name || '').trim(),
            avatarUrl: String(payload.picture || '').trim(),
            emailVerified:
                toBoolean(payload.email_verified) ||
                payload.verified_email === true
        };
    }

    if (!profile) {
        throw idTokenError || new Error('Unable to verify Google account');
    }
    if (!profile.email || !profile.googleId) {
        throw new Error('Google account did not return a valid email identity');
    }
    if (!profile.emailVerified) {
        throw new Error('Google account email is not verified');
    }

    return profile;
};

exports.registerCustomer = async (req, res, next) => {
    try {
        const name = String(req.body.name || '').trim();
        const password = String(req.body.password || '');
        const digits = normalizeDigits(req.body.phone);
        const phone = digits.length > 10 ? digits.slice(-10) : digits;
        if (name.length < 2 || name.length > 80) return res.status(400).json({ success: false, message: 'Please provide a valid name' });
        if (!/^\d{10}$/.test(phone)) return res.status(400).json({ success: false, message: 'Please provide a valid 10-digit mobile number' });
        if (password.length < 6 || password.length > 72) return res.status(400).json({ success: false, message: 'Password must be between 6 and 72 characters' });
        const existing = await User.findOne({ phone: { $in: [phone, `+91${phone}`] } });
        if (existing) return res.status(409).json({ success: false, message: 'An account already exists with this mobile number' });

        const { role, restaurant, branch } = await resolveCustomerScope();

        const user = await User.create({
            name,
            phone,
            password,
            role: role._id,
            restaurantId: restaurant._id,
            branchId: branch._id,
            status: 'Active'
        });
        const token = user.getSignedJwtToken();
        res.status(201).json({
            success: true,
            token,
            data: mapUserResponse(user, role.name)
        });
    } catch (error) {
        if (error?.code === 11000) return res.status(409).json({ success: false, message: 'An account already exists with this mobile number' });
        if (error?.statusCode) {
            return res.status(error.statusCode).json({ success: false, message: error.message });
        }
        next(error);
    }
};

// @desc    Login user
// @route   POST /api/v1/auth/login
// @access  Public
exports.login = async (req, res, next) => {
    try {
        const { phone, password } = req.body;

        if (!phone || !password) {
            return res.status(400).json({ success: false, message: 'Please provide mobile number and password' });
        }

        const digits = normalizeDigits(phone);
        if (digits.length < 10 || digits.length > 12) {
            return res.status(400).json({ success: false, message: 'Please provide a valid mobile number' });
        }
        const localNumber = digits.length > 10 ? digits.slice(-10) : digits;
        const user = await User.findOne({ phone: { $in: [String(phone).trim(), localNumber, `+91${localNumber}`] } })
            .select('+password')
            .populate('role');
        if (!user) {
            return res.status(401).json({ success: false, message: 'Invalid credentials' });
        }

        if (user.status !== 'Active') {
            return res.status(403).json({ success: false, message: 'Account is not active' });
        }

        const isMatch = await user.matchPassword(password);
        if (!isMatch) {
            return res.status(401).json({ success: false, message: 'Invalid credentials' });
        }

        const token = user.getSignedJwtToken();

        res.status(200).json({
            success: true,
            token,
            data: mapUserResponse(user, user.role.name)
        });
    } catch (error) {
        next(error);
    }
};

// @desc    Login or register customer via Google
// @route   POST /api/v1/auth/google/customer
// @access  Public
exports.googleCustomerAuth = async (req, res, next) => {
    try {
        const idToken = String(req.body.idToken || '').trim();
        const accessToken = String(req.body.accessToken || '').trim();
        if (!idToken && !accessToken) {
            return res.status(400).json({
                success: false,
                message: 'Google sign-in token is required'
            });
        }

        const verified = await verifyGoogleCustomer({ idToken, accessToken });
        const fallbackName = String(req.body.name || '').trim();
        const fallbackAvatar = String(req.body.photoUrl || '').trim();
        const fallbackEmail = normalizeEmail(req.body.email);
        const googleProfile = {
            googleId: verified.googleId,
            email: verified.email || fallbackEmail,
            name: verified.name || fallbackName || 'TasteHub Customer',
            avatarUrl: verified.avatarUrl || fallbackAvatar
        };

        if (!googleProfile.email) {
            return res.status(400).json({
                success: false,
                message: 'Google account email could not be resolved'
            });
        }

        let user = await User.findOne({
            $or: [{ googleId: googleProfile.googleId }, { email: googleProfile.email }]
        }).populate('role');

        if (user && user.role?.name !== CUSTOMER_ROLE_NAME) {
            return res.status(403).json({
                success: false,
                message: 'Google customer sign-in is only available for customer accounts'
            });
        }

        const { role, restaurant, branch } = await resolveCustomerScope();

        if (!user) {
            user = await User.create({
                name: googleProfile.name,
                email: googleProfile.email,
                avatarUrl: googleProfile.avatarUrl,
                googleId: googleProfile.googleId,
                authProvider: 'google',
                password: crypto.randomBytes(24).toString('hex'),
                role: role._id,
                restaurantId: restaurant._id,
                branchId: branch._id,
                status: 'Active'
            });
            user = await User.findById(user._id).populate('role');
        } else {
            user.name = googleProfile.name || user.name;
            user.email = googleProfile.email || user.email;
            user.avatarUrl = googleProfile.avatarUrl || user.avatarUrl || '';
            user.googleId = googleProfile.googleId;
            user.authProvider = 'google';
            user.role = user.role?._id || role._id;
            user.restaurantId = user.restaurantId || restaurant._id;
            user.branchId = user.branchId || branch._id;
            user.status = 'Active';
            await user.save();
            user = await User.findById(user._id).populate('role');
        }

        const token = user.getSignedJwtToken();
        return res.status(200).json({
            success: true,
            token,
            data: mapUserResponse(user, user.role?.name || CUSTOMER_ROLE_NAME)
        });
    } catch (error) {
        if (error?.statusCode) {
            return res.status(error.statusCode).json({
                success: false,
                message: error.message
            });
        }
        if (error?.code === 11000) {
            return res.status(409).json({
                success: false,
                message: 'A Google-linked customer account already exists'
            });
        }
        return res.status(401).json({
            success: false,
            message: error.message || 'Google sign-in failed'
        });
    }
};

// @desc    Get current logged in user
// @route   GET /api/v1/auth/me
// @access  Private
exports.getMe = async (req, res, next) => {
    try {
        const user = await User.findById(req.user.id).populate('role');
        const recentOrders = await Order.find({ userId: req.user.id })
            .sort({ createdAt: -1 })
            .limit(5)
            .lean();
        res.status(200).json({
            success: true,
            data: {
                ...user.toObject(),
                recentOrders
            }
        });
    } catch (error) {
        next(error);
    }
};

// @desc    Update current logged in user profile
// @route   PATCH /api/v1/auth/me
// @access  Private
exports.updateMe = async (req, res, next) => {
    try {
        const allowedFields = ['name', 'email', 'phone', 'address', 'avatarUrl', 'savedCards'];
        const updates = {};

        for (const field of allowedFields) {
            if (req.body[field] !== undefined) {
                updates[field] = req.body[field];
            }
        }

        if (updates.email !== undefined) {
            updates.email = normalizeEmail(updates.email) || undefined;
        }

        if (updates.phone !== undefined) {
            const digits = normalizeDigits(updates.phone);
            if (digits && !/^\d{10}$/.test(digits)) {
                return res.status(400).json({
                    success: false,
                    message: 'Please provide a valid 10-digit mobile number'
                });
            }
            updates.phone = digits || undefined;
        }

        const user = await User.findByIdAndUpdate(req.user.id, updates, {
            new: true,
            runValidators: true
        }).populate('role');

        res.status(200).json({
            success: true,
            data: user
        });
    } catch (error) {
        next(error);
    }
};

// @desc    Get demo profile
// @route   GET /api/v1/auth/demo-profile/:demoKey
// @access  Public (demo app flow)
exports.getDemoProfile = async (req, res, next) => {
    try {
        const demoKey = (req.params.demoKey || '').trim();
        if (!demoKey) {
            return res.status(400).json({
                success: false,
                message: 'Demo profile key is required'
            });
        }

        const profile = await CustomerProfile.findOne({ demoKey }).lean();

        res.status(200).json({
            success: true,
            data: profile || null
        });
    } catch (error) {
        next(error);
    }
};

// @desc    Create or update demo profile
// @route   PATCH /api/v1/auth/demo-profile/:demoKey
// @access  Public (demo app flow)
exports.updateDemoProfile = async (req, res, next) => {
    try {
        const demoKey = (req.params.demoKey || '').trim();
        if (!demoKey) {
            return res.status(400).json({
                success: false,
                message: 'Demo profile key is required'
            });
        }

        const allowedFields = ['name', 'email', 'phone', 'address', 'savedCards'];
        const updates = {};

        for (const field of allowedFields) {
            if (req.body[field] !== undefined) {
                updates[field] = req.body[field];
            }
        }

        if (!updates.name || !String(updates.name).trim()) {
            return res.status(400).json({
                success: false,
                message: 'Name is required'
            });
        }

        const profile = await CustomerProfile.findOneAndUpdate(
            { demoKey },
            { $set: updates, $setOnInsert: { demoKey } },
            {
                upsert: true,
                new: true,
                runValidators: true
            }
        ).lean();

        res.status(200).json({
            success: true,
            data: profile
        });
    } catch (error) {
        next(error);
    }
};
