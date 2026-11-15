import 'package:flutter/material.dart';
import 'shadcn_theme.dart';

enum ShadcnBadgeVariant {
  defaultVariant,
  secondary,
  outline,
  destructive,
  success,
  warning,
}

class ShadcnBadge extends StatelessWidget {
  const ShadcnBadge({
    super.key,
    required this.label,
    this.variant = ShadcnBadgeVariant.defaultVariant,
    this.icon,
    this.onTap,
  });

  final String label;
  final ShadcnBadgeVariant variant;
  final IconData? icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    Border? border;

    switch (variant) {
      case ShadcnBadgeVariant.defaultVariant:
        bg = ShadcnColors.primary;
        fg = ShadcnColors.primaryForeground;
        break;
      case ShadcnBadgeVariant.secondary:
        bg = ShadcnColors.secondary;
        fg = ShadcnColors.secondaryForeground;
        break;
      case ShadcnBadgeVariant.outline:
        bg = Colors.transparent;
        fg = ShadcnColors.foreground;
        border = Border.all(color: ShadcnColors.border);
        break;
      case ShadcnBadgeVariant.destructive:
        bg = ShadcnColors.destructive;
        fg = ShadcnColors.destructiveForeground;
        break;
      case ShadcnBadgeVariant.success:
        bg = ShadcnColors.successMuted;
        fg = ShadcnColors.success;
        border = Border.all(color: ShadcnColors.success.withValues(alpha: 0.3));
        break;
      case ShadcnBadgeVariant.warning:
        bg = ShadcnColors.warningMuted;
        fg = ShadcnColors.warning;
        border = Border.all(color: ShadcnColors.warning.withValues(alpha: 0.3));
        break;
    }

    Widget content = Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(ShadcnRadius.full),
        border: border,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: fg),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: fg,
              height: 1.2,
            ),
          ),
        ],
      ),
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(ShadcnRadius.full),
        child: content,
      );
    }
    return content;
  }
}
