const mongoose = require('mongoose');
const onlinePaymentSchema = new mongoose.Schema({
  orderId: { type: mongoose.Schema.Types.ObjectId, ref: 'Order', required: true, index: true },
  tableSessionId: { type: mongoose.Schema.Types.ObjectId, ref: 'TableSession', required: true },
  provider: { type: String, enum: ['Razorpay'], default: 'Razorpay' },
  providerLinkId: { type: String, required: true, unique: true },
  shortUrl: { type: String, required: true },
  amount: { type: Number, required: true },
  currency: { type: String, default: 'INR' },
  status: { type: String, enum: ['Created', 'Paid', 'Failed', 'Expired', 'Cancelled'], default: 'Created', index: true },
  providerPaymentId: String,
  expiresAt: { type: Date, required: true },
  paidAt: Date
}, { timestamps: true });
onlinePaymentSchema.index({ orderId: 1, status: 1 });
module.exports = mongoose.model('OnlinePayment', onlinePaymentSchema);