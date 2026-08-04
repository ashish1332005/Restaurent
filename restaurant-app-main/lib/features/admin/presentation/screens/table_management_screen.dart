import 'package:flutter/material.dart';

import '../widgets/admin_ui.dart';

class TableManagementScreen extends StatefulWidget {
  const TableManagementScreen({super.key});

  @override
  State<TableManagementScreen> createState() => _TableManagementScreenState();
}

class _TableManagementScreenState extends State<TableManagementScreen> {
  final List<String> _floors = ['Floor 1', 'Floor 2', 'Terrace'];
  String _selectedFloor = 'Floor 1';
  String _selectedTableName = '08';

  final List<Map<String, dynamic>> _tables = [
    {'name': '01', 'capacity': 2, 'status': 'Available', 'shape': 'square'},
    {'name': '02', 'capacity': 4, 'status': 'Available', 'shape': 'square'},
    {'name': '03', 'capacity': 4, 'status': 'Occupied', 'shape': 'square'},
    {'name': '04', 'capacity': 6, 'status': 'Reserved', 'shape': 'circle'},
    {'name': '05', 'capacity': 2, 'status': 'Available', 'shape': 'square'},
    {'name': '06', 'capacity': 4, 'status': 'Available', 'shape': 'square'},
    {'name': '07', 'capacity': 2, 'status': 'Cleaning', 'shape': 'square'},
    {'name': '08', 'capacity': 3, 'status': 'Occupied', 'shape': 'square'},
  ];

