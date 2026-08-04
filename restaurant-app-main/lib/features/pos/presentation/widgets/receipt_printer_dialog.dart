import 'package:flutter/material.dart';

class ReceiptPrinterDialog extends StatelessWidget {
  const ReceiptPrinterDialog({
    super.key,
    required this.orderId,
    required this.tableNo,
    required this.waiterName,
    required this.items,
    required this.subtotal,
    required this.cgst,
    required this.sgst,
    required this.total,
    required this.paymentMethod,
    this.restaurantName = 'The Royal Spices Restaurant',
    this.gstin = '07AAAAA0000A1Z5',
    this.fssai = '10021011000432',
  });

  final String orderId;
  final String tableNo;
  final String waiterName;
  final List<Map<String, dynamic>> items;
  final double subtotal;
  final double cgst;
  final double sgst;
  final double total;
  final String paymentMethod;
  final String restaurantName;
  final String gstin;
  final String fssai;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: Colors.white,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.print_rounded, color: Color(0xFF4B6BFB), size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Thermal Bill Preview',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Thermal Receipt Slip Layout (Simulating 80mm paper)
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFFAFAFA),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Restaurant Branding
                    Text(
                      restaurantName.toUpperCase(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'Monospace',
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                        color: Color(0xFF0F172A),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Sector 18, Block B, Main Road',
                      style: TextStyle(fontFamily: 'Monospace', fontSize: 11, color: Color(0xFF64748B)),
                    ),
                    Text(
                      'GSTIN: $gstin | FSSAI: $fssai',
                      style: const TextStyle(fontFamily: 'Monospace', fontSize: 10, color: Color(0xFF64748B)),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      '- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -',
                      style: TextStyle(fontFamily: 'Monospace', color: Color(0xFF94A3B8)),
                    ),
                    const SizedBox(height: 8),

                    // Order Info Grid
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Bill No: $orderId', style: const TextStyle(fontFamily: 'Monospace', fontSize: 12, fontWeight: FontWeight.bold)),
                        Text('Table: $tableNo', style: const TextStyle(fontFamily: 'Monospace', fontSize: 12, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Staff: $waiterName', style: const TextStyle(fontFamily: 'Monospace', fontSize: 11, color: Color(0xFF64748B))),
                        Text(
                          '${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}',
                          style: const TextStyle(fontFamily: 'Monospace', fontSize: 11, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -',
                      style: TextStyle(fontFamily: 'Monospace', color: Color(0xFF94A3B8)),
                    ),
                    const SizedBox(height: 8),

                    // Items Table
                    Row(
                      children: const [
                        Expanded(flex: 3, child: Text('ITEM', style: TextStyle(fontFamily: 'Monospace', fontSize: 11, fontWeight: FontWeight.bold))),
                        Expanded(child: Text('QTY', textAlign: TextAlign.center, style: TextStyle(fontFamily: 'Monospace', fontSize: 11, fontWeight: FontWeight.bold))),
                        Expanded(child: Text('AMT', textAlign: TextAlign.right, style: TextStyle(fontFamily: 'Monospace', fontSize: 11, fontWeight: FontWeight.bold))),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ...items.map((item) {
                      final name = item['name'] ?? 'Item';
                      final qty = item['qty'] ?? item['quantity'] ?? 1;
                      final price = (item['price'] ?? 0).toDouble();
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          children: [
                            Expanded(flex: 3, child: Text(name, style: const TextStyle(fontFamily: 'Monospace', fontSize: 11))),
                            Expanded(child: Text('$qty', textAlign: TextAlign.center, style: const TextStyle(fontFamily: 'Monospace', fontSize: 11))),
                            Expanded(child: Text('${(price * qty).toInt()}', textAlign: TextAlign.right, style: const TextStyle(fontFamily: 'Monospace', fontSize: 11))),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: 8),
                    const Text(
                      '- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -',
                      style: TextStyle(fontFamily: 'Monospace', color: Color(0xFF94A3B8)),
                    ),

                    // Totals & Taxes
                    _receiptRow('Subtotal', '₹${subtotal.toInt()}'),
                    _receiptRow('CGST (2.5%)', '₹${cgst.toStringAsFixed(1)}'),
                    _receiptRow('SGST (2.5%)', '₹${sgst.toStringAsFixed(1)}'),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('NET TOTAL', style: TextStyle(fontFamily: 'Monospace', fontSize: 14, fontWeight: FontWeight.w900)),
                        Text('₹${total.toInt()}', style: const TextStyle(fontFamily: 'Monospace', fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF1FA971))),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Payment Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1FA971).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'PAID VIA ${paymentMethod.toUpperCase()}',
                        style: const TextStyle(
                          fontFamily: 'Monospace',
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1FA971),
                          fontSize: 11,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Thank You! Please Visit Again',
                      style: TextStyle(fontFamily: 'Monospace', fontSize: 11, fontStyle: FontStyle.italic, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded, size: 16),
                      label: const Text('Close'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('🖨️ Thermal Receipt sent to Bluetooth/USB Printer!'),
                            backgroundColor: Color(0xFF1FA971),
                          ),
                        );
                        Navigator.of(context).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1FA971),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.print_rounded, size: 18),
                      label: const Text('Print Receipt (80mm)'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _receiptRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontFamily: 'Monospace', fontSize: 11, color: Color(0xFF64748B))),
          Text(value, style: const TextStyle(fontFamily: 'Monospace', fontSize: 11, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
