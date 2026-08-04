const express = require('express');
const { createRestaurant, getRestaurants, createBranch, getBranches } = require('./restaurant.controller');
const { protect } = require('../../middlewares/auth.middleware');
const { authorize } = require('../../middlewares/rbac.middleware');

const router = express.Router();

router.route('/')
    .post(protect, authorize('Super Admin'), createRestaurant)
    .get(protect, authorize('Super Admin', 'Restaurant Admin', 'Manager'), getRestaurants);

router.route('/:restaurantId/branches')
    .post(protect, authorize('Super Admin', 'Restaurant Admin'), createBranch)
    .get(protect, getBranches);

module.exports = router;
