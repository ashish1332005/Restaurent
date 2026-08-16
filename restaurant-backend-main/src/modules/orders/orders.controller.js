const mongoose = require('mongoose');
const Order = require('../../models/Order.model');
const Table = require('../../models/Table.model');
const MenuItem = require('../../models/MenuItem.model');
const Invoice = require('../../models/Invoice.model');
const TableSession = require('../../models/TableSession.model');
const Inventory = require('../../models/Inventory.model');
const InventoryMovement = require('../../models/InventoryMovement.model');
const socketService = require('../../services/socket.service');
const { assertBranchAccess, isSuperAdmin } = require('../../utils/access-scope');
const { recordPaidCustomerOrder } = require('../../services/customer-loyalty.service');

const getRequestedBranchId = (req) => req.body?.branchId || req.query?.branchId || req.user.branchId;
const staffRoles = new Set(['Super Admin', 'Restaurant Admin', 'Manager', 'Waiter', 'Cashier']);

const canChangeStatus = (roleName, from, to) => {
    if (roleName === 'Super Admin' || roleName === 'Restaurant Admin' || roleName === 'Manager') {
        return to !== 'Paid' && from !== 'Paid';
    }
    if (roleName === 'Kitchen') return (from === 'Pending' || from === 'Accepted') && to === 'Preparing' || from === 'Preparing' && to === 'Ready';
    if (roleName === 'Waiter') return from === 'Pending' && to === 'Accepted' || from === 'Ready' && to === 'Served' || from === 'Served' && to === 'Bill Requested';
    return false;
};

