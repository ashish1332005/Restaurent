const express = require('express');
const { createRestaurant, getRestaurants, createBranch, getBranches, updateRestaurantSettings, updateBranchSettings } = require('./restaurant.controller');
const { protect } = require('../../middlewares/auth.middleware');
const { authorize } = require('../../middlewares/rbac.middleware');
const { requireActiveSubscription } = require('../../middlewares/subscription.middleware');
const { enforcePlanLimit } = require('../../middlewares/plan-limits.middleware');

const router = express.Router();

router.route('/')
    .post(protect, authorize('Super Admin'), createRestaurant)
    .get(protect, authorize('Super Admin', 'Restaurant Admin', 'Manager'), getRestaurants);

router.route('/:restaurantId/branches')
    .post(protect, authorize('Super Admin', 'Restaurant Admin'), requireActiveSubscription, enforcePlanLimit('branches'), createBranch)
    .get(protect, authorize('Super Admin', 'Restaurant Admin', 'Manager'), getBranches);

module.exports = router;
router.patch('/:restaurantId/settings', protect, requireActiveSubscription, authorize('Super Admin', 'Restaurant Admin'), updateRestaurantSettings);
router.patch('/branches/:branchId/settings', protect, requireActiveSubscription, authorize('Super Admin', 'Restaurant Admin', 'Manager'), updateBranchSettings);

