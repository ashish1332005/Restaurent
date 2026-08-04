const express = require('express');
const { createCategory, getCategories, createMenuItem, getMenuItems } = require('./menu.controller');
const { protect } = require('../../middlewares/auth.middleware');
const { authorize } = require('../../middlewares/rbac.middleware');

const router = express.Router();

router.route('/categories')
    .post(protect, authorize('Restaurant Admin', 'Manager'), createCategory)
    .get(protect, getCategories);

router.route('/items')
    .post(protect, authorize('Restaurant Admin', 'Manager'), createMenuItem)
    .get(protect, getMenuItems);

module.exports = router;
