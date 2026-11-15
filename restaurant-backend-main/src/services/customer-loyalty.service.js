const RestaurantCustomer = require('../models/RestaurantCustomer.model');
const MenuItem = require('../models/MenuItem.model');
const Branch = require('../models/Branch.model');

const normalizePhone = (value) => String(value || '').replace(/\D/g, '').slice(-10);

const recordPaidCustomerOrder = async (order, session) => {
    if (!order || !order.customerPhone) return null;
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

    const earnedPoints = Math.floor(Number(order.total || 0) * 0.05); // 5% cashback as loyalty points

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
            loyaltyPoints: earnedPoints,
            loyaltyPointsRedeemed: 0,
            itemStats: [...orderStats.values()]
        });
    } else {
        customer.name = String(order.customerName || customer.name).trim().slice(0, 80) || customer.name;
        customer.lastVisitAt = now;
        customer.lastBranchId = order.branchId;
        customer.paidOrderCount += 1;
        customer.totalSpending = Math.round((customer.totalSpending + order.total) * 100) / 100;
        customer.averageBill = Math.round((customer.totalSpending / customer.paidOrderCount) * 100) / 100;
        customer.loyaltyPoints = (customer.loyaltyPoints || 0) + earnedPoints;

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

const getCustomerLoyaltyInfo = async (restaurantId, phone) => {
    const cleanPhone = normalizePhone(phone);
    if (!/^\d{10}$/.test(cleanPhone)) return null;

    const customer = await RestaurantCustomer.findOne({ restaurantId, phone: cleanPhone }).lean();
    if (!customer) {
        return {
            isNewCustomer: true,
            phone: cleanPhone,
            loyaltyPoints: 0,
            visitCount: 0,
            favoriteDish: null
        };
    }

    return {
        isNewCustomer: false,
        name: customer.name,
        phone: customer.phone,
        loyaltyPoints: customer.loyaltyPoints || 0,
        visitCount: customer.paidOrderCount || 0,
        totalSpending: customer.totalSpending || 0,
        favoriteDish: customer.favoriteDish || null,
        favoriteDishQuantity: customer.favoriteDishQuantity || 0
    };
};

const redeemLoyaltyPoints = async ({ restaurantId, phone, pointsToRedeem, session }) => {
    const cleanPhone = normalizePhone(phone);
    const redeemAmount = Math.max(0, Math.floor(Number(pointsToRedeem || 0)));
    if (!redeemAmount) return 0;

    const customer = await RestaurantCustomer.findOne({ restaurantId, phone: cleanPhone }).session(session);
    if (!customer || !customer.loyaltyPoints || customer.loyaltyPoints <= 0) return 0;

    const actualRedeemed = Math.min(customer.loyaltyPoints, redeemAmount);
    customer.loyaltyPoints -= actualRedeemed;
    customer.loyaltyPointsRedeemed = (customer.loyaltyPointsRedeemed || 0) + actualRedeemed;
    await customer.save({ session });

    return actualRedeemed;
};

module.exports = {
    recordPaidCustomerOrder,
    getCustomerLoyaltyInfo,
    redeemLoyaltyPoints
};
