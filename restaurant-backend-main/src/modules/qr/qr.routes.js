const express = require('express');
const mongoose = require('mongoose');
const crypto = require('crypto');
const Table = require('../../models/Table.model');
const TableSession = require('../../models/TableSession.model');
const Branch = require('../../models/Branch.model');
const Restaurant = require('../../models/Restaurant.model');
const MenuItem = require('../../models/MenuItem.model');
const mongooseConnection = require('mongoose');
const Order = require('../../models/Order.model');
const ServiceRequest = require('../../models/ServiceRequest.model');
const OnlinePayment = require('../../models/OnlinePayment.model');
const Invoice = require('../../models/Invoice.model');
const socketService = require('../../services/socket.service');
const { hashTableQrToken } = require('../../utils/table-qr');
const { isMenuItemAvailableAt } = require('../../utils/menu-availability');

const router = express.Router();

const normalizeTableToken = (value) => String(value || '').trim();
const normalizePhone = (value) => String(value || '').replace(/\D/g, '').slice(-10);
const escapeRegExp = (value) => value.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
const toMoney = (value) => Math.round(Number(value || 0) * 100) / 100;
const createSessionToken = () => crypto.randomBytes(32).toString('base64url');
const hashSessionToken = (token) => crypto.createHash('sha256').update(token).digest('hex');

const findTableByToken = (tableToken) => Table.findOne({ qrTokenHash: hashTableQrToken(tableToken), qrTokenActive: true });

const emitOrderCreated = (order) => {
  try {
    const io = socketService.getIo();
    io.to(`branch_${order.branchId}`).emit('newOrder', order);
  } catch (_) {
    // Socket server is unavailable in tests/serverless contexts; order creation should still succeed.
  }
};

router.get('/table/:tableCode', async (req, res, next) => {
  try {
    const table = await findTableByToken(normalizeTableToken(req.params.tableCode)).lean();
    if (!table) {
      return res.status(404).json({ success: false, message: 'Table QR not found' });
    }

    const branch = await Branch.findById(table.branchId).lean();
    const restaurant = branch ? await Restaurant.findById(branch.restaurantId).lean() : null;
    const menu = await MenuItem.find({ branchId: table.branchId, isAvailable: true })
      .populate('categoryId', 'name nameHi')
      .sort({ displayOrder: 1, name: 1 })
      .lean();

    const availableMenu = menu.filter((item) =>
      isMenuItemAvailableAt(item, branch?.timezone)
    );
    const customerMenu = availableMenu.map((item) => ({
      ...item,
      imageUrl: item.imageUrl || item.image || ''
    }));
    res.json({ success: true, data: { table, branch, restaurant, menu: customerMenu } });
  } catch (error) {
    next(error);
  }
});

