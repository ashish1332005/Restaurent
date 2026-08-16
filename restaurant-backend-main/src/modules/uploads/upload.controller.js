const crypto = require('crypto');
const fs = require('fs/promises');
const path = require('path');

const uploadDirectory = path.resolve(__dirname, '../../../uploads');
const extensions = Object.freeze({
    'image/jpeg': '.jpg',
    'image/png': '.png',
    'image/webp': '.webp'
});

exports.saveImage = async (req, res, next) => {
    try {
        if (!req.file) return res.status(400).json({ success: false, message: 'Choose a JPEG, PNG or WebP image' });
        const extension = extensions[req.file.mimetype];
        if (!extension) return res.status(415).json({ success: false, message: 'Only JPEG, PNG and WebP images are allowed' });
        await fs.mkdir(uploadDirectory, { recursive: true });
        const fileName = `${Date.now()}-${crypto.randomBytes(12).toString('hex')}${extension}`;
        await fs.writeFile(path.join(uploadDirectory, fileName), req.file.buffer, { flag: 'wx' });
        res.status(201).json({ success: true, data: { url: '/uploads/' + fileName } });
    } catch (error) {
        next(error);
    }
};