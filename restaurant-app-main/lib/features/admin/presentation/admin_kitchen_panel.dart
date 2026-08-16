import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/network/restaurant_api.dart';
import '../../../core/theme/hospitality_theme.dart';

class AdminKitchenPanel extends StatefulWidget {
  const AdminKitchenPanel({
    super.key,
    required this.initialOrders,
    required this.branchId,
    required this.reloadAdmin,
  });
  final List<Map<String, dynamic>> initialOrders;
  final String? branchId;
  final VoidCallback reloadAdmin;
  @override
  State<AdminKitchenPanel> createState() => _AdminKitchenPanelState();
}

class _AdminKitchenPanelState extends State<AdminKitchenPanel> {
  late List<Map<String, dynamic>> orders;
  Timer? clock, poller;
  final busy = <String>{};
  bool refreshing = false;
  static const active = {'Pending', 'Accepted', 'Preparing', 'Ready'};

  @override
  void initState() {
    super.initState();
    orders = _active(widget.initialOrders);
    clock = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
    poller = Timer.periodic(const Duration(seconds: 10), (_) => _refresh());
  }

  @override
  void didUpdateWidget(covariant AdminKitchenPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialOrders != widget.initialOrders && !refreshing) {
      orders = _active(widget.initialOrders);
    }
  }

  @override
  void dispose() {
    clock?.cancel();
    poller?.cancel();
    super.dispose();
  }

  List<Map<String, dynamic>> _active(List<Map<String, dynamic>> source) {
    final result = source.where((o) => active.contains(o['status'])).toList();
    result.sort((a, b) => _created(a).compareTo(_created(b)));
    return result;
  }

  Future<void> _refresh() async {
    if (refreshing || widget.branchId == null) return;
    refreshing = true;
    try {
      final data = await RestaurantApi.getOrders(branchId: widget.branchId);
      if (mounted) setState(() => orders = _active(data));
    } catch (_) {
    } finally {
      refreshing = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final pending = orders.where((o) => o['status'] == 'Pending').length;
    final cooking = orders.where((o) => o['status'] == 'Preparing').length;
    final ready = orders.where((o) => o['status'] == 'Ready').length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              'Kitchen display',
              style: GoogleFonts.playfairDisplay(
                fontSize: 27,
                fontWeight: FontWeight.w700,
              ),
            ),
            _metric('Waiting', pending, const Color(0xFFE5A12B)),
            _metric('Cooking', cooking, const Color(0xFFD66A2C)),
            _metric('Ready', ready, const Color(0xFF2F8A61)),
            IconButton(
              onPressed: _refresh,
              tooltip: 'Refresh kitchen',
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (orders.isEmpty)
          _empty()
        else
          LayoutBuilder(
            builder: (_, box) {
              final columns = box.maxWidth >= 1200
                  ? 3
                  : box.maxWidth >= 720
                  ? 2
                  : 1;
              final width = (box.maxWidth - (columns - 1) * 14) / columns;
              return Wrap(
                spacing: 14,
                runSpacing: 14,
                children: orders
                    .map((o) => SizedBox(width: width, child: _ticket(o)))
                    .toList(),
              );
            },
          ),
      ],
    );
  }

  Widget _metric(String label, int value, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .1),
      borderRadius: BorderRadius.circular(30),
    ),
    child: Text(
      '$label  $value',
      style: TextStyle(color: color, fontWeight: FontWeight.w700),
    ),
  );
  Widget _empty() => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(52),
    decoration: _decoration(),
    child: const Column(
      children: [
        Icon(Icons.soup_kitchen_outlined, size: 48, color: Color(0xFFB59A8B)),
        SizedBox(height: 12),
        Text('Kitchen queue is clear.'),
      ],
    ),
  );

  Widget _ticket(Map<String, dynamic> order) {
    final id = '${order['_id']}';
    final status = '${order['status'] ?? 'Pending'}';
    final elapsed = DateTime.now().difference(_created(order));
    final urgent = elapsed.inMinutes >= 20 && status != 'Ready';
    final tableData = order['tableId'];
    final table = tableData is Map
        ? '${tableData['name'] ?? 'Table'}'
        : '${order['orderType'] ?? 'Takeaway'}';
    final items = (order['items'] as List? ?? const [])
        .whereType<Map>()
        .toList();
    final next = status == 'Pending' || status == 'Accepted'
        ? 'Preparing'
        : status == 'Preparing'
        ? 'Ready'
        : 'Served';
    return Container(
      decoration: _decoration(
        border: urgent ? const Color(0xFFC84435) : _statusColor(status),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: _statusColor(status).withValues(alpha: .1),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(17),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '#${_shortId(id)} · $table',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Text(
                  _elapsed(elapsed),
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: urgent
                        ? const Color(0xFFC84435)
                        : const Color(0xFF5E514A),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...items.map((item) {
                  final menu = item['menuItem'];
                  final name = menu is Map ? menu['name'] : 'Menu item';
                  final extras = [
                    if ('${item['selectedVariant'] ?? ''}'.isNotEmpty)
                      item['selectedVariant'],
                    ...(item['selectedAddOns'] as List? ?? const []),
                  ].join(', ');
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 29,
                          height: 29,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF1D6),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${item['quantity'] ?? 1}',
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '$name',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              if (extras.isNotEmpty)
                                Text(
                                  extras,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF667085),
                                  ),
                                ),
                              if ('${item['notes'] ?? ''}'.isNotEmpty)
                                Text(
                                  'Note: ${item['notes']}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFFC84435),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                if ('${order['kitchenNotes'] ?? ''}'.isNotEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    color: const Color(0xFFFFF3D7),
                    child: Text('Kitchen note: ${order['kitchenNotes']}'),
                  ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: _statusColor(status),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                    ),
                    onPressed: busy.contains(id)
                        ? null
                        : () => _advance(order, next),
                    icon: busy.contains(id)
                        ? const SizedBox(
                            width: 17,
                            height: 17,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: HospitalityColors.surface,
                            ),
                          )
                        : Icon(
                            next == 'Ready'
                                ? Icons.notifications_active_outlined
                                : next == 'Served'
                                ? Icons.room_service_outlined
                                : Icons.local_fire_department_outlined,
                          ),
                    label: Text(
                      next == 'Ready'
                          ? 'Mark ready · notify waiter'
                          : 'Mark $next',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _advance(Map<String, dynamic> order, String next) async {
    final id = '${order['_id']}';
    setState(() => busy.add(id));
    try {
      await RestaurantApi.updateOrderStatus(id, next);
      await _refresh();
      widget.reloadAdmin();
      if (mounted && next == 'Ready') {
        _message('Order ready. Waiter dashboard notified.');
      }
    } catch (error) {
      if (mounted) _message(RestaurantApi.messageFor(error));
    } finally {
      if (mounted) setState(() => busy.remove(id));
    }
  }

  DateTime _created(Map<String, dynamic> o) =>
      DateTime.tryParse('${o['createdAt'] ?? ''}')?.toLocal() ?? DateTime.now();
  String _elapsed(Duration d) => d.inMinutes < 1
      ? 'Now'
      : d.inHours > 0
      ? '${d.inHours}h ${d.inMinutes % 60}m'
      : '${d.inMinutes}m';
  String _shortId(String id) =>
      id.length > 6 ? id.substring(id.length - 6).toUpperCase() : id;
  Color _statusColor(String s) => switch (s) {
    'Preparing' => const Color(0xFFD66A2C),
    'Ready' => const Color(0xFF2F8A61),
    'Accepted' => const Color(0xFF3B74B9),
    _ => const Color(0xFFE5A12B),
  };
  BoxDecoration _decoration({Color? border}) => BoxDecoration(
    color: HospitalityColors.surface,
    borderRadius: BorderRadius.circular(HospitalityRadius.medium),
    border: Border.all(
      color: border ?? HospitalityColors.outline,
      width: border == null ? 1 : 1.5,
    ),
  );
  void _message(String text) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(text), behavior: SnackBarBehavior.floating),
  );
}
