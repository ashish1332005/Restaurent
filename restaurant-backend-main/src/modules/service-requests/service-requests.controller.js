const ServiceRequest = require('../../models/ServiceRequest.model');
const { assertBranchAccess, isSuperAdmin } = require('../../utils/access-scope');
const socketService = require('../../services/socket.service');

exports.list = async (req, res, next) => {
  try {
    const branchId = String(req.query.branchId || '').trim();
    if (!branchId && !isSuperAdmin(req.user)) return res.status(400).json({ success: false, message: 'branchId is required' });
    if (branchId) await assertBranchAccess(req.user, branchId);
    const query = branchId ? { branchId } : {};
    if (req.query.status) query.status = req.query.status;
    const records = await ServiceRequest.find(query).populate('tableId', 'name status').populate('acknowledgedBy resolvedBy', 'name').sort({ createdAt: -1 }).limit(200).lean();
    res.json({ success: true, count: records.length, data: records });
  } catch (error) { next(error); }
};

exports.update = async (req, res, next) => {
  try {
    const record = await ServiceRequest.findById(req.params.id);
    if (!record) return res.status(404).json({ success: false, message: 'Service request not found' });
    await assertBranchAccess(req.user, record.branchId);
    const status = String(req.body.status || '');
    if (!['Acknowledged', 'Resolved'].includes(status)) return res.status(400).json({ success: false, message: 'Invalid request status' });
    if (record.status === 'Resolved') return res.status(409).json({ success: false, message: 'Request is already resolved' });
    if (status === 'Acknowledged') {
      record.status = 'Acknowledged'; record.acknowledgedBy = req.user._id; record.acknowledgedAt = new Date();
    } else {
      record.status = 'Resolved'; record.resolvedBy = req.user._id; record.resolvedAt = new Date();
      if (!record.acknowledgedBy) { record.acknowledgedBy = req.user._id; record.acknowledgedAt = new Date(); }
    }
    await record.save();
    try { socketService.getIo().to(`branch_${record.branchId}`).emit('tableServiceUpdated', record); } catch (_) {}
    res.json({ success: true, data: record });
  } catch (error) { next(error); }
};
