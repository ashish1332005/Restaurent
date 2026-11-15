const mongoose = require('mongoose');

const dishFeedbackSchema = new mongoose.Schema({
    menuItemId: { type: mongoose.Schema.Types.ObjectId, ref: 'MenuItem' },
    name: { type: String, trim: true },
    isLiked: { type: Boolean, default: true }
}, { _id: false });

const feedbackSchema = new mongoose.Schema({
    restaurantId: { type: mongoose.Schema.Types.ObjectId, ref: 'Restaurant', required: true, index: true },
    branchId: { type: mongoose.Schema.Types.ObjectId, ref: 'Branch', required: true, index: true },
    tableId: { type: mongoose.Schema.Types.ObjectId, ref: 'Table' },
    orderId: { type: mongoose.Schema.Types.ObjectId, ref: 'Order' },
    customerName: { type: String, trim: true, default: 'Guest' },
    customerPhone: { type: String, trim: true, default: '' },
    rating: { type: Number, required: true, min: 1, max: 5, index: true },
    foodRating: { type: Number, min: 1, max: 5, default: null },
    serviceRating: { type: Number, min: 1, max: 5, default: null },
    ambienceRating: { type: Number, min: 1, max: 5, default: null },
    comments: { type: String, trim: true, maxlength: 1000, default: '' },
    dishRatings: { type: [dishFeedbackSchema], default: [] },
    status: { type: String, enum: ['New', 'Reviewed', 'Resolved'], default: 'New', index: true }
}, { timestamps: true });

module.exports = mongoose.model('Feedback', feedbackSchema);
