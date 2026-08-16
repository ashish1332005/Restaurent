const express = require('express');
const { getInventory, updateStock, getMovements } = require('./inventory.controller');
const { protect } = require('../../middlewares/auth.middleware');
const { authorize } = require('../../middlewares/rbac.middleware');
const { requireActiveSubscription } = require('../../middlewares/subscription.middleware');

const router = express.Router();

router.use(protect);
router.use(requireActiveSubscription);
router.use(authorize('Restaurant Admin', 'Manager', 'Kitchen'));

router.get('/movements', getMovements);

router.route('/')
    .get(getInventory)
    .patch(updateStock);

module.exports = router;

