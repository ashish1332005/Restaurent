import 'package:flutter/material.dart';
import 'hospitality_theme.dart';

class HospitalityPage extends StatelessWidget {
  const HospitalityPage({
    super.key,
    required this.child,
    this.maxWidth = 1280,
    this.compact = false,
  });
  final Widget child;
  final double maxWidth;
  final bool compact;

  @override
  Widget build(BuildContext context) => SafeArea(
    child: LayoutBuilder(
      builder: (context, constraints) {
        final horizontal = constraints.maxWidth < 600
            ? (compact ? 12.0 : 16.0)
            : constraints.maxWidth < 1000
            ? 24.0
            : 32.0;
        return SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: EdgeInsets.fromLTRB(horizontal, 16, horizontal, 32),
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: child,
            ),
          ),
        );
      },
    ),
  );
}

class HospitalityCard extends StatelessWidget {
  const HospitalityCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(HospitalitySpace.md),
    this.color,
    this.onTap,
  });
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: color ?? HospitalityColors.surface,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(HospitalityRadius.medium),
      side: const BorderSide(color: HospitalityColors.outline),
    ),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: Padding(padding: padding, child: child),
    ),
  );
}

class HospitalitySectionTitle extends StatelessWidget {
  const HospitalitySectionTitle({
    super.key,
    required this.title,
    this.subtitle,
    this.action,
  });
  final String title;
  final String? subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.headlineSmall),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(subtitle!, style: Theme.of(context).textTheme.bodySmall),
            ],
          ],
        ),
      ),
      if (action != null) ...[const SizedBox(width: 12), action!],
    ],
  );
}

class HospitalityEmptyState extends StatelessWidget {
  const HospitalityEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });
  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: HospitalitySpace.xl),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 4),
        DecoratedBox(
          decoration: const BoxDecoration(
            color: HospitalityColors.softSaffron,
            shape: BoxShape.circle,
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Icon(icon, color: HospitalityColors.saffron, size: 28),
          ),
        ),
        const SizedBox(height: 16),
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 6),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        if (action != null) ...[const SizedBox(height: 16), action!],
      ],
    ),
  );
}
