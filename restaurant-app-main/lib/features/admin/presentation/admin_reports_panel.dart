import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/network/restaurant_api.dart';
import '../../../core/services/report_download_service.dart';

class AdminReportsPanel extends StatefulWidget {
  const AdminReportsPanel({super.key, required this.branchId});
  final String? branchId;
  @override
  State<AdminReportsPanel> createState() => _AdminReportsPanelState();
}

class _AdminReportsPanelState extends State<AdminReportsPanel> {
  int days = 30;
  bool loading = true;
  Map<String, dynamic> sales = {}, menu = {};
  List<Map<String, dynamic>> customers = [];
  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant AdminReportsPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.branchId != widget.branchId) _load();
  }

  Map<String, dynamic> get query {
    final end = DateTime.now(), start = end.subtract(Duration(days: days));
    return {
      'branchId': widget.branchId,
      'startDate': start.toUtc().toIso8601String(),
      'endDate': end.toUtc().toIso8601String(),
      'limit': 10,
    };
  }

  Future<void> _load() async {
    if (widget.branchId == null) {
      if (mounted) setState(() => loading = false);
      return;
    }
    setState(() => loading = true);
    try {
      final result = await Future.wait([
        RestaurantApi.getSalesReport(query),
        RestaurantApi.getMenuPerformanceReport(query),
        RestaurantApi.getCustomerInsightsReport(query),
      ]);
      if (mounted)
        setState(() {
          sales = result[0] as Map<String, dynamic>;
          menu = result[1] as Map<String, dynamic>;
          customers = result[2] as List<Map<String, dynamic>>;
          loading = false;
        });
    } catch (e) {
      if (mounted) {
        setState(() => loading = false);
        _message(RestaurantApi.messageFor(e));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final best = (menu['bestSelling'] as List? ?? const [])
            .whereType<Map>()
            .toList(),
        low = (menu['lowSelling'] as List? ?? const [])
            .whereType<Map>()
            .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 10,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              'Reports & insights',
              style: GoogleFonts.playfairDisplay(
                fontSize: 27,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(
              width: 150,
              child: DropdownButtonFormField<int>(
                isExpanded: true,
                initialValue: days,
                decoration: const InputDecoration(labelText: 'Period'),
                items: [7, 30, 90]
                    .map(
                      (v) => DropdownMenuItem(
                        value: v,
                        child: Text('Last $v days'),
                      ),
                    )
                    .toList(),
                onChanged: (v) {
                  setState(() => days = v ?? 30);
                  _load();
                },
              ),
            ),
            OutlinedButton.icon(
              onPressed: loading ? null : _export,
              icon: const Icon(Icons.download_outlined),
              label: const Text('Export CSV'),
            ),
            IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
          ],
        ),
        const SizedBox(height: 14),
        if (loading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(45),
              child: CircularProgressIndicator(),
            ),
          )
        else ...[
          LayoutBuilder(
            builder: (_, box) {
              final width = box.maxWidth >= 800
                  ? (box.maxWidth - 28) / 3
                  : box.maxWidth;
              return Wrap(
                spacing: 14,
                runSpacing: 14,
                children: [
                  _metric(
                    'Total sales',
                    '₹${_money(sales['totalSales'])}',
                    Icons.currency_rupee,
                    width,
                    const Color(0xFF2F8A61),
                  ),
                  _metric(
                    'Paid orders',
                    '${sales['totalOrders'] ?? 0}',
                    Icons.receipt_long_outlined,
                    width,
                    const Color(0xFF3B74B9),
                  ),
                  _metric(
                    'Average bill',
                    '₹${_money(sales['averageOrderValue'])}',
                    Icons.analytics_outlined,
                    width,
                    const Color(0xFFD66A2C),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (_, box) {
              final wide = box.maxWidth >= 920;
              final blocks = [
                _ranked('Best selling', best, false),
                _ranked('Low selling', low, true),
                _customers(),
              ];
              return wide
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (int i = 0; i < blocks.length; i++) ...[
                          Expanded(child: blocks[i]),
                          if (i < blocks.length - 1) const SizedBox(width: 14),
                        ],
                      ],
                    )
                  : Column(
                      children: blocks
                          .map(
                            (b) => Padding(
                              padding: const EdgeInsets.only(bottom: 14),
                              child: b,
                            ),
                          )
                          .toList(),
                    );
            },
          ),
        ],
      ],
    );
  }

  Widget _metric(
    String label,
    String value,
    IconData icon,
    double width,
    Color color,
  ) => SizedBox(
    width: width,
    child: Container(
      padding: const EdgeInsets.all(18),
      decoration: _box(),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withValues(alpha: .1),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Color(0xFF667085)),
                ),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
  Widget _ranked(String title, List<Map> rows, bool low) => _section(
    title,
    rows.isEmpty
        ? [const ListTile(title: Text('No sales data.'))]
        : rows.asMap().entries.map((entry) {
            final row = entry.value;
            return ListTile(
              dense: true,
              leading: CircleAvatar(
                radius: 16,
                backgroundColor: (low
                    ? const Color(0xFFFFE2DE)
                    : const Color(0xFFE3F3E9)),
                child: Text(
                  '${entry.key + 1}',
                  style: TextStyle(
                    color: low
                        ? const Color(0xFFC84435)
                        : const Color(0xFF2F8A61),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              title: Text(
                '${row['name']}',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: Text('${row['quantitySold'] ?? 0} portions'),
              trailing: Text('₹${_money(row['revenue'])}'),
            );
          }).toList(),
  );
  Widget _customers() => _section(
    'Repeat customers',
    customers.isEmpty
        ? [const ListTile(title: Text('No repeat customer data.'))]
        : customers
              .take(10)
              .map(
                (c) => ListTile(
                  dense: true,
                  leading: const CircleAvatar(
                    radius: 16,
                    child: Icon(Icons.person_outline, size: 18),
                  ),
                  title: Text(
                    '${c['name']}',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(
                    '${c['visitCount'] ?? 0} visits · ${c['phone'] ?? ''}',
                  ),
                  trailing: Tooltip(
                    message: 'Favorite: ${c['favoriteDish'] ?? '—'}',
                    child: Text('₹${_money(c['totalSpending'])}'),
                  ),
                ),
              )
              .toList(),
  );
  Widget _section(String title, List<Widget> rows) => Container(
    decoration: _box(),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
        ),
        const Divider(height: 1),
        ...rows,
      ],
    ),
  );
  Future<void> _export() async {
    final out = StringBuffer(
      'Section,Name,Quantity/Visits,Revenue/Spending,Favorite Dish\n',
    );
    for (final raw in (menu['bestSelling'] as List? ?? const [])) {
      if (raw is Map)
        out.writeln(
          'Best Selling,"${_csv(raw['name'])}",${raw['quantitySold'] ?? 0},${raw['revenue'] ?? 0},',
        );
    }
    for (final c in customers) {
      out.writeln(
        'Customer,"${_csv(c['name'])}",${c['visitCount'] ?? 0},${c['totalSpending'] ?? 0},"${_csv(c['favoriteDish'])}"',
      );
    }
    try {
      await downloadReportCsv(
        out.toString(),
        'restaurant-report-$days-days.csv',
      );
      if (mounted) _message('CSV report downloaded.');
    } catch (e) {
      if (mounted) _message('$e');
    }
  }

  String _csv(dynamic value) => '${value ?? ''}'.replaceAll('"', '""');
  String _money(dynamic value) => (value as num? ?? 0).toStringAsFixed(2);
  BoxDecoration _box() => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(18),
    border: Border.all(color: const Color(0xFFE6DED2)),
  );
  void _message(String text) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(text), behavior: SnackBarBehavior.floating),
  );
}
