import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class AdminSidebar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;
  final double width;

  const AdminSidebar({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
    this.width = 260,
  });

  @override
  Widget build(BuildContext context) {
    final items = <({IconData icon, String title, int index})>[
      (icon: Icons.dashboard_customize_rounded, title: 'Dashboard', index: 0),
      (icon: Icons.menu_book_rounded, title: 'Menu Management', index: 1),
      (icon: Icons.receipt_long_rounded, title: 'Orders', index: 2),
      (
        icon: Icons.table_restaurant_rounded,
        title: 'Table Management',
        index: 3,
      ),
      (icon: Icons.inventory_2_rounded, title: 'Inventory', index: 4),
      (icon: Icons.groups_rounded, title: 'Staff Management', index: 5),
      (icon: Icons.event_seat_rounded, title: 'Reservations', index: 6),
      (
        icon: Icons.insert_chart_rounded,
        title: 'Reports & Analytics',
        index: 7,
      ),
      (icon: Icons.local_offer_rounded, title: 'Offers & Coupons', index: 8),
      (icon: Icons.settings_rounded, title: 'Settings', index: 9),
    ];

    return Container(
      width: width,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF171012), Color(0xFF231317), Color(0xFF120C0D)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        border: Border(right: BorderSide(color: Color(0xFF332426))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 28),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: Row(
                children: [
                  Container(
                    height: 48,
                    width: 48,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.restaurant_menu_rounded,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'TastyBite',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Restaurant Command Center',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 28),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'RESTAURANT OPERATIONS',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: Colors.white54,
                letterSpacing: 1.2,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              children: [
                for (final item in items)
                  _buildMenuItem(context, item.icon, item.title, item.index),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primaryColor.withValues(alpha: 0.95),
                    const Color(0xFFFF8A3D),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  Container(
                    height: 42,
                    width: 42,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Icon(
                      Icons.insights_rounded,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Live operations',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'All systems online • Peak at 8:30 PM',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context,
    IconData icon,
    String title,
    int index,
  ) {
    final isActive = selectedIndex == index;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Material(
        color: isActive
            ? Colors.white.withValues(alpha: 0.10)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 4,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          leading: Container(
            height: 42,
            width: 42,
            decoration: BoxDecoration(
              color: isActive
                  ? AppTheme.primaryColor
                  : Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(
              icon,
              color: isActive ? Colors.white : Colors.white70,
              size: 20,
            ),
          ),
          title: Text(
            title,
            style: TextStyle(
              color: isActive ? Colors.white : Colors.white70,
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
          trailing: isActive
              ? const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.white70,
                  size: 14,
                )
              : null,
          onTap: () => onItemSelected(index),
        ),
      ),
    );
  }
}
