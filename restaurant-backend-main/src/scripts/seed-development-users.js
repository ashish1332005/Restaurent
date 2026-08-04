const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');
require('dotenv').config();

const Role = require('../models/Role.model');
const User = require('../models/User.model');
const Restaurant = require('../models/Restaurant.model');
const Branch = require('../models/Branch.model');

if (process.env.NODE_ENV === 'production') {
    throw new Error('Development seed is disabled in production.');
}

const defaultPassword = process.env.DEV_SEED_PASSWORD || 'TasteHub@123';
const mongoUri = process.env.MONGO_URI || 'mongodb://127.0.0.1:27017/restaurant_automation';

const accounts = [
    { name: 'TasteHub Admin', email: 'admin@tastehub.dev', phone: '9000000001', role: 'Restaurant Admin' },
    { name: 'TasteHub Customer', email: 'customer@tastehub.dev', phone: '9000000002', role: 'Customer' },
    { name: 'TasteHub Cashier', email: 'cashier@tastehub.dev', phone: '9000000003', role: 'Cashier' },
    { name: 'TasteHub Kitchen', email: 'kitchen@tastehub.dev', phone: '9000000004', role: 'Kitchen' },
    { name: 'TasteHub Waiter', email: 'waiter@tastehub.dev', phone: '9000000005', role: 'Waiter' },
];

async function ensureUser(account, role, restaurantId, branchId) {
    let user = await User.findOne({ $or: [{ phone: account.phone }, { email: account.email }] }).select('+password');
    if (!user) {
        user = await User.create({
            ...account,
            password: defaultPassword,
            role: role._id,
            restaurantId,
            branchId,
            status: 'Active',
        });
        return user;
    }

    user.name = account.name;
    user.role = role._id;
    user.restaurantId = restaurantId;
    user.branchId = branchId;
    user.status = 'Active';
    if (process.env.DEV_SEED_RESET_PASSWORDS === 'true') {
        user.password = await bcrypt.hash(defaultPassword, 12);
        await User.updateOne({ _id: user._id }, { $set: {
            name: user.name, role: user.role, restaurantId, branchId,
            status: user.status, password: user.password,
        } });
    } else {
        await User.updateOne({ _id: user._id }, { $set: {
            name: user.name, role: user.role, restaurantId, branchId, status: user.status,
        } });
    }
    return user;
}

async function seed() {
    await mongoose.connect(mongoUri);

    const roles = {};
    for (const name of [...new Set(accounts.map(account => account.role))]) {
        roles[name] = await Role.findOneAndUpdate(
            { name, restaurantId: null },
            { $setOnInsert: { name, restaurantId: null, isSystemRole: true, permissions: [] } },
            { upsert: true, returnDocument: 'after', runValidators: true },
        );
    }

    const adminAccount = accounts[0];
    let admin = await User.findOne({ phone: adminAccount.phone });
    if (!admin) {
        admin = await User.create({
            ...adminAccount,
            password: defaultPassword,
            role: roles['Restaurant Admin']._id,
            restaurantId: null,
            branchId: null,
            status: 'Active',
        });
    }

    let restaurant = await Restaurant.findOne({ name: 'TasteHub Development' });
    if (!restaurant) {
        restaurant = await Restaurant.create({
            name: 'TasteHub Development', ownerId: admin._id,
            subscriptionPlan: 'Enterprise', settings: { currency: 'INR', taxRate: 5 },
        });
    }

    let branch = await Branch.findOne({ restaurantId: restaurant._id, name: 'Main Branch' });
    if (!branch) {
        branch = await Branch.create({
            restaurantId: restaurant._id, name: 'Main Branch', timezone: 'Asia/Kolkata',
            location: { city: 'Development', country: 'India' },
        });
    }

    for (const account of accounts) {
        await ensureUser(account, roles[account.role], restaurant._id, branch._id);
    }

    console.log('\nTasteHub development accounts are ready:');
    for (const account of accounts) console.log(`${account.role.padEnd(18)} ${account.phone}`);
    console.log(`Password           ${process.env.DEV_SEED_PASSWORD ? '[DEV_SEED_PASSWORD]' : defaultPassword}`);
    console.log('\nSet DEV_SEED_RESET_PASSWORDS=true to reset existing seeded passwords.');
}

seed()
    .catch(error => { console.error(`Seed failed: ${error.message}`); process.exitCode = 1; })
    .finally(() => mongoose.disconnect());
