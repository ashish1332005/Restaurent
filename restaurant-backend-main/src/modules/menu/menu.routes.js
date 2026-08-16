const express = require('express');
const { createCategory, getCategories, updateCategory, deleteCategory, createMenuItem, getMenuItems, updateMenuItem, setMenuItemAvailability, deleteMenuItem, updateMenuItemRecipe, bulkUpdateMenuItems, duplicateMenuItem, reorderMenuItems, reorderCategories, getMenuHistory, restoreMenuHistory } = require('./menu.controller');
const { protect } = require('../../middlewares/auth.middleware');
const { authorize } = require('../../middlewares/rbac.middleware');
const { requireActiveSubscription } = require('../../middlewares/subscription.middleware');

const router = express.Router();

router.route('/categories')
    .post(protect, requireActiveSubscription, authorize('Restaurant Admin', 'Manager'), createCategory)
    .get(protect, requireActiveSubscription, getCategories);

router.patch('/categories/reorder', protect, requireActiveSubscription, authorize('Restaurant Admin', 'Manager'), reorderCategories);

router.route('/categories/:id')
    .patch(protect, requireActiveSubscription, authorize('Restaurant Admin', 'Manager'), updateCategory)
    .delete(protect, requireActiveSubscription, authorize('Restaurant Admin', 'Manager'), deleteCategory);

router.route('/items')
    .post(protect, requireActiveSubscription, authorize('Restaurant Admin', 'Manager'), createMenuItem)
    .get(protect, requireActiveSubscription, getMenuItems);

router.patch('/items/bulk', protect, requireActiveSubscription, authorize('Restaurant Admin', 'Manager'), bulkUpdateMenuItems);
router.patch('/items/reorder', protect, requireActiveSubscription, authorize('Restaurant Admin', 'Manager'), reorderMenuItems);
router.post('/items/:id/duplicate', protect, requireActiveSubscription, authorize('Restaurant Admin', 'Manager'), duplicateMenuItem);
router.get('/history', protect, requireActiveSubscription, authorize('Restaurant Admin', 'Manager'), getMenuHistory);
router.post('/history/:id/restore', protect, requireActiveSubscription, authorize('Restaurant Admin'), restoreMenuHistory);

router.route('/items/:id')
    .patch(protect, requireActiveSubscription, authorize('Restaurant Admin', 'Manager'), updateMenuItem)
    .delete(protect, requireActiveSubscription, authorize('Restaurant Admin', 'Manager'), deleteMenuItem);

router.patch('/items/:id/recipe', protect, requireActiveSubscription, authorize('Restaurant Admin', 'Manager'), updateMenuItemRecipe);

router.patch('/items/:id/availability', protect, requireActiveSubscription, authorize('Restaurant Admin', 'Manager'), setMenuItemAvailability);

module.exports = router;

