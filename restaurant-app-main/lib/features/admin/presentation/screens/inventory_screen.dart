import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../widgets/admin_ui.dart';

class InventoryScreen extends StatelessWidget {
  const InventoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final lowStockItems = _inventoryItems
        .where((item) => item.status != 'Healthy')
        .toList();

    return Padding(
      padding: adminPagePadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AdminPageHeader(
            eyebrow: 'STOCK CONTROL',
            title: 'Protect service quality before inventory slips.',
            subtitle:
                'Watch low-stock alerts, stock value, and supply risk without digging through spreadsheets.',
            trailing: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.file_download_rounded),
                  label: const Text('Export Report'),
                ),
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Add Stock'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          const AdminInsightStrip(
            children: [
              AdminMiniInfoCard(
                label: 'Low stock alerts',
                value: '3',
                icon: Icons.warning_rounded,
                color: AppTheme.primaryColor,
              ),
              AdminMiniInfoCard(
                label: 'Inventory value',
                value: '\u20B91.45L',
                icon: Icons.account_balance_wallet_rounded,
                color: Color(0xFF1FA971),
              ),
              AdminMiniInfoCard(
                label: 'Pending POs',
                value: '2',
                icon: Icons.local_shipping_rounded,
                color: Color(0xFF4B6BFB),
              ),
              AdminMiniInfoCard(
                label: 'Wastage trend',
                value: '1.8%',
                icon: Icons.insights_rounded,
                color: Color(0xFFFFA726),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final stacked = constraints.maxWidth < 1180;

                final summaryRail = Column(
                  children: [
                    AdminPanel(
                      color: const Color(0xFF101522),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: const Text(
                              'Supply pulse',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),
                          const Text(
                            'Tonight looks covered, but produce and dairy need attention before the dinner rush.',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Use this rail to spot weak inventory pockets, push replenishment faster, and protect your best-selling items.',
                            style: TextStyle(
                              color: Color(0xFFC8D0DC),
                              height: 1.45,
                            ),
                          ),
                          const SizedBox(height: 20),
                          const AdminDetailRow(
                            label: 'Fastest moving category',
                            value: 'Dairy',
                            valueColor: Colors.white,
                          ),
                          const SizedBox(height: 12),
                          const AdminDetailRow(
                            label: 'Next delivery slot',
                            value: '5:30 PM',
                            valueColor: Colors.white,
                          ),
                          const SizedBox(height: 12),
                          const AdminDetailRow(
                            label: 'Coverage window',
                            value: '8.5 hours',
                            valueColor: Colors.white,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    AdminPanel(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const AdminSectionHeading(
                            title: 'Restock priorities',
                            subtitle:
                                'The most urgent items to review with purchasing.',
                          ),
                          const SizedBox(height: 18),
                          for (var i = 0; i < lowStockItems.length; i++) ...[
                            AdminActionTile(
                              icon: Icons.inventory_2_rounded,
                              color: lowStockItems[i].statusColor,
                              title: lowStockItems[i].name,
                              subtitle:
                                  '${lowStockItems[i].stockLabel} left • ${lowStockItems[i].supplier}',
                              trailing: Text(
                                lowStockItems[i].etaLabel,
                                style: TextStyle(
                                  color: lowStockItems[i].statusColor,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            if (i < lowStockItems.length - 1)
                              const SizedBox(height: 12),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    AdminPanel(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const AdminSectionHeading(
                            title: 'Supplier actions',
                            subtitle:
                                'Quick next steps for incoming and delayed orders.',
                          ),
                          const SizedBox(height: 18),
                          for (var i = 0; i < _supplierActions.length; i++) ...[
                            AdminActionTile(
                              icon: _supplierActions[i].icon,
                              color: _supplierActions[i].color,
                              title: _supplierActions[i].title,
                              subtitle: _supplierActions[i].subtitle,
                            ),
                            if (i < _supplierActions.length - 1)
                              const SizedBox(height: 12),
                          ],
                        ],
                      ),
                    ),
                  ],
                );

                final registerPanel = AdminPanel(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AdminSectionHeading(
                        title: 'Inventory register',
                        subtitle:
                            '${_inventoryItems.length} tracked ingredients with live stock posture and supplier visibility.',
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF7F8FC),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: const Text(
                            'Updated 5 mins ago',
                            style: TextStyle(
                              color: AppTheme.textSecondaryLight,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: ListView(
                          children: [
                            AdminResponsiveDataTable(
                              minWidth: 980,
                              columnSpacing: 22,
                              headingRowColor: WidgetStateProperty.all(
                                const Color(0xFFF7F8FC),
                              ),
                              columns: const [
                                DataColumn(
                                  label: Text(
                                    'Item Name',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                DataColumn(
                                  label: Text(
                                    'Category',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                DataColumn(
                                  label: Text(
                                    'Current Stock',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                DataColumn(
                                  label: Text(
                                    'Par Level',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                DataColumn(
                                  label: Text(
                                    'Supplier',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                DataColumn(
                                  label: Text(
                                    'Status',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                DataColumn(
                                  label: Text(
                                    'Actions',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                              rows: _inventoryItems
                                  .map(_buildInventoryRow)
                                  .toList(),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );

                if (stacked) {
                  return ListView(
                    children: [
                      summaryRail,
                      const SizedBox(height: 18),
                      SizedBox(height: 620, child: registerPanel),
                    ],
                  );
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 360,
                      child: ListView(children: [summaryRail]),
                    ),
                    const SizedBox(width: 18),
                    Expanded(child: registerPanel),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  DataRow _buildInventoryRow(_InventoryItem item) {
    return DataRow(
      cells: [
        DataCell(
          Text(item.name, style: const TextStyle(fontWeight: FontWeight.w700)),
        ),
        DataCell(Text(item.category)),
        DataCell(
          Text(
            item.stockLabel,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        DataCell(Text(item.parLabel)),
        DataCell(Text(item.supplier)),
        DataCell(AdminStatusChip(label: item.status, color: item.statusColor)),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.edit_rounded, color: Color(0xFF4B6BFB)),
                onPressed: () {},
              ),
              IconButton(
                icon: Icon(
                  item.status == 'Healthy'
                      ? Icons.visibility_rounded
                      : Icons.add_shopping_cart_rounded,
                  color: item.status == 'Healthy'
                      ? const Color(0xFF64748B)
                      : AppTheme.primaryColor,
                ),
                onPressed: () {},
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _InventoryItem {
  const _InventoryItem({
    required this.name,
    required this.category,
    required this.stockLabel,
    required this.parLabel,
    required this.supplier,
    required this.status,
    required this.statusColor,
    required this.etaLabel,
  });

  final String name;
  final String category;
  final String stockLabel;
  final String parLabel;
  final String supplier;
  final String status;
  final Color statusColor;
  final String etaLabel;
}

class _SupplierAction {
  const _SupplierAction({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
}

const _inventoryItems = [
  _InventoryItem(
    name: 'Tomato',
    category: 'Vegetables',
    stockLabel: '15 kg',
    parLabel: '28 kg',
    supplier: 'Green Basket',
    status: 'Low Stock',
    statusColor: AppTheme.primaryColor,
    etaLabel: 'Restock in 2h',
  ),
  _InventoryItem(
    name: 'Pizza Dough',
    category: 'Raw Materials',
    stockLabel: '50 kg',
    parLabel: '40 kg',
    supplier: 'Daily Bake Co.',
    status: 'Healthy',
    statusColor: Color(0xFF1FA971),
    etaLabel: 'Stable',
  ),
  _InventoryItem(
    name: 'Mozzarella Cheese',
    category: 'Dairy',
    stockLabel: '20 kg',
    parLabel: '24 kg',
    supplier: 'Milky Way Foods',
    status: 'Watch',
    statusColor: Color(0xFFFFA726),
    etaLabel: 'PO due 4:45 PM',
  ),
  _InventoryItem(
    name: 'Coca Cola Cans',
    category: 'Beverages',
    stockLabel: '200 units',
    parLabel: '120 units',
    supplier: 'Metro Beverages',
    status: 'Healthy',
    statusColor: Color(0xFF1FA971),
    etaLabel: 'Stable',
  ),
  _InventoryItem(
    name: 'Basil',
    category: 'Herbs',
    stockLabel: '1.5 kg',
    parLabel: '4 kg',
    supplier: 'Fresh Farms',
    status: 'Critical',
    statusColor: Color(0xFFEF4444),
    etaLabel: 'Call supplier',
  ),
];

const _supplierActions = [
  _SupplierAction(
    icon: Icons.phone_in_talk_rounded,
    color: AppTheme.primaryColor,
    title: 'Call Fresh Farms',
    subtitle: 'Basil delivery is behind schedule and needs manual follow-up.',
  ),
  _SupplierAction(
    icon: Icons.receipt_long_rounded,
    color: Color(0xFF4B6BFB),
    title: 'Review pending PO #2481',
    subtitle: 'Mozzarella refill is confirmed, but the ETA needs validation.',
  ),
  _SupplierAction(
    icon: Icons.history_toggle_off_rounded,
    color: Color(0xFFFFA726),
    title: 'Audit morning wastage',
    subtitle: 'Produce usage spiked 7% above the usual prep average today.',
  ),
];
