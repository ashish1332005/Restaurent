const Order = require('../../models/Order.model');
const RestaurantCustomer = require('../../models/RestaurantCustomer.model');
const { assertBranchAccess, assertRestaurantAccess, isSuperAdmin } = require('../../utils/access-scope');

const toDate = (value, label) => {
    if (!value) return null;
    const date = new Date(value);
    if (Number.isNaN(date.getTime())) {
        const error = new Error(`Invalid ${label}`);
        error.statusCode = 400;
        throw error;
    }
    return date;
};

const getReportQuery = async (req) => {
    const branchId = req.query.branchId || req.user.branchId;
    if (!branchId && !isSuperAdmin(req.user)) {
        const error = new Error('branchId is required');
        error.statusCode = 400;
        throw error;
    }
    if (branchId) await assertBranchAccess(req.user, branchId);
    const query = { paymentStatus: 'Paid' };
    if (branchId) query.branchId = branchId;
    const startDate = toDate(req.query.startDate, 'startDate');
    const endDate = toDate(req.query.endDate, 'endDate');
    if (startDate && endDate && endDate < startDate) {
        const error = new Error('endDate must be after startDate');
        error.statusCode = 400;
        throw error;
    }
    if (startDate || endDate) query.createdAt = { ...(startDate ? { $gte: startDate } : {}), ...(endDate ? { $lte: endDate } : {}) };
    return query;
};

const parseLimit = (value, fallback = 10) => {
    const parsed = Number.parseInt(value, 10);
    return Number.isInteger(parsed) && parsed > 0 ? Math.min(parsed, 100) : fallback;
};

const maskPhone = (phone) => phone ? `******${String(phone).slice(-4)}` : '';

exports.getSalesOverview = async (req, res, next) => {
    try {
        const query = await getReportQuery(req);
        const [summary] = await Order.aggregate([{ $match: query }, { $group: { _id: null, totalSales: { $sum: '$total' }, totalOrders: { $sum: 1 }, averageOrderValue: { $avg: '$total' } } }]);
        res.status(200).json({ success: true, data: summary ? { totalSales: summary.totalSales, totalOrders: summary.totalOrders, averageOrderValue: Math.round(summary.averageOrderValue * 100) / 100 } : { totalSales: 0, totalOrders: 0, averageOrderValue: 0 } });
    } catch (error) {
        next(error);
    }
};

exports.getMenuPerformance = async (req, res, next) => {
    try {
        const query = await getReportQuery(req);
        const limit = parseLimit(req.query.limit);
        const rows = await Order.aggregate([
            { $match: query },
            { $unwind: '$items' },
            { $group: { _id: '$items.menuItem', quantitySold: { $sum: '$items.quantity' }, revenue: { $sum: { $multiply: ['$items.quantity', '$items.price'] } }, orderCount: { $sum: 1 } } },
            { $lookup: { from: 'menuitems', localField: '_id', foreignField: '_id', as: 'menuItem' } },
            { $unwind: { path: '$menuItem', preserveNullAndEmptyArrays: true } },
            { $project: { _id: 0, menuItemId: '$_id', name: { $ifNull: ['$menuItem.name', 'Deleted menu item'] }, quantitySold: 1, revenue: { $round: ['$revenue', 2] }, orderCount: 1 } },
            { $facet: { bestSelling: [{ $sort: { quantitySold: -1, revenue: -1 } }, { $limit: limit }], lowSelling: [{ $sort: { quantitySold: 1, revenue: 1 } }, { $limit: limit }] } }
        ]);
        res.status(200).json({ success: true, data: rows[0] || { bestSelling: [], lowSelling: [] } });
    } catch (error) {
        next(error);
    }
};

