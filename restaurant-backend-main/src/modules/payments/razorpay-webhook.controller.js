const crypto = require('crypto');
const mongoose = require('mongoose');
const OnlinePayment = require('../../models/OnlinePayment.model');
const Order = require('../../models/Order.model');
const Invoice = require('../../models/Invoice.model');
const Table = require('../../models/Table.model');
const TableSession = require('../../models/TableSession.model');
const socketService = require('../../services/socket.service');

const signaturesMatch = (rawBody, received, secret) => {
  const expected = crypto.createHmac('sha256', secret).update(rawBody).digest('hex');
  const left = Buffer.from(expected, 'utf8');
  const right = Buffer.from(String(received || ''), 'utf8');
  return left.length === right.length && crypto.timingSafeEqual(left, right);
};

exports.handleRazorpayWebhook = async (req, res, next) => {
  const secret = process.env.RAZORPAY_WEBHOOK_SECRET;
  const signature = req.get('x-razorpay-signature');
  if (!secret || !Buffer.isBuffer(req.body) || !signaturesMatch(req.body, signature, secret)) {
    return res.status(401).json({ success: false, message: 'Invalid Razorpay webhook signature' });
  }
  let payload;
  try { payload = JSON.parse(req.body.toString('utf8')); } catch (_) { return res.status(400).json({ success: false, message: 'Invalid webhook body' }); }
  if (payload.event !== 'payment_link.paid') return res.status(200).json({ success: true, ignored: true });
  const link = payload.payload?.payment_link?.entity;
  const providerPayment = payload.payload?.payment?.entity;
  if (!link?.id) return res.status(400).json({ success: false, message: 'Payment link id is missing' });
  let session;
  try {
    const payment = await OnlinePayment.findOne({ providerLinkId: link.id });
    if (!payment || payment.status === 'Paid') return res.status(200).json({ success: true, duplicate: payment?.status === 'Paid' });
    if (Number(link.amount_paid) !== Math.round(payment.amount * 100)) return res.status(409).json({ success: false, message: 'Webhook payment amount mismatch' });
    session = await mongoose.startSession();
    let paidOrders = [];
    const { recordPaidCustomerOrder } = require('../../services/customer-loyalty.service');
    await session.withTransaction(async () => {
      const currentPayment = await OnlinePayment.findOne({ _id: payment._id, status: { $ne: 'Paid' } }).session(session);
      if (!currentPayment) return;
      const targetOrderIds = (currentPayment.orderIds && currentPayment.orderIds.length) ? currentPayment.orderIds : [currentPayment.orderId];
      const orders = await Order.find({ _id: { $in: targetOrderIds }, paymentStatus: 'Unpaid' }).session(session);
      const paymentMethod = providerPayment?.method === 'card' ? 'Card' : providerPayment?.method === 'wallet' ? 'Wallet' : 'UPI';
      const transactionId = providerPayment?.id || link.id;

      for (const order of orders) {
        await Invoice.create([{
          orderId: order._id,
          paymentMethod,
          transactionId,
          amount: order.total,
          status: 'Paid'
        }], { session });
        order.paymentStatus = 'Paid';
        order.status = 'Paid';
        await order.save({ session });
        await recordPaidCustomerOrder(order, session);
        paidOrders.push(order);
      }

      if (paidOrders.length && paidOrders[0].tableId) {
        await Table.findByIdAndUpdate(paidOrders[0].tableId, { status: 'Cleaning' }, { session });
        await TableSession.updateMany({ tableId: paidOrders[0].tableId, status: 'Active' }, { status: 'Closed', closedAt: new Date() }, { session });
      }

      currentPayment.status = 'Paid';
      currentPayment.providerPaymentId = providerPayment?.id || '';
      currentPayment.paidAt = new Date();
      await currentPayment.save({ session });
    });
    for (const paidOrder of paidOrders) {
      try { socketService.getIo().to(`branch_${paidOrder.branchId}`).emit('billPaid', { order: paidOrder }); } catch (_) {}
    }
    return res.status(200).json({ success: true });
  } catch (error) {
    if (error?.code === 11000) return res.status(200).json({ success: true, duplicate: true });
    next(error);
  } finally { if (session) await session.endSession(); }
};