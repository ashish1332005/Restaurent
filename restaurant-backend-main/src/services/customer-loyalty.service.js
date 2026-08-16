const RestaurantCustomer = require('../models/RestaurantCustomer.model');
const MenuItem = require('../models/MenuItem.model');
const Branch = require('../models/Branch.model');

const normalizePhone = (value) => String(value || '').replace(/\D/g, '');

const recordPaidCustomerOrder = async (order, session) => {
    if (order.source !== 'CustomerQR') return null;
    const phone = normalizePhone(order.customerPhone);
    if (!/^\d{10}$/.test(phone)) return null;

    const branch = await Branch.findById(order.branchId).select('restaurantId').session(session).lean();
    if (!branch) return null;
    const restaurantId = branch.restaurantId;
    const itemIds = order.items.map((item) => item.menuItem);
    const menuItems = await MenuItem.find({ _id: { $in: itemIds } }).select('name').session(session).lean();
    const namesById = new Map(menuItems.map((item) => [String(item._id), item.name]));
    const orderStats = new Map();
    for (const item of order.items) {
        const key = String(item.menuItem);
        orderStats.set(key, { menuItemId: item.menuItem, name: namesById.get(key) || 'Menu item', quantity: (orderStats.get(key)?.quantity || 0) + item.quantity });
    }

    let customer = await RestaurantCustomer.findOne({ restaurantId, phone }).session(session);
    const now = order.createdAt || new Date();
    if (!customer) {
        customer = new RestaurantCustomer({
            restaurantId,
            phone,
            name: String(order.customerName || 'Guest').trim().slice(0, 80) || 'Guest',
            firstVisitAt: now,
            lastVisitAt: now,
            lastBranchId: order.branchId,
            paidOrderCount: 1,
            totalSpending: order.total,
            averageBill: order.total,
            itemStats: [...orderStats.values()]
        });
    } else {
        customer.name = String(order.customerName || customer.name).trim().slice(0, 80) || customer.name;
        customer.lastVisitAt = now;
        customer.lastBranchId = order.branchId;
        customer.paidOrderCount += 1;
        customer.totalSpending = Math.round((customer.totalSpending + order.total) * 100) / 100;
        customer.averageBill = Math.round((customer.totalSpending / customer.paidOrderCount) * 100) / 100;
        const statsById = new Map(customer.itemStats.map((item) => [String(item.menuItemId), item]));
        for (const stat of orderStats.values()) {
            const existing = statsById.get(String(stat.menuItemId));
            if (existing) {
                existing.quantity += stat.quantity;
                existing.name = stat.name;
            } else {
                customer.itemStats.push(stat);
            }
        }
    }
    const favorite = customer.itemStats.reduce((top, item) => !top || item.quantity > top.quantity ? item : top, null);
    customer.favoriteDish = favorite?.name || '';
    customer.favoriteDishQuantity = favorite?.quantity || 0;
    await customer.save({ session });
    return customer;
};

module.exports = { recordPaidCustomerOrder };