exports.getCustomerInsights = async (req, res, next) => {
    try {
        const query = await getReportQuery(req);
        const limit = parseLimit(req.query.limit, 25);
        const customerQuery = { ...query, customerPhone: { $ne: '' } };
        const [customers, favorites] = await Promise.all([
            Order.aggregate([
                { $match: customerQuery },
                { $group: { _id: '$customerPhone', name: { $last: '$customerName' }, visitCount: { $sum: 1 }, totalSpending: { $sum: '$total' }, averageBill: { $avg: '$total' }, lastVisit: { $max: '$createdAt' } } },
                { $sort: { visitCount: -1, totalSpending: -1 } },
                { $limit: limit }
            ]),
            Order.aggregate([
                { $match: customerQuery },
                { $unwind: '$items' },
                { $group: { _id: { phone: '$customerPhone', menuItem: '$items.menuItem' }, quantity: { $sum: '$items.quantity' } } },
                { $sort: { '_id.phone': 1, quantity: -1 } },
                { $group: { _id: '$_id.phone', menuItem: { $first: '$_id.menuItem' }, quantity: { $first: '$quantity' } } },
                { $lookup: { from: 'menuitems', localField: 'menuItem', foreignField: '_id', as: 'menuItemData' } },
                { $unwind: { path: '$menuItemData', preserveNullAndEmptyArrays: true } },
                { $project: { _id: 0, phone: '$_id', favoriteDish: { $ifNull: ['$menuItemData.name', 'Deleted menu item'] }, favoriteDishQuantity: '$quantity' } }
            ])
        ]);
        const favoriteByPhone = new Map(favorites.map((entry) => [entry.phone, entry]));
        const data = customers.map((customer) => ({ name: customer.name || 'Guest', phone: maskPhone(customer._id), visitCount: customer.visitCount, totalSpending: Math.round(customer.totalSpending * 100) / 100, averageBill: Math.round(customer.averageBill * 100) / 100, lastVisit: customer.lastVisit, favoriteDish: favoriteByPhone.get(customer._id)?.favoriteDish || null, favoriteDishQuantity: favoriteByPhone.get(customer._id)?.favoriteDishQuantity || 0 }));
        res.status(200).json({ success: true, data });
    } catch (error) {
        next(error);
    }
};
const escapeRegExp = (value) => value.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');

exports.getCustomerProfiles = async (req, res, next) => {
    try {
        const restaurantId = req.query.restaurantId || req.user.restaurantId;
        if (!restaurantId) return res.status(400).json({ success: false, message: 'restaurantId is required' });
        await assertRestaurantAccess(req.user, restaurantId);
        const query = { restaurantId };
        const branchId = req.query.branchId || (!isSuperAdmin(req.user) && req.user.role?.name !== 'Restaurant Admin' ? req.user.branchId : null);
        if (branchId) {
            await assertBranchAccess(req.user, branchId);
            query.lastBranchId = branchId;
        }
        const segment = String(req.query.segment || '').trim().toLowerCase();
        if (segment === 'regular') query.paidOrderCount = { $gte: Math.max(1, Number.parseInt(req.query.minOrders, 10) || 3) };
        if (segment === 'high_spender') query.totalSpending = { $gte: Math.max(1, Number(req.query.minSpend) || 5000) };
        if (segment === 'inactive') {
            const inactiveDays = Math.min(3650, Math.max(1, Number.parseInt(req.query.inactiveDays, 10) || 30));
            query.lastVisitAt = { $lte: new Date(Date.now() - inactiveDays * 24 * 60 * 60 * 1000) };
        }
        if (segment && !['regular', 'high_spender', 'inactive'].includes(segment)) return res.status(400).json({ success: false, message: 'Invalid customer segment' });
        const search = String(req.query.search || '').trim().slice(0, 80);
        if (search) query.name = new RegExp(escapeRegExp(search), 'i');
        const page = Math.max(1, Number.parseInt(req.query.page, 10) || 1);
        const limit = parseLimit(req.query.limit, 25);
        const [total, customers] = await Promise.all([
            RestaurantCustomer.countDocuments(query),
            RestaurantCustomer.find(query).sort({ lastVisitAt: -1, totalSpending: -1 }).skip((page - 1) * limit).limit(limit).lean()
        ]);
        const data = customers.map((customer) => ({
            id: customer._id,
            name: customer.name,
            phone: maskPhone(customer.phone),
            paidOrderCount: customer.paidOrderCount,
            totalSpending: customer.totalSpending,
            averageBill: customer.averageBill,
            firstVisitAt: customer.firstVisitAt,
            lastVisitAt: customer.lastVisitAt,
            favoriteDish: customer.favoriteDish || null,
            favoriteDishQuantity: customer.favoriteDishQuantity || 0
        }));
        res.status(200).json({ success: true, count: data.length, pagination: { page, limit, total, totalPages: Math.ceil(total / limit) }, data });
    } catch (error) {
        next(error);
    }
};