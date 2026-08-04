import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../application/customer_cart_provider.dart';
import '../../data/customer_menu_items.dart';
import '../widgets/bestseller_categories_section.dart';
import '../widgets/customer_footer.dart';
import '../widgets/dashboard_header.dart';

class CustomerReorderScreen extends ConsumerWidget {
  const CustomerReorderScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dietaryMode = ref.watch(customerDietaryPreferenceProvider);
    final vegOnly = dietaryMode == CustomerDietaryMode.veg;
    final visibleItems = popularCustomerMenuItems
        .where(
          (item) =>
              item.category.toLowerCase().startsWith('dessert') ||
              item.isVeg == vegOnly,
        )
        .toList();

    return Scaffold(
      backgroundColor: AppTheme.scaffoldBackgroundLight,
      appBar: AppBar(
        backgroundColor: const Color(0xFF061339),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text.rich(
          TextSpan(
            children: [
              TextSpan(text: 'Taste'),
              TextSpan(
                text: 'Hub',
                style: TextStyle(color: Color(0xFFFFA24A)),
              ),
            ],
          ),
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        actions: [
          IconButton(
            tooltip: 'Cart',
            onPressed: () => context.push('/cart'),
            icon: const Icon(Icons.shopping_cart_outlined),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(72, 12, 16, 58),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF061339), Color(0xFF0A1B52)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Column(
              children: [
                CustomerSearchToolbar(
                  onSearchTap: () => context.push('/customer/search'),
                  onMicTap: () => context.push('/customer/search'),
                ),
                const SizedBox(height: 44),
                Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.shopping_basket_outlined,
                    color: Colors.white,
                    size: 38,
                  ),
                ),
                const SizedBox(height: 22),
                const Text(
                  'Reordering will be easy',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 27,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Once you place your first order, tap Reorder to add it straight back to your cart.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFFB8C5E0),
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
          BestsellerCategoriesSection(
            items: visibleItems,
            vegOnly: vegOnly,
            onCategoryTap: (category) =>
                context.push('/customer/category/${_slugify(category)}'),
          ),
          const SizedBox(height: 32),
          CustomerFooter(
            onMenuTap: () => context.push('/customer/menu'),
            onOffersTap: () => context.push('/customer/offers'),
            onOrdersTap: () => context.push('/customer/orders'),
            onHelpTap: () => context.push('/customer/profile'),
          ),
        ],
      ),
    );
  }
}

String _slugify(String value) {
  return value
      .toLowerCase()
      .replaceAll('&', 'and')
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-|-$'), '');
}
