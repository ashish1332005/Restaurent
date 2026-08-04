import 'package:flutter/material.dart';

import '../../../../../core/theme/app_theme.dart';

class CartItemCard extends StatelessWidget {
  const CartItemCard({
    super.key,
    required this.title,
    required this.price,
    required this.quantity,
    required this.modifiers,
    required this.imageUrl,
    this.onIncrease,
    this.onDecrease,
    this.onRemove,
  });

  final String title;
  final String price;
  final int quantity;
  final List<String> modifiers;
  final String imageUrl;
  final VoidCallback? onIncrease;
  final VoidCallback? onDecrease;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 420;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: compact ? 16 : 24, vertical: 8),
      child: Container(
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
        padding: const EdgeInsets.all(12),
        child: compact ? _buildCompactLayout() : _buildWideLayout(),
      ),
    );
  }

  Widget _buildWideLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildImage(),
        const SizedBox(width: 16),
        Expanded(child: _buildDetails()),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const SizedBox(height: 12),
            QuantitySelector(
              quantity: quantity,
              onIncrease: onIncrease,
              onDecrease: onDecrease,
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: onRemove,
              child: const Icon(
                Icons.delete_outline,
                color: AppTheme.primaryColor,
                size: 20,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCompactLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildImage(),
            const SizedBox(width: 12),
            Expanded(child: _buildDetails(maxTitleLines: 2)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Text(
              price,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryLight,
              ),
            ),
            const Spacer(),
            QuantitySelector(
              quantity: quantity,
              onIncrease: onIncrease,
              onDecrease: onDecrease,
            ),
            const SizedBox(width: 12),
            InkWell(
              onTap: onRemove,
              child: const Icon(
                Icons.delete_outline,
                color: AppTheme.primaryColor,
                size: 20,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildImage() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Stack(
        children: [
          Image.network(imageUrl, width: 80, height: 80, fit: BoxFit.cover),
          Positioned(
            top: 6,
            left: 6,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Icon(Icons.circle, color: Colors.green.shade600, size: 8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetails({int maxTitleLines = 3}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          maxLines: maxTitleLines,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimaryLight,
          ),
        ),
        const SizedBox(height: 8),
        if (modifiers.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: modifiers.map((mod) => _buildModifierBadge(mod)).toList(),
          ),
        if (maxTitleLines > 2) ...[
          const SizedBox(height: 12),
          Text(
            price,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryLight,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildModifierBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: AppTheme.textSecondaryLight,
          fontSize: 11,
        ),
      ),
    );
  }
}

class QuantitySelector extends StatelessWidget {
  const QuantitySelector({
    super.key,
    required this.quantity,
    this.onIncrease,
    this.onDecrease,
  });

  final int quantity;
  final VoidCallback? onIncrease;
  final VoidCallback? onDecrease;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildBtn(Icons.remove, onDecrease),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              quantity.toString(),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
          _buildBtn(Icons.add, onIncrease),
        ],
      ),
    );
  }

  Widget _buildBtn(IconData icon, VoidCallback? onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Icon(icon, color: AppTheme.primaryColor, size: 16),
      ),
    );
  }
}
