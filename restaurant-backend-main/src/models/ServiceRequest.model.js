const mongoose = require('mongoose');
const serviceRequestSchema = new mongoose.Schema({
  branchId: { type: mongoose.Schema.Types.ObjectId, ref: 'Branch', required: true, index: true },
  tableId: { type: mongoose.Schema.Types.ObjectId, ref: 'Table', required: true, index: true },
  tableSessionId: { type: mongoose.Schema.Types.ObjectId, ref: 'TableSession' },
  type: { type: String, enum: ['Waiter', 'Water', 'Bill', 'Refill'], required: true },
  customerName: { type: String, trim: true, default: '' },
  paymentMethod: { type: String, enum: ['Cash', 'Card', 'UPI'], default: null },
  menuItemId: { type: mongoose.Schema.Types.ObjectId, ref: 'MenuItem', default: null },
  dishName: { type: String, trim: true, maxlength: 120, default: '' },
  dishNameHi: { type: String, trim: true, maxlength: 120, default: '' },
  refillPolicy: { type: String, enum: ['Limited', 'Unlimited'], default: null },
  refillLimit: { type: Number, min: 1, default: null },
  refillNumber: { type: Number, min: 1, default: null },
  status: { type: String, enum: ['Open', 'Acknowledged', 'Resolved'], default: 'Open', index: true },
  acknowledgedBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
  acknowledgedAt: Date,
  resolvedBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
  resolvedAt: Date
}, { timestamps: true });
serviceRequestSchema.index({ tableSessionId: 1, type: 1, status: 1 });
serviceRequestSchema.index({ tableSessionId: 1, menuItemId: 1, dishName: 1, createdAt: -1 });
module.exports = mongoose.model('ServiceRequest', serviceRequestSchema);
