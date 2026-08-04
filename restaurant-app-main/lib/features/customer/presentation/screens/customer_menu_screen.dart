import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../application/customer_cart_provider.dart';
import '../../data/customer_menu_items.dart';
import '../../domain/models/customer_menu_item.dart';
import '../widgets/floating_cart_bar.dart';
import '../widgets/customer_ui.dart';

class CustomerMenuScreen extends ConsumerWidget {
  const CustomerMenuScreen({super.key, this.categorySlug});

  final String? categorySlug;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartCount = ref.watch(customerCartItemCountProvider);
    final dietaryMode = ref.watch(customerDietaryPreferenceProvider);
    final vegOnly = dietaryMode == CustomerDietaryMode.veg;
    final dietaryItems = popularCustomerMenuItems
        .where((item) => item.isVeg == vegOnly)
        .toList();
    final categories =
        dietaryItems.map((item) => item.category).toSet().toList()..sort();
    final dishes = _filteredItems(dietaryItems);
    final title = categorySlug == null
        ? (vegOnly ? 'Veg Menu' : 'Non-Veg Menu')
        : _prettyCategory(categorySlug!, categories);
    final compact = MediaQuery.sizeOf(context).width < 420;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.textPrimaryLight,
        elevation: 0,
        title: Text(title),
        actions: [
          IconButton(
            onPressed: () => context.push('/cart'),
            icon: Badge.count(
              count: cartCount,
              isLabelVisible: cartCount > 0,
              child: const Icon(Icons.shopping_cart_outlined),
            ),
          ),
        ],
      ),
      body: CustomerScreenBackground(
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            compact ? 16 : 20,
            12,
            compact ? 16 : 20,
            24,
          ),
          children: [
            CustomerHeroCard(
              eyebrow: categorySlug == null
                  ? (vegOnly ? 'VEG CURATION' : 'NON-VEG CURATION')
                  : 'CATEGORY VIEW',
              title: categorySlug == null
                  ? (vegOnly
                        ? 'Choose fresh veg favorites for the table.'
                        : 'Choose bold non-veg favorites for the table.')
                  : '$title picks ready for a quick order.',
              subtitle: categorySlug == null
                  ? (vegOnly
                        ? 'Browse vegetarian bestsellers, jump between categories, and add favorites without mixing the menu.'
                        : 'Browse non-veg bestsellers, jump between categories, and add favorites without mixing the menu.')
                  : 'This category view keeps only the matching dishes upfront so customers can order faster.',
              icon: Icons.restaurant_menu_rounded,
              accent: vegOnly
                  ? const Color(0xFF16A34A)
                  : const Color(0xFFDC2626),
              footer: Row(
                children: [
                  CustomerMetricPill(
                    label: 'Visible dishes',
                    value: '${dishes.length}',
                  ),
                  const SizedBox(width: 12),
                  CustomerMetricPill(
                    label: 'Popular sections',
                    value: '${categories.length}',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _BestsellerCategoriesSection(
              items: dietaryItems,
              vegOnly: vegOnly,
              selectedCategorySlug: categorySlug,
              onCategoryTap: (category) =>
                  context.push('/customer/category/${_slugify(category)}'),
            ),
            if (categorySlug != null) ...[
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => context.push('/customer/menu'),
                  icon: const Icon(Icons.grid_view_rounded),
                  label: Text(
                    vegOnly ? 'Back to veg menu' : 'Back to non-veg menu',
                  ),
                ),
              ),
            ],
            const SizedBox(height: 20),
            CustomerSectionCard(
              title: 'Featured dishes',
              subtitle: categorySlug == null
                  ? 'Built around quick wins for hungry guests.'
                  : 'The strongest dishes in this category right now.',
              action: cartCount > 0
                  ? CustomerBadgeChip(
                      label: '$cartCount in cart',
                      icon: Icons.shopping_bag_outlined,
                    )
                  : null,
              child: dishes.isEmpty
                  ? _EmptyDietaryState(
                      message: categorySlug == null
                          ? (vegOnly
                                ? 'No veg dishes are available right now.'
                                : 'No non-veg dishes are available right now.')
                          : 'No matching dishes found in this category for the current toggle.',
                    )
                  : Column(
                      children: [
                        for (var i = 0; i < dishes.length; i++) ...[
                          _MenuCard(dish: dishes[i], index: i),
                          if (i < dishes.length - 1) const SizedBox(height: 16),
                        ],
                      ],
                    ),
            ),
            const SizedBox(height: 132),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: AnimatedSwitcher(
        duration: const Duration(milliseconds: 260),
        switchInCurve: Curves.easeOutBack,
        switchOutCurve: Curves.easeIn,
        child: cartCount > 0
            ? CustomerFloatingCartBar(
                key: const ValueKey('menu-cart-bar'),
                onTap: () => context.push('/cart'),
              )
            : const SizedBox.shrink(),
      ),
    );
  }

  List<CustomerMenuItem> _filteredItems(List<CustomerMenuItem> source) {
    if (categorySlug == null) {
      return source;
    }

    return source
        .where((item) => _slugify(item.category) == categorySlug)
        .toList();
  }

  String _prettyCategory(String slug, List<String> categories) {
    final match = categories
        .where((category) => _slugify(category) == slug)
        .cast<String?>()
        .firstWhere((category) => category != null, orElse: () => null);
    return match ?? slug.replaceAll('-', ' ');
  }
}

