const Category = require('../../models/Category.model');
const MenuItem = require('../../models/MenuItem.model');
const Inventory = require('../../models/Inventory.model');
const mongoose = require('mongoose');
const MenuAudit = require('../../models/MenuAudit.model');
const { recordMenuAudit, snapshot } = require('../../utils/menu-audit');
const { assertBranchAccess, assertRestaurantAccess, isSuperAdmin } = require('../../utils/access-scope');

const getRequestedBranchId = (req) => req.body?.branchId || req.query?.branchId || req.user.branchId;

exports.createCategory = async (req, res, next) => {
    try {
        const branchId = getRequestedBranchId(req) || null;
        if (branchId) await assertBranchAccess(req.user, branchId);
        const category = await Category.create({ restaurantId: req.user.restaurantId, branchId, name: req.body.name, nameHi: req.body.nameHi, image: req.body.image, order: req.body.order, isActive: req.body.isActive });
        await recordMenuAudit({ user: req.user, branchId: branchId || req.user.branchId, resourceType: 'Category', resourceId: category._id, action: 'Created', summary: 'Category created', before: null, after: category });
        res.status(201).json({ success: true, data: category });
    } catch (error) { next(error); }
};

exports.getCategories = async (req, res, next) => {
    try {
        const branchId = getRequestedBranchId(req);
        if (!branchId && isSuperAdmin(req.user)) return res.status(400).json({ success: false, message: 'branchId is required' });
        if (branchId) await assertBranchAccess(req.user, branchId);
        const query = { restaurantId: req.user.restaurantId };
        if (branchId) query.$or = [{ branchId }, { branchId: null }];
        const categories = await Category.find(query).sort({ order: 1, name: 1 });
        res.status(200).json({ success: true, data: categories });
    } catch (error) { next(error); }
};

exports.createMenuItem = async (req, res, next) => {
    try {
        const branchId = getRequestedBranchId(req);
        await assertBranchAccess(req.user, branchId);
        const category = await Category.findOne({ _id: req.body.categoryId, restaurantId: req.user.restaurantId, $or: [{ branchId }, { branchId: null }] });
        if (!category) return res.status(400).json({ success: false, message: 'Invalid category for this branch' });
        const publishStatus = req.body.publishStatus || 'Published';
        if (!['Draft', 'Published', 'Scheduled'].includes(publishStatus)) {
            return res.status(400).json({ success: false, message: 'Invalid publish status' });
        }
        if (publishStatus === 'Scheduled' && !req.body.publishAt) {
            return res.status(400).json({ success: false, message: 'Scheduled menu items require a publish date' });
        }
        const menuItem = await MenuItem.create({
            branchId,
            categoryId: category._id,
            subCategoryId: req.body.subCategoryId || null,
            itemType: req.body.itemType,
            name: req.body.name,
            nameHi: req.body.nameHi,
            description: req.body.description,
            descriptionHi: req.body.descriptionHi,
            basePrice: req.body.basePrice,
            displayOrder: req.body.displayOrder,
            variants: Array.isArray(req.body.variants) ? req.body.variants : [],
            modifiers: Array.isArray(req.body.modifiers) ? req.body.modifiers : [],
            image: req.body.image,
            imageUrl: req.body.imageUrl || req.body.image,
            isVeg: req.body.isVeg,
            spiceLevel: req.body.spiceLevel,
            dietaryTags: req.body.dietaryTags,
            allergens: req.body.allergens,
            isAvailable: req.body.isAvailable,
            publishStatus,
            publishAt: req.body.publishAt,
            isFeatured: req.body.isFeatured,
            isPopular: req.body.isPopular,
            preparationTime: req.body.preparationTime,
            thaliConfig: req.body.thaliConfig,
            availabilitySchedule: req.body.availabilitySchedule,
            nutritionalInfo: req.body.nutritionalInfo,
            discount: req.body.discount,
            taxRate: req.body.taxRate
        });
        await recordMenuAudit({ user: req.user, branchId, resourceType: 'MenuItem', resourceId: menuItem._id, action: 'Created', summary: 'Menu item created', before: null, after: menuItem });
        res.status(201).json({ success: true, data: menuItem });
    } catch (error) { next(error); }
};

