const express = require('express');
const { protect } = require('../../middlewares/auth.middleware');
const { authorize } = require('../../middlewares/rbac.middleware');
const controller = require('./coupons.controller');

const router = express.Router();
router.get('/available', controller.getAvailableCoupons);
router.use(protect);
router.get('/', authorize('Restaurant Admin', 'Manager'), controller.getAdminCoupons);
router.post('/', authorize('Restaurant Admin', 'Manager'), controller.createCoupon);
router.patch('/:id', authorize('Restaurant Admin', 'Manager'), controller.updateCoupon);
router.delete('/:id', authorize('Restaurant Admin'), controller.deleteCoupon);
module.exports = router;
