/**
 * Thermal Printer Receipt & KOT Engine
 * Generates formatted text & structured JSON ready for 80mm (48 cols) and 58mm (32 cols) ESC/POS printers.
 */

const padRight = (str, len) => {
    const s = String(str || '');
    return s.length >= len ? s.slice(0, len) : s + ' '.repeat(len - s.length);
};

const padLeft = (str, len) => {
    const s = String(str || '');
    return s.length >= len ? s.slice(0, len) : ' '.repeat(len - s.length) + s;
};

const center = (str, width) => {
    const s = String(str || '').trim();
    if (s.length >= width) return s.slice(0, width);
    const leftPad = Math.floor((width - s.length) / 2);
    return ' '.repeat(leftPad) + s + ' '.repeat(width - s.length - leftPad);
};

const divider = (char = '-', width = 48) => char.repeat(width);

const formatDate = (date) => {
    const d = new Date(date || Date.now());
    return d.toLocaleString('en-IN', { timeZone: 'Asia/Kolkata', hour12: true });
};

/**
 * Generates ESC/POS compatible text and structured payload for Kitchen Order Ticket (KOT)
 */
const generateKotReceipt = (order, branch = {}, options = {}) => {
    const width = options.width === 58 ? 32 : 48;
    const lines = [];

    lines.push(center('*** KITCHEN ORDER TICKET (KOT) ***', width));
    lines.push(divider('=', width));
    lines.push(`KOT / Order ID: ${String(order._id).slice(-6).toUpperCase()}`);
    lines.push(`Table: ${order.tableId?.name || (order.orderType === 'Takeaway' ? 'TAKEAWAY' : 'DELIVERY')}`);
    lines.push(`Type: ${order.orderType || 'Dine-In'}  |  Source: ${order.source || 'POS'}`);
    lines.push(`Time: ${formatDate(order.createdAt)}`);
    if (order.customerName) lines.push(`Customer: ${order.customerName}`);
    lines.push(divider('-', width));

    if (width === 48) {
        lines.push('QTY  ITEM DESCRIPTION                    NOTES  ');
    } else {
        lines.push('QTY  ITEM DESCRIPTION           ');
    }
    lines.push(divider('-', width));

    let totalQty = 0;
    (order.items || []).forEach((item) => {
        const qty = item.quantity || 1;
        totalQty += qty;
        const name = item.menuItem?.name || item.name || 'Menu Item';
        const variant = item.selectedVariant ? ` (${item.selectedVariant})` : '';
        const addOns = (item.selectedAddOns && item.selectedAddOns.length) ? ` + [${item.selectedAddOns.join(', ')}]` : '';
        const fullItemName = `${name}${variant}${addOns}`;

        const qtyStr = padRight(`${qty}x`, 5);
        if (width === 48) {
            lines.push(`${qtyStr}${padRight(fullItemName, 35)}`);
            if (item.notes) lines.push(`     *Note: ${item.notes}`);
        } else {
            lines.push(`${qtyStr}${fullItemName}`);
            if (item.notes) lines.push(`  *Note: ${item.notes}`);
        }
    });

    lines.push(divider('-', width));
    lines.push(`Total Items Count: ${totalQty}`);
    if (order.kitchenNotes) {
        lines.push(divider('~', width));
        lines.push(`SPECIAL INSTRUCTIONS:\n${order.kitchenNotes}`);
    }
    lines.push(divider('=', width));
    lines.push('\n\n\n'); // Feed lines for paper cut

    return {
        type: 'KOT',
        orderId: order._id,
        table: order.tableId?.name || order.orderType,
        totalItems: totalQty,
        timestamp: order.createdAt,
        rawText: lines.join('\n'),
        items: order.items
    };
};

/**
 * Generates ESC/POS compatible text and structured payload for Final Customer Bill
 */
