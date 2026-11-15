/**
 * Notification & WhatsApp Digital Invoicing Service
 */

const Order = require('../models/Order.model');
const Branch = require('../models/Branch.model');
const Restaurant = require('../models/Restaurant.model');
const Invoice = require('../models/Invoice.model');

const formatMoney = (val) => `₹${Number(val || 0).toFixed(2)}`;

/**
 * Generates an interactive WhatsApp invoice message and wa.me deep link
 */
const generateWhatsAppInvoice = async (orderId) => {
    const order = await Order.findById(orderId)
        .populate('tableId', 'name')
        .populate('items.menuItem', 'name');
    if (!order) throw new Error('Order not found');

    const branch = await Branch.findById(order.branchId).lean();
    const restaurant = branch ? await Restaurant.findById(branch.restaurantId).lean() : null;
    const invoice = await Invoice.findOne({ orderId: order._id }).lean();

    const restName = restaurant?.name || branch?.name || 'Our Restaurant';
    const tableName = order.tableId?.name ? `Table ${order.tableId.name}` : (order.orderType || 'Dine-In');

    let msg = `🧾 *${restName.toUpperCase()} - DIGITAL BILL*\n`;
    if (branch?.location?.address) msg += `📍 ${branch.location.address}\n`;
    if (branch?.contact?.phone) msg += `📞 Phone: ${branch.contact.phone}\n`;
    if (branch?.gstNumber) msg += `🏛️ GSTIN: ${branch.gstNumber}\n`;
    msg += `--------------------------------\n`;
    msg += `*Bill No:* #${String(order._id).slice(-6).toUpperCase()}\n`;
    msg += `*Order for:* ${tableName}\n`;
    msg += `*Date:* ${new Date(order.createdAt).toLocaleDateString('en-IN')} ${new Date(order.createdAt).toLocaleTimeString('en-IN', { hour: '2-digit', minute: '2-digit' })}\n`;
    if (order.customerName) msg += `*Customer:* ${order.customerName}\n`;
    msg += `--------------------------------\n`;
    msg += `*ITEMS ORDERED:*\n`;

    (order.items || []).forEach((item) => {
        const name = item.menuItem?.name || item.name || 'Dish';
        const variant = item.selectedVariant ? ` (${item.selectedVariant})` : '';
        const qty = item.quantity || 1;
        const total = formatMoney((item.price || 0) * qty);
        msg += `• ${qty}x ${name}${variant} - ${total}\n`;
    });

    msg += `--------------------------------\n`;
    msg += `*Subtotal:* ${formatMoney(order.subTotal)}\n`;
    if (order.discount > 0) {
        msg += `*Discount${order.couponCode ? ` (${order.couponCode})` : ''}:* -${formatMoney(order.discount)}\n`;
    }
    if (order.tax > 0) {
        msg += `*Taxes (GST):* +${formatMoney(order.tax)}\n`;
    }
    msg += `*TOTAL AMOUNT:* *${formatMoney(order.total)}*\n`;
    msg += `*Payment Status:* ${order.paymentStatus === 'Paid' ? 'PAID ✅' : 'PENDING ⏳'}\n`;
    if (invoice?.paymentMethod) {
        msg += `*Paid via:* ${invoice.paymentMethod.toUpperCase()}\n`;
    }
    msg += `--------------------------------\n`;
    msg += `🙏 *${branch?.invoiceFooter || 'Thank you for dining with us! Visit again.'}*\n`;

    const cleanPhone = String(order.customerPhone || '').replace(/\D/g, '').slice(-10);
    const targetPhone = cleanPhone ? `91${cleanPhone}` : '';
    const shareUrl = `https://wa.me/${targetPhone}?text=${encodeURIComponent(msg)}`;

    return {
        message: msg,
        shareUrl,
        customerPhone: cleanPhone,
        total: order.total
    };
};

/**
 * Generates an end-of-day summary report for the restaurant owner
 */
const generateDailyOwnerDigest = async (restaurantId, branchId, date = new Date()) => {
    const start = new Date(date);
    start.setHours(0, 0, 0, 0);
    const end = new Date(date);
    end.setHours(23, 59, 59, 999);

    const query = {
        branchId,
        createdAt: { $gte: start, $lte: end }
    };

    const orders = await Order.find(query)
        .populate('items.menuItem', 'name')
        .lean();

    const paidOrders = orders.filter((o) => o.paymentStatus === 'Paid');
    const totalSales = Math.round(paidOrders.reduce((sum, o) => sum + o.total, 0) * 100) / 100;
    const totalDiscounts = Math.round(paidOrders.reduce((sum, o) => sum + (o.discount || 0), 0) * 100) / 100;
    const totalTax = Math.round(paidOrders.reduce((sum, o) => sum + (o.tax || 0), 0) * 100) / 100;

    // Top selling items
    const itemMap = new Map();
    for (const o of paidOrders) {
        for (const it of o.items || []) {
            const name = it.menuItem?.name || 'Dish';
            itemMap.set(name, (itemMap.get(name) || 0) + it.quantity);
        }
    }
    const topDishes = [...itemMap.entries()]
        .sort((a, b) => b[1] - a[1])
        .slice(0, 5)
        .map(([name, qty]) => `${name} (${qty})`);

    const branch = await Branch.findById(branchId).lean();
    const branchName = branch?.name || 'Restaurant';

    let digest = `📊 *DAILY SALES DIGEST - ${branchName.toUpperCase()}*\n`;
    digest += `📅 Date: ${start.toLocaleDateString('en-IN')}\n`;
    digest += `--------------------------------\n`;
    digest += `💰 *Total Sales:* ${formatMoney(totalSales)}\n`;
    digest += `🧾 *Total Paid Orders:* ${paidOrders.length}\n`;
    digest += `🎁 *Discounts Given:* ${formatMoney(totalDiscounts)}\n`;
    digest += `🏛️ *Taxes Collected:* ${formatMoney(totalTax)}\n`;
    digest += `--------------------------------\n`;
    if (topDishes.length) {
        digest += `🔥 *Top Selling Dishes:*\n${topDishes.map((d, i) => ` ${i + 1}. ${d}`).join('\n')}\n`;
        digest += `--------------------------------\n`;
    }
    digest += `Report auto-generated by Restaurant Automation.`;

    return {
        summary: {
            date: start,
            totalSales,
            paidOrderCount: paidOrders.length,
            totalOrdersCount: orders.length,
            totalDiscounts,
            totalTax,
            topDishes
        },
        formattedMessage: digest
    };
};

/**
 * Dispatch or mock SMS/OTP
 */
const sendOtp = async (phone, otp) => {
    // In production, integrate Fast2SMS, Twilio, or MSG91 here using environment variables
    console.log(`[OTP DISPATCH] Sent OTP: ${otp} to phone: +91${phone}`);
    return { success: true, phone, mode: process.env.SMS_PROVIDER ? 'live' : 'mock' };
};

module.exports = {
    generateWhatsAppInvoice,
    generateDailyOwnerDigest,
    sendOtp
};