exports.getMenuItems = async (req, res, next) => {
    try {
        const branchId = getRequestedBranchId(req);
        if (!branchId && !isSuperAdmin(req.user)) return res.status(400).json({ success: false, message: 'branchId is required' });
        if (branchId) await assertBranchAccess(req.user, branchId);
        const query = branchId ? { branchId } : {};
        if (req.query.categoryId) query.categoryId = req.query.categoryId;
        const menuItems = await MenuItem.find(query).sort({ displayOrder: 1, name: 1 }).populate('categoryId', 'name nameHi');
        res.status(200).json({ success: true, count: menuItems.length, data: menuItems });
    } catch (error) { next(error); }
};
const assertCategoryScope = async (user, category) => {
    await assertRestaurantAccess(user, category.restaurantId);
    if (category.branchId) await assertBranchAccess(user, category.branchId);
};

exports.updateCategory = async (req, res, next) => {
    try {
        const category = await Category.findById(req.params.id);
        if (!category) return res.status(404).json({ success: false, message: 'Category not found' });
        await assertCategoryScope(req.user, category);
        const before = snapshot(category);
        const updates = {};
        for (const key of ['name', 'nameHi', 'image', 'order', 'isActive']) if (req.body[key] !== undefined) updates[key] = req.body[key];
        const updated = await Category.findByIdAndUpdate(category._id, updates, { new: true, runValidators: true });
        await recordMenuAudit({ user: req.user, branchId: category.branchId || req.user.branchId, resourceType: 'Category', resourceId: category._id, action: 'Updated', summary: 'Category updated', before, after: updated });
        res.status(200).json({ success: true, data: updated });
    } catch (error) { next(error); }
};

exports.deleteCategory = async (req, res, next) => {
    try {
        const category = await Category.findById(req.params.id);
        if (!category) return res.status(404).json({ success: false, message: 'Category not found' });
        await assertCategoryScope(req.user, category);
        if (await MenuItem.exists({ categoryId: category._id })) return res.status(409).json({ success: false, message: 'Move or delete category menu items first' });
        const before = snapshot(category);
        await category.deleteOne();
        await recordMenuAudit({ user: req.user, branchId: category.branchId || req.user.branchId, resourceType: 'Category', resourceId: category._id, action: 'Deleted', summary: 'Category deleted', before, after: null });
        res.status(200).json({ success: true, message: 'Category deleted' });
    } catch (error) { next(error); }
};

exports.updateMenuItem = async (req, res, next) => {
    try {
        const item = await MenuItem.findById(req.params.id);
        if (!item) return res.status(404).json({ success: false, message: 'Menu item not found' });
        await assertBranchAccess(req.user, item.branchId);
        if (req.body.categoryId !== undefined) {
            const category = await Category.findOne({ _id: req.body.categoryId, restaurantId: req.user.restaurantId, $or: [{ branchId: item.branchId }, { branchId: null }] });
            if (!category) return res.status(400).json({ success: false, message: 'Invalid category for this branch' });
        }
        const updates = {};
        const requestedPublishStatus = req.body.publishStatus;
        if (requestedPublishStatus !== undefined &&
            !['Draft', 'Published', 'Scheduled'].includes(requestedPublishStatus)) {
            return res.status(400).json({ success: false, message: 'Invalid publish status' });
        }
        const effectivePublishStatus = requestedPublishStatus ?? item.publishStatus ?? 'Published';
        const effectivePublishAt = req.body.publishAt !== undefined
            ? req.body.publishAt
            : item.publishAt;
        if (effectivePublishStatus === 'Scheduled' && !effectivePublishAt) {
            return res.status(400).json({ success: false, message: 'Scheduled menu items require a publish date' });
        }
        for (const key of ['categoryId', 'subCategoryId', 'itemType', 'name', 'nameHi', 'description', 'descriptionHi', 'basePrice', 'displayOrder', 'variants', 'modifiers', 'image', 'imageUrl', 'isVeg', 'spiceLevel', 'dietaryTags', 'allergens', 'isAvailable', 'publishStatus', 'publishAt', 'isFeatured', 'isPopular', 'preparationTime', 'thaliConfig', 'availabilitySchedule', 'nutritionalInfo', 'discount', 'taxRate']) if (req.body[key] !== undefined) updates[key] = req.body[key];
        if (effectivePublishStatus !== 'Scheduled') updates.publishAt = null;
        const before = snapshot(item);
        const updated = await MenuItem.findByIdAndUpdate(item._id, updates, { new: true, runValidators: true }).populate('categoryId', 'name nameHi');
        await recordMenuAudit({ user: req.user, branchId: item.branchId, resourceType: 'MenuItem', resourceId: item._id, action: 'Updated', summary: 'Menu item edited', before, after: updated });
        res.status(200).json({ success: true, data: updated });
    } catch (error) { next(error); }
};

