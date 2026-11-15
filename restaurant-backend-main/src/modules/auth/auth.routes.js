const express = require('express');
const {
    login,
    registerRestaurantOwner,
    registerCustomer,
    googleCustomerAuth,
    forgotPassword,
    resetPassword,
    verifyOtp,
    getMe,
    updateMe,
    getDemoProfile,
    updateDemoProfile
} = require('./auth.controller');
const { protect } = require('../../middlewares/auth.middleware');

const router = express.Router();

router.post('/login', login);
router.post('/register/restaurant', registerRestaurantOwner);
router.post('/register/customer', registerCustomer);
router.post('/google/customer', googleCustomerAuth);
router.post('/forgot-password', forgotPassword);
router.post('/reset-password', resetPassword);
router.post('/verify-otp', verifyOtp);
router.get('/demo-profile/:demoKey', getDemoProfile);
router.patch('/demo-profile/:demoKey', updateDemoProfile);
router.get('/me', protect, getMe);
router.patch('/me', protect, updateMe);

module.exports = router;