const startPreparingWithInventory = async (orderId, userId) => {
    const session = await mongoose.startSession();
    let preparedOrder;
    const lowStock = [];
    try {
        await session.withTransaction(async () => {
            const current = await Order.findById(orderId).session(session);
            if (!current) {
                const error = new Error('Order not found'); error.statusCode = 404; throw error;
            }
            if (current.inventoryConsumed) {
                current.status = 'Preparing';
                await current.save({ session });
                preparedOrder = current;
                return;
            }
            const itemQuantities = new Map();
            for (const line of current.items) {
                const id = String(line.menuItem);
                itemQuantities.set(id, (itemQuantities.get(id) || 0) + Number(line.quantity || 0));
            }
            const menuItems = await MenuItem.find({ _id: { $in: [...itemQuantities.keys()] }, branchId: current.branchId }).select('recipe').session(session).lean();
            const requirements = new Map();
            for (const menuItem of menuItems) {
                const servings = itemQuantities.get(String(menuItem._id)) || 0;
                for (const recipeLine of menuItem.recipe || []) {
                    const inventoryId = String(recipeLine.inventoryId);
                    const needed = Number(recipeLine.quantityPerServing) * servings;
                    requirements.set(inventoryId, Math.round(((requirements.get(inventoryId) || 0) + needed) * 10000) / 10000);
                }
            }
            if (requirements.size) {
                const inventory = await Inventory.find({ _id: { $in: [...requirements.keys()] }, branchId: current.branchId }).session(session);
                const byId = new Map(inventory.map((record) => [String(record._id), record]));
                for (const [inventoryId, needed] of requirements) {
                    const record = byId.get(inventoryId);
                    if (!record || record.quantity < needed) {
                        const error = new Error(`${record?.ingredientName || 'Recipe ingredient'} has insufficient stock`);
                        error.statusCode = 409;
                        throw error;
                    }
                }
                for (const [inventoryId, needed] of requirements) {
                    const record = byId.get(inventoryId);
                    record.quantity = Math.round((record.quantity - needed) * 10000) / 10000;
                    await record.save({ session });
                    if (record.quantity <= record.threshold) lowStock.push(record.toObject());
                    await InventoryMovement.create([{
                        branchId: current.branchId, inventoryId: record._id, ingredientName: record.ingredientName,
                        type: 'Order Consumption', quantityDelta: -needed, balanceAfter: record.quantity,
                        unit: record.unit, reason: `Automatic recipe consumption for order ${current._id}`,
                        orderId: current._id, createdBy: userId
                    }], { session });
                }
            }
            current.inventoryConsumed = true;
            current.status = 'Preparing';
            await current.save({ session });
            preparedOrder = current;
        });
        for (const record of lowStock) {
            try { socketService.getIo().to(`branch_${record.branchId}`).emit('inventoryAlert', record); } catch (_) {}
        }
        return preparedOrder;
    } finally {
        await session.endSession();
    }
};
exports.createOrder = async (req, res, next) => {
    try {
        const roleName = req.user.role?.name;
        if (!staffRoles.has(roleName)) return res.status(403).json({ success: false, message: 'Only authorized staff can create orders' });
        const branchId = getRequestedBranchId(req);
        await assertBranchAccess(req.user, branchId);
        const tableId = req.body.tableId || null;
        if (tableId) {
            const table = await Table.findById(tableId).select('branchId status');
            if (!table || String(table.branchId) !== String(branchId)) return res.status(400).json({ success: false, message: 'Invalid table for this branch' });
            if (table.status === 'Cleaning') return res.status(409).json({ success: false, message: 'Table is being cleaned' });
        }
        const requestedItems = Array.isArray(req.body.items) ? req.body.items : [];
        if (!requestedItems.length || requestedItems.length > 50) return res.status(400).json({ success: false, message: 'Add between 1 and 50 items' });
        const menuIds = requestedItems.map((item) => item.menuItem);
        if (menuIds.some((id) => !id)) return res.status(400).json({ success: false, message: 'Invalid menu item' });
        const menuItems = await MenuItem.find({ _id: { $in: menuIds }, branchId, isAvailable: true }).lean();
        const menuById = new Map(menuItems.map((item) => [String(item._id), item]));
        if (menuById.size !== new Set(menuIds.map(String)).size) return res.status(400).json({ success: false, message: 'Some menu items are unavailable' });
        let subTotal = 0;
        let itemDiscount = 0;
        let tax = 0;
        const items = requestedItems.map((requested) => {
            const menuItem = menuById.get(String(requested.menuItem));
            const quantity = Math.min(50, Math.max(1, Number.parseInt(requested.quantity, 10) || 1));
            const selectedVariant = String(requested.selectedVariant || '').trim();
            const variant = selectedVariant ? (menuItem.variants || []).find((entry) => entry.name === selectedVariant) : null;
            if (selectedVariant && !variant) { const error = new Error(`Invalid variant for ${menuItem.name}`); error.statusCode = 400; throw error; }
            const selectedAddOns = Array.isArray(requested.selectedAddOns) ? requested.selectedAddOns.map((name) => String(name).trim()).filter(Boolean) : [];
            const addOns = selectedAddOns.map((name) => (menuItem.modifiers || []).find((entry) => entry.name === name));
            if (addOns.some((entry) => !entry)) { const error = new Error(`Invalid add-on for ${menuItem.name}`); error.statusCode = 400; throw error; }
            const price = Math.round(((variant ? variant.price : menuItem.basePrice) + addOns.reduce((sum, entry) => sum + Number(entry.price || 0), 0)) * 100) / 100;
            const lineSubtotal = price * quantity;
            const lineDiscount = lineSubtotal * Math.max(0, Number(menuItem.discount || 0)) / 100;
            const lineTax = (lineSubtotal - lineDiscount) * Math.max(0, Number(menuItem.taxRate || 0)) / 100;
            subTotal += lineSubtotal;
            itemDiscount += lineDiscount;
            tax += lineTax;
            return { menuItem: menuItem._id, quantity, price, selectedVariant, selectedAddOns, notes: String(requested.notes || '').trim().slice(0, 300) };
        });
        const manualDiscount = Math.max(0, Number(req.body.manualDiscount || 0));
        const maxManualDiscount = Math.max(0, subTotal - itemDiscount + tax);
        if (manualDiscount > maxManualDiscount) return res.status(400).json({ success: false, message: 'Discount exceeds order total' });
        subTotal = Math.round(subTotal * 100) / 100;
        tax = Math.round(tax * 100) / 100;
        const discount = Math.round((itemDiscount + manualDiscount) * 100) / 100;
        const total = Math.round((subTotal + tax - discount) * 100) / 100;
        const sourceByRole = { 'Restaurant Admin': 'Admin', Manager: 'Admin', Waiter: 'Waiter', Cashier: 'Cashier', 'Super Admin': 'Admin' };
        const order = await Order.create({ branchId, tableId, userId: req.user.id, source: sourceByRole[roleName] || 'Waiter', customerName: String(req.body.customerName || '').trim().slice(0, 80), customerPhone: String(req.body.customerPhone || '').replace(/\D/g, '').slice(-10), orderType: tableId ? 'Dine-In' : 'Takeaway', items, subTotal, tax, discount, total, kitchenNotes: String(req.body.kitchenNotes || '').trim().slice(0, 500), paymentStatus: 'Unpaid', status: 'Pending' });
        if (order.tableId) await Table.findByIdAndUpdate(order.tableId, { status: 'Occupied' });
        const io = socketService.getIo();
        io.to(`branch_${order.branchId}`).emit('newOrder', order);
        res.status(201).json({ success: true, data: order });
    } catch (error) { next(error); }
};
exports.getOrders = async (req, res, next) => {
    try {
        const branchId = getRequestedBranchId(req);
        if (!branchId && !isSuperAdmin(req.user)) return res.status(400).json({ success: false, message: 'branchId is required' });
        if (branchId) await assertBranchAccess(req.user, branchId);
        const query = branchId ? { branchId } : {};
        if (req.query.status) query.status = req.query.status;
        const orders = await Order.find(query).populate('tableId', 'name').populate('userId', 'name role').populate('items.menuItem', 'name');
        res.status(200).json({ success: true, count: orders.length, data: orders });
    } catch (error) {
        next(error);
    }
};