router.post('/table/:tableCode/order', async (req, res, next) => {
  try {
    const customerName = String(req.body.customerName || '').trim();
    const customerPhone = normalizePhone(req.body.customerPhone);
    if (customerName.length < 2 || customerName.length > 80) return res.status(400).json({ success: false, message: 'Please provide a valid customer name' });
    if (!/^\d{10}$/.test(customerPhone)) return res.status(400).json({ success: false, message: 'Please provide a valid 10-digit mobile number' });
    const table = await findTableByToken(normalizeTableToken(req.params.tableCode));
    if (!table) {
      return res.status(404).json({ success: false, message: 'Table QR not found' });
    }

    const branch = await Branch.findById(table.branchId).lean();
    const restaurant = branch ? await Restaurant.findById(branch.restaurantId).lean() : null;
    if (!restaurant || !restaurant.isActive || !['Trial', 'Active'].includes(restaurant.subscriptionStatus)) {
      return res.status(403).json({ success: false, message: 'This restaurant is not accepting QR orders' });
    }
    const latitude = Number(req.body.latitude);
    const longitude = Number(req.body.longitude);
    const hasRestaurantLocation = Number.isFinite(restaurant.geoLocation?.latitude) && Number.isFinite(restaurant.geoLocation?.longitude);
    if (hasRestaurantLocation && (!Number.isFinite(latitude) || !Number.isFinite(longitude))) {
      return res.status(400).json({ success: false, message: 'Location is required to place an order' });
    }
    if (hasRestaurantLocation) {
      const radians = (degrees) => degrees * Math.PI / 180;
      const deltaLat = radians(latitude - restaurant.geoLocation.latitude);
      const deltaLng = radians(longitude - restaurant.geoLocation.longitude);
      const a = Math.sin(deltaLat / 2) ** 2 + Math.cos(radians(restaurant.geoLocation.latitude)) * Math.cos(radians(latitude)) * Math.sin(deltaLng / 2) ** 2;
      const distance = 2 * 6371000 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
      if (distance > restaurant.orderRadiusMeters) return res.status(403).json({ success: false, message: 'You must be at the restaurant to place this order' });
    }

    const requestedItems = Array.isArray(req.body.items) ? req.body.items : [];
    if (requestedItems.length === 0) {
      return res.status(400).json({ success: false, message: 'Please add at least one item' });
    }

    const menuIds = requestedItems.map((item) => item.menuItem).filter(Boolean);
    if (menuIds.length !== requestedItems.length || menuIds.some((id) => !mongoose.Types.ObjectId.isValid(id))) {
      return res.status(400).json({ success: false, message: 'Invalid menu item in order' });
    }

    const menuItems = await MenuItem.find({
      _id: { $in: menuIds },
      branchId: table.branchId,
      isAvailable: true
    }).lean();
    const availableItems = menuItems.filter((item) =>
      isMenuItemAvailableAt(item, branch.timezone)
    );
    const menuById = new Map(availableItems.map((item) => [String(item._id), item]));

    if (menuById.size !== new Set(menuIds.map(String)).size) {
      return res.status(409).json({ success: false, message: 'Some menu items are currently outside their serving schedule or unavailable.' });
    }

    const now = new Date();
    let tableSession = await TableSession.findOne({ tableId: table._id, status: 'Active' }).select('+tokenHash');
    if (tableSession && tableSession.expiresAt <= now) {
      tableSession.status = 'Expired';
      await tableSession.save();
      tableSession = null;
    }
    if (tableSession && tableSession.customerPhone !== customerPhone) return res.status(409).json({ success: false, message: 'This table already has an active primary customer. Please contact them or a waiter.' });

    const suppliedSessionToken = String(req.get('x-table-session-token') || '').trim();
    if (tableSession && (!suppliedSessionToken || hashSessionToken(suppliedSessionToken) !== tableSession.tokenHash)) return res.status(401).json({ success: false, message: 'Primary customer session token is required for an additional order.' });
    let tableSessionToken = null;
    if (!tableSession) {
      if (table.status !== 'Available') return res.status(409).json({ success: false, message: 'This table is not available for a new customer session.' });
      tableSessionToken = createSessionToken();
      try {
        await TableSession.create({ tableId: table._id, branchId: table.branchId, customerName, customerPhone, tokenHash: hashSessionToken(tableSessionToken), expiresAt: new Date(now.getTime() + 4 * 60 * 60 * 1000) });
      } catch (sessionError) {
        if (sessionError && sessionError.code === 11000) return res.status(409).json({ success: false, message: 'This mobile number or table already has an active order session. Complete payment first.' });
        throw sessionError;
      }
    }

    const items = requestedItems.map((item) => {
      const menuItem = menuById.get(String(item.menuItem));
      const quantity = Math.max(1, Number.parseInt(item.quantity, 10) || 1);
      const selectedVariant = String(item.selectedVariant || '').trim();
      const variant = selectedVariant ? (menuItem.variants || []).find((entry) => entry.name === selectedVariant) : null;
      if (selectedVariant && !variant) { const error = new Error(`Invalid variant for ${menuItem.name}`); error.statusCode = 400; throw error; }
      const selectedAddOns = Array.isArray(item.selectedAddOns) ? item.selectedAddOns.map((value) => String(value).trim()).filter(Boolean) : [];
      const addOns = selectedAddOns.map((name) => (menuItem.modifiers || []).find((entry) => entry.name === name));
      if (addOns.some((entry) => !entry)) { const error = new Error(`Invalid add-on for ${menuItem.name}`); error.statusCode = 400; throw error; }
      const price = toMoney((variant ? variant.price : menuItem.basePrice) + addOns.reduce((sum, entry) => sum + Number(entry.price || 0), 0));
      return {
        menuItem: menuItem._id,
        quantity,
        price,
        selectedVariant,
        selectedAddOns,
        notes: item.notes || '',
      };
    });

    const calculatedSubTotal = toMoney(items.reduce((sum, item) => sum + item.price * item.quantity, 0));
    const tax = toMoney(items.reduce((sum, item) => sum + (item.price * item.quantity * Number(menuById.get(String(item.menuItem)).taxRate || 0) / 100), 0));
    const discount = 0;
    const total = toMoney(calculatedSubTotal + tax);

    const order = await Order.create({
      branchId: table.branchId,
      tableId: table._id,
      source: 'CustomerQR',
      customerName,
      customerPhone,
      orderType: 'Dine-In',
      items,
      subTotal: calculatedSubTotal,
      tax,
      discount,
      total,
      kitchenNotes: req.body.kitchenNotes || '',
      status: 'Pending',
      paymentStatus: 'Unpaid'
    });

    await Table.findByIdAndUpdate(table._id, { status: 'Occupied' });
    emitOrderCreated(order);

    res.status(201).json({ success: true, data: { order, tableSessionToken } });
  } catch (error) {
    next(error);
  }
});

