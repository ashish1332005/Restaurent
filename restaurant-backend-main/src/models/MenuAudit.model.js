const mongoose = require('mongoose');

const menuAuditSchema = new mongoose.Schema({
  restaurantId: { type: mongoose.Schema.Types.ObjectId, ref: 'Restaurant', required: true, index: true },
  branchId: { type: mongoose.Schema.Types.ObjectId, ref: 'Branch', required: true, index: true },
  actorId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  resourceType: { type: String, enum: ['MenuItem', 'Category'], required: true },
  resourceId: { type: mongoose.Schema.Types.ObjectId, required: true, index: true },
  action: {
    type: String,
    enum: ['Created', 'Updated', 'Deleted', 'Restored', 'Duplicated', 'Bulk Updated', 'Reordered'],
    required: true
  },
  summary: { type: String, trim: true, maxlength: 240, default: '' },
  before: { type: mongoose.Schema.Types.Mixed, default: null },
  after: { type: mongoose.Schema.Types.Mixed, default: null }
}, { timestamps: true });

menuAuditSchema.index({ branchId: 1, createdAt: -1 });
menuAuditSchema.index({ resourceId: 1, createdAt: -1 });
module.exports = mongoose.model('MenuAudit', menuAuditSchema);