exports.updateOrderStatus = async (req, res, next) => {
    try {
        let order = await Order.findById(req.params.id);
        if (!order) return res.status(404).json({ success: false, message: 'Order not found' });
        await assertBranchAccess(req.user, order.branchId);
        const nextStatus = req.body.status;
        if (!canChangeStatus(req.user.role?.name, order.status, nextStatus)) {
            return res.status(403).json({ success: false, message: `Cannot change order from ${order.status} to ${nextStatus}` });
        }
        const paidMealCompleted = nextStatus === 'Served' && order.paymentStatus === 'Paid';
        if (nextStatus === 'Preparing' && !order.inventoryConsumed) {
            order = await startPreparingWithInventory(order._id, req.user._id);
        } else {
            order.status = paidMealCompleted ? 'Paid' : nextStatus;
            await order.save();
        }
        if (paidMealCompleted && order.tableId) {
            await Table.findByIdAndUpdate(order.tableId, { status: 'Cleaning' });
            await TableSession.updateMany({ tableId: order.tableId, status: 'Active' }, { status: 'Closed', closedAt: new Date() });
        }
        const io = socketService.getIo();
        io.to(`branch_${order.branchId}`).emit('orderUpdated', order);
        if (nextStatus === 'Ready') io.to(`branch_${order.branchId}`).emit('orderReady', { orderId: order._id, tableId: order.tableId, status: order.status });
        res.status(200).json({ success: true, data: order });
    } catch (error) {
        next(error);
    }
};

exports.createBill = async (req, res, next) => {
    const allowedRoles = new Set(['Super Admin', 'Restaurant Admin', 'Manager', 'Cashier']);
    const validPaymentMethods = new Set(['Cash', 'Card', 'UPI', 'Wallet', 'Split']);
    let session;
    try {
        if (!allowedRoles.has(req.user.role?.name)) return res.status(403).json({ success: false, message: 'Only reception/cashier or admin can create bills' });
        const paymentMethod = String(req.body.paymentMethod || 'Cash');
        if (!validPaymentMethods.has(paymentMethod)) return res.status(400).json({ success: false, message: 'Invalid payment method' });
        const existingOrder = await Order.findById(req.params.id);
        if (!existingOrder) return res.status(404).json({ success: false, message: 'Order not found' });
        await assertBranchAccess(req.user, existingOrder.branchId);
        const servedForBilling = ['Served', 'Bill Requested'].includes(existingOrder.status);
        const posPrepayment = ['Admin', 'Cashier'].includes(existingOrder.source) && ['Pending', 'Accepted', 'Preparing', 'Ready'].includes(existingOrder.status);
        if (!servedForBilling && !posPrepayment) return res.status(409).json({ success: false, message: 'Order is not eligible for billing yet' });
        if (existingOrder.paymentStatus === 'Paid') return res.status(409).json({ success: false, message: 'Order is already paid' });
        let splitPayments = [];
        if (paymentMethod === 'Split') {
            splitPayments = Array.isArray(req.body.splitPayments) ? req.body.splitPayments.map((entry) => ({ paymentMethod: String(entry.paymentMethod || ''), amount: Math.round(Number(entry.amount || 0) * 100) / 100, transactionId: String(entry.transactionId || '').trim() })) : [];
            if (splitPayments.length < 2 || splitPayments.some((entry) => !['Cash', 'Card', 'UPI', 'Wallet'].includes(entry.paymentMethod) || entry.amount <= 0)) return res.status(400).json({ success: false, message: 'Provide at least two valid split payments' });
            const splitTotal = Math.round(splitPayments.reduce((sum, entry) => sum + entry.amount, 0) * 100) / 100;
            if (splitTotal !== Math.round(existingOrder.total * 100) / 100) return res.status(400).json({ success: false, message: 'Split payment total must match the bill total' });
        }

        session = await Order.startSession();
        let order;
        let invoice;
        await session.withTransaction(async () => {
            order = await Order.findOne({ _id: existingOrder._id, paymentStatus: 'Unpaid' }).session(session);
            if (!order) {
                const error = new Error('Order is already paid or unavailable');
                error.statusCode = 409;
                throw error;
            }
            invoice = await Invoice.create([{
                orderId: order._id,
                paymentMethod,
                transactionId: String(req.body.transactionId || '').trim(),
                splitPayments,
                amount: order.total,
                status: 'Paid',
                cashierId: req.user.id
            }], { session }).then((records) => records[0]);
            const mealComplete = ['Served', 'Bill Requested'].includes(order.status);
            order.paymentStatus = 'Paid';
            if (mealComplete) order.status = 'Paid';
            await order.save({ session });
            if (order.tableId && mealComplete) {
                await Table.findByIdAndUpdate(order.tableId, { status: 'Cleaning' }, { session });
                await TableSession.updateMany({ tableId: order.tableId, status: 'Active' }, { status: 'Closed', closedAt: new Date() }, { session });
            }
        });
        const io = socketService.getIo();
        io.to(`branch_${order.branchId}`).emit('billPaid', { order, invoice });
        res.status(201).json({ success: true, data: { order, invoice } });
    } catch (error) {
        if (error?.code === 11000 || error?.statusCode === 409) return res.status(409).json({ success: false, message: 'Order has already been billed' });
        next(error);
    } finally {
        if (session) await session.endSession();
    }
};


