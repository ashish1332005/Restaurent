const express = require('express');
const { getMySubscription, createCheckout, verifyPaymentWebhook, approveManualPayment } = require('./payments.controller');
const { protect } = require('../../middlewares/auth.middleware');
const { authorize } = require('../../middlewares/rbac.middleware');

const router = express.Router();

router.post('/webhook', verifyPaymentWebhook);

router.use(protect);
router.get('/subscription', authorize('Restaurant Admin', 'Manager', 'Super Admin'), getMySubscription);
router.post('/checkout', authorize('Restaurant Admin', 'Manager'), createCheckout);
router.post('/:paymentId/approve-manual', authorize('Super Admin'), approveManualPayment);

module.exports = router;