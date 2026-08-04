const express = require('express');
const { getInventory, updateStock } = require('./inventory.controller');
const { protect } = require('../../middlewares/auth.middleware');
const { authorize } = require('../../middlewares/rbac.middleware');

const router = express.Router();

router.use(protect);
router.use(authorize('Restaurant Admin', 'Manager', 'Kitchen'));

router.route('/')
    .get(getInventory)
    .patch(updateStock);

module.exports = router;
