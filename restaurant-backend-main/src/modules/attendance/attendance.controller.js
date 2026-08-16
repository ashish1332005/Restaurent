const Attendance = require('../../models/Attendance.model');
const User = require('../../models/User.model');
const { assertBranchAccess, isSuperAdmin } = require('../../utils/access-scope');
const getBranchId = (req) => req.body?.branchId || req.query?.branchId || req.user.branchId;
const dayRange = (raw) => { const start = raw ? new Date(raw) : new Date(); if (Number.isNaN(start.getTime())) return null; start.setUTCHours(0,0,0,0); return { start, end: new Date(start.getTime() + 86400000) }; };

exports.list = async (req, res, next) => {
  try {
    const branchId = getBranchId(req);
    if (!branchId && !isSuperAdmin(req.user)) return res.status(400).json({ success:false, message:'branchId is required' });
    if (branchId) await assertBranchAccess(req.user, branchId);
    const range = dayRange(req.query.date);
    if (!range) return res.status(400).json({ success:false, message:'Invalid attendance date' });
    const query = { shiftDate: { $gte: range.start, $lt: range.end } };
    if (branchId) query.branchId = branchId;
    await Attendance.updateMany({ ...query, status: 'Scheduled', scheduledEnd: { $lt: new Date() }, clockIn: { $exists: false } }, { status: 'Absent' });
    const records = await Attendance.find(query).populate('userId','name phone status').sort({ scheduledStart:1 }).lean();
    res.json({ success:true, count:records.length, data:records });
  } catch(error){ next(error); }
};

exports.schedule = async (req, res, next) => {
  try {
    const branchId = getBranchId(req); const branch = await assertBranchAccess(req.user, branchId);
    const staff = await User.findOne({ _id:req.body.userId, branchId, restaurantId:branch.restaurantId }).populate('role','name');
    if (!staff || staff.role?.name === 'Customer') return res.status(400).json({ success:false, message:'Invalid staff member for this branch' });
    const start = new Date(req.body.scheduledStart), end = new Date(req.body.scheduledEnd);
    if (Number.isNaN(start.getTime()) || Number.isNaN(end.getTime()) || end <= start || end-start > 86400000) return res.status(400).json({ success:false, message:'Provide a valid shift time' });
    const shiftDate = new Date(start); shiftDate.setUTCHours(0,0,0,0);
    const record = await Attendance.findOneAndUpdate({ branchId, userId:staff._id, shiftDate }, { $set:{ scheduledStart:start, scheduledEnd:end, notes:String(req.body.notes||'').trim().slice(0,250) }, $setOnInsert:{ status:'Scheduled' } }, { new:true, upsert:true, runValidators:true, setDefaultsOnInsert:true });
    res.status(201).json({ success:true, data:record });
  } catch(error){ next(error); }
};

const updateClock = async (req, res, next, action) => {
  try {
    const record = await Attendance.findById(req.params.id);
    if (!record) return res.status(404).json({ success:false, message:'Shift not found' });
    await assertBranchAccess(req.user, record.branchId);
    const elevated = ['Super Admin','Restaurant Admin','Manager'].includes(req.user.role?.name);
    if (!elevated && String(record.userId) !== String(req.user._id)) return res.status(403).json({ success:false, message:'You can only update your own attendance' });
    const now = new Date();
    if (action === 'in') {
      if (record.clockIn) return res.status(409).json({ success:false, message:'Already clocked in' });
      record.clockIn = now; record.status = now > new Date(record.scheduledStart.getTime()+10*60000) ? 'Late' : 'Present';
    } else {
      if (!record.clockIn) return res.status(409).json({ success:false, message:'Clock in first' });
      if (record.clockOut) return res.status(409).json({ success:false, message:'Already clocked out' });
      record.clockOut = now; record.status = 'Completed';
    }
    await record.save(); res.json({ success:true, data:record });
  } catch(error){ next(error); }
};
exports.clockIn = (req,res,next) => updateClock(req,res,next,'in');
exports.clockOut = (req,res,next) => updateClock(req,res,next,'out');