exports.setMenuItemAvailability = async (req, res, next) => {
    try {
        if (typeof req.body.isAvailable !== 'boolean') return res.status(400).json({ success: false, message: 'isAvailable must be a boolean' });
        const item = await MenuItem.findById(req.params.id);
        if (!item) return res.status(404).json({ success: false, message: 'Menu item not found' });
        await assertBranchAccess(req.user, item.branchId);
        const before = snapshot(item);
        item.isAvailable = req.body.isAvailable;
        await item.save();
        await recordMenuAudit({ user: req.user, branchId: item.branchId, resourceType: 'MenuItem', resourceId: item._id, action: 'Updated', summary: `Availability set to ${item.isAvailable}`, before, after: item });
        res.status(200).json({ success: true, data: item });
    } catch (error) { next(error); }
};

exports.deleteMenuItem = async (req, res, next) => {
    try {
        const item = await MenuItem.findById(req.params.id);
        if (!item) return res.status(404).json({ success: false, message: 'Menu item not found' });
        await assertBranchAccess(req.user, item.branchId);
        const before = snapshot(item);
        await item.deleteOne();
        await recordMenuAudit({ user: req.user, branchId: item.branchId, resourceType: 'MenuItem', resourceId: item._id, action: 'Deleted', summary: `Deleted ${item.name}`, before, after: null });
        res.status(200).json({ success: true, message: 'Menu item deleted' });
    } catch (error) { next(error); }
};
exports.updateMenuItemRecipe = async (req, res, next) => {
    try {
        const item = await MenuItem.findById(req.params.id);
        if (!item) return res.status(404).json({ success: false, message: 'Menu item not found' });
        await assertBranchAccess(req.user, item.branchId);
        if (!Array.isArray(req.body.recipe)) return res.status(400).json({ success: false, message: 'recipe must be an array' });
        const recipe = req.body.recipe.map((entry) => ({ inventoryId: entry.inventoryId, quantityPerServing: Number(entry.quantityPerServing) }));
        if (recipe.length > 50 || recipe.some((entry) => !entry.inventoryId || !Number.isFinite(entry.quantityPerServing) || entry.quantityPerServing <= 0 || entry.quantityPerServing > 100000)) return res.status(400).json({ success: false, message: 'Recipe contains invalid ingredient quantities' });
        const ids = recipe.map((entry) => String(entry.inventoryId));
        if (new Set(ids).size !== ids.length) return res.status(400).json({ success: false, message: 'Recipe cannot contain duplicate ingredients' });
        const scopedCount = await Inventory.countDocuments({ _id: { $in: ids }, branchId: item.branchId });
        if (scopedCount !== ids.length) return res.status(400).json({ success: false, message: 'Recipe ingredient is outside the menu branch' });
        const before = snapshot(item);
        item.recipe = recipe;
        await item.save();
        await item.populate('recipe.inventoryId', 'ingredientName unit quantity threshold');
        await recordMenuAudit({ user: req.user, branchId: item.branchId, resourceType: 'MenuItem', resourceId: item._id, action: 'Updated', summary: 'Recipe updated', before, after: item });
        res.status(200).json({ success: true, data: item });
    } catch (error) { next(error); }
};
const parseIds = (values) => {
    if (!Array.isArray(values) || values.length === 0 || values.length > 100) return null;
    const ids = [...new Set(values.map((value) => String(value)))];
    return ids.every((id) => mongoose.Types.ObjectId.isValid(id)) ? ids : null;
};

