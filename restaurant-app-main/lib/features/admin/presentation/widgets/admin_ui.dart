import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

const adminOrange = Color(0xFFFF4D0A);
const adminBackground = Color(0xFFF7F8FB);
const adminSurface = Colors.white;
const adminBorder = Color(0xFFE5EAF1);
const adminInk = Color(0xFF111827);
const adminMuted = Color(0xFF687385);
const adminSuccess = Color(0xFF16A34A);

final adminCardShadow = [
  BoxShadow(
    color: const Color(0xFF101828).withValues(alpha: 0.070),
    blurRadius: 26,
    offset: const Offset(0, 14),
  ),
];

bool isAdminCompactLayout(BuildContext context, {double breakpoint = 1024}) =>
    MediaQuery.sizeOf(context).width < breakpoint;

double adminPageHorizontalPadding(BuildContext context) {
  final width = MediaQuery.sizeOf(context).width;
  if (width < 600) {
    return 16;
  }
  if (width < 1024) {
    return 20;
  }
  return 28;
}

double adminPageVerticalPadding(BuildContext context) {
  final width = MediaQuery.sizeOf(context).width;
  return width < 600 ? 16 : 28;
}

EdgeInsets adminPagePadding(BuildContext context, {double? bottom}) {
  final horizontal = adminPageHorizontalPadding(context);
  final vertical = adminPageVerticalPadding(context);
  return EdgeInsets.fromLTRB(
    horizontal,
    vertical,
    horizontal,
    bottom ?? vertical,
  );
}

class AdminShellBackground extends StatelessWidget {
  final Widget child;

  const AdminShellBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFFFFBF8), adminBackground, Color(0xFFF5F7FB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: child,
    );
  }
}

class AdminPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double radius;
  final Color? color;

  const AdminPanel({
    super.key,
    required this.child,
    this.padding,
    this.radius = 24,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color ?? adminSurface,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: adminBorder),
        boxShadow: adminCardShadow,
      ),
      child: Padding(
        padding: padding ?? const EdgeInsets.all(22),
        child: child,
      ),
    );
  }
}

class AdminResponsiveDataTable extends StatelessWidget {
  const AdminResponsiveDataTable({
    super.key,
    required this.columns,
    required this.rows,
    this.minWidth = 720,
    this.columnSpacing = 24,
    this.headingRowColor,
  });

  final List<DataColumn> columns;
  final List<DataRow> rows;
  final double minWidth;
  final double columnSpacing;
  final WidgetStateProperty<Color?>? headingRowColor;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final needsHorizontalScroll = constraints.maxWidth < minWidth;
        final effectiveWidth = constraints.maxWidth > minWidth
            ? constraints.maxWidth
            : minWidth;

        return Scrollbar(
          thumbVisibility: needsHorizontalScroll,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: effectiveWidth),
              child: DataTable(
                columnSpacing: columnSpacing,
                headingRowColor: headingRowColor,
                columns: columns,
                rows: rows,
              ),
            ),
          ),
        );
      },
    );
  }
}

class AdminPageHeader extends StatelessWidget {
  final String eyebrow;
  final String title;
  final String subtitle;
  final Widget? trailing;

  const AdminPageHeader({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final compact = MediaQuery.sizeOf(context).width < 600;

    return Wrap(
      spacing: 16,
      runSpacing: 16,
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: adminOrange.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  eyebrow,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: adminOrange,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                title,
                style: theme.textTheme.headlineLarge?.copyWith(
                  fontSize: compact ? 24 : 32,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                  height: 1.12,
                  color: adminInk,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                subtitle,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontSize: compact ? 14 : 16,
                  color: adminMuted,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
        ?trailing,
      ],
    );
  }
}

class AdminMetricCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final String detail;
  final Color accent;

  const AdminMetricCard({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    required this.detail,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AdminPanel(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: accent),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.trending_up_rounded, color: accent, size: 15),
                    const SizedBox(width: 4),
                    Text(
                      'LIVE',
                      style: TextStyle(
                        color: accent,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: .5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            title,
            style: theme.textTheme.bodyLarge?.copyWith(color: adminMuted),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              detail,
              style: theme.textTheme.bodySmall?.copyWith(
                color: accent,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AdminInsightStrip extends StatelessWidget {
  final List<Widget> children;

  const AdminInsightStrip({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    return AdminPanel(
      padding: const EdgeInsets.all(8),
      color: adminSurface,
      child: Wrap(spacing: 12, runSpacing: 12, children: children),
    );
  }
}

class AdminMiniInfoCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const AdminMiniInfoCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 180),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: adminMuted),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class AdminStatusChip extends StatelessWidget {
  final String label;
  final Color color;

  const AdminStatusChip({super.key, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class AdminSectionHeading extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget? trailing;

  const AdminSectionHeading({
    super.key,
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 16,
      runSpacing: 12,
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: adminMuted),
            ),
          ],
        ),
        ?trailing,
      ],
    );
  }
}

class AdminDetailRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const AdminDetailRow({
    super.key,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: adminMuted),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: valueColor ?? AppTheme.textPrimaryLight,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class AdminActionTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const AdminActionTile({
    super.key,
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final content = Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: adminBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: adminMuted,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          if (trailing case final trailingWidget?) ...[
            const SizedBox(width: 12),
            trailingWidget,
          ],
        ],
      ),
    );

    if (onTap == null) {
      return content;
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: content,
    );
  }
}