const generateBillReceipt = (order, invoice = {}, branch = {}, restaurant = {}, options = {}) => {
    const width = options.width === 58 ? 32 : 48;
    const lines = [];

    const restName = restaurant?.name || branch?.name || 'Restaurant';
    lines.push(center(restName.toUpperCase(), width));
    if (branch?.location?.address) lines.push(center(branch.location.address, width));
    if (branch?.contact?.phone) lines.push(center(`Phone: ${branch.contact.phone}`, width));
    if (branch?.gstNumber) lines.push(center(`GSTIN: ${branch.gstNumber}`, width));
    if (branch?.fssaiNumber) lines.push(center(`FSSAI Lic: ${branch.fssaiNumber}`, width));
    if (branch?.invoiceHeader) lines.push(center(branch.invoiceHeader, width));

    lines.push(divider('=', width));
    lines.push(`Bill No: ${invoice?.transactionId || String(order._id).slice(-6).toUpperCase()}`);
    lines.push(`Table: ${order.tableId?.name || order.orderType || 'Dine-In'}`);
    lines.push(`Date: ${formatDate(invoice?.createdAt || order.updatedAt || Date.now())}`);
    if (order.customerName) lines.push(`Customer: ${order.customerName} (${order.customerPhone || ''})`);
    lines.push(divider('-', width));

    if (width === 48) {
        lines.push('ITEM NAME                 QTY    PRICE    TOTAL');
    } else {
        lines.push('ITEM              QTY     AMT');
    }
    lines.push(divider('-', width));

    (order.items || []).forEach((item) => {
        const qty = item.quantity || 1;
        const rate = (item.price || 0).toFixed(2);
        const lineTotal = ((item.price || 0) * qty).toFixed(2);
        const name = item.menuItem?.name || item.name || 'Item';
        const variant = item.selectedVariant ? ` (${item.selectedVariant})` : '';
        const itemLabel = `${name}${variant}`;

        if (width === 48) {
            lines.push(
                padRight(itemLabel.slice(0, 24), 25) +
                padLeft(qty, 5) +
                padLeft(rate, 9) +
                padLeft(lineTotal, 9)
            );
        } else {
            lines.push(
                padRight(itemLabel.slice(0, 16), 17) +
                padLeft(qty, 4) +
                padLeft(lineTotal, 11)
            );
        }
    });

    lines.push(divider('-', width));

    const addSummaryLine = (label, val) => {
        const valStr = `INR ${Number(val || 0).toFixed(2)}`;
        lines.push(padRight(label, width - valStr.length) + valStr);
    };

    addSummaryLine('Sub Total:', order.subTotal);
    if (order.discount > 0) {
        addSummaryLine(`Discount${order.couponCode ? ` (${order.couponCode})` : ''}:`, -order.discount);
    }
    if (order.tax > 0) {
        addSummaryLine('Taxes (GST):', order.tax);
    }

    lines.push(divider('=', width));
    const grandTotalStr = `INR ${Number(order.total || 0).toFixed(2)}`;
    lines.push(padRight('GRAND TOTAL:', width - grandTotalStr.length) + grandTotalStr);
    lines.push(divider('=', width));

    const paymentMethod = invoice?.paymentMethod || order.paymentMethod || (order.paymentStatus === 'Paid' ? 'Paid' : 'Unpaid');
    lines.push(`Payment Mode: ${paymentMethod.toUpperCase()}`);
    lines.push(`Status: ${order.paymentStatus === 'Paid' ? 'PAID' : 'PENDING'}`);

    // Generate UPI Dynamic QR string if UPI ID is present
    let upiString = '';
    if (branch?.upiId) {
        upiString = `upi://pay?pa=${encodeURIComponent(branch.upiId)}&pn=${encodeURIComponent(restName)}&am=${encodeURIComponent(order.total)}&tn=${encodeURIComponent(`Bill-${String(order._id).slice(-6)}`)}&cu=INR`;
        lines.push(divider('-', width));
        lines.push(center('Scan UPI QR to Pay', width));
    }

    lines.push(divider('-', width));
    lines.push(center(branch?.invoiceFooter || 'Thank You! Visit Again.', width));
    lines.push('\n\n\n'); // Feed lines

    return {
        type: 'FINAL_BILL',
        orderId: order._id,
        invoiceId: invoice?._id,
        table: order.tableId?.name || order.orderType,
        subTotal: order.subTotal,
        tax: order.tax,
        discount: order.discount,
        couponCode: order.couponCode,
        grandTotal: order.total,
        paymentStatus: order.paymentStatus,
        paymentMethod,
        upiString,
        rawText: lines.join('\n')
    };
};

module.exports = {
    generateKotReceipt,
    generateBillReceipt
};
