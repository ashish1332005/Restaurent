import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

class DashboardHeader extends StatelessWidget {
  const DashboardHeader({
    super.key,
    required this.userName,
    required this.onMenuTap,
    required this.onNotificationsTap,
    required this.onProfileTap,
    required this.onWalletTap,
    required this.onSearchTap,
    required this.onMicTap,
    this.showSearchRow = true,
  });

  final String userName;
  final VoidCallback onMenuTap;
  final VoidCallback onNotificationsTap;
  final VoidCallback onProfileTap;
  final VoidCallback onWalletTap;
  final VoidCallback onSearchTap;
  final VoidCallback onMicTap;
  final bool showSearchRow;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 360;

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          compact ? 14 : 20,
          12,
          compact ? 14 : 20,
          10,
        ),
        child: Column(
          children: [
            Row(
              children: [
                InkWell(
                  onTap: onMenuTap,
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
                const SizedBox(width: 10),
                _TopSurfaceButton(
                  icon: Icons.account_balance_wallet_outlined,
                  tooltip: 'Wallet',
                  onTap: onWalletTap,
                ),
                const SizedBox(width: 8),
                _TopSurfaceButton(
                  icon: Icons.person_outline_rounded,
                  tooltip: 'Profile',
                  onTap: onProfileTap,
                ),
              ],
            ),
            if (showSearchRow) ...[
              const SizedBox(height: 16),
              CustomerSearchToolbar(
                onSearchTap: onSearchTap,
                onMicTap: onMicTap,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class CustomerSearchToolbar extends StatelessWidget {
  const CustomerSearchToolbar({
    super.key,
    required this.onSearchTap,
    required this.onMicTap,
    this.showDietaryToggle = false,
    this.vegOnly = true,
    this.onVegChanged,
  });

  final VoidCallback onSearchTap;
  final VoidCallback onMicTap;
  final bool showDietaryToggle;
  final bool vegOnly;
  final ValueChanged<bool>? onVegChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: InkWell(
            onTap: onSearchTap,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              height: 54,
              padding: const EdgeInsets.only(left: 16, right: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.search_rounded,
                    color: Color(0xFF344054),
                    size: 28,
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Search for food',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Color(0xFF667085),
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Voice search',
                    onPressed: onMicTap,
                    icon: const Icon(
                      Icons.mic_none_rounded,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (showDietaryToggle)
              Padding(
                  padding: const EdgeInsets.only(left: 10),
                  child: InkWell(
                    onTap: () => onVegChanged?.call(!vegOnly),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      height: 54,
                      width: 96,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 15,
                            height: 15,
                            decoration: BoxDecoration(
                              color: vegOnly
                                  ? const Color(0xFF3AA655)
                                  : AppTheme.primaryColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            vegOnly ? 'Pure Veg' : 'Non Veg',
                            style: TextStyle(
                              color: vegOnly
                                  ? const Color(0xFF247A39)
                                  : const Color(0xFFB42318),
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
      ],
    );
  }
}

class _TopSurfaceButton extends StatelessWidget {
  const _TopSurfaceButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
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
      ),
    );
  }
}
