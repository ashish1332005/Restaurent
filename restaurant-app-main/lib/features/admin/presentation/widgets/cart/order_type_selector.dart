import 'package:flutter/material.dart';

import '../../../../../core/theme/app_theme.dart';

class OrderTypeSelector extends StatelessWidget {
  const OrderTypeSelector({
    super.key,
    this.itemCount = 3,
    this.primaryLabel = 'Dine In',
    this.secondaryLabel = 'Takeaway',
    this.primarySelected = true,
    this.onPrimaryTap,
    this.onSecondaryTap,
  });

  final int itemCount;
  final String primaryLabel;
  final String secondaryLabel;
  final bool primarySelected;
  final VoidCallback? onPrimaryTap;
  final VoidCallback? onSecondaryTap;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 420;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: compact ? 16 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$itemCount Items in Cart',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryLight,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: compact ? double.infinity : null,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.borderLight),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Expanded(
                  child: _buildSegment(
                    title: primaryLabel,
                    isSelected: primarySelected,
                    onTap: onPrimaryTap,
                  ),
                ),
                Container(width: 1, height: 20, color: AppTheme.borderLight),
                Expanded(
                  child: _buildSegment(
                    title: secondaryLabel,
                    isSelected: !primarySelected,
                    onTap: onSecondaryTap,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSegment({
    required String title,
    required bool isSelected,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFEF2F2) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected
                ? AppTheme.primaryColor
                : AppTheme.textSecondaryLight,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
