import 'package:flutter/material.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../../customer/application/customer_cart_provider.dart';

class OrderSummaryCard extends StatelessWidget {
  const OrderSummaryCard({super.key, this.summary});

  final CustomerCartSummary? summary;

  @override
  Widget build(BuildContext context) {
    final discount = summary?.discount ?? 0;
    final appliedCoupon = summary?.appliedCoupon;
    final compact = MediaQuery.sizeOf(context).width < 420;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: compact ? 16 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Order Summary',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryLight,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                _buildRow(
                  'Item Total (${summary?.itemCount ?? 3} Items)',
                  formatPrice(
                    summary?.subtotal ?? 727.0,
                    showDecimalsForWholeNumbers: true,
                  ),
                ),
                if (discount > 0) ...[
                  const SizedBox(height: 12),
                  _buildRow(
                    'Coupon (${appliedCoupon?.code ?? 'Saved'})',
                    '- ${formatPrice(discount, showDecimalsForWholeNumbers: true)}',
                    valueColor: const Color(0xFF16A34A),
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Flexible(
                            child: Text(
                              'Service Charge (5%)',
                              style: TextStyle(
                                color: Colors.grey.shade700,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.info_outline,
                            size: 14,
                            color: Colors.grey.shade500,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      formatPrice(
                        summary?.serviceCharge ?? 36.35,
                        showDecimalsForWholeNumbers: true,
                      ),
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        color: AppTheme.textPrimaryLight,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildRow(
                  'CGST (2.5%)',
                  formatPrice(
                    summary?.cgst ?? 19.08,
                    showDecimalsForWholeNumbers: true,
                  ),
                ),
                const SizedBox(height: 12),
                _buildRow(
                  'SGST (2.5%)',
                  formatPrice(
                    summary?.sgst ?? 19.08,
                    showDecimalsForWholeNumbers: true,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: List.generate(
                    40,
                    (index) => Expanded(
                      child: Container(
                        height: 1,
                        color: index.isEven
                            ? Colors.grey.shade300
                            : Colors.transparent,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Total Payable',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimaryLight,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      formatPrice(
                        summary?.total ?? 801.51,
                        showDecimalsForWholeNumbers: true,
                      ),
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF22C55E),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(String title, String value, {Color? valueColor}) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          value,
          textAlign: TextAlign.right,
          style: TextStyle(
            color: valueColor ?? AppTheme.textPrimaryLight,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
