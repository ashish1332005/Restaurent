import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/animations/flutterfx/animated_price_ticker.dart';
import '../../core/animations/flutterfx/bouncy_tap.dart';

class FloatingCartBar extends StatelessWidget {
  const FloatingCartBar({
    super.key,
    required this.itemCount,
    required this.subtotal,
    required this.onViewCart,
    this.preferHindi = false,
  });

  final int itemCount;
  final double subtotal;
  final VoidCallback onViewCart;
  final bool preferHindi;

  @override
  Widget build(BuildContext context) {
    if (itemCount <= 0) return const SizedBox.shrink();

    const ink = Color(0xFF071A31);
    const saffron = Color(0xFFC99232);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: BouncyTap(
          onTap: onViewCart,
          scaleDown: 0.97,
          child: Container(
            height: 62,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: ink,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x3D071A31),
                  blurRadius: 18,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                // Item count & subtotal
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.shopping_bag_outlined,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          '$itemCount ${itemCount == 1 ? (preferHindi ? 'आइटम' : 'ITEM') : (preferHindi ? 'आइटम्स' : 'ITEMS')} | ',
                          style: GoogleFonts.dmSans(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.3,
                          ),
                        ),
                        AnimatedPriceTicker(
                          amount: subtotal,
                          prefix: '₹',
                          style: GoogleFonts.dmSans(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      preferHindi ? 'अतिरिक्त कर शामिल नहीं' : 'Taxes applicable at checkout',
                      style: GoogleFonts.dmSans(
                        color: Colors.white60,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                // View Cart CTA
                Row(
                  children: [
                    Text(
                      preferHindi ? 'कार्ट देखें' : 'View Cart',
                      style: GoogleFonts.dmSans(
                        color: saffron,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(
                      Icons.arrow_forward_rounded,
                      color: saffron,
                      size: 18,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
