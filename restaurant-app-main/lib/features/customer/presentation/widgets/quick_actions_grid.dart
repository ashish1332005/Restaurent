import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/models/customer_menu_item.dart';

class QuickActionsGrid extends StatefulWidget {
  const QuickActionsGrid({
    super.key,
    required this.onActionTap,
    required this.items,
    required this.vegOnly,
  });

  final ValueChanged<String> onActionTap;
  final List<CustomerMenuItem> items;
  final bool vegOnly;

  @override
  State<QuickActionsGrid> createState() => _QuickActionsGridState();
}

class _QuickActionsGridState extends State<QuickActionsGrid> {
  static const _itemWidth = 102.0;
  static const _itemGap = 16.0;
  static const _scrollStep = _itemWidth + _itemGap;

  final ScrollController _scrollController = ScrollController();
  Timer? _autoScrollTimer;

  _CategoryStripItem get _fixedItem => const _CategoryStripItem(
    label: 'Under 200',
    imageUrl: '',
    accent: Color(0xFFEA580C),
    icon: Icons.shopping_basket_rounded,
  );

  List<_CategoryStripItem> get _categoryItems {
    final seen = <String>{};
    final items = <_CategoryStripItem>[];

    for (final dish in widget.items) {
      if (!seen.add(dish.category)) {
        continue;
      }

      items.add(
        _CategoryStripItem(
          label: dish.category,
          imageUrl: dish.imageUrl,
          accent: _accentForCategory(dish.category, dish.isVeg),
          icon: _iconForCategory(dish.category),
        ),
      );
    }

    return items;
  }

  List<_CategoryStripItem> get _scrollingItems {
    final categories = _categoryItems;
    return [_fixedItem, ...categories];
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _resetAndStartScroll());
  }

  @override
  void didUpdateWidget(covariant QuickActionsGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.vegOnly != widget.vegOnly ||
        oldWidget.items != widget.items) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _resetAndStartScroll(),
      );
    }
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _resetAndStartScroll() {
    if (!mounted || !_scrollController.hasClients) {
      return;
    }

    final displayItems = _scrollingItems;
    if (displayItems.length <= 1) {
      _autoScrollTimer?.cancel();
      return;
    }
    _scrollController.jumpTo(0);
    _startAutoScroll(displayItems.length);
  }

  void _startAutoScroll(int categoryCount) {
    _autoScrollTimer?.cancel();
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (!mounted || !_scrollController.hasClients || categoryCount == 0) {
        return;
      }

      final position = _scrollController.position;
      if (position.maxScrollExtent <= 0) {
        return;
      }

      if (_scrollController.offset >= position.maxScrollExtent - 4) {
        _scrollController.jumpTo(0);
      }

      final nextOffset = (_scrollController.offset + _scrollStep).clamp(
        0.0,
        position.maxScrollExtent,
      );

      _scrollController.animateTo(
        nextOffset,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Expanded(
                child: Container(height: 1, color: const Color(0xFFE5E7EB)),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  widget.vegOnly ? 'Veg Categories' : 'Non-Veg Categories',
                  style: const TextStyle(
                    color: AppTheme.textSecondaryLight,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              Expanded(
                child: Container(height: 1, color: const Color(0xFFE5E7EB)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        SizedBox(
          height: 126,
          child: ListView.separated(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        itemCount: _scrollingItems.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(width: _itemGap),
                        itemBuilder: (context, index) {
                          final item = _scrollingItems[index];

                          return _CategoryStripTapWrapper(
                            label: item.label,
                            onTap: widget.onActionTap,
                            child: _CircleCategoryItem(item: item),
                          );
                        },
                      ),
        ),
      ],
    );
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
        return const Color(0xFFDB2777);
      case 'Salad':
        return const Color(0xFF059669);
      case 'Thali':
        return const Color(0xFF7C3AED);
      case 'Grill':
        return const Color(0xFFEA580C);
      case 'Biryani':
        return const Color(0xFFB45309);
      default:
        return isVeg ? const Color(0xFF1FA971) : AppTheme.primaryColor;
    }
  }

  IconData _iconForCategory(String category) {
    switch (category) {
      case 'Pizza':
        return Icons.local_pizza_outlined;
      case 'Burgers':
        return Icons.lunch_dining_outlined;
      case 'Italian':
        return Icons.dinner_dining_outlined;
      case 'Desserts':
        return Icons.icecream_outlined;
      case 'Salad':
        return Icons.eco_outlined;
      case 'Thali':
        return Icons.rice_bowl_outlined;
      case 'Grill':
        return Icons.outdoor_grill_outlined;
      case 'Biryani':
        return Icons.ramen_dining_outlined;
      default:
        return Icons.restaurant_menu_rounded;
    }
  }
}

class _CategoryStripItem {
  const _CategoryStripItem({
    required this.label,
    required this.imageUrl,
    required this.accent,
    this.icon,
  });

  final String label;
  final String imageUrl;
  final Color accent;
  final IconData? icon;
}

class _CategoryStripTapWrapper extends StatelessWidget {
  const _CategoryStripTapWrapper({
    required this.label,
    required this.onTap,
    required this.child,
  });

  final String label;
  final ValueChanged<String> onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onTap(label),
      borderRadius: BorderRadius.circular(999),
      child: child,
    );
  }
}

class _CircleCategoryItem extends StatelessWidget {
  const _CircleCategoryItem({required this.item});

  final _CategoryStripItem item;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 102,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: item.accent.withValues(alpha: 0.18),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ClipOval(
              child: item.imageUrl.isEmpty
                  ? Container(
                      color: const Color(0xFFFFF1E8),
                      alignment: Alignment.center,
                      child: Icon(
                        item.icon ?? Icons.restaurant_menu_rounded,
                        color: item.accent,
                        size: 32,
                      ),
                    )
                  : Image.network(
                      item.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Container(
                        color: const Color(0xFFFFF1E8),
                        alignment: Alignment.center,
                        child: Icon(
                          Icons.restaurant_menu_rounded,
                          color: item.accent,
                          size: 30,
                        ),
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 20,
            child: Center(
              child: Text(
                item.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                softWrap: false,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppTheme.textPrimaryLight,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  height: 1.0,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