router.get('/table/:tableCode/order', async (req, res, next) => {
  try {
    const table = await findTableByToken(normalizeTableToken(req.params.tableCode));
    if (!table) return res.status(404).json({ success: false, message: 'Table QR not found' });
    const token = String(req.get('x-table-session-token') || '').trim();
    const tableSession = await TableSession.findOne({ tableId: table._id, status: 'Active' }).select('+tokenHash');
    if (!tableSession || !token || hashSessionToken(token) !== tableSession.tokenHash) return res.status(401).json({ success: false, message: 'A valid primary customer session is required.' });
    if (tableSession.expiresAt <= new Date()) {
      tableSession.status = 'Expired';
      await tableSession.save();
      return res.status(401).json({ success: false, message: 'Customer session has expired.' });
    }
    const order = await Order.findOne({ tableId: table._id, customerPhone: tableSession.customerPhone })
      .populate('items.menuItem', 'name nameHi itemType thaliConfig imageUrl')
      .sort({ createdAt: -1 })
      .lean();
    if (!order) return res.status(404).json({ success: false, message: 'No order found for this session.' });
    res.json({ success: true, data: { order, session: { customerName: tableSession.customerName, customerPhone: tableSession.customerPhone, expiresAt: tableSession.expiresAt } } });
  } catch (error) {
    next(error);
  }
});
const requireCustomerSession = async (table, token) => {
  const session = await TableSession.findOne({ tableId: table._id, status: 'Active' }).select('+tokenHash');
  if (!session || !token || hashSessionToken(token) !== session.tokenHash || session.expiresAt <= new Date()) return null;
  return session;
};
const razorpayRequest = async (path, options = {}) => {
  if (process.env.RAZORPAY_ENABLED !== 'true' || !process.env.RAZORPAY_KEY_ID || !process.env.RAZORPAY_KEY_SECRET) {
    const error = new Error('Online payment is not configured for this restaurant app.'); error.statusCode = 503; throw error;
  }
  const auth = Buffer.from(`${process.env.RAZORPAY_KEY_ID}:${process.env.RAZORPAY_KEY_SECRET}`).toString('base64');
  const response = await fetch(`https://api.razorpay.com/v1${path}`, { ...options, headers: { Authorization: `Basic ${auth}`, 'Content-Type': 'application/json', ...(options.headers || {}) } });
  const body = await response.json().catch(() => ({}));
  if (!response.ok) { const error = new Error(body.error?.description || 'Payment gateway request failed.'); error.statusCode = 502; throw error; }
  return body;
};

