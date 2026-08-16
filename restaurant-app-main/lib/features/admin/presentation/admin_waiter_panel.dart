import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/network/restaurant_api.dart';

class AdminWaiterPanel extends StatefulWidget {
  const AdminWaiterPanel({
    super.key,
    required this.initialOrders,
    required this.initialTables,
    required this.branchId,
    required this.reloadAdmin,
  });
  final List<Map<String, dynamic>> initialOrders;
  final List<Map<String, dynamic>> initialTables;
  final String? branchId;
  final VoidCallback reloadAdmin;
  @override
  State<AdminWaiterPanel> createState() => _AdminWaiterPanelState();
}

class _AdminWaiterPanelState extends State<AdminWaiterPanel> {
  List<Map<String, dynamic>> requests = [];
  late List<Map<String, dynamic>> orders, tables;
  Timer? poller;
  final busy = <String>{};
  bool loading = true, refreshing = false;

  @override
  void initState() {
    super.initState();
    orders = widget.initialOrders;
    tables = widget.initialTables;
    _refresh();
    poller = Timer.periodic(const Duration(seconds: 10), (_) => _refresh());
  }

  @override
  void didUpdateWidget(covariant AdminWaiterPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    orders = widget.initialOrders;
    tables = widget.initialTables;
  }

  @override
  void dispose() {
    poller?.cancel();
    super.dispose();
  }

