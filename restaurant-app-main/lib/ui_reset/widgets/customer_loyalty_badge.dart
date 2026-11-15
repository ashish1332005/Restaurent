import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CustomerLoyaltyBadge extends StatelessWidget {
  const CustomerLoyaltyBadge({
    super.key,
    required this.customerName,
    required this.loyaltyPoints,
    required this.visitCount,
    this.onTap,
  });

  final String customerName;
  final int loyaltyPoints;
  final int visitCount;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    const saffron = Color(0xFFC99232);

    final tier = visitCount >= 10
        ? 'Platinum Diner 👑'
        : visitCount >= 4
            ? 'Gold Diner 🌟'
            : visitCount >= 1
                ? 'Silver Guest ✨'
                : 'Welcome Guest 🎉';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF2A1A14), Color(0xFF452C22)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1A000000),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: saffron.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: saffron.withValues(alpha: 0.5)),
              ),
              child: const Center(
                child: Text(
                  '🪙',
                  style: TextStyle(fontSize: 22),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          customerName.isNotEmpty
                              ? 'Namaste, $customerName'
                              : 'Loyalty Rewards',
                          style: GoogleFonts.dmSans(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFC99232),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          tier,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    loyaltyPoints > 0
                        ? '$loyaltyPoints Reward Coins • Redeem ₹$loyaltyPoints at checkout'
                        : 'Earn 5% cashback coins on today\'s meal',
                    style: GoogleFonts.dmSans(
                      color: const Color(0xFFFFE3B0),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
