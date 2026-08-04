import 'package:flutter/material.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../../customer/application/customer_cart_provider.dart';

class CheckoutBottomBar extends StatelessWidget {
  const CheckoutBottomBar({super.key, this.total = 801.51, this.onCheckout});

  final double total;
  final VoidCallback? onCheckout;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Use the bar's real available width instead of the device width. The
        // cart can sit inside a padded panel on tablets and desktop layouts.
        final compact = constraints.maxWidth < 620;

        return Container(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 16 : 24,
            vertical: 16,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 20,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: compact ? _buildCompactLayout() : _buildWideLayout(),
          ),
        );
      },
    );
  }

  Widget _buildWideLayout() {
    return Row(
      children: [
        _buildSecurityIcon(),
        const SizedBox(width: 16),
        _buildSecurityText(),
        const Spacer(),
        Row(
          children: [
            _buildTotals(crossAxisAlignment: CrossAxisAlignment.end),
            const SizedBox(width: 16),
            _buildCheckoutButton(expand: false),
          ],
        ),
      ],
    );
  }

  Widget _buildCompactLayout() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSecurityIcon(),
            const SizedBox(width: 12),
            Expanded(child: _buildSecurityText()),
            const SizedBox(width: 12),
            _buildTotals(crossAxisAlignment: CrossAxisAlignment.end),
          ],
        ),
        const SizedBox(height: 14),
        _buildCheckoutButton(expand: true),
      ],
    );
  }

  Widget _buildSecurityIcon() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        color: Color(0xFFFFF7ED),
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.security, color: Colors.orange, size: 20),
    );
  }

  Widget _buildSecurityText() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Safe & Secure',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimaryLight,
          ),
        ),
        Text(
          '100% secure payments',
          style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
        ),
      ],
    );
  }

  Widget _buildTotals({required CrossAxisAlignment crossAxisAlignment}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: crossAxisAlignment,
      children: [
        Text(
          formatPrice(total, showDecimalsForWholeNumbers: true),
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimaryLight,
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'View Bill Details',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
            Icon(
              Icons.keyboard_arrow_down,
              size: 14,
              color: Colors.grey.shade600,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCheckoutButton({required bool expand}) {
    final button = ElevatedButton(
      onPressed: onCheckout,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              'Proceed to Checkout',
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
          ),
          SizedBox(width: 8),
          Icon(Icons.arrow_forward, size: 18),
        ],
      ),
    );

    if (!expand) {
      return button;
    }

    return SizedBox(width: double.infinity, child: button);
  }
}
