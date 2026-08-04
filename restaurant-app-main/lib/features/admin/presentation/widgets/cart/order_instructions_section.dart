import 'package:flutter/material.dart';

import '../../../../../core/theme/app_theme.dart';

class OrderInstructionsSection extends StatelessWidget {
  const OrderInstructionsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 720;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: compact ? 16 : 24),
      child: compact
          ? Column(
              children: [
                _buildInstructionCard(context),
                const SizedBox(height: 16),
                _buildEtaCard(),
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 3, child: _buildInstructionCard(context)),
                const SizedBox(width: 16),
                Expanded(flex: 2, child: _buildEtaCard(height: 146)),
              ],
            ),
    );
  }

  Widget _buildInstructionCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.description_outlined,
                color: Colors.orange.shade700,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Special Instructions',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimaryLight,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            height: 80,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.borderLight),
            ),
            child: Stack(
              children: [
                TextField(
                  maxLines: 2,
                  decoration: InputDecoration(
                    hintText: 'Any special instructions for the kitchen...',
                    hintStyle: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 12,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textPrimaryLight,
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Text(
                    '0/120',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 10),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEtaCard({double? height}) {
    return Container(
      height: height,
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDCFCE7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: height == null ? MainAxisSize.min : MainAxisSize.max,
        children: const [
          Row(
            children: [
              Icon(Icons.access_time, color: Color(0xFF22C55E), size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Estimated Time',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF166534),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Text(
            '20-25 mins',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF166534),
            ),
          ),
          SizedBox(height: 8),
          Text(
            'We will notify you when your order is ready',
            style: TextStyle(
              fontSize: 11,
              color: Color(0xFF166534),
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}
