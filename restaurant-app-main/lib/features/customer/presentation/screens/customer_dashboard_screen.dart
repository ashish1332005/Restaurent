import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../application/customer_cart_provider.dart';
import '../../application/customer_profile_provider.dart';
import '../../data/customer_menu_items.dart';
import '../widgets/custom_bottom_nav_bar.dart';
import '../widgets/customer_footer.dart';
import '../widgets/customer_profile_drawer.dart';
import '../widgets/dashboard_header.dart';
import '../widgets/bestseller_categories_section.dart';
import '../widgets/floating_cart_bar.dart';
import '../widgets/hero_slider_banner.dart';
import '../widgets/popular_dishes_section.dart';
import '../widgets/quick_actions_grid.dart';

class CustomerDashboardScreen extends ConsumerStatefulWidget {
  const CustomerDashboardScreen({super.key});

  @override
  ConsumerState<CustomerDashboardScreen> createState() =>
      _CustomerDashboardScreenState();
}

class _CustomerDashboardScreenState
    extends ConsumerState<CustomerDashboardScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _scrollController = ScrollController();
  Timer? _scrollIdleTimer;
  int _selectedIndex = 0;
  bool _showBottomNav = true;
  bool _isScrolling = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScrollDirection);
  }

  @override
  void dispose() {
    _scrollIdleTimer?.cancel();
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
    if (direction != ScrollDirection.idle) {
      if (!_isScrolling && mounted) setState(() => _isScrolling = true);
      _scrollIdleTimer?.cancel();
      _scrollIdleTimer = Timer(const Duration(milliseconds: 180), () {
        if (mounted && _isScrolling) setState(() => _isScrolling = false);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final dietaryMode = ref.watch(customerDietaryPreferenceProvider);
    final cartCount = ref.watch(customerCartItemCountProvider);
    final profile = ref.watch(customerProfileProvider).asData?.value;
    final vegOnly = dietaryMode == CustomerDietaryMode.veg;
    final visibleMenuItems = popularCustomerMenuItems
        .where((item) => item.isVeg == vegOnly)
        .toList();

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppTheme.scaffoldBackgroundLight,
      drawer: CustomerProfileDrawer(
        userName: profile?.name ?? 'Kartik',
        phoneNumber: profile?.phone ?? '+91 91169 01749',
        onNavigate: _handleDrawerNavigation,
      ),
      body: Stack(
        children: [
          NotificationListener<ScrollNotification>(
            onNotification: (_) => false,
            child: CustomScrollView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFFB91C2B), Color(0xFFE23744)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Column(
                      children: [
                        DashboardHeader(
                          userName: profile?.name ?? 'Kartik',
                          onMenuTap: () => context.go('/customer'),
                          onNotificationsTap: () =>
                              context.push('/customer/notifications'),
                          onProfileTap: () =>
                              _scaffoldKey.currentState?.openDrawer(),
                          onWalletTap: () => context.push('/customer/wallet'),
                          onSearchTap: () => context.push('/customer/search'),
                          onMicTap: () => context.push('/customer/search'),
                          showSearchRow: false,
                        ),
                      ],
                    ),
                  ),
                ),
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _StickySearchDelegate(
                    onSearchTap: () => context.push('/customer/search'),
                    onMicTap: () => context.push('/customer/search'),
                    showDietaryToggle: !_isScrolling,
                    vegOnly: vegOnly,
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
                  child: Column(
                    children: [
                      HeroSliderBanner(
                        integrated: true,
                        featuredItems: visibleMenuItems,
                        vegOnly: vegOnly,
                        onOrderNowTap: () => context.push('/customer/menu'),
                        onOfferTap: () => context.push('/customer/offers'),
                      ),
                      const SizedBox(height: 24),
                      QuickActionsGrid(
                        items: visibleMenuItems,
                        vegOnly: vegOnly,
                        onActionTap: (action) =>
                            _handleCategoryStripTap(context, action),
                      ),
                      const SizedBox(height: 24),
                      BestsellerCategoriesSection(
                        items: visibleMenuItems,
                        vegOnly: vegOnly,
                        onCategoryTap: (category) =>
                            _handleCategoryStripTap(context, category),
                      ),
                      const SizedBox(height: 24),
                      PopularDishesSection(
                        items: visibleMenuItems,
                        onViewAllTap: () => context.push('/customer/menu'),
                        onFavoritesTap: () =>
                            context.push('/customer/favorites'),
                      ),
                      const SizedBox(height: 32),
                      CustomerFooter(
                        onMenuTap: () => context.push('/customer/menu'),
                        onOffersTap: () => context.push('/customer/offers'),
                        onOrdersTap: () => context.push('/customer/orders'),
                        onHelpTap: () => context.push('/customer/profile'),
                      ),
                      SizedBox(height: cartCount > 0 ? 112 : 40),
                    ],
                  ),
                ),
              ],
            ),
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
                  key: const ValueKey('dashboard-cart-bar'),
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
                key: const ValueKey('dashboard-scanner-fab'),
                margin: const EdgeInsets.only(top: 30),
                height: 64,
                width: 64,
                child: FloatingActionButton(
                  onPressed: () => context.push('/customer/scanner'),
                  backgroundColor: AppTheme.primaryColor,
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
                  if (index == 3) {
                    context.push('/cart');
                    return;
                  }

                  if (index == 1) {
                    _handleReorder();
                    return;
                  }

                  if (index == 4) {
                    context.push('/customer/categories');
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

  void _handleDrawerNavigation(String path) {
    Navigator.of(context).pop();
    context.push(path);
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

  void _handleCategoryStripTap(BuildContext context, String action) {
    switch (action) {
      case 'Under 200':
        context.push('/customer/menu');
        break;
      default:
        context.push('/customer/category/${_slugify(action)}');
    }
  }
}

class _DesktopContent extends StatelessWidget {
  const _DesktopContent({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1180),
        child: child,
      ),
    );
  }
}

class _StickySearchDelegate extends SliverPersistentHeaderDelegate {
  const _StickySearchDelegate({
    required this.onSearchTap,
    required this.onMicTap,
    required this.showDietaryToggle,
    required this.vegOnly,
    required this.onVegChanged,
  });

  final VoidCallback onSearchTap;
  final VoidCallback onMicTap;
  final bool showDietaryToggle;
  final bool vegOnly;
  final ValueChanged<bool> onVegChanged;

  @override
  double get minExtent => 78;

  @override
  double get maxExtent => 78;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Material(
      color: const Color(0xFF0A1B52),
      elevation: overlapsContent ? 8 : 0,
      shadowColor: Colors.black38,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
        child: _DesktopContent(
          child: CustomerSearchToolbar(
            onSearchTap: onSearchTap,
            onMicTap: onMicTap,
            showDietaryToggle: showDietaryToggle,
            vegOnly: vegOnly,
            onVegChanged: onVegChanged,
          ),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _StickySearchDelegate oldDelegate) {
    return oldDelegate.showDietaryToggle != showDietaryToggle ||
        oldDelegate.vegOnly != vegOnly;
  }
}

String _slugify(String value) {
  return value
      .toLowerCase()
      .replaceAll('&', 'and')
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-|-$'), '');
}
