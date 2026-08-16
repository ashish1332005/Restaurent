const mongoose = require('mongoose');

const orderItemSchema = new mongoose.Schema({
    menuItem: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'MenuItem',
        required: true
    },
    quantity: {
        type: Number,
        required: true,
        min: 1
    },
    price: {
        type: Number,
        required: true,
        min: 0
    },
    selectedVariant: String,
    selectedAddOns: [String],
    notes: String,
    status: {
        type: String,
        enum: ['Pending', 'Preparing', 'Ready', 'Served'],
        default: 'Pending'
    }
});

const orderSchema = new mongoose.Schema({
    branchId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Branch',
        required: true
    },
    tableId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Table' // optional, null for delivery/takeaway
    },
    userId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
        required: function requiredUserForStaffOrders() {
            return this.source !== 'CustomerQR';
        }
    },
    source: {
        type: String,
        enum: ['Admin', 'Waiter', 'Cashier', 'CustomerApp', 'CustomerQR'],
        default: 'Waiter'
    },
    customerName: {
        type: String,
        trim: true,
        default: ''
    },
    customerPhone: {
        type: String,
        trim: true,
        default: ''
    },
    orderType: {
        type: String,
        enum: ['Dine-In', 'Takeaway', 'Delivery'],
        default: 'Dine-In'
    },
    items: {
        type: [orderItemSchema],
        validate: {
            validator(items) {
                return Array.isArray(items) && items.length > 0;
            },
            message: 'Order must contain at least one item'
        }
    },
    subTotal: {
        type: Number,
        required: true,
        min: 0
    },
    tax: {
        type: Number,
        default: 0,
        min: 0
    },
    discount: {
        type: Number,
        default: 0,
        min: 0
    },
    total: {
        type: Number,
        required: true,
        min: 0
    },
    status: {
        type: String,
        enum: ['Pending', 'Accepted', 'Preparing', 'Ready', 'Served', 'Customer Finished', 'Bill Requested', 'Paid', 'Cancelled'],
        default: 'Pending'
    },
    paymentStatus: {
        type: String,
        enum: ['Unpaid', 'Paid', 'Refunded'],
        default: 'Unpaid'
    },
    kitchenNotes: String,
    inventoryConsumed: { type: Boolean, default: false }
}, {
    timestamps: true
});

module.exports = mongoose.model('Order', orderSchema);

