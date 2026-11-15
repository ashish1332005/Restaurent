const express = require('express');
const { getMySubscription, createCheckout, verifySubscriptionRazorpay, verifyPaymentWebhook, approveManualPayment, activateSubscriptionOnline } = require('./payments.controller');
const { protect } = require('../../middlewares/auth.middleware');
const { authorize } = require('../../middlewares/rbac.middleware');

const router = express.Router();

router.post('/webhook', verifyPaymentWebhook);

router.use(protect);
router.get('/subscription', authorize('Restaurant Admin', 'Manager', 'Admin', 'Super Admin'), getMySubscription);
router.post('/checkout', authorize('Restaurant Admin', 'Manager', 'Admin', 'Super Admin'), createCheckout);
router.post('/activate-online', authorize('Restaurant Admin', 'Manager', 'Admin', 'Super Admin'), activateSubscriptionOnline);
router.post('/verify-subscription-razorpay', authorize('Restaurant Admin', 'Manager', 'Admin', 'Super Admin'), verifySubscriptionRazorpay);
router.post('/:paymentId/approve-manual', authorize('Super Admin'), approveManualPayment);

module.exports = router;