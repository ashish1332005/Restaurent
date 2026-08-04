import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../application/customer_cart_provider.dart';
import '../../data/customer_menu_items.dart';
import '../../domain/models/customer_menu_item.dart';
import '../widgets/custom_bottom_nav_bar.dart';
import '../widgets/customer_footer.dart';
import '../widgets/dashboard_header.dart';
import '../widgets/floating_cart_bar.dart';

class CustomerCategoriesScreen extends ConsumerStatefulWidget {
  const CustomerCategoriesScreen({super.key});

  @override
  ConsumerState<CustomerCategoriesScreen> createState() =>
      _CustomerCategoriesScreenState();
}

class _CustomerCategoriesScreenState
    extends ConsumerState<CustomerCategoriesScreen> {
  final _scrollController = ScrollController();
  int _selectedIndex = 4;
  bool _showBottomNav = true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScrollDirection);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _handleScrollDirection() {
    if (!_scrollController.hasClients) return;
    final direction = _scrollController.position.userScrollDirection;
    final shouldShow =
        _scrollController.offset <= 0 || direction == ScrollDirection.forward;
    if (direction != ScrollDirection.idle && shouldShow != _showBottomNav) {
      setState(() => _showBottomNav = shouldShow);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dietaryMode = ref.watch(customerDietaryPreferenceProvider);
    final cartCount = ref.watch(customerCartItemCountProvider);
    final vegOnly = dietaryMode == CustomerDietaryMode.veg;
    final dietaryItems = popularCustomerMenuItems
        .where((item) => item.isVeg == vegOnly)
        .toList();
    final sections = _buildCategorySections(dietaryItems);

    return Scaffold(
      backgroundColor: const Color(0xFFF1F8FF),
      body: Stack(
        children: [
          CustomScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: _CategoriesTopHeader(
                  onHomeTap: () => context.push('/customer'),
                  onWalletTap: () => context.push('/customer/wallet'),
                  onProfileTap: () => context.push('/customer/profile'),
                ),
              ),
              SliverPersistentHeader(
                pinned: true,
                delegate: _CategoriesStickySearchDelegate(
                  vegOnly: vegOnly,
                  onSearchTap: () => context.push('/customer/search'),
                  onMicTap: () => context.push('/customer/search'),
                  onVegChanged: (value) => ref
                      .read(customerDietaryPreferenceProvider.notifier)
                      .setMode(
                        value
                            ? CustomerDietaryMode.veg
                            : CustomerDietaryMode.nonVeg,
                      ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        vegOnly ? 'Veg Categories' : 'Non-Veg Categories',
                        style: const TextStyle(
                          color: AppTheme.textPrimaryLight,
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.6,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        vegOnly
                            ? 'Har category ke top product previews ek line me dekh lo aur jaldi choose karo.'
                            : 'Har category ke top non-veg product previews ek line me dekh lo aur jaldi choose karo.',
                        style: const TextStyle(
                          color: AppTheme.textSecondaryLight,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 20),
                      if (sections.isEmpty)
                        const _EmptyCategoryState()
                      else
                        ...sections.map(
                          (section) => Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: _CategoryPreviewSection(
                              section: section,
                              onTap: () => context.push(
                                '/customer/category/${_slugify(section.title)}',
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: CustomerFooter(
                  onMenuTap: () => context.push('/customer/menu'),
                  onOffersTap: () => context.push('/customer/offers'),
                  onOrdersTap: () => context.push('/customer/orders'),
                  onHelpTap: () => context.push('/customer/profile'),
                ),
              ),
              SliverToBoxAdapter(
                child: SizedBox(height: cartCount > 0 ? 112 : 40),
              ),
            ],
          ),
          if (cartCount > 0)
            Positioned(
              left: 0,
              right: 0,
              bottom: 8,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 260),
                switchInCurve: Curves.easeOutBack,
                switchOutCurve: Curves.easeIn,
                child: CustomerFloatingCartBar(
                  key: const ValueKey('categories-cart-bar'),
                  onTap: () => context.push('/cart'),
                ),
              ),
            ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: AnimatedSwitcher(
        duration: const Duration(milliseconds: 260),
        switchInCurve: Curves.easeOutBack,
        switchOutCurve: Curves.easeIn,
        child: !_showBottomNav || cartCount > 0
            ? const SizedBox.shrink()
            : Container(
                key: const ValueKey('categories-scanner-fab'),
                margin: const EdgeInsets.only(top: 30),
                height: 64,
                width: 64,
                child: FloatingActionButton(
                  onPressed: () => context.push('/customer/scanner'),
                  backgroundColor: const Color(0xFF1565D8),
                  elevation: 6,
                  shape: const CircleBorder(),
                  child: const Icon(
                    Icons.qr_code_scanner_rounded,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              ),
      ),
      bottomNavigationBar: AnimatedSize(
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
        child: _showBottomNav
            ? CustomBottomNavBar(
                selectedIndex: _selectedIndex,
                onItemTapped: (index) {
                  if (index == 0) {
                    context.push('/customer');
                    return;
                  }

                  if (index == 1) {
                    _handleReorder();
                    return;
                  }

                  if (index == 3) {
                    context.push('/cart');
                    return;
                  }

                  setState(() {
                    _selectedIndex = index;
                  });
                },
              )
            : const SizedBox.shrink(),
      ),
    );
  }

  void _handleReorder() {
    final lastOrder = ref.read(customerLastOrderProvider);
    if (lastOrder == null || lastOrder.isEmpty) {
      context.push('/customer/reorder');
      return;
    }

    ref.read(customerCartProvider.notifier).addOrderItems(lastOrder);
    context.push('/cart');
  }
}

class _CategoriesTopHeader extends StatelessWidget {
  const _CategoriesTopHeader({
    required this.onHomeTap,
    required this.onWalletTap,
    required this.onProfileTap,
  });

  final VoidCallback onHomeTap;
  final VoidCallback onWalletTap;
  final VoidCallback onProfileTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0B1C59), Color(0xFF0A256D), Color(0xFFDBF1FF)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: [0.0, 0.74, 1.0],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
          child: Column(
            children: [
              Row(
                children: [
                  InkWell(
                    onTap: onHomeTap,
                    borderRadius: BorderRadius.circular(20),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 6),
                      child: Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: 'Taste',
                              style: TextStyle(color: Colors.white),
                            ),
                            TextSpan(
                              text: 'Hub',
                              style: TextStyle(color: Color(0xFFFFA24A)),
                            ),
                          ],
                        ),
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.8,
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                  _TopSurfaceButton(
                    icon: Icons.account_balance_wallet_outlined,
                    onTap: onWalletTap,
                  ),
                  const SizedBox(width: 8),
                  _TopSurfaceButton(
                    icon: Icons.person_outline_rounded,
                    onTap: onProfileTap,
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoriesStickySearchDelegate extends SliverPersistentHeaderDelegate {
  const _CategoriesStickySearchDelegate({
    required this.vegOnly,
    required this.onSearchTap,
    required this.onMicTap,
    required this.onVegChanged,
  });

  final bool vegOnly;
  final VoidCallback onSearchTap;
  final VoidCallback onMicTap;
  final ValueChanged<bool> onVegChanged;

  @override
  double get minExtent => 82;

  @override
  double get maxExtent => 82;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Material(
      color: const Color(0xFFDBF1FF),
      elevation: overlapsContent ? 6 : 0,
      shadowColor: Colors.black12,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
        child: CustomerSearchToolbar(
          onSearchTap: onSearchTap,
          onMicTap: onMicTap,
          showDietaryToggle: true,
          vegOnly: vegOnly,
          onVegChanged: onVegChanged,
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _CategoriesStickySearchDelegate oldDelegate) {
    return oldDelegate.vegOnly != vegOnly;
  }
}

class _TopSurfaceButton extends StatelessWidget {
  const _TopSurfaceButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.10),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
        ),
        child: Icon(icon, color: Colors.white, size: 22),
      ),
    );
  }
}

class _CategoryPreviewSection extends StatelessWidget {
  const _CategoryPreviewSection({required this.section, required this.onTap});

  final _CategoryPreviewSectionData section;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(28),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: const Color(0xFFE1ECF7)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      section.title,
                      style: const TextStyle(
                        color: AppTheme.textPrimaryLight,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: section.accent.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '${section.itemCount} items',
                      style: TextStyle(
                        color: section.accent,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                section.subtitle,
                style: const TextStyle(
                  color: AppTheme.textSecondaryLight,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: List.generate(section.previewImages.length, (index) {
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        right: index == section.previewImages.length - 1
                            ? 0
                            : 10,
                      ),
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(22),
                          child: Image.network(
                            section.previewImages[index],
                            fit: BoxFit.cover,
                            errorBuilder: (_, error, stackTrace) => Container(
                              color: const Color(0xFFEFF6FF),
                              alignment: Alignment.center,
                              child: Icon(
                                Icons.restaurant_menu_rounded,
                                color: section.accent,
                                size: 28,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyCategoryState extends StatelessWidget {
  const _EmptyCategoryState();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: const Text(
        'No categories are available right now.',
        style: TextStyle(
          color: AppTheme.textSecondaryLight,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _CategoryPreviewSectionData {
  const _CategoryPreviewSectionData({
    required this.title,
    required this.subtitle,
    required this.itemCount,
    required this.previewImages,
    required this.accent,
  });

  final String title;
  final String subtitle;
  final int itemCount;
  final List<String> previewImages;
  final Color accent;
}

List<_CategoryPreviewSectionData> _buildCategorySections(
  List<CustomerMenuItem> items,
) {
  final grouped = <String, List<CustomerMenuItem>>{};
  for (final item in items) {
    grouped.putIfAbsent(item.category, () => []).add(item);
  }

  final sections = <_CategoryPreviewSectionData>[];
  for (final entry in grouped.entries) {
    final category = entry.key;
    final categoryItems = entry.value;
    final firstItem = categoryItems.first;
    final previews = _previewImagesForCategory(
      category,
      fallback: firstItem.imageUrl,
    );

    sections.add(
      _CategoryPreviewSectionData(
        title: category,
        subtitle: _subtitleForCategory(category, firstItem.isVeg),
        itemCount: categoryItems.length,
        previewImages: previews,
        accent: _accentForCategory(category, firstItem.isVeg),
      ),
    );
  }

  sections.sort((a, b) => a.title.compareTo(b.title));
  return sections;
}

List<String> _previewImagesForCategory(
  String category, {
  required String fallback,
}) {
  switch (category) {
    case 'Pizza':
      return const [
        'https://images.unsplash.com/photo-1513104890138-7c749659a591?q=80&w=400&auto=format&fit=crop',
        'https://images.unsplash.com/photo-1541745537411-b8046dc6d66c?q=80&w=400&auto=format&fit=crop',
        'https://images.unsplash.com/photo-1594007654729-407eedc4be65?q=80&w=400&auto=format&fit=crop',
        'https://images.unsplash.com/photo-1534308983496-4fabb1a015ee?q=80&w=400&auto=format&fit=crop',
      ];
    case 'Burgers':
      return const [
        'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?q=80&w=400&auto=format&fit=crop',
        'https://images.unsplash.com/photo-1553979459-d2229ba7433b?q=80&w=400&auto=format&fit=crop',
        'https://images.unsplash.com/photo-1571091718767-18b5b1457add?q=80&w=400&auto=format&fit=crop',
        'https://images.unsplash.com/photo-1585238342024-78d387f4a707?q=80&w=400&auto=format&fit=crop',
      ];
    case 'Italian':
      return const [
        'https://images.unsplash.com/photo-1473093295043-cdd812d0e601?q=80&w=400&auto=format&fit=crop',
        'https://images.unsplash.com/photo-1621996346565-e3dbc646d9a9?q=80&w=400&auto=format&fit=crop',
        'https://images.unsplash.com/photo-1555949258-eb67b1ef0ceb?q=80&w=400&auto=format&fit=crop',
        'https://images.unsplash.com/photo-1521389508051-d7ffb5dc8d5f?q=80&w=400&auto=format&fit=crop',
      ];
    case 'Desserts':
      return const [
        'https://images.unsplash.com/photo-1551024506-0bccd828d307?q=80&w=400&auto=format&fit=crop',
        'https://images.unsplash.com/photo-1563729784474-d77dbb933a9e?q=80&w=400&auto=format&fit=crop',
        'https://images.unsplash.com/photo-1488477181946-6428a0291777?q=80&w=400&auto=format&fit=crop',
        'https://images.unsplash.com/photo-1464306076886-da185f6a9d05?q=80&w=400&auto=format&fit=crop',
      ];
    case 'Salad':
      return const [
        'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?q=80&w=400&auto=format&fit=crop',
        'https://images.unsplash.com/photo-1540420773420-3366772f4999?q=80&w=400&auto=format&fit=crop',
        'https://images.unsplash.com/photo-1490645935967-10de6ba17061?q=80&w=400&auto=format&fit=crop',
        'https://images.unsplash.com/photo-1529059997568-3d847b1154f0?q=80&w=400&auto=format&fit=crop',
      ];
    case 'Thali':
      return const [
        'https://images.unsplash.com/photo-1668236543090-82eba5ee5976?q=80&w=400&auto=format&fit=crop',
        'https://images.unsplash.com/photo-1631452180519-c014fe946bc7?q=80&w=400&auto=format&fit=crop',
        'https://images.unsplash.com/photo-1601050690597-df0568f70950?q=80&w=400&auto=format&fit=crop',
        'https://images.unsplash.com/photo-1631515243349-e0cb75fb8d3a?q=80&w=400&auto=format&fit=crop',
      ];
    case 'Grill':
      return const [
        'https://images.unsplash.com/photo-1529193591184-b1d58069ecdd?q=80&w=400&auto=format&fit=crop',
        'https://images.unsplash.com/photo-1558030006-450675393462?q=80&w=400&auto=format&fit=crop',
        'https://images.unsplash.com/photo-1600891964092-4316c288032e?q=80&w=400&auto=format&fit=crop',
        'https://images.unsplash.com/photo-1544025162-d76694265947?q=80&w=400&auto=format&fit=crop',
      ];
    case 'Biryani':
      return const [
        'https://images.unsplash.com/photo-1633945274309-2c16c9682a8c?q=80&w=400&auto=format&fit=crop',
        'https://images.unsplash.com/photo-1701579231373-429c38b770e0?q=80&w=400&auto=format&fit=crop',
        'https://images.unsplash.com/photo-1596797038530-2c107aa2d4c3?q=80&w=400&auto=format&fit=crop',
        'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?q=80&w=400&auto=format&fit=crop',
      ];
    default:
      return [fallback, fallback, fallback, fallback];
  }
}

String _subtitleForCategory(String category, bool isVeg) {
  switch (category) {
    case 'Pizza':
      return 'Cheesy hot picks for quick ordering.';
    case 'Burgers':
      return 'Stacked comfort meals customers love.';
    case 'Italian':
      return 'Creamy bowls and rich pasta favourites.';
    case 'Desserts':
      return 'Sweet endings and quick sugar cravings.';
    case 'Salad':
      return 'Fresh bowls and lighter healthy picks.';
    case 'Thali':
      return 'Full meal comfort in one category.';
    case 'Grill':
      return 'Smoky grilled bites and bold flavours.';
    case 'Biryani':
      return 'Rice bowls packed with rich spice.';
    default:
      return isVeg
          ? 'Curated vegetarian picks in this category.'
          : 'Curated non-veg picks in this category.';
  }
}

Color _accentForCategory(String category, bool isVeg) {
  switch (category) {
    case 'Pizza':
      return isVeg ? const Color(0xFFDC2626) : const Color(0xFFB91C1C);
    case 'Burgers':
      return const Color(0xFFCA8A04);
    case 'Italian':
      return const Color(0xFF2563EB);
    case 'Desserts':
      return const Color(0xFF9333EA);
    case 'Salad':
      return const Color(0xFF059669);
    case 'Thali':
      return const Color(0xFF7C3AED);
    case 'Grill':
      return const Color(0xFFEA580C);
    case 'Biryani':
      return const Color(0xFFB45309);
    default:
      return isVeg ? const Color(0xFF16A34A) : const Color(0xFFDC2626);
  }
}

String _slugify(String value) {
  return value
      .toLowerCase()
      .replaceAll('&', 'and')
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-|-$'), '');
}
