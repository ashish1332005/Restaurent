const express = require('express');
const { getSalesOverview } = require('./reports.controller');
const { protect } = require('../../middlewares/auth.middleware');
const { authorize } = require('../../middlewares/rbac.middleware');

const router = express.Router();

router.use(protect);
router.use(authorize('Super Admin', 'Restaurant Admin', 'Manager'));

router.get('/sales', getSalesOverview);

module.exports = router;