exports.bulkUpdateMenuItems = async (req, res, next) => {
    try {
        const branchId = String(req.body.branchId || req.user.branchId || '').trim();
        await assertBranchAccess(req.user, branchId);
        const ids = parseIds(req.body.ids);
        if (!ids) return res.status(400).json({ success: false, message: 'Provide 1 to 100 valid menu item IDs' });
        const action = String(req.body.action || '');
        const updates = {};
        let summary = '';
        if (action === 'availability' && typeof req.body.value === 'boolean') {
            updates.isAvailable = req.body.value; summary = `Availability set to ${req.body.value}`;
        } else if (action === 'publish' && ['Draft', 'Published'].includes(req.body.value)) {
            updates.publishStatus = req.body.value; updates.publishAt = null; summary = `Publish status set to ${req.body.value}`;
        } else if (action === 'category' && mongoose.Types.ObjectId.isValid(req.body.value)) {
            const category = await Category.findOne({ _id: req.body.value, restaurantId: req.user.restaurantId, $or: [{ branchId }, { branchId: null }] });
            if (!category) return res.status(400).json({ success: false, message: 'Invalid category for this branch' });
            updates.categoryId = category._id; summary = `Moved to category ${category.name}`;
        } else {
            return res.status(400).json({ success: false, message: 'Invalid bulk action' });
        }
        const before = await MenuItem.find({ _id: { $in: ids }, branchId }).lean();
        if (before.length !== ids.length) return res.status(404).json({ success: false, message: 'Some menu items were not found in this branch' });
        await MenuItem.updateMany({ _id: { $in: ids }, branchId }, { $set: updates }, { runValidators: true });
        const after = await MenuItem.find({ _id: { $in: ids }, branchId }).lean();
        const afterById = new Map(after.map((item) => [String(item._id), item]));
        await Promise.all(before.map((item) => recordMenuAudit({ user: req.user, branchId, resourceType: 'MenuItem', resourceId: item._id, action: 'Bulk Updated', summary, before: item, after: afterById.get(String(item._id)) })));
        res.json({ success: true, count: after.length, data: after });
    } catch (error) { next(error); }
};

exports.duplicateMenuItem = async (req, res, next) => {
    try {
        const source = await MenuItem.findById(req.params.id);
        if (!source) return res.status(404).json({ success: false, message: 'Menu item not found' });
        await assertBranchAccess(req.user, source.branchId);
        const data = source.toObject();
        delete data._id; delete data.__v; delete data.createdAt; delete data.updatedAt;
        data.name = `${source.name} Copy`;
        data.publishStatus = 'Draft'; data.publishAt = null; data.isAvailable = false;
        data.displayOrder = Number(source.displayOrder || 0) + 1;
        const copy = await MenuItem.create(data);
        await recordMenuAudit({ user: req.user, branchId: source.branchId, resourceType: 'MenuItem', resourceId: copy._id, action: 'Duplicated', summary: `Duplicated from ${source.name}`, before: null, after: copy });
        res.status(201).json({ success: true, data: copy });
    } catch (error) { next(error); }
};

exports.reorderMenuItems = async (req, res, next) => {
    try {
        const branchId = String(req.body.branchId || req.user.branchId || '').trim();
        await assertBranchAccess(req.user, branchId);
        const entries = Array.isArray(req.body.items) ? req.body.items : [];
        if (!entries.length || entries.length > 200 || entries.some((entry) => !mongoose.Types.ObjectId.isValid(entry.id) || !Number.isInteger(entry.order) || entry.order < 0)) return res.status(400).json({ success: false, message: 'Provide valid item ordering' });
        const ids = entries.map((entry) => String(entry.id));
        if (new Set(ids).size !== ids.length) return res.status(400).json({ success: false, message: 'Duplicate menu item IDs are not allowed' });
        const before = await MenuItem.find({ _id: { $in: ids }, branchId }).lean();
        if (before.length !== ids.length) return res.status(404).json({ success: false, message: 'Some menu items were not found in this branch' });
        await MenuItem.bulkWrite(entries.map((entry) => ({ updateOne: { filter: { _id: entry.id, branchId }, update: { $set: { displayOrder: entry.order } } } })));
        await Promise.all(before.map((item) => recordMenuAudit({ user: req.user, branchId, resourceType: 'MenuItem', resourceId: item._id, action: 'Reordered', summary: 'Menu display order changed', before: item, after: { ...item, displayOrder: entries.find((entry) => String(entry.id) === String(item._id)).order } })));
        res.json({ success: true, message: 'Menu order updated' });
    } catch (error) { next(error); }
};

exports.reorderCategories = async (req, res, next) => {
    try {
        const branchId = String(req.body.branchId || req.user.branchId || '').trim();
        await assertBranchAccess(req.user, branchId);
        const entries = Array.isArray(req.body.categories) ? req.body.categories : [];
        if (!entries.length || entries.length > 100 || entries.some((entry) => !mongoose.Types.ObjectId.isValid(entry.id) || !Number.isInteger(entry.order) || entry.order < 0)) return res.status(400).json({ success: false, message: 'Provide valid category ordering' });
        const ids = entries.map((entry) => String(entry.id));
        const rows = await Category.find({ _id: { $in: ids }, restaurantId: req.user.restaurantId, $or: [{ branchId }, { branchId: null }] }).lean();
        if (rows.length !== new Set(ids).size) return res.status(404).json({ success: false, message: 'Some categories were not found' });
        await Category.bulkWrite(entries.map((entry) => ({ updateOne: { filter: { _id: entry.id }, update: { $set: { order: entry.order } } } })));
        await Promise.all(rows.map((category) => recordMenuAudit({ user: req.user, branchId, resourceType: 'Category', resourceId: category._id, action: 'Reordered', summary: 'Category order changed', before: category, after: { ...category, order: entries.find((entry) => String(entry.id) === String(category._id)).order } })));
        res.json({ success: true, message: 'Category order updated' });
    } catch (error) { next(error); }
};

exports.getMenuHistory = async (req, res, next) => {
    try {
        const branchId = String(req.query.branchId || req.user.branchId || '').trim();
        await assertBranchAccess(req.user, branchId);
        const query = { restaurantId: req.user.restaurantId, branchId };
        if (req.query.itemId) {
            if (!mongoose.Types.ObjectId.isValid(req.query.itemId)) return res.status(400).json({ success: false, message: 'Invalid itemId' });
            query.resourceId = req.query.itemId;
        }
        const limit = Math.min(100, Math.max(1, Number(req.query.limit) || 50));
        const history = await MenuAudit.find(query).populate('actorId', 'name').sort({ createdAt: -1 }).limit(limit).lean();
        res.json({ success: true, count: history.length, data: history });
    } catch (error) { next(error); }
};

exports.restoreMenuHistory = async (req, res, next) => {
    try {
        const audit = await MenuAudit.findOne({ _id: req.params.id, restaurantId: req.user.restaurantId });
        if (!audit) return res.status(404).json({ success: false, message: 'Menu history entry not found' });
        await assertBranchAccess(req.user, audit.branchId);
        if (!audit.before) return res.status(409).json({ success: false, message: 'This history entry has no previous state to restore' });
        const Model = audit.resourceType === 'Category' ? Category : MenuItem;
        const current = await Model.findById(audit.resourceId).lean();
        const restored = snapshot(audit.before);
        delete restored._id; delete restored.__v; delete restored.createdAt; delete restored.updatedAt;
        const document = await Model.findOneAndUpdate({ _id: audit.resourceId }, { $set: restored }, { upsert: true, new: true, runValidators: true, setDefaultsOnInsert: true });
        await recordMenuAudit({ user: req.user, branchId: audit.branchId, resourceType: audit.resourceType, resourceId: audit.resourceId, action: 'Restored', summary: `Restored from ${audit.action}`, before: current, after: document });
        res.json({ success: true, data: document });
    } catch (error) { next(error); }
};
