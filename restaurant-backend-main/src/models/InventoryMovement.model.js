const mongoose = require('mongoose');
const inventoryMovementSchema = new mongoose.Schema({
  branchId: { type: mongoose.Schema.Types.ObjectId, ref: 'Branch', required: true, index: true },
  inventoryId: { type: mongoose.Schema.Types.ObjectId, ref: 'Inventory', required: true, index: true },
  ingredientName: { type: String, required: true },
  type: { type: String, enum: ['Opening', 'Purchase', 'Usage', 'Wastage', 'Correction', 'Order Consumption'], required: true },
  quantityDelta: { type: Number, required: true },
  balanceAfter: { type: Number, required: true, min: 0 },
  unit: { type: String, required: true },
  reason: { type: String, trim: true, maxlength: 250, default: '' },
  orderId: { type: mongoose.Schema.Types.ObjectId, ref: 'Order' },
  createdBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User' }
}, { timestamps: true });
inventoryMovementSchema.index({ branchId: 1, createdAt: -1 });
module.exports = mongoose.model('InventoryMovement', inventoryMovementSchema);
