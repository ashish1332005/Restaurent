import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/animations/flutterfx/animated_price_ticker.dart';
import '../../core/animations/flutterfx/bouncy_tap.dart';
import '../../core/animations/flutterfx/shimmer_box.dart';
import '../../core/network/restaurant_api.dart';
import 'veg_non_veg_badge.dart';

class FoodMenuCard extends StatelessWidget {
  const FoodMenuCard({
    super.key,
    required this.item,
    required this.quantity,
    required this.onAdd,
    required this.onDecrease,
    required this.onTap,
    required this.preferHindi,
    required this.isAvailable,
    required this.availabilityLabel,
  });

  final Map<String, dynamic> item;
  final int quantity;
  final VoidCallback onAdd;
  final VoidCallback onDecrease;
  final VoidCallback onTap;
  final bool preferHindi;
  final bool isAvailable;
  final String availabilityLabel;

  @override
  Widget build(BuildContext context) {
    const saffron = Color(0xFFC99232);
    const ink = Color(0xFF071A31);
    const leaf = Color(0xFF237A59);

    final isVeg = item['isVeg'] != false;
    final isThali = item['itemType'] == 'Thali';
    final variants = ((item['variants'] as List?) ?? const []).whereType<Map>();
    final modifiers = ((item['modifiers'] as List?) ?? const []).whereType<Map>();
    final hasChoices = variants.isNotEmpty || modifiers.isNotEmpty;

    final nameEn = '${item['name'] ?? ''}';
    final nameHi = '${item['nameHi'] ?? ''}';
    final name = preferHindi && nameHi.isNotEmpty ? nameHi : nameEn;
    final secondaryName = preferHindi ? nameEn : nameHi;

    final descEn = '${item['description'] ?? ''}';
    final descHi = '${item['descriptionHi'] ?? ''}';
    final desc = preferHindi && descHi.isNotEmpty ? descHi : descEn;

    final image = RestaurantApi.mediaUrl(item['imageUrl'] ?? item['image']);
    final spiceLevel = '${item['spiceLevel'] ?? 'None'}';
    final dietaryTags = ((item['dietaryTags'] as List?) ?? const [])
        .map((e) => '$e')
        .toList();
    final allergens = ((item['allergens'] as List?) ?? const [])
        .map((e) => '$e')
        .toList();

    final variantPrices = variants
        .map((entry) => (entry['price'] as num?)?.toDouble())
        .whereType<double>()
        .toList();
    final displayPrice = variantPrices.isEmpty
        ? (item['basePrice'] as num?)?.toDouble() ?? 0
        : variantPrices.reduce((a, b) => a < b ? a : b);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF2ECE4)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Details Column
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Veg indicator & Badges row
                    Row(
                      children: [
                        VegNonVegBadge(isVeg: isVeg, size: 16),
                        const SizedBox(width: 8),
                        if (item['isBestseller'] == true) ...[
                          _pillBadge('Bestseller 🔥', const Color(0xFFFFF3E0), const Color(0xFFE65100)),
                          const SizedBox(width: 6),
                        ],
                        if (item['isChefSpecial'] == true) ...[
                          _pillBadge("Chef's Special 👨‍🍳", const Color(0xFFEDE7F6), const Color(0xFF5E35B1)),
                          const SizedBox(width: 6),
                        ],
                        if (isThali)
                          _pillBadge('Thali 🍱', const Color(0xFFE8F5E9), leaf),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Item Name
                    Text(
                      name,
                      style: GoogleFonts.dmSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: ink,
                      ),
                    ),
                    if (secondaryName.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        secondaryName,
                        style: GoogleFonts.dmSans(
                          fontSize: 12,
                          color: Colors.black45,
                        ),
                      ),
                    ],
                    const SizedBox(height: 6),
                    // Animated Price Ticker
                    Row(
                      children: [
                        if (variantPrices.isNotEmpty)
                          Text(
                            'From ',
                            style: GoogleFonts.dmSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: ink,
                            ),
                          ),
                        AnimatedPriceTicker(
                          amount: displayPrice,
                          prefix: '₹',
                          style: GoogleFonts.dmSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: ink,
                          ),
                        ),
                      ],
                    ),
                    if (desc.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        desc,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.dmSans(
                          fontSize: 12,
                          color: Colors.black54,
                          height: 1.35,
                        ),
                      ),
                    ],
                    // Dietary & Spice tags
                    if (spiceLevel != 'None' || dietaryTags.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          if (spiceLevel != 'None')
                            _tagBadge(
                              spiceLevel == 'Hot' || spiceLevel == 'Extra Hot'
                                  ? '🌶️ $spiceLevel'
                                  : '🌱 $spiceLevel',
                            ),
                          ...dietaryTags.take(2).map(_tagBadge),
                        ],
                      ),
                    ],
                    if (allergens.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        'Contains: ${allergens.join(', ')}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFFB42318),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    if (!isAvailable) ...[
                      const SizedBox(height: 6),
                      Text(
                        availabilityLabel,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFFB54708),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 14),
              // Image & Counter Button Column
              Column(
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: image.isNotEmpty
                            ? Image.network(
                                image,
                                width: 104,
                                height: 96,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => _placeholder(),
                              )
                            : _placeholder(),
                      ),
                      // Positioned Add/Counter button floating over image bottom
                      Positioned(
                        bottom: -14,
                        left: 10,
                        right: 10,
                        child: _buildCounterButton(context, saffron, leaf),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (hasChoices)
                    Text(
                      preferHindi ? 'कस्टमाइज़ेबल' : 'Customisable',
                      style: GoogleFonts.dmSans(
                        fontSize: 10,
                        color: Colors.black45,
                        fontWeight: FontWeight.w600,
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

  Widget _buildCounterButton(BuildContext context, Color saffron, Color leaf) {
    if (!isAvailable) {
      return Container(
        height: 32,
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(
          child: Text(
            'SOLD OUT',
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.black54),
          ),
        ),
      );
    }

    if (quantity == 0) {
      return BouncyTap(
        onTap: onAdd,
        scaleDown: 0.92,
        child: Container(
          height: 32,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: saffron, width: 1.5),
            boxShadow: const [
              BoxShadow(
                color: Color(0x1A000000),
                blurRadius: 6,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'ADD',
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: saffron,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(Icons.add_rounded, size: 16, color: saffron),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      height: 32,
      decoration: BoxDecoration(
        color: saffron,
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(
            color: Color(0x26C99232),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          BouncyTap(
            onTap: onDecrease,
            scaleDown: 0.85,
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: Icon(Icons.remove_rounded, size: 16, color: Colors.white),
            ),
          ),
          AnimatedPriceTicker(
            amount: quantity.toDouble(),
            prefix: '',
            style: GoogleFonts.dmSans(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          BouncyTap(
            onTap: onAdd,
            scaleDown: 0.85,
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: Icon(Icons.add_rounded, size: 16, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _pillBadge(String label, Color bg, Color text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: text),
        ),
      );

  Widget _tagBadge(String label) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: const Color(0xFFF4F0E8),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF5A483E)),
        ),
      );

  Widget _placeholder() => const ShimmerBox(
        width: 104,
        height: 96,
        borderRadius: 16,
      );
}
