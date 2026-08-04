const express = require('express');
const { getUsers, createUser, updateUser } = require('./users.controller');
const { protect } = require('../../middlewares/auth.middleware');
const { authorize } = require('../../middlewares/rbac.middleware');

const router = express.Router();

// Only Admins and Managers can manage staff
router.use(protect);
router.use(authorize('Super Admin', 'Restaurant Admin', 'Manager'));

router.route('/')
    .get(getUsers)
    .post(createUser);

router.route('/:id')
    .put(updateUser);

module.exports = router;