  @override
  Widget build(BuildContext context) {
    final selectedTable = _tables.firstWhere(
      (table) => table['name'] == _selectedTableName,
      orElse: () => _tables.first,
    );
    final compact = MediaQuery.sizeOf(context).width < 900;

    return Container(
      color: adminBackground,
      child: SingleChildScrollView(
        padding: adminPagePadding(context, bottom: 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _topBar(context),
            const SizedBox(height: 18),
            _floorTabs(),
            const SizedBox(height: 16),
            _statusSummary(),
            const SizedBox(height: 18),
            if (compact) ...[
              _floorMapCard(),
              const SizedBox(height: 18),
              _selectedTableCard(selectedTable),
              const SizedBox(height: 18),
              _quickActionsCard(selectedTable),
            ] else ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 3, child: _floorMapCard()),
                  const SizedBox(width: 18),
                  Expanded(
                    flex: 2,
                    child: Column(
                      children: [
                        _selectedTableCard(selectedTable),
                        const SizedBox(height: 18),
                        _quickActionsCard(selectedTable),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _topBar(BuildContext context) {
    return Row(
      children: [
        IconButton.filledTonal(
          onPressed: () => Navigator.maybePop(context),
          icon: const Icon(Icons.arrow_back_rounded),
          style: IconButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: adminInk,
            side: const BorderSide(color: adminBorder),
          ),
        ),
        const SizedBox(width: 10),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Table Management',
                style: TextStyle(
                  color: adminInk,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'See table status, assign guests and generate QR codes.',
                style: TextStyle(color: adminMuted, fontSize: 13),
              ),
            ],
          ),
        ),
        IconButton.filled(
          onPressed: _showAddTableDialog,
          icon: const Icon(Icons.add_rounded),
          style: IconButton.styleFrom(backgroundColor: adminOrange),
        ),
      ],
    );
  }

  Widget _floorTabs() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _floors.map((floor) {
          final selected = _selectedFloor == floor;
          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: ChoiceChip(
              label: Text(floor),
              selected: selected,
              selectedColor: adminOrange,
              backgroundColor: Colors.white,
              side: BorderSide(color: selected ? adminOrange : adminBorder),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              labelStyle: TextStyle(
                color: selected ? Colors.white : adminInk,
                fontWeight: FontWeight.w800,
              ),
              onSelected: (_) => setState(() => _selectedFloor = floor),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _statusSummary() {
    final available = _countStatus('Available');
    final occupied = _countStatus('Occupied');
    final reserved = _countStatus('Reserved');
    final cleaning = _countStatus('Cleaning');

    return GridView.count(
      crossAxisCount: MediaQuery.sizeOf(context).width < 620 ? 2 : 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 2.35,
      children: [
        _summaryTile('Available', '$available', Icons.check_circle_rounded),
        _summaryTile('Occupied', '$occupied', Icons.people_rounded),
        _summaryTile('Reserved', '$reserved', Icons.event_available_rounded),
        _summaryTile('Cleaning', '$cleaning', Icons.cleaning_services_rounded),
      ],
    );
  }

  Widget _summaryTile(String status, String count, IconData icon) {
    final color = _getStatusColor(status);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: adminBorder),
        boxShadow: adminCardShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 19),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  status,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: adminMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  count,
                  style: const TextStyle(
                    color: adminInk,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _floorMapCard() {
    return AdminPanel(
      padding: const EdgeInsets.all(16),
      radius: 18,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: AdminSectionHeading(
                  title: 'Floor Plan',
                  subtitle: 'Tap a table to view details and actions.',
                ),
              ),
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.tune_rounded),
                color: adminInk,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFBFCFE),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: adminBorder),
            ),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _tables.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: MediaQuery.sizeOf(context).width < 430 ? 3 : 4,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1,
              ),
              itemBuilder: (context, index) {
                final table = _tables[index];
                return _tableTile(table);
              },
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 12,
            runSpacing: 10,
            children: const [
              _LegendDot(label: 'Available', color: Color(0xFF16A34A)),
              _LegendDot(label: 'Occupied', color: Color(0xFFFF4D0A)),
              _LegendDot(label: 'Reserved', color: Color(0xFFF59E0B)),
              _LegendDot(label: 'Cleaning', color: Color(0xFF94A3B8)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _tableTile(Map<String, dynamic> table) {
    final status = table['status'] as String;
    final color = _getStatusColor(status);
    final selected = table['name'] == _selectedTableName;
    final circular = table['shape'] == 'circle';

    return InkWell(
      borderRadius: BorderRadius.circular(circular ? 999 : 14),
      onTap: () => setState(() => _selectedTableName = table['name'] as String),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: color.withValues(alpha: status == 'Cleaning' ? 0.08 : 0.12),
          shape: circular ? BoxShape.circle : BoxShape.rectangle,
          borderRadius: circular ? null : BorderRadius.circular(14),
          border: Border.all(
            color: selected ? adminInk : color.withValues(alpha: 0.65),
            width: selected ? 2.2 : 1.4,
          ),
        ),
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    table['name'] as String,
                    style: const TextStyle(
                      color: adminInk,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '(${table['capacity']})',
                    style: const TextStyle(
                      color: adminMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              right: 7,
              top: 7,
              child: Icon(_getStatusIcon(status), color: color, size: 16),
            ),
            if (selected)
              Positioned(
                right: 7,
                bottom: 7,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: const BoxDecoration(
                    color: adminOrange,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.person_rounded,
                    color: Colors.white,
                    size: 13,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _selectedTableCard(Map<String, dynamic> table) {
    final status = table['status'] as String;
    final color = _getStatusColor(status);

    return AdminPanel(
      padding: const EdgeInsets.all(18),
      radius: 18,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(Icons.table_restaurant_rounded, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Table ${table['name']}',
                      style: const TextStyle(
                        color: adminInk,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Capacity: ${table['capacity']} guests',
                      style: const TextStyle(color: adminMuted),
                    ),
                  ],
                ),
              ),
              AdminStatusChip(label: status, color: color),
            ],
          ),
          const SizedBox(height: 18),
          _detailLine('Floor', _selectedFloor),
          _detailLine(
            'Waiter',
            status == 'Occupied' ? 'Rohit' : 'Not assigned',
          ),
          _detailLine(
            'Current order',
            status == 'Occupied' ? '#ORD-1058' : 'No active order',
          ),
          _detailLine(
            'Next reservation',
            status == 'Reserved' ? '7:30 PM' : 'None',
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _showQrDialog,
                  icon: const Icon(Icons.qr_code_rounded),
                  label: const Text('Generate QR'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: adminOrange,
                    side: const BorderSide(color: adminOrange),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _showToast('Opening active order'),
                  icon: const Icon(Icons.receipt_long_rounded),
                  label: const Text('View Order'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: adminOrange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _quickActionsCard(Map<String, dynamic> table) {
    return AdminPanel(
      padding: const EdgeInsets.all(18),
      radius: 18,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AdminSectionHeading(
            title: 'Quick Actions',
            subtitle: 'Change status without opening another page.',
          ),
          const SizedBox(height: 14),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 2.05,
            children: [
              _statusAction('Available', Icons.check_circle_rounded),
              _statusAction('Occupied', Icons.people_rounded),
              _statusAction('Reserved', Icons.event_available_rounded),
              _statusAction('Cleaning', Icons.cleaning_services_rounded),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statusAction(String status, IconData icon) {
    final color = _getStatusColor(status);
    final selectedTable = _tables.firstWhere(
      (table) => table['name'] == _selectedTableName,
    );
    final active = selectedTable['status'] == status;

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () {
        setState(() => selectedTable['status'] = status);
        _showToast('Table $_selectedTableName marked $status');
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: active ? color.withValues(alpha: 0.14) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: active ? color : adminBorder),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 19),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                status,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: active ? color : adminInk,
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailLine(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: adminMuted, fontSize: 13),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: adminInk,
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  int _countStatus(String status) =>
      _tables.where((table) => table['status'] == status).length;

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Available':
        return adminSuccess;
      case 'Occupied':
        return adminOrange;
      case 'Reserved':
        return const Color(0xFFF59E0B);
      case 'Cleaning':
        return const Color(0xFF94A3B8);
      default:
        return adminMuted;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'Available':
        return Icons.check_circle_rounded;
      case 'Occupied':
        return Icons.people_rounded;
      case 'Reserved':
        return Icons.event_available_rounded;
      case 'Cleaning':
        return Icons.cleaning_services_rounded;
      default:
        return Icons.circle_rounded;
    }
  }

  void _showAddTableDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Table'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(decoration: InputDecoration(labelText: 'Table number')),
            SizedBox(height: 14),
            TextField(decoration: InputDecoration(labelText: 'Capacity')),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _tables.add({
                  'name': '${_tables.length + 1}'.padLeft(2, '0'),
                  'capacity': 4,
                  'status': 'Available',
                  'shape': 'square',
                });
              });
              Navigator.pop(context);
            },
            child: const Text('Add Table'),
          ),
        ],
      ),
    );
  }

  void _showQrDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Table $_selectedTableName QR Code'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 190,
              height: 190,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: adminBorder),
              ),
              child: const Icon(
                Icons.qr_code_2_rounded,
                size: 150,
                color: adminInk,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Print and place this QR on the table for customer ordering.',
              textAlign: TextAlign.center,
              style: TextStyle(color: adminMuted),
            ),
          ],
        ),
        actions: [
          OutlinedButton.icon(
            onPressed: () => _showToast('QR downloaded'),
            icon: const Icon(Icons.download_rounded),
            label: const Text('Download'),
          ),
          ElevatedButton.icon(
            onPressed: () => _showToast('QR sent to printer'),
            icon: const Icon(Icons.print_rounded),
            label: const Text('Print'),
          ),
        ],
      ),
    );
  }

  void _showToast(String msg) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: adminInk));
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.16),
            border: Border.all(color: color),
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            color: adminMuted,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
