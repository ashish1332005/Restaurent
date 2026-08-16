const express = require('express');
const { getSalesOverview, getMenuPerformance, getCustomerInsights, getCustomerProfiles } = require('./reports.controller');
const { protect } = require('../../middlewares/auth.middleware');
const { authorize } = require('../../middlewares/rbac.middleware');
const { requireActiveSubscription } = require('../../middlewares/subscription.middleware');

const router = express.Router();

router.use(protect);
router.use(requireActiveSubscription);
router.use(authorize('Super Admin', 'Restaurant Admin', 'Manager'));

router.get('/sales', getSalesOverview);
router.get('/menu-performance', getMenuPerformance);
router.get('/customers', getCustomerInsights);
router.get('/customer-profiles', getCustomerProfiles);

module.exports = router;