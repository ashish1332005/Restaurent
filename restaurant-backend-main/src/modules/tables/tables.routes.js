const express = require('express');
const { createTable, getTables, updateTableStatus } = require('./tables.controller');
const { protect } = require('../../middlewares/auth.middleware');
const { authorize } = require('../../middlewares/rbac.middleware');

const router = express.Router();

router.use(protect);

router.route('/')
    .post(authorize('Restaurant Admin', 'Manager'), createTable)
    .get(getTables);

router.route('/:id/status')
    .patch(updateTableStatus);

module.exports = router;
