import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/network/restaurant_api.dart';

class AdminInventoryPanel extends StatefulWidget {
  const AdminInventoryPanel({super.key, required this.branchId});
  final String? branchId;
  @override
  State<AdminInventoryPanel> createState() => _AdminInventoryPanelState();
}

class _AdminInventoryPanelState extends State<AdminInventoryPanel> {
  List<Map<String, dynamic>> items = [], movements = [], menu = [];
  bool loading = true;
  String query = '';
  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant AdminInventoryPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.branchId != widget.branchId) _load();
  }

  Future<void> _load() async {
    if (widget.branchId == null) {
      if (mounted) setState(() => loading = false);
      return;
    }
    setState(() => loading = true);
    try {
      final values = await Future.wait([
        RestaurantApi.getInventory(branchId: widget.branchId),
        RestaurantApi.getInventoryMovements(branchId: widget.branchId),
      ]);
      if (mounted)
        setState(() {
          items = values[0];
          movements = values[1];
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
    final low = items
        .where(
          (i) => (i['quantity'] as num? ?? 0) <= (i['threshold'] as num? ?? 0),
        )
        .length;
    final filtered = items
        .where(
          (i) => '${i['ingredientName']}'.toLowerCase().contains(
            query.toLowerCase(),
          ),
        )
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
              'Inventory',
              style: GoogleFonts.playfairDisplay(
                fontSize: 27,
                fontWeight: FontWeight.w700,
              ),
            ),
            _badge('Items', items.length, const Color(0xFF3B74B9)),
            _badge('Low stock', low, const Color(0xFFC84435)),
            FilledButton.icon(
              onPressed: () => _adjust(),
              icon: const Icon(Icons.add),
              label: const Text('Add stock item'),
            ),
            IconButton(
              onPressed: _load,
              tooltip: 'Refresh',
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        const SizedBox(height: 14),
        TextField(
          onChanged: (v) => setState(() => query = v),
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.search),
            hintText: 'Search ingredient',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 14),
        if (loading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(45),
              child: CircularProgressIndicator(),
            ),
          )
        else
          LayoutBuilder(
            builder: (_, box) {
              final wide = box.maxWidth >= 980;
              final stock = _stock(filtered);
              final history = _history();
              return wide
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 3, child: stock),
                        const SizedBox(width: 14),
                        Expanded(flex: 2, child: history),
                      ],
                    )
                  : Column(
                      children: [stock, const SizedBox(height: 14), history],
                    );
            },
          ),
      ],
    );
  }

  Widget _stock(List<Map<String, dynamic>> records) => _section(
    'Current stock',
    records.isEmpty
        ? [const ListTile(title: Text('No inventory items found.'))]
        : records.map((i) {
            final qty = (i['quantity'] as num? ?? 0).toDouble(),
                threshold = (i['threshold'] as num? ?? 0).toDouble();
            final low = qty <= threshold;
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: low
                    ? const Color(0xFFFFE2DE)
                    : const Color(0xFFE3F3E9),
                child: Icon(
                  low
                      ? Icons.warning_amber_rounded
                      : Icons.inventory_2_outlined,
                  color: low
                      ? const Color(0xFFC84435)
                      : const Color(0xFF2F8A61),
                ),
              ),
              title: Text(
                '${i['ingredientName']}',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: Text('Minimum ${_number(threshold)} ${i['unit']}'),
              trailing: Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                children: [
                  Text(
                    '${_number(qty)} ${i['unit']}',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: low ? const Color(0xFFC84435) : null,
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (type) => _adjust(item: i, type: type),
                    itemBuilder: (_) =>
                        ['Purchase', 'Usage', 'Wastage', 'Correction']
                            .map((v) => PopupMenuItem(value: v, child: Text(v)))
                            .toList(),
                  ),
                ],
              ),
            );
          }).toList(),
  );
  Widget _history() => _section(
    'Recent movements',
    movements.take(40).map((m) {
      final delta = (m['quantityDelta'] as num? ?? 0).toDouble();
      return ListTile(
        dense: true,
        leading: Icon(
          delta >= 0 ? Icons.south_west : Icons.north_east,
          color: delta >= 0 ? const Color(0xFF2F8A61) : const Color(0xFFC84435),
        ),
        title: Text(
          '${m['ingredientName']} · ${m['type']}',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          '${m['reason'] ?? ''}${'${m['reason'] ?? ''}'.isEmpty ? '' : ' · '}${_date(m['createdAt'])}',
        ),
        trailing: Text(
          '${delta >= 0 ? '+' : ''}${_number(delta)} ${m['unit']}',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      );
    }).toList(),
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
        if (rows.isEmpty)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Text('No movements yet.', textAlign: TextAlign.center),
          )
        else
          ...rows,
      ],
    ),
  );
  Widget _badge(String label, int count, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .1),
      borderRadius: BorderRadius.circular(30),
    ),
    child: Text(
      '$label $count',
      style: TextStyle(color: color, fontWeight: FontWeight.w700),
    ),
  );
  Future<void> _adjust({Map<String, dynamic>? item, String? type}) async {
    final name = TextEditingController(
          text: item?['ingredientName']?.toString() ?? '',
        ),
        amount = TextEditingController(),
        unit = TextEditingController(text: item?['unit']?.toString() ?? 'kg'),
        threshold = TextEditingController(
          text: item?['threshold']?.toString() ?? '10',
        ),
        reason = TextEditingController();
    String movement = type ?? (item == null ? 'Opening' : 'Purchase');
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (_, setDialog) => AlertDialog(
          title: Text(
            item == null
                ? 'Add inventory item'
                : 'Update ${item['ingredientName']}',
          ),
          content: SizedBox(
            width: 430,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: name,
                    enabled: item == null,
                    decoration: const InputDecoration(
                      labelText: 'Ingredient name',
                    ),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    initialValue: movement,
                    decoration: const InputDecoration(
                      labelText: 'Movement type',
                    ),
                    items:
                        [
                              'Opening',
                              'Purchase',
                              'Usage',
                              'Wastage',
                              'Correction',
                            ]
                            .map(
                              (v) => DropdownMenuItem(value: v, child: Text(v)),
                            )
                            .toList(),
                    onChanged: (v) => setDialog(() => movement = v ?? movement),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: amount,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: ['Usage', 'Wastage'].contains(movement)
                          ? 'Quantity used/wasted'
                          : 'Quantity added',
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: unit,
                    enabled: item == null,
                    decoration: const InputDecoration(
                      labelText: 'Unit (kg, litre, pcs)',
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: threshold,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Low-stock threshold',
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: reason,
                    decoration: const InputDecoration(
                      labelText: 'Reason / supplier / note',
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
    if (ok != true) return;
    final value = double.tryParse(amount.text);
    if (name.text.trim().length < 2 || value == null || value <= 0) {
      _message('Enter a valid ingredient and quantity.');
      return;
    }
    final delta = ['Usage', 'Wastage'].contains(movement) ? -value : value;
    try {
      await RestaurantApi.updateInventoryStock({
        'branchId': widget.branchId,
        'ingredientName': name.text.trim(),
        'quantityDelta': delta,
        'unit': unit.text.trim(),
        'threshold': double.tryParse(threshold.text) ?? 0,
        'type': movement,
        'reason': reason.text.trim(),
      });
      await _load();
      if (mounted) _message('Inventory updated.');
    } catch (e) {
      if (mounted) _message(RestaurantApi.messageFor(e));
    }
  }

  String _number(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(2);
  String _date(dynamic raw) {
    final d = DateTime.tryParse('$raw')?.toLocal();
    return d == null
        ? ''
        : '${d.day}/${d.month} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }

  BoxDecoration _box() => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(18),
    border: Border.all(color: const Color(0xFFE6DED2)),
  );
  void _message(String text) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(text), behavior: SnackBarBehavior.floating),
  );
}