  Future<void> _refresh() async {
    if (refreshing || widget.branchId == null) return;
    refreshing = true;
    try {
      final values = await Future.wait([
        RestaurantApi.getServiceRequests(branchId: widget.branchId),
        RestaurantApi.getOrders(branchId: widget.branchId),
        RestaurantApi.getTables(branchId: widget.branchId),
      ]);
      if (mounted)
        setState(() {
          requests = values[0].where((r) => r['status'] != 'Resolved').toList();
          orders = values[1];
          tables = values[2];
          loading = false;
        });
    } catch (error) {
      if (mounted && loading) _message(RestaurantApi.messageFor(error));
    } finally {
      refreshing = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final ready = orders.where((o) => o['status'] == 'Ready').toList();
    final bills = orders.where((o) => o['status'] == 'Bill Requested').toList();
    final cleaning = tables.where((t) => t['status'] == 'Cleaning').toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 10,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              'Waiter operations',
              style: GoogleFonts.playfairDisplay(
                fontSize: 27,
                fontWeight: FontWeight.w700,
              ),
            ),
            _badge(
              Icons.notifications_active_outlined,
              'Calls',
              requests.length,
              const Color(0xFFC84435),
            ),
            _badge(
              Icons.room_service_outlined,
              'Ready',
              ready.length,
              const Color(0xFF2F8A61),
            ),
            _badge(
              Icons.receipt_long_outlined,
              'Bills',
              bills.length,
              const Color(0xFF6B55A3),
            ),
            IconButton(
              onPressed: _refresh,
              tooltip: 'Refresh',
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (loading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(40),
              child: CircularProgressIndicator(),
            ),
          )
        else
          LayoutBuilder(
            builder: (_, box) {
              final wide = box.maxWidth >= 950;
              final sections = [
                _section(
                  'Guest calls',
                  Icons.notifications_active_outlined,
                  requests.map(_requestCard).toList(),
                ),
                _section(
                  'Food ready',
                  Icons.room_service_outlined,
                  ready.map(_readyCard).toList(),
                ),
                _section(
                  'Bill requested',
                  Icons.receipt_long_outlined,
                  bills.map(_billCard).toList(),
                ),
                _section(
                  'Cleaning handoff',
                  Icons.cleaning_services_outlined,
                  cleaning.map(_cleaningCard).toList(),
                ),
              ];
              if (!wide)
                return Column(
                  children: sections
                      .map(
                        (s) => Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: s,
                        ),
                      )
                      .toList(),
                );
              return Wrap(
                spacing: 14,
                runSpacing: 14,
                children: sections
                    .map(
                      (s) => SizedBox(width: (box.maxWidth - 14) / 2, child: s),
                    )
                    .toList(),
              );
            },
          ),
      ],
    );
  }

  Widget _badge(IconData icon, String label, int count, Color color) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: .1),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 17, color: color),
            const SizedBox(width: 6),
            Text(
              '$label $count',
              style: TextStyle(color: color, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      );
  Widget _section(String title, IconData icon, List<Widget> children) =>
      Container(
        decoration: _box(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(icon, color: const Color(0xFFD66A2C)),
                  const SizedBox(width: 9),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            if (children.isEmpty)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Nothing pending.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFF806E64)),
                ),
              )
            else
              ...children,
          ],
        ),
      );

  Widget _requestCard(Map<String, dynamic> r) {
    final table = r['tableId'] is Map
        ? '${r['tableId']['name'] ?? 'Table'}'
        : 'Table';
    final status = '${r['status'] ?? 'Open'}';
    final refillDetail = r['type'] == 'Refill'
        ? ' · ${r['dishName'] ?? 'Dish'}${('${r['dishNameHi'] ?? ''}').isEmpty ? '' : ' / ${r['dishNameHi']}'} · Refill #${r['refillNumber'] ?? 1}${r['refillPolicy'] == 'Limited' ? ' of ${r['refillLimit']}' : ''}'
        : '';
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: const Color(0xFFFFE7D6),
        child: Icon(
          _requestIcon('${r['type']}'),
          color: const Color(0xFFD66A2C),
        ),
      ),
      title: Text(
        '$table · ${r['type']}',
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      subtitle: Text(
        '${r['customerName'] ?? 'Guest'} · ${_age(r['createdAt'])} · $status${r['paymentMethod'] == null ? '' : ' · Pay by ${r['paymentMethod']}'}$refillDetail',
      ),
      trailing: FilledButton(
        onPressed: busy.contains('${r['_id']}')
            ? null
            : () => _requestAction(
                r,
                status == 'Open' ? 'Acknowledged' : 'Resolved',
              ),
        child: Text(status == 'Open' ? 'Accept' : 'Done'),
      ),
    );
  }

  Widget _readyCard(Map<String, dynamic> o) =>
      _orderTile(o, Icons.restaurant, 'Serve', () => _orderStatus(o, 'Served'));
  Widget _billCard(Map<String, dynamic> o) => _orderTile(
    o,
    Icons.payments_outlined,
    'Open POS',
    () => _message('Bill is ready for POS payment.'),
  );
  Widget _orderTile(
    Map<String, dynamic> o,
    IconData icon,
    String action,
    VoidCallback tap,
  ) {
    final id = '${o['_id']}';
    final table = o['tableId'] is Map
        ? '${o['tableId']['name'] ?? 'Table'}'
        : '${o['orderType'] ?? 'Takeaway'}';
    final count = (o['items'] as List? ?? const []).fold<int>(
      0,
      (sum, i) => sum + ((i as Map)['quantity'] as num? ?? 0).toInt(),
    );
    return ListTile(
      leading: CircleAvatar(child: Icon(icon)),
      title: Text(
        '$table · Order #${_short(id)}',
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      subtitle: Text('$count items · ${_age(o['createdAt'])}'),
      trailing: FilledButton(
        onPressed: busy.contains(id) ? null : tap,
        child: Text(action),
      ),
    );
  }

  Widget _cleaningCard(Map<String, dynamic> t) {
    final id = '${t['_id']}';
    return ListTile(
      leading: const CircleAvatar(child: Icon(Icons.cleaning_services)),
      title: Text(
        '${t['name'] ?? 'Table'}',
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      subtitle: const Text('Payment complete · cleaning required'),
      trailing: FilledButton(
        onPressed: busy.contains(id) ? null : () => _tableAvailable(t),
        child: const Text('Ready'),
      ),
    );
  }

  Future<void> _requestAction(
    Map<String, dynamic> request,
    String status,
  ) async => _run(
    '${request['_id']}',
    () => RestaurantApi.updateServiceRequest('${request['_id']}', status),
    status == 'Resolved' ? 'Guest request completed.' : 'Request accepted.',
  );
  Future<void> _orderStatus(Map<String, dynamic> order, String status) async =>
      _run(
        '${order['_id']}',
        () => RestaurantApi.updateOrderStatus('${order['_id']}', status),
        'Order marked served.',
      );
  Future<void> _tableAvailable(Map<String, dynamic> table) async => _run(
    '${table['_id']}',
    () => RestaurantApi.updateTableStatus('${table['_id']}', 'Available'),
    'Table is available for next guest.',
  );
  Future<void> _run(
    String id,
    Future<void> Function() action,
    String success,
  ) async {
    setState(() => busy.add(id));
    try {
      await action();
      await _refresh();
      widget.reloadAdmin();
      if (mounted) _message(success);
    } catch (e) {
      if (mounted) _message(RestaurantApi.messageFor(e));
    } finally {
      if (mounted) setState(() => busy.remove(id));
    }
  }

  IconData _requestIcon(String type) => type == 'Water'
      ? Icons.water_drop_outlined
      : type == 'Refill'
      ? Icons.refresh_rounded
      : type == 'Bill'
      ? Icons.receipt_long_outlined
      : Icons.support_agent;
  String _short(String id) =>
      id.length > 6 ? id.substring(id.length - 6).toUpperCase() : id;
  String _age(dynamic raw) {
    final date = DateTime.tryParse('$raw')?.toLocal();
    if (date == null) return 'now';
    final min = DateTime.now().difference(date).inMinutes;
    return min < 1
        ? 'now'
        : min < 60
        ? '${min}m ago'
        : '${min ~/ 60}h ago';
  }

  BoxDecoration _box() => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(18),
    border: Border.all(color: const Color(0xFFECE2D9)),
  );
  void _message(String text) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(text), behavior: SnackBarBehavior.floating),
  );
}
