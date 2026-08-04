const express = require('express');
const mongoose = require('mongoose');
const Table = require('../../models/Table.model');
const Branch = require('../../models/Branch.model');
const Restaurant = require('../../models/Restaurant.model');
const MenuItem = require('../../models/MenuItem.model');
const Order = require('../../models/Order.model');
const socketService = require('../../services/socket.service');

const router = express.Router();

const normalizeTableCode = (value) => String(value || '').trim();
const escapeRegExp = (value) => value.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
const toMoney = (value) => Math.round(Number(value || 0) * 100) / 100;

const findTableByCode = (tableCode) => Table.findOne({
  name: new RegExp(`^${escapeRegExp(tableCode)}$`, 'i')
});

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
    const tableCode = normalizeTableCode(req.params.tableCode);
    const table = await findTableByCode(tableCode).lean();
    if (!table) {
      return res.status(404).json({ success: false, message: 'Table QR not found' });
    }

    const branch = await Branch.findById(table.branchId).lean();
    const restaurant = branch ? await Restaurant.findById(branch.restaurantId).lean() : null;
    const menu = await MenuItem.find({ branchId: table.branchId, isAvailable: true })
      .populate('categoryId', 'name')
      .sort({ isFeatured: -1, isPopular: -1, name: 1 })
      .lean();

    res.json({ success: true, data: { table, branch, restaurant, menu } });
  } catch (error) {
    next(error);
  }
});

router.post('/table/:tableCode/order', async (req, res, next) => {
  try {
    const tableCode = normalizeTableCode(req.params.tableCode);
    const table = await findTableByCode(tableCode);
    if (!table) {
      return res.status(404).json({ success: false, message: 'Table QR not found' });
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
    const menuById = new Map(menuItems.map((item) => [String(item._id), item]));

    if (menuById.size !== new Set(menuIds.map(String)).size) {
      return res.status(400).json({ success: false, message: 'Some menu items are unavailable for this table' });
    }

    const items = requestedItems.map((item) => {
      const menuItem = menuById.get(String(item.menuItem));
      const quantity = Math.max(1, Number.parseInt(item.quantity, 10) || 1);
      const price = toMoney(item.price ?? menuItem.basePrice);
      return {
        menuItem: menuItem._id,
        quantity,
        price,
        selectedVariant: item.selectedVariant || '',
        selectedAddOns: Array.isArray(item.selectedAddOns) ? item.selectedAddOns : [],
        notes: item.notes || '',
      };
    });

    const calculatedSubTotal = toMoney(items.reduce((sum, item) => sum + item.price * item.quantity, 0));
    const tax = toMoney(req.body.tax ?? 0);
    const discount = toMoney(req.body.discount ?? 0);
    const total = toMoney(req.body.total ?? calculatedSubTotal + tax - discount);

    const order = await Order.create({
      branchId: table.branchId,
      tableId: table._id,
      source: 'CustomerQR',
      customerName: req.body.customerName || `Table ${table.name} Customer`,
      customerPhone: req.body.customerPhone || '',
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

    res.status(201).json({ success: true, data: order });
  } catch (error) {
    next(error);
  }
});

module.exports = router;
