const express = require('express');
const { createOrder, getOrders, updateOrderStatus } = require('./orders.controller');
const { protect } = require('../../middlewares/auth.middleware');

const router = express.Router();

router.use(protect);

router.route('/')
    .post(createOrder)
    .get(getOrders);

router.route('/:id/status')
    .patch(updateOrderStatus);

module.exports = router;