router.post('/table/:tableCode/payment-link', async (req, res, next) => {
  try {
    const table = await findTableByToken(normalizeTableToken(req.params.tableCode));
    if (!table) return res.status(404).json({ success: false, message: 'Table QR not found' });
    const tableSession = await requireCustomerSession(table, String(req.get('x-table-session-token') || '').trim());
    if (!tableSession) return res.status(401).json({ success: false, message: 'A valid primary customer session is required.' });
    const order = await Order.findOne({ tableId: table._id, customerPhone: tableSession.customerPhone, paymentStatus: 'Unpaid' }).sort({ createdAt: -1 });
    if (!order || !['Served', 'Bill Requested'].includes(order.status)) return res.status(409).json({ success: false, message: 'Online payment is available after food is served.' });
    const existing = await OnlinePayment.findOne({ orderId: order._id, status: 'Created', expiresAt: { $gt: new Date() } });
    if (existing) return res.json({ success: true, data: { paymentId: existing._id, paymentUrl: existing.shortUrl, expiresAt: existing.expiresAt } });
    const expiresAt = new Date(Date.now() + 15 * 60 * 1000);
    const gateway = await razorpayRequest('/payment_links', { method: 'POST', body: JSON.stringify({ amount: Math.round(order.total * 100), currency: 'INR', accept_partial: false, expire_by: Math.floor(expiresAt.getTime() / 1000), reference_id: String(order._id), description: `Bill for ${table.name || 'restaurant table'}`, customer: { name: tableSession.customerName, contact: `+91${tableSession.customerPhone}` }, notify: { sms: false, email: false }, reminder_enable: false, notes: { orderId: String(order._id), tableId: String(table._id) } }) });
    const payment = await OnlinePayment.create({ orderId: order._id, tableSessionId: tableSession._id, providerLinkId: gateway.id, shortUrl: gateway.short_url, amount: order.total, expiresAt });
    order.status = 'Bill Requested'; await order.save();
    res.status(201).json({ success: true, data: { paymentId: payment._id, paymentUrl: payment.shortUrl, expiresAt } });
  } catch (error) { next(error); }
});

