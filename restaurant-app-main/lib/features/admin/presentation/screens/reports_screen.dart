import 'package:flutter/material.dart';
import '../../../../core/services/backup_export_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../widgets/admin_ui.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  void _showExportOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Export Restaurant Reports',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            const Text(
              'Select data report to generate and download in CSV format.',
              style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.table_chart_rounded, color: Color(0xFF1FA971)),
              title: const Text('Export Daily Sales & Orders Report (CSV)'),
              subtitle: const Text('Includes order IDs, totals, status, and payment mode'),
              onTap: () {
                Navigator.pop(sheetContext);
                final csvData = BackupExportService.generateSalesCsvReport();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('📊 Sales Report Exported! (${csvData.split('\n').length} records)'),
                    backgroundColor: const Color(0xFF1FA971),
                  ),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.people_alt_rounded, color: Color(0xFF4B6BFB)),
              title: const Text('Export Staff Roster & Shifts Report (CSV)'),
              subtitle: const Text('Includes staff credentials, assigned roles, and shifts'),
              onTap: () {
                Navigator.pop(sheetContext);
                final csvData = BackupExportService.generateStaffCsvReport();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('👥 Staff Roster Exported! (${csvData.split('\n').length} records)'),
                    backgroundColor: const Color(0xFF4B6BFB),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: adminPagePadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AdminPageHeader(
            eyebrow: 'PERFORMANCE & ANALYTICS',
            title: 'Make reporting easier to read and act on.',
            subtitle:
                'Bring revenue trends, margin signals, and top-selling items into one calmer analytics view.',
            trailing: ElevatedButton.icon(
              onPressed: () => _showExportOptions(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1FA971),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              icon: const Icon(Icons.download_rounded),
              label: const Text('Export Sales Data (CSV)'),
            ),
          ),
          const SizedBox(height: 22),
          const AdminInsightStrip(
            children: [
              AdminMiniInfoCard(
                label: 'Gross revenue',
                value: '\u20B91,24,500',
                icon: Icons.payments_rounded,
                color: Color(0xFF1FA971),
              ),
              AdminMiniInfoCard(
                label: 'Net profit',
                value: '\u20B935,200',
                icon: Icons.trending_up_rounded,
                color: Color(0xFF4B6BFB),
              ),
              AdminMiniInfoCard(
                label: 'Food cost',
                value: '28%',
                icon: Icons.pie_chart_rounded,
                color: AppTheme.primaryColor,
              ),
            ],
          ),
          const SizedBox(height: 22),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final stacked = constraints.maxWidth < 1100;

                if (stacked) {
                  return ListView(
                    children: [
                      SizedBox(height: 360, child: _buildRevenuePanel()),
                      const SizedBox(height: 18),
                      _buildTopItemsPanel(),
                    ],
                  );
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 2, child: _buildRevenuePanel()),
                    const SizedBox(width: 18),
                    Expanded(child: _buildTopItemsPanel()),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRevenuePanel() {
    return AdminPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AdminSectionHeading(
            title: 'Revenue trend',
            subtitle: 'Monthly earnings momentum across the current period.',
          ),
          const SizedBox(height: 22),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: const [
                _ReportBar(label: 'Jan', height: 90, color: Color(0xFF4B6BFB)),
                _ReportBar(label: 'Feb', height: 115, color: Color(0xFF6280FC)),
                _ReportBar(
                  label: 'Mar',
                  height: 130,
                  color: AppTheme.primaryColor,
                ),
                _ReportBar(label: 'Apr', height: 155, color: Color(0xFFFF7584)),
                _ReportBar(label: 'May', height: 176, color: Color(0xFFFF9F55)),
                _ReportBar(label: 'Jun', height: 205, color: Color(0xFF1FA971)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopItemsPanel() {
    return AdminPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          AdminSectionHeading(
            title: 'Top selling items',
            subtitle: 'Best performers by order count and contribution.',
          ),
          SizedBox(height: 18),
          _TopItemTile(
            name: 'Butter Chicken',
            orders: '145 orders',
            revenue: '\u20B946,400',
            color: AppTheme.primaryColor,
          ),
          SizedBox(height: 14),
          _TopItemTile(
            name: 'Garlic Naan',
            orders: '320 orders',
            revenue: '\u20B919,200',
            color: Color(0xFF4B6BFB),
          ),
          SizedBox(height: 14),
          _TopItemTile(
            name: 'Paneer Tikka',
            orders: '95 orders',
            revenue: '\u20B922,800',
            color: Color(0xFF1FA971),
          ),
        ],
      ),
    );
  }
}

class _ReportBar extends StatelessWidget {
  final String label;
  final double height;
  final Color color;

  const _ReportBar({
    required this.label,
    required this.height,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Container(
              height: height,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color.withValues(alpha: 0.35), color],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              style: const TextStyle(
                color: AppTheme.textSecondaryLight,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopItemTile extends StatelessWidget {
  final String name;
  final String orders;
  final String revenue;
  final Color color;

  const _TopItemTile({
    required this.name,
    required this.orders,
    required this.revenue,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 340;

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(Icons.star_rounded, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      orders,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondaryLight,
                      ),
                    ),
                    if (compact) ...[
                      const SizedBox(height: 8),
                      Text(
                        revenue,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: color,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                    ],
                  ],
                ),
              ),
              if (!compact)
                Text(
                  revenue,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w800,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
