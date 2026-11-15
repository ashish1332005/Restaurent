import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/animations/flutterfx/animated_price_ticker.dart';
import '../../core/animations/flutterfx/bouncy_tap.dart';
import '../../core/animations/flutterfx/shimmer_box.dart';
import '../../core/network/restaurant_api.dart';
import 'veg_non_veg_badge.dart';

class HighlightsCarousel extends StatelessWidget {
  const HighlightsCarousel({
    super.key,
    required this.title,
    required this.subtitle,
    required this.items,
    required this.onAddItem,
    required this.preferHindi,
    this.cartQuantities = const {},
  });

  final String title;
  final String subtitle;
  final List<Map<String, dynamic>> items;
  final void Function(Map<String, dynamic> item) onAddItem;
  final bool preferHindi;
  final Map<String, int> cartQuantities;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    const saffron = Color(0xFFC99232);
    const ink = Color(0xFF071A31);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                title,
                style: GoogleFonts.playfairDisplay(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: ink,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                subtitle,
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  color: Colors.black54,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 220,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 18),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(width: 14),
            itemBuilder: (context, index) {
              final item = items[index];
              final id = '${item['_id']}';
              final name = preferHindi && (item['nameHi']?.toString().isNotEmpty ?? false)
                  ? '${item['nameHi']}'
                  : '${item['name'] ?? ''}';
              final price = (item['basePrice'] as num?)?.toDouble() ?? 0;
              final image = RestaurantApi.mediaUrl(item['imageUrl'] ?? item['image']);
              final isVeg = item['isVeg'] != false;
              final qty = cartQuantities[id] ?? 0;

              return Container(
                width: 160,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x0C000000),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                  border: Border.all(color: const Color(0xFFF0EAE1)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                          child: image.isNotEmpty
                              ? Image.network(
                                  image,
                                  height: 105,
                                  width: 160,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => _placeholder(),
                                )
                              : _placeholder(),
                        ),
                        Positioned(
                          top: 8,
                          left: 8,
                          child: VegNonVegBadge(isVeg: isVeg, size: 16),
                        ),
                        if (item['isBestseller'] == true || item['isChefSpecial'] == true)
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: saffron,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                item['isChefSpecial'] == true ? "Chef's" : 'Bestseller',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: GoogleFonts.dmSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: ink,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              AnimatedPriceTicker(
                                amount: price,
                                prefix: '₹',
                                style: GoogleFonts.dmSans(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF237A59),
                                ),
                              ),
                              BouncyTap(
                                onTap: () => onAddItem(item),
                                scaleDown: 0.88,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: qty > 0 ? saffron : const Color(0xFFFFF1D6),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: saffron),
                                  ),
                                  child: Text(
                                    qty > 0 ? '$qty in cart' : 'ADD +',
                                    style: TextStyle(
                                      color: qty > 0 ? Colors.white : saffron,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _placeholder() => const ShimmerBox(
        width: 160,
        height: 105,
        borderRadius: 0,
      );
}
