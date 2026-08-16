const mongoose = require('mongoose');
const tableSessionSchema = new mongoose.Schema({
    tableId: { type: mongoose.Schema.Types.ObjectId, ref: 'Table', required: true },
    branchId: { type: mongoose.Schema.Types.ObjectId, ref: 'Branch', required: true, index: true },
    customerName: { type: String, required: true, trim: true },
    customerPhone: { type: String, required: true, trim: true },
    tokenHash: { type: String, required: true, select: false },
    status: { type: String, enum: ['Active', 'Closed', 'Expired', 'Cancelled'], default: 'Active', index: true },
    expiresAt: { type: Date, required: true, index: true },
    closedAt: { type: Date, default: null }
}, { timestamps: true });
tableSessionSchema.index({ tableId: 1 }, { unique: true, partialFilterExpression: { status: 'Active' } });
tableSessionSchema.index({ customerPhone: 1 }, { unique: true, partialFilterExpression: { status: 'Active' } });
module.exports = mongoose.model('TableSession', tableSessionSchema);