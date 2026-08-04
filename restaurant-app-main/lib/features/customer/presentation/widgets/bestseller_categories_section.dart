import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/models/customer_menu_item.dart';

class BestsellerCategoriesSection extends StatelessWidget {
  const BestsellerCategoriesSection({
    super.key,
    required this.items,
    required this.vegOnly,
    required this.onCategoryTap,
  });

  final List<CustomerMenuItem> items;
  final bool vegOnly;
  final ValueChanged<String> onCategoryTap;

  @override
  Widget build(BuildContext context) {
    final groupedItems = <String, List<CustomerMenuItem>>{};
    for (final item in items) {
      groupedItems
          .putIfAbsent(item.category, () => <CustomerMenuItem>[])
          .add(item);
    }
    final width = MediaQuery.sizeOf(context).width;
    final crossAxisCount = width >= 760 ? 3 : 2;
    final cards = groupedItems.entries
        .map((entry) => _buildCardData(entry.key, entry.value))
        .toList();

    if (cards.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFE9EEF5)),
          ),
          child: Text(
            vegOnly
                ? 'No veg bestseller categories are available right now.'
                : 'No non-veg bestseller categories are available right now.',
            style: const TextStyle(
              color: AppTheme.textSecondaryLight,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              'Bestsellers',
              style: TextStyle(
                color: AppTheme.textPrimaryLight,
                fontSize: 28,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.6,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              vegOnly
                  ? 'Best veg categories customers are ordering most right now.'
                  : 'Best non-veg categories customers are ordering most right now.',
              style: const TextStyle(
                color: AppTheme.textSecondaryLight,
                fontSize: 13,
                fontWeight: FontWeight.w500,
                height: 1.45,
              ),
            ),
          ),
          const SizedBox(height: 18),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: cards.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 14,
              mainAxisSpacing: 16,
              mainAxisExtent: 244,
            ),
            itemBuilder: (context, index) {
              final card = cards[index];
              return _BestsellerCategoryCard(
                card: card,
                onTap: () => onCategoryTap(card.category),
              );
            },
          ),
        ],
      ),
    );
  }

  _BestsellerCategoryCardData _buildCardData(
    String category,
    List<CustomerMenuItem> categoryItems,
  ) {
    final imageUrls = categoryItems
        .map((item) => item.imageUrl)
        .where((url) => url.isNotEmpty)
        .take(4)
        .toList();

    return _BestsellerCategoryCardData(
      category: category,
      title: '${vegOnly ? 'Veg' : 'Non-Veg'} $category',
      badgeLabel:
          '${categoryItems.length} ${categoryItems.length == 1 ? 'dish' : 'dishes'}',
      imageUrls: imageUrls,
    );
  }
}

class _BestsellerCategoryCard extends StatelessWidget {
  const _BestsellerCategoryCard({required this.card, required this.onTap});

  final _BestsellerCategoryCardData card;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(28),
        child: Container(
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 14),
          decoration: BoxDecoration(
            color: const Color(0xFFF4F6FB),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: const Color(0xFFE9EEF5)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              Expanded(
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: card.imageUrls.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemBuilder: (context, index) {
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.network(
                        card.imageUrls[index],
                        fit: BoxFit.cover,
                        errorBuilder: (_, error, stackTrace) => Container(
                          color: const Color(0xFFFFEDD5),
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.restaurant_menu_rounded,
                            color: Color(0xFFEA580C),
                            size: 28,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              Transform.translate(
                offset: const Offset(0, -10),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.97),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Text(
                    card.badgeLabel,
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              Text(
                card.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppTheme.textPrimaryLight,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  height: 1.15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BestsellerCategoryCardData {
  const _BestsellerCategoryCardData({
    required this.category,
    required this.title,
    required this.badgeLabel,
    required this.imageUrls,
  });

  final String category;
  final String title;
  final String badgeLabel;
  final List<String> imageUrls;
}
