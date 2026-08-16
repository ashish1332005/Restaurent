const express = require('express');
const { createTable, getTables, updateTable, deleteTable, updateTableStatus, rotateTableQr, setTableQrActive } = require('./tables.controller');
const { protect } = require('../../middlewares/auth.middleware');
const { authorize } = require('../../middlewares/rbac.middleware');
const { requireActiveSubscription } = require('../../middlewares/subscription.middleware');
const { enforcePlanLimit } = require('../../middlewares/plan-limits.middleware');

const router = express.Router();

router.use(protect);
router.use(requireActiveSubscription);

router.route('/')
    .post(authorize('Restaurant Admin', 'Manager'), enforcePlanLimit('tables'), createTable)
    .get(getTables);

router.route('/:id')
    .patch(authorize('Restaurant Admin', 'Manager'), updateTable)
    .delete(authorize('Restaurant Admin', 'Manager'), deleteTable);

router.post('/:id/qr/rotate', authorize('Restaurant Admin', 'Manager'), rotateTableQr);
router.patch('/:id/qr/status', authorize('Restaurant Admin', 'Manager'), setTableQrActive);

router.route('/:id/status')
    .patch(authorize('Restaurant Admin', 'Manager', 'Waiter'), updateTableStatus);

module.exports = router;
