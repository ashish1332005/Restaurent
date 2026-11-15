import 'package:flutter/material.dart';
import 'shadcn_theme.dart';

class ShadcnStatCard extends StatelessWidget {
  const ShadcnStatCard({
    super.key,
    required this.title,
    required this.value,
    this.description,
    this.icon,
    this.trend,
    this.isPositiveTrend = true,
    this.onTap,
  });

  final String title;
  final String value;
  final String? description;
  final IconData? icon;
  final String? trend;
  final bool isPositiveTrend;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: ShadcnColors.card,
        borderRadius: BorderRadius.circular(ShadcnRadius.lg),
        border: Border.all(color: ShadcnColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: ShadcnTypography.muted.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (icon != null)
                Icon(icon, size: 16, color: ShadcnColors.mutedForeground),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: ShadcnTypography.h2.copyWith(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.8,
            ),
          ),
          if (trend != null || description != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                if (trend != null) ...[
                  Text(
                    trend!,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isPositiveTrend
                          ? ShadcnColors.success
                          : ShadcnColors.destructive,
                    ),
                  ),
                  const SizedBox(width: 4),
                ],
                if (description != null)
                  Expanded(
                    child: Text(
                      description!,
                      style: ShadcnTypography.small.copyWith(fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
