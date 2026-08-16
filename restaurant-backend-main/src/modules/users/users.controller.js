const User = require('../../models/User.model');
const Role = require('../../models/Role.model');
const { assertBranchAccess, isSuperAdmin } = require('../../utils/access-scope');

const getRequestedBranchId = (req) => req.body?.branchId || req.query?.branchId || req.user.branchId;

const getAssignableRole = async (actor, roleId) => {
    const role = await Role.findById(roleId).lean();
    if (!role) {
        const error = new Error('Role not found');
        error.statusCode = 400;
        throw error;
    }
    if (isSuperAdmin(actor)) return role;
    const prohibitedRoles = new Set(['Super Admin', 'Restaurant Admin', 'Customer']);
    if (prohibitedRoles.has(role.name) || (actor.role?.name === 'Manager' && role.name === 'Manager')) {
        const error = new Error('You cannot assign this role');
        error.statusCode = 403;
        throw error;
    }
    if (role.restaurantId && String(role.restaurantId) !== String(actor.restaurantId)) {
        const error = new Error('Role is outside your restaurant');
        error.statusCode = 403;
        throw error;
    }
    return role;
};

exports.getUsers = async (req, res, next) => {
    try {
        const branchId = getRequestedBranchId(req);
        if (branchId) await assertBranchAccess(req.user, branchId);
        const query = isSuperAdmin(req.user) ? {} : { restaurantId: req.user.restaurantId };
        if (branchId) query.branchId = branchId;
        const staffRoleIds = await Role.find({ name: { $ne: 'Customer' } }).distinct('_id');
        query.role = { $in: staffRoleIds };
        const users = await User.find(query).populate('role', 'name permissions').sort({ name: 1 });
        res.status(200).json({ success: true, count: users.length, data: users });
    } catch (error) {
        next(error);
    }
};

exports.createUser = async (req, res, next) => {
    try {
        const branchId = getRequestedBranchId(req);
        const branch = await assertBranchAccess(req.user, branchId);
        const role = await getAssignableRole(req.user, req.body.role);
        const restaurantId = isSuperAdmin(req.user) ? branch.restaurantId : req.user.restaurantId;
        const user = await User.create({
            name: req.body.name,
            phone: req.body.phone,
            email: req.body.email,
            password: req.body.password,
            role: role._id,
            restaurantId,
            branchId: branch._id,
            status: req.body.status || 'Active'
        });
        const safeUser = await User.findById(user._id).populate('role', 'name permissions');
        res.status(201).json({ success: true, data: safeUser });
    } catch (error) {
        next(error);
    }
};

exports.updateUser = async (req, res, next) => {
    try {
        const query = { _id: req.params.id };
        if (!isSuperAdmin(req.user)) query.restaurantId = req.user.restaurantId;
        if (req.user.branchId) query.branchId = req.user.branchId;
        const existing = await User.findOne(query).populate('role');
        if (!existing) return res.status(404).json({ success: false, message: 'Staff user not found' });

        if (String(existing._id) === String(req.user._id) && req.body.status !== undefined && req.body.status !== 'Active') return res.status(400).json({ success: false, message: 'You cannot deactivate your own account' });

        const updates = {};
        for (const field of ['name', 'phone', 'email', 'status']) {
            if (req.body[field] !== undefined) updates[field] = req.body[field];
        }
        if (req.body.branchId !== undefined) {
            const branch = await assertBranchAccess(req.user, req.body.branchId);
            updates.branchId = branch._id;
            updates.restaurantId = isSuperAdmin(req.user) ? branch.restaurantId : req.user.restaurantId;
        }
        if (req.body.role !== undefined) {
            const role = await getAssignableRole(req.user, req.body.role);
            updates.role = role._id;
        }
        const user = await User.findByIdAndUpdate(existing._id, updates, { new: true, runValidators: true }).populate('role', 'name');
        res.status(200).json({ success: true, data: user });
    } catch (error) {
        next(error);
    }
};
exports.getAssignableRoles = async (req, res, next) => {
    try {
        const prohibited = isSuperAdmin(req.user) ? ['Customer'] : req.user.role?.name === 'Manager' ? ['Super Admin', 'Restaurant Admin', 'Manager', 'Customer'] : ['Super Admin', 'Restaurant Admin', 'Customer'];
        const roles = await Role.find({ name: { $nin: prohibited }, $or: [{ restaurantId: null }, { restaurantId: req.user.restaurantId }] }).select('name permissions').sort({ name: 1 }).lean();
        res.status(200).json({ success: true, data: roles });
    } catch (error) { next(error); }
};
