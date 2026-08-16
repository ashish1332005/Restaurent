const mongoose = require('mongoose');
const attendanceSchema = new mongoose.Schema({
  branchId: { type: mongoose.Schema.Types.ObjectId, ref: 'Branch', required: true, index: true },
  userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true, index: true },
  shiftDate: { type: Date, required: true, index: true },
  scheduledStart: { type: Date, required: true },
  scheduledEnd: { type: Date, required: true },
  clockIn: Date,
  clockOut: Date,
  status: { type: String, enum: ['Scheduled', 'Present', 'Late', 'Absent', 'Completed'], default: 'Scheduled' },
  notes: { type: String, trim: true, maxlength: 250, default: '' }
}, { timestamps: true });
attendanceSchema.index({ branchId: 1, userId: 1, shiftDate: 1 }, { unique: true });
module.exports = mongoose.model('Attendance', attendanceSchema);
