const crypto = require('crypto');
const hashTableQrToken = (token) => crypto.createHash('sha256').update(String(token || '')).digest('hex');
const createTableQrToken = () => {
    const token = crypto.randomBytes(32).toString('base64url');
    return { token, tokenHash: hashTableQrToken(token) };
};
module.exports = { createTableQrToken, hashTableQrToken };