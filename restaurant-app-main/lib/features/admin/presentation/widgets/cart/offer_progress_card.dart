import 'package:flutter/material.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../../customer/application/customer_cart_provider.dart';

class OfferProgressCard extends StatelessWidget {
  const OfferProgressCard({super.key, this.summary});

  final CustomerCartSummary? summary;

  @override
  Widget build(BuildContext context) {
    const successColor = Color(0xFF22C55E);
    final amountToUnlockOffer = summary?.amountToUnlockOffer ?? 213.0;
    final subtotal = summary?.subtotal ?? 787.0;
    final offerThreshold = summary?.offerThreshold ?? 1000.0;
    final progress = summary?.offerProgress ?? 0.8;
    final isOfferUnlocked = amountToUnlockOffer <= 0;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: MediaQuery.sizeOf(context).width < 420 ? 16 : 24,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 420;

          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFDCFCE7)),
            ),
            child: compact
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildGiftIcon(),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              isOfferUnlocked
                                  ? '10% OFF has been unlocked for this order'
                                  : 'Add items worth ${formatPrice(amountToUnlockOffer)} more to get 10% OFF',
                              style: const TextStyle(
                                color: AppTheme.textPrimaryLight,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildProgressBar(progress, successColor),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${formatPrice(subtotal)} / ${formatPrice(offerThreshold)}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textPrimaryLight,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          _buildOfferChip(successColor, isOfferUnlocked),
                        ],
                      ),
                    ],
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _buildGiftIcon(),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isOfferUnlocked
                                  ? '10% OFF has been unlocked for this order'
                                  : 'Add items worth ${formatPrice(amountToUnlockOffer)} more to get 10% OFF',
                              style: const TextStyle(
                                color: AppTheme.textPrimaryLight,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 12),
                            _buildProgressBar(progress, successColor),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${formatPrice(subtotal)} / ${formatPrice(offerThreshold)}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimaryLight,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildOfferChip(successColor, isOfferUnlocked),
                        ],
                      ),
                    ],
                  ),
          );
        },
      ),
    );
  }

  Widget _buildGiftIcon() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(
        Icons.card_giftcard,
        color: Colors.orangeAccent,
        size: 24,
      ),
    );
  }

  Widget _buildProgressBar(double progress, Color successColor) {
    return Stack(
      children: [
        Container(
          height: 6,
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xFFDCFCE7),
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        FractionallySizedBox(
          widthFactor: progress,
          child: Container(
            height: 6,
            decoration: BoxDecoration(
              color: successColor,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOfferChip(Color successColor, bool isOfferUnlocked) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: successColor),
      ),
      child: Text(
        isOfferUnlocked ? 'Offer Applied' : 'View Offers',
        style: TextStyle(
          color: successColor,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
