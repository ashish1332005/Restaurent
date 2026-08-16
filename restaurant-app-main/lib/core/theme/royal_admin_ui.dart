import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

abstract final class RoyalAdminColors {
  static const navy = Color(0xFF071A31);
  static const navySoft = Color(0xFF102B50);
  static const ivory = Color(0xFFFFFBF4);
  static const gold = Color(0xFFC99232);
  static const goldLight = Color(0xFFF4D38B);
  static const line = Color(0xFFE9DCCD);
  static const ink = Color(0xFF142033);
  static const muted = Color(0xFF6D7480);
}

class RoyalAdminSurface extends StatelessWidget {
  const RoyalAdminSurface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.onTap,
  });
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white.withValues(alpha: .92),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(18),
      side: const BorderSide(color: RoyalAdminColors.line),
    ),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: Padding(padding: padding, child: child),
    ),
  );
}

class RoyalAdminIcon extends StatelessWidget {
  const RoyalAdminIcon({super.key, required this.icon, required this.color});
  final IconData icon;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
    width: 48,
    height: 48,
    decoration: BoxDecoration(
      color: color.withValues(alpha: .12),
      shape: BoxShape.circle,
    ),
    child: Icon(icon, color: color, size: 25),
  );
}

class RoyalMetricCard extends StatelessWidget {
  const RoyalMetricCard({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    this.detail,
    this.onTap,
  });
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final String? detail;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => RoyalAdminSurface(
    onTap: onTap,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RoyalAdminIcon(icon: icon, color: iconColor),
        const SizedBox(height: 12),
        Text(
          label,
          style: const TextStyle(
            color: RoyalAdminColors.muted,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: GoogleFonts.playfairDisplay(
            color: RoyalAdminColors.ink,
            fontSize: 25,
            fontWeight: FontWeight.w700,
          ),
        ),
        if (detail != null) ...[
          const SizedBox(height: 6),
          Text(
            detail!,
            style: TextStyle(
              color: iconColor,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ],
    ),
  );
}

class RoyalSectionHeading extends StatelessWidget {
  const RoyalSectionHeading({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
  });
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(
          title,
          style: GoogleFonts.playfairDisplay(
            color: RoyalAdminColors.ink,
            fontSize: 24,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      if (actionLabel != null)
        TextButton.icon(
          onPressed: onAction,
          label: Text(actionLabel!),
          icon: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
          iconAlignment: IconAlignment.end,
        ),
    ],
  );
}

class RoyalInsightTile extends StatelessWidget {
  const RoyalInsightTile({
    super.key,
    required this.icon,
    required this.color,
    required this.title,
    required this.value,
    this.onTap,
  });
  final IconData icon;
  final Color color;
  final String title;
  final String value;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => RoyalAdminSurface(
    onTap: onTap,
    padding: const EdgeInsets.all(12),
    child: Row(
      children: [
        RoyalAdminIcon(icon: icon, color: color),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: RoyalAdminColors.ink,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
