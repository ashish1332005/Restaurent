const express = require('express');
const { createOrder, getOrders, updateOrderStatus, createBill } = require('./orders.controller');
const { protect } = require('../../middlewares/auth.middleware');
const { authorize } = require('../../middlewares/rbac.middleware');
const { requireActiveSubscription } = require('../../middlewares/subscription.middleware');

const router = express.Router();

router.use(protect);
router.use(requireActiveSubscription);

router.route('/')
    .post(authorize('Super Admin', 'Restaurant Admin', 'Manager', 'Waiter', 'Cashier'), createOrder)
    .get(authorize('Super Admin', 'Restaurant Admin', 'Manager', 'Waiter', 'Kitchen', 'Cashier'), getOrders);

router.route('/:id/status')
    .patch(authorize('Super Admin', 'Restaurant Admin', 'Manager', 'Waiter', 'Kitchen'), updateOrderStatus);

router.route('/:id/bill')
    .post(authorize('Super Admin', 'Restaurant Admin', 'Manager', 'Cashier'), createBill);

module.exports = router;