class _BestsellerCategoriesSection extends StatelessWidget {
  const _BestsellerCategoriesSection({
    required this.items,
    required this.vegOnly,
    required this.selectedCategorySlug,
    required this.onCategoryTap,
  });

  final List<CustomerMenuItem> items;
  final bool vegOnly;
  final String? selectedCategorySlug;
  final ValueChanged<String> onCategoryTap;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFE9EEF5)),
        ),
        child: const Text(
          'No bestseller categories are available right now.',
          style: TextStyle(
            color: AppTheme.textSecondaryLight,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            'Bestsellers',
            style: TextStyle(
              color: AppTheme.textPrimaryLight,
              fontSize: 29,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.6,
            ),
          ),
        ),
        const SizedBox(height: 8),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            'Popular categories shown only for the currently selected diet.',
            style: TextStyle(
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
            mainAxisExtent: 248,
          ),
          itemBuilder: (context, index) {
            final card = cards[index];
            final selected = _slugify(card.category) == selectedCategorySlug;

            return _BestsellerCategoryCard(
              card: card,
              selected: selected,
              onTap: () => onCategoryTap(card.category),
            );
          },
        ),
      ],
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
  const _BestsellerCategoryCard({
    required this.card,
    required this.selected,
    required this.onTap,
  });

  final _BestsellerCategoryCardData card;
  final bool selected;
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
            color: selected ? const Color(0xFFFFF6F2) : const Color(0xFFF4F6FB),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: selected
                  ? const Color(0xFFFCC7B2)
                  : const Color(0xFFE9EEF5),
              width: 1.2,
            ),
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
                style: TextStyle(
                  color: selected
                      ? AppTheme.primaryColor
                      : AppTheme.textPrimaryLight,
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

class _EmptyDietaryState extends StatelessWidget {
  const _EmptyDietaryState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Text(
        message,
        style: const TextStyle(
          color: AppTheme.textSecondaryLight,
          fontWeight: FontWeight.w600,
          height: 1.5,
        ),
      ),
    );
  }
}

class _MenuCard extends ConsumerWidget {
  const _MenuCard({required this.dish, required this.index});

  final CustomerMenuItem dish;
  final int index;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accent = _cardAccent(index);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE9EEF5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 460;

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Image.network(
                  dish.imageUrl,
                  width: compact ? 92 : 104,
                  height: compact ? 92 : 104,
                  fit: BoxFit.cover,
                ),
              ),
              SizedBox(width: compact ? 12 : 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        CustomerBadgeChip(
                          label: dish.category,
                          icon: Icons.restaurant_rounded,
                          color: accent,
                        ),
                        CustomerBadgeChip(
                          label: dish.isVeg ? 'Pure Veg' : 'Non-Veg',
                          icon: dish.isVeg
                              ? Icons.eco_outlined
                              : Icons.lunch_dining_outlined,
                          color: dish.isVeg
                              ? const Color(0xFF16A34A)
                              : const Color(0xFFDC2626),
                          backgroundColor: dish.isVeg
                              ? const Color(0xFFEAF8EE)
                              : const Color(0xFFFFECEC),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      dish.title,
                      maxLines: compact ? 3 : 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: compact ? 16 : 18,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimaryLight,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      dish.description,
                      maxLines: compact ? 3 : 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppTheme.textSecondaryLight,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        CustomerBadgeChip(
                          label: 'Chef pick',
                          icon: Icons.star_rounded,
                          color: accent,
                          backgroundColor: accent.withValues(alpha: 0.10),
                        ),
                        const CustomerBadgeChip(
                          label: 'Ready in 15-20 mins',
                          icon: Icons.timer_outlined,
                          color: Color(0xFF475569),
                          backgroundColor: Color(0xFFF8FAFC),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    if (compact) ...[
                      Text(
                        formatPrice(dish.price),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimaryLight,
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => _addToCart(context, ref),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: accent,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 14,
                            ),
                          ),
                          child: const Text('Add to cart'),
                        ),
                      ),
                    ] else
                      Wrap(
                        spacing: 12,
                        runSpacing: 10,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            formatPrice(dish.price),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.textPrimaryLight,
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () => _addToCart(context, ref),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: accent,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 14,
                              ),
                            ),
                            child: const Text('Add to cart'),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _addToCart(BuildContext context, WidgetRef ref) {
    ref.read(customerCartProvider.notifier).addItem(dish);
  }

  Color _cardAccent(int index) {
    switch (index % 3) {
      case 0:
        return AppTheme.primaryColor;
      case 1:
        return const Color(0xFF2563EB);
      default:
        return const Color(0xFF059669);
    }
  }
}

String _slugify(String value) {
  return value
      .toLowerCase()
      .replaceAll('&', 'and')
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-|-$'), '');
}
