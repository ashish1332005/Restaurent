const MenuAudit = require('../models/MenuAudit.model');

const snapshot = (document) => {
  if (!document) return null;
  const value = typeof document.toObject === 'function'
    ? document.toObject({ depopulate: true })
    : { ...document };
  return JSON.parse(JSON.stringify(value));
};

const recordMenuAudit = async ({ user, branchId, resourceType, resourceId, action, summary, before, after }) => {
  if (!user?._id || !user.restaurantId || !branchId || !resourceId) return null;
  return MenuAudit.create({
    restaurantId: user.restaurantId,
    branchId,
    actorId: user._id,
    resourceType,
    resourceId,
    action,
    summary: summary || '',
    before: snapshot(before),
    after: snapshot(after)
  });
};

module.exports = { snapshot, recordMenuAudit };