router.get('/table/:tableCode/payment/:paymentId/status', async (req, res, next) => {
  let dbSession;
  try {
    const table = await findTableByToken(normalizeTableToken(req.params.tableCode));
    if (!table) return res.status(404).json({ success: false, message: 'Table QR not found' });
    const tableSession = await requireCustomerSession(table, String(req.get('x-table-session-token') || '').trim());
    if (!tableSession) return res.status(401).json({ success: false, message: 'A valid primary customer session is required.' });
    const payment = await OnlinePayment.findOne({ _id: req.params.paymentId, tableSessionId: tableSession._id });
    if (!payment) return res.status(404).json({ success: false, message: 'Payment attempt not found.' });
    if (payment.status !== 'Paid') {
      const gateway = await razorpayRequest(`/payment_links/${payment.providerLinkId}`);
      if (gateway.status === 'paid') {
        dbSession = await mongooseConnection.startSession();
        await dbSession.withTransaction(async () => {
          const order = await Order.findOne({ _id: payment.orderId, paymentStatus: 'Unpaid' }).session(dbSession);
          if (order) {
            await Invoice.create([{ orderId: order._id, paymentMethod: gateway.payments?.[0]?.method === 'card' ? 'Card' : gateway.payments?.[0]?.method === 'wallet' ? 'Wallet' : 'UPI', transactionId: gateway.payments?.[0]?.payment_id || gateway.id, amount: order.total, status: 'Paid' }], { session: dbSession });
            order.paymentStatus = 'Paid'; order.status = 'Paid'; await order.save({ session: dbSession });
            await Table.findByIdAndUpdate(table._id, { status: 'Cleaning' }, { session: dbSession });
            await TableSession.updateMany({ tableId: table._id, status: 'Active' }, { status: 'Closed', closedAt: new Date() }, { session: dbSession });
          }
          payment.status = 'Paid'; payment.providerPaymentId = gateway.payments?.[0]?.payment_id || ''; payment.paidAt = new Date(); await payment.save({ session: dbSession });
        });
      } else if (['cancelled', 'expired'].includes(gateway.status)) { payment.status = gateway.status === 'expired' ? 'Expired' : 'Cancelled'; await payment.save(); }
    }
    res.json({ success: true, data: { status: payment.status, paidAt: payment.paidAt } });
  } catch (error) { next(error); } finally { if (dbSession) await dbSession.endSession(); }
});
module.exports = router;
router.post('/table/:tableCode/request', async (req, res, next) => {
  try {
    const table = await findTableByToken(normalizeTableToken(req.params.tableCode));
    if (!table) return res.status(404).json({ success: false, message: 'Table QR not found' });
    const token = String(req.get('x-table-session-token') || '').trim();
    const tableSession = await TableSession.findOne({ tableId: table._id, status: 'Active' }).select('+tokenHash');
    if (!tableSession || !token || hashSessionToken(token) !== tableSession.tokenHash) return res.status(401).json({ success: false, message: 'A valid primary customer session is required.' });
    if (tableSession.expiresAt <= new Date()) {
      tableSession.status = 'Expired';
      await tableSession.save();
      return res.status(401).json({ success: false, message: 'Customer session has expired.' });
    }
    const type = String(req.body.type || '').trim();
    if (!['Waiter', 'Water', 'Bill', 'Refill'].includes(type)) return res.status(400).json({ success: false, message: 'Invalid service request type.' });

    let requestedPaymentMethod = '';
    let refillDetails = {};
    if (type === 'Bill') {
      const order = await Order.findOne({ tableId: table._id, paymentStatus: 'Unpaid' }).sort({ createdAt: -1 });
      if (!order || !['Served', 'Bill Requested'].includes(order.status)) return res.status(409).json({ success: false, message: 'Bill can be requested after food is served.' });
      requestedPaymentMethod = String(req.body.paymentMethod || '').trim();
      if (requestedPaymentMethod && !['Cash', 'Card', 'UPI'].includes(requestedPaymentMethod)) return res.status(400).json({ success: false, message: 'Invalid payment method.' });
      order.status = 'Bill Requested';
      await order.save();
    }

    if (type === 'Refill') {
      const menuItemId = String(req.body.menuItemId || '').trim();
      const dishName = String(req.body.dishName || '').trim();
      if (!mongoose.Types.ObjectId.isValid(menuItemId) || !dishName) return res.status(400).json({ success: false, message: 'Valid thali and dish are required for a refill.' });
      const order = await Order.findOne({ tableId: table._id, customerPhone: tableSession.customerPhone, paymentStatus: 'Unpaid', status: 'Served', 'items.menuItem': menuItemId }).sort({ createdAt: -1 }).lean();
      if (!order) return res.status(409).json({ success: false, message: 'Refill is available after this thali is served.' });
      const menuItem = await MenuItem.findOne({ _id: menuItemId, branchId: table.branchId, itemType: 'Thali' }).lean();
      if (!menuItem) return res.status(404).json({ success: false, message: 'Thali is no longer available.' });
      const dish = (menuItem.thaliConfig?.includedItems || []).find((entry) => entry.name === dishName);
      if (!dish || !['Limited', 'Unlimited'].includes(dish.refillPolicy)) return res.status(400).json({ success: false, message: 'This dish does not include a refill.' });
      const openRequest = await ServiceRequest.findOne({ tableSessionId: tableSession._id, type: 'Refill', menuItemId: menuItem._id, dishName: dish.name, status: { $in: ['Open', 'Acknowledged'] } }).lean();
      if (openRequest) return res.status(409).json({ success: false, message: 'A refill request for this dish is already pending.' });
      const used = await ServiceRequest.countDocuments({ tableSessionId: tableSession._id, type: 'Refill', menuItemId: menuItem._id, dishName: dish.name });
      if (dish.refillPolicy === 'Limited' && used >= Number(dish.refillLimit || 0)) return res.status(409).json({ success: false, message: 'The included refill limit for this dish is complete.' });
      refillDetails = { menuItemId: menuItem._id, dishName: dish.name, dishNameHi: dish.nameHi || '', refillPolicy: dish.refillPolicy, refillLimit: dish.refillPolicy === 'Limited' ? dish.refillLimit : null, refillNumber: used + 1 };
    }

    const serviceRequest = await ServiceRequest.create({ branchId: table.branchId, tableId: table._id, tableSessionId: tableSession._id, type, customerName: tableSession.customerName, paymentMethod: requestedPaymentMethod || undefined, ...refillDetails });
    try {
      socketService.getIo().to(`branch_${table.branchId}`).emit('tableServiceRequested', { tableId: table._id, branchId: table.branchId, type, customerName: tableSession.customerName, paymentMethod: requestedPaymentMethod || null, ...refillDetails });
    } catch (_) {
      // The request remains valid even if sockets are unavailable.
    }
    res.status(201).json({ success: true, data: serviceRequest });
  } catch (error) {
    next(error);
  }
});