const express = require('express');
const multer = require('multer');
const { protect } = require('../../middlewares/auth.middleware');
const { authorize } = require('../../middlewares/rbac.middleware');
const { requireActiveSubscription } = require('../../middlewares/subscription.middleware');
const { saveImage } = require('./upload.controller');

const router = express.Router();
const upload = multer({
    storage: multer.memoryStorage(),
    limits: { fileSize: 3 * 1024 * 1024, files: 1 },
    fileFilter: (_req, file, callback) => {
        const allowed = ['image/jpeg', 'image/png', 'image/webp'].includes(file.mimetype);
        callback(allowed ? null : new Error('Only JPEG, PNG and WebP images are allowed'), allowed);
    }
});

router.post('/images', protect, requireActiveSubscription, authorize('Restaurant Admin', 'Manager'), upload.single('image'), saveImage);

module.exports = router;