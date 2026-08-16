const crypto = require('crypto');
const Payment = require('../../models/Payment.model');
const Subscription = require('../../models/Subscription.model');
const Restaurant = require('../../models/Restaurant.model');

const addDays = (date, days) => new Date(date.getTime() + days * 24 * 60 * 60 * 1000);

const activatePaidSubscription = async ({ payment, providerPaymentId, paymentMethod, validityDays = 30 }) => {
    const now = new Date();
    const expiresAt = addDays(now, Number(validityDays || 30));

    payment.status = 'Paid';
    payment.paidAt = now;
    payment.providerPaymentId = providerPaymentId || payment.providerPaymentId;
    payment.paymentMethod = paymentMethod || payment.paymentMethod;
    await payment.save();

    const subscription = await Subscription.findByIdAndUpdate(payment.subscriptionId, {
        status: 'Active',
        startsAt: now,
        expiresAt
    }, { new: true });

    const restaurant = await Restaurant.findByIdAndUpdate(payment.restaurantId, {
        subscriptionStatus: 'Active',
        subscriptionExpiresAt: expiresAt,
        subscriptionPlan: subscription.plan,
        isActive: true
    }, { new: true });

    return { payment, subscription, restaurant };
};

exports.getMySubscription = async (req, res, next) => {
    try {
        const subscription = await Subscription.findOne({ restaurantId: req.user.restaurantId })
            .sort({ createdAt: -1 })
            .lean();
        const payments = await Payment.find({ restaurantId: req.user.restaurantId })
            .sort({ createdAt: -1 })
            .limit(10)
            .lean();

        res.status(200).json({ success: true, data: { subscription, payments } });
    } catch (error) {
        next(error);
    }
};

exports.createCheckout = async (req, res, next) => {
    try {
        const subscription = await Subscription.findOne({ restaurantId: req.user.restaurantId })
            .sort({ createdAt: -1 });
        if (!subscription) {
            return res.status(404).json({ success: false, message: 'Subscription not found' });
        }

        const provider = String(req.body.provider || 'Manual');
        const paymentMethod = String(req.body.paymentMethod || 'Manual');
        if (!['Manual', 'Razorpay', 'Stripe'].includes(provider) || !['Cash', 'Card', 'UPI', 'Wallet', 'NetBanking', 'Manual'].includes(paymentMethod)) {
            return res.status(400).json({ success: false, message: 'Invalid subscription payment provider or method' });
        }
        const existing = await Payment.findOne({ restaurantId: req.user.restaurantId, subscriptionId: subscription._id, status: 'Created' }).sort({ createdAt: -1 });
        if (existing) return res.status(200).json({ success: true, data: { payment: existing, checkoutStatus: 'PENDING' } });
        const payment = await Payment.create({
            restaurantId: req.user.restaurantId,
            subscriptionId: subscription._id,
            amount: subscription.amount,
            currency: subscription.currency,
            status: 'Created',
            provider,
            paymentMethod
        });

        res.status(201).json({ success: true, data: { payment, checkoutStatus: 'CREATED' } });
    } catch (error) {
        next(error);
    }
};

exports.verifyPaymentWebhook = async (req, res, next) => {
    try {
        const webhookSecret = String(process.env.PAYMENT_WEBHOOK_SECRET || '').trim();
        const signature = String(req.headers['x-payment-signature'] || '').trim();
        const payload = JSON.stringify(req.body || {});
        const expected = crypto.createHmac('sha256', webhookSecret).update(payload).digest('hex');

        if (!webhookSecret || !signature || signature.length !== expected.length || !crypto.timingSafeEqual(Buffer.from(signature), Buffer.from(expected))) {
            return res.status(401).json({ success: false, message: 'Invalid payment webhook signature' });
        }

        const payment = await Payment.findById(req.body.paymentId);
        if (!payment) return res.status(404).json({ success: false, message: 'Payment not found' });
        if (payment.status === 'Paid') return res.status(200).json({ success: true, data: { payment } });
        if (req.body.status !== 'Paid') return res.status(400).json({ success: false, message: 'Payment is not successful' });

        const data = await activatePaidSubscription({
            payment,
            providerPaymentId: req.body.providerPaymentId,
            paymentMethod: req.body.paymentMethod,
            validityDays: req.body.validityDays
        });

        res.status(200).json({ success: true, data });
    } catch (error) {
        next(error);
    }
};

exports.approveManualPayment = async (req, res, next) => {
    try {
        const payment = await Payment.findById(req.params.paymentId);
        if (!payment) return res.status(404).json({ success: false, message: 'Payment not found' });
        if (payment.status === 'Paid') return res.status(200).json({ success: true, data: { payment } });

        const data = await activatePaidSubscription({
            payment,
            providerPaymentId: req.body.providerPaymentId || `manual-${payment._id}`,
            paymentMethod: req.body.paymentMethod || 'Manual',
            validityDays: req.body.validityDays
        });

        res.status(200).json({ success: true, data });
    } catch (error) {
        next(error);
    }
};