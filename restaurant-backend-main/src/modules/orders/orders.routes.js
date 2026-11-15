const express = require('express');
const { createOrder, getOrders, updateOrderStatus, createBill, getKotReceipt, getBillReceipt, getWhatsAppBill, getDailyDigest } = require('./orders.controller');
const { protect } = require('../../middlewares/auth.middleware');
const { authorize } = require('../../middlewares/rbac.middleware');
const { requireActiveSubscription } = require('../../middlewares/subscription.middleware');

const router = express.Router();

router.use(protect);
router.use(requireActiveSubscription);

router.get('/daily-digest', authorize('Super Admin', 'Restaurant Admin', 'Manager'), getDailyDigest);

router.route('/')
    .post(authorize('Super Admin', 'Restaurant Admin', 'Manager', 'Waiter', 'Cashier'), createOrder)
    .get(authorize('Super Admin', 'Restaurant Admin', 'Manager', 'Waiter', 'Kitchen', 'Cashier'), getOrders);

router.route('/:id/status')
    .patch(authorize('Super Admin', 'Restaurant Admin', 'Manager', 'Waiter', 'Kitchen'), updateOrderStatus);

router.route('/:id/bill')
    .post(authorize('Super Admin', 'Restaurant Admin', 'Manager', 'Cashier'), createBill);

router.get('/:id/kot-receipt', authorize('Super Admin', 'Restaurant Admin', 'Manager', 'Kitchen', 'Waiter'), getKotReceipt);
router.get('/:id/bill-receipt', authorize('Super Admin', 'Restaurant Admin', 'Manager', 'Cashier', 'Waiter'), getBillReceipt);
router.post('/:id/whatsapp-bill', authorize('Super Admin', 'Restaurant Admin', 'Manager', 'Cashier', 'Waiter'), getWhatsAppBill);

module.exports = router;