const express = require('express');
const { getUsers, createUser, updateUser, getAssignableRoles } = require('./users.controller');
const { protect } = require('../../middlewares/auth.middleware');
const { authorize } = require('../../middlewares/rbac.middleware');
const { requireActiveSubscription } = require('../../middlewares/subscription.middleware');
const { enforcePlanLimit } = require('../../middlewares/plan-limits.middleware');

const router = express.Router();

router.use(protect);
router.use(authorize('Super Admin', 'Restaurant Admin', 'Manager'));
router.use(requireActiveSubscription);

router.get('/roles/assignable', getAssignableRoles);

router.route('/')
    .get(getUsers)
    .post(enforcePlanLimit('staff'), createUser);

router.route('/:id')
    .put(updateUser);

module.exports = router;

