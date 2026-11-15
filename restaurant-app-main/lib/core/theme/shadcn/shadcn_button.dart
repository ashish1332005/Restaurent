import 'package:flutter/material.dart';
import '../../animations/flutterfx/bouncy_tap.dart';
import 'shadcn_theme.dart';

enum ShadcnButtonVariant {
  defaultVariant,
  secondary,
  outline,
  ghost,
  destructive,
}

enum ShadcnButtonSize {
  sm,
  defaultSize,
  lg,
  icon,
}

class ShadcnButton extends StatelessWidget {
  const ShadcnButton({
    super.key,
    required this.onPressed,
    this.label,
    this.icon,
    this.variant = ShadcnButtonVariant.defaultVariant,
    this.size = ShadcnButtonSize.defaultSize,
    this.isLoading = false,
  });

  final VoidCallback? onPressed;
  final String? label;
  final Widget? icon;
  final ShadcnButtonVariant variant;
  final ShadcnButtonSize size;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    Border? border;

    switch (variant) {
      case ShadcnButtonVariant.defaultVariant:
        bg = ShadcnColors.primary;
        fg = ShadcnColors.primaryForeground;
        break;
      case ShadcnButtonVariant.secondary:
        bg = ShadcnColors.secondary;
        fg = ShadcnColors.secondaryForeground;
        break;
      case ShadcnButtonVariant.outline:
        bg = Colors.white;
        fg = ShadcnColors.foreground;
        border = Border.all(color: ShadcnColors.border);
        break;
      case ShadcnButtonVariant.ghost:
        bg = Colors.transparent;
        fg = ShadcnColors.foreground;
        break;
      case ShadcnButtonVariant.destructive:
        bg = ShadcnColors.destructive;
        fg = ShadcnColors.destructiveForeground;
        break;
    }

    double height;
    EdgeInsets padding;
    double fontSize;

    switch (size) {
      case ShadcnButtonSize.sm:
        height = 36;
        padding = const EdgeInsets.symmetric(horizontal: 12);
        fontSize = 12;
        break;
      case ShadcnButtonSize.defaultSize:
        height = 42;
        padding = const EdgeInsets.symmetric(horizontal: 16);
        fontSize = 14;
        break;
      case ShadcnButtonSize.lg:
        height = 48;
        padding = const EdgeInsets.symmetric(horizontal: 24);
        fontSize = 15;
        break;
      case ShadcnButtonSize.icon:
        height = 40;
        padding = EdgeInsets.zero;
        fontSize = 14;
        break;
    }

    final isIconOnly = size == ShadcnButtonSize.icon;

    return BouncyTap(
      onTap: isLoading ? null : onPressed,
      scaleDown: 0.96,
      child: Container(
        height: height,
        width: isIconOnly ? height : null,
        padding: isIconOnly ? EdgeInsets.zero : padding,
        decoration: BoxDecoration(
          color: onPressed == null ? bg.withValues(alpha: 0.5) : bg,
          borderRadius: BorderRadius.circular(ShadcnRadius.md),
          border: border,
          boxShadow: variant == ShadcnButtonVariant.defaultVariant
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: isLoading
              ? SizedBox.square(
                  dimension: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: fg,
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (icon != null) ...[
                      icon!,
                      if (label != null) const SizedBox(width: 8),
                    ],
                    if (label != null)
                      Text(
                        label!,
                        style: TextStyle(
                          fontSize: fontSize,
                          fontWeight: FontWeight.w600,
                          color: fg,
                          letterSpacing: -0.1,
                        ),
                      ),
                  ],
                ),
        ),
      ),
    );
  }
}
