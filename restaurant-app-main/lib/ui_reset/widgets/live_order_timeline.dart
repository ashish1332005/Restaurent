import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/animations/flutterfx/bouncy_tap.dart';
import '../../core/animations/flutterfx/pulsing_badge.dart';

class LiveOrderTimeline extends StatelessWidget {
  const LiveOrderTimeline({
    super.key,
    required this.order,
    required this.onRefresh,
    required this.onServiceRequest,
    required this.onRequestBill,
    required this.onSendWhatsAppBill,
    required this.onGiveFeedback,
    required this.preferHindi,
  });

  final Map<String, dynamic> order;
  final VoidCallback onRefresh;
  final void Function(String type) onServiceRequest;
  final VoidCallback onRequestBill;
  final VoidCallback onSendWhatsAppBill;
  final VoidCallback onGiveFeedback;
  final bool preferHindi;

  @override
  Widget build(BuildContext context) {
    const saffron = Color(0xFFC99232);
    const ink = Color(0xFF071A31);
    const leaf = Color(0xFF237A59);

    final status = '${order['status'] ?? 'Placed'}';
    final items = ((order['items'] as List?) ?? const []).whereType<Map>().toList();
    final total = (order['total'] as num?)?.toDouble() ?? 0;

    final stages = [
      ('Placed', '📝', 'Order Placed'),
      ('Accepted', '👨‍🍳', 'Kitchen Accepted'),
      ('Preparing', '🔥', 'Cooking Your Food'),
      ('Ready', '🍽️', 'Ready to Serve'),
      ('Served', '🎉', 'Served on Table'),
    ];

    int currentIndex = stages.indexWhere((s) => s.$1.toLowerCase() == status.toLowerCase());
    if (currentIndex == -1) {
      if (status == 'Paid' || status == 'Completed' || status == 'Bill Requested') {
        currentIndex = stages.length - 1;
      } else {
        currentIndex = 0;
      }
    }

    final isServedOrCompleted = status == 'Served' || status == 'Completed' || status == 'Paid';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE8F5E9), width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12237A59),
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with Pulsing Live Beacon
          Row(
            children: [
              const PulsingBadge(
                color: leaf,
                size: 9,
                ringScale: 2.6,
              ),
              const SizedBox(width: 8),
              Text(
                preferHindi ? 'लाइव ऑर्डर स्टेटस' : 'LIVE ORDER TRACKING',
                style: GoogleFonts.dmSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0,
                  color: leaf,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: onRefresh,
                icon: const Icon(Icons.refresh_rounded, size: 20, color: leaf),
                tooltip: 'Refresh status',
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            stages[currentIndex].$3,
            style: GoogleFonts.playfairDisplay(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: ink,
            ),
          ),
          const SizedBox(height: 14),

          // 5-Stage Stepper
          Row(
            children: List.generate(stages.length, (index) {
              final isDone = index <= currentIndex;
              final isCurrent = index == currentIndex;
              return Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: isDone ? leaf : const Color(0xFFF0EAE1),
                              shape: BoxShape.circle,
                              border: isCurrent
                                  ? Border.all(color: saffron, width: 2.5)
                                  : null,
                              boxShadow: isCurrent
                                  ? [
                                      BoxShadow(
                                        color: saffron.withValues(alpha: 0.4),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Center(
                              child: isDone
                                  ? (isCurrent
                                      ? Text(stages[index].$2, style: const TextStyle(fontSize: 14))
                                      : const Icon(Icons.check, size: 16, color: Colors.white))
                                  : Text(
                                      '${index + 1}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.black38,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            stages[index].$1,
                            style: GoogleFonts.dmSans(
                              fontSize: 9,
                              fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w500,
                              color: isDone ? ink : Colors.black38,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    if (index < stages.length - 1)
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: 14,
                        height: 2,
                        color: index < currentIndex ? leaf : const Color(0xFFE0D8CE),
                      ),
                  ],
                ),
              );
            }),
          ),
          const SizedBox(height: 16),

          // Running Items Preview
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFBF8F3),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Running Bill (${items.length} items)',
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.black54,
                      ),
                    ),
                    Text(
                      '₹${total.toStringAsFixed(0)}',
                      style: GoogleFonts.dmSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: leaf,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ...items.take(3).map((item) {
                  final rawName = item['name'] ?? (item['menuItem'] is Map ? item['menuItem']['name'] : 'Item');
                  final qty = item['quantity'] ?? 1;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Text(
                      '• $rawName x$qty',
                      style: GoogleFonts.dmSans(fontSize: 12, color: ink),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }),
                if (items.length > 3)
                  Text(
                    '+${items.length - 3} more items',
                    style: const TextStyle(fontSize: 11, color: Colors.black45),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Service Requests Row
          Row(
            children: [
              _serviceBtn(Icons.water_drop_outlined, 'Water', () => onServiceRequest('Water')),
              const SizedBox(width: 8),
              _serviceBtn(Icons.room_service_outlined, 'Waiter', () => onServiceRequest('Waiter')),
              const SizedBox(width: 8),
              _serviceBtn(Icons.restaurant_outlined, 'Cutlery', () => onServiceRequest('Cutlery')),
              const SizedBox(width: 8),
              _serviceBtn(Icons.receipt_long_outlined, 'Bill', onRequestBill),
            ],
          ),
          const SizedBox(height: 12),

          // Actions Row (WhatsApp Bill & Feedback)
          Row(
            children: [
              Expanded(
                child: BouncyTap(
                  onTap: onSendWhatsAppBill,
                  child: Container(
                    height: 42,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF25D366)),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.send_rounded, size: 16, color: Color(0xFF25D366)),
                        SizedBox(width: 6),
                        Text(
                          'WhatsApp Bill',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1E7E34),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (isServedOrCompleted) ...[
                const SizedBox(width: 10),
                Expanded(
                  child: BouncyTap(
                    onTap: onGiveFeedback,
                    child: Container(
                      height: 42,
                      decoration: BoxDecoration(
                        color: saffron,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x33C99232),
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.star_rounded, size: 18, color: Colors.white),
                          SizedBox(width: 6),
                          Text(
                            'Rate Dining',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _serviceBtn(IconData icon, String label, VoidCallback onTap) => Expanded(
        child: BouncyTap(
          onTap: onTap,
          scaleDown: 0.90,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF9ED),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFFE0A3)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 18, color: const Color(0xFFC99232)),
                const SizedBox(height: 3),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF071A31),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}
