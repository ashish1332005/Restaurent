import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

class PopularFilterStrip extends StatelessWidget {
  const PopularFilterStrip({
    super.key,
    required this.selectedFilter,
    required this.onFilterSelected,
  });

  final String selectedFilter;
  final ValueChanged<String> onFilterSelected;

  static const _filters = <({String label, IconData icon})>[
    (label: 'All', icon: Icons.grid_view_rounded),
    (label: 'Near Me', icon: Icons.near_me_outlined),
    (label: 'Top Rated', icon: Icons.star_outline_rounded),
    (label: 'Fast Delivery', icon: Icons.timer_outlined),
    (label: 'Offers', icon: Icons.local_offer_outlined),
    (label: 'Under ₹299', icon: Icons.currency_rupee_rounded),
    (label: 'Pure Veg', icon: Icons.eco_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'Explore dishes',
            style: TextStyle(
              color: AppTheme.textPrimaryLight,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 44,
          child: ScrollConfiguration(
            behavior: const _FilterStripScrollBehavior(),
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              itemCount: _filters.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
              final filter = _filters[index];
              final selected = filter.label == selectedFilter;
              return InkWell(
                onTap: () => onFilterSelected(filter.label),
                borderRadius: BorderRadius.circular(14),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: selected ? AppTheme.primaryColor : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: selected
                          ? AppTheme.primaryColor
                          : const Color(0xFFE4E7EC),
                    ),
                    boxShadow: selected
                        ? [
                            BoxShadow(
                              color: AppTheme.primaryColor.withValues(alpha: .18),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        filter.icon,
                        size: 18,
                        color: selected
                            ? Colors.white
                            : AppTheme.textSecondaryLight,
                      ),
                      const SizedBox(width: 7),
                      Text(
                        filter.label,
                        style: TextStyle(
                          color: selected
                              ? Colors.white
                              : AppTheme.textPrimaryLight,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _FilterStripScrollBehavior extends MaterialScrollBehavior {
  const _FilterStripScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => const {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.stylus,
      };
}
