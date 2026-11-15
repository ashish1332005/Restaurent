import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/network/restaurant_api.dart';
import '../../../core/theme/hospitality_theme.dart';

class AdminPosPanel extends StatefulWidget {
  const AdminPosPanel({
    super.key,
    required this.menu,
    required this.tables,
    required this.branchId,
    required this.reload,
  });
  final List<Map<String, dynamic>> menu;
  final List<Map<String, dynamic>> tables;
  final String? branchId;
  final VoidCallback reload;
  @override
  State<AdminPosPanel> createState() => _AdminPosPanelState();
}

class _AdminPosPanelState extends State<AdminPosPanel> {
  final cart = <String, _PosLine>{};
  final search = TextEditingController();
  final discount = TextEditingController(text: '0');
  final customerName = TextEditingController();
  final customerPhone = TextEditingController();
  String? tableId;
  bool busy = false;
  String selectedCategory = 'all';
  bool vegOnly = false;

  @override
  void dispose() {
    search.dispose();
    discount.dispose();
    customerName.dispose();
    customerPhone.dispose();
    super.dispose();
  }

  void _quickAdd(Map<String, dynamic> item) {
    HapticFeedback.lightImpact();
    final key = '${item['_id']}::';
    final existing = cart[key];
    final price = (item['basePrice'] as num? ?? 0).toDouble();
    if (existing != null) {
      setState(() => existing.quantity += 1);
    } else {
      setState(() {
        cart[key] = _PosLine(
          item: item,
          variant: '',
          addOns: const [],
          quantity: 1,
          unitPrice: price,
        );
      });
    }
  }

  double get subtotal =>
      cart.values.fold(0, (sum, line) => sum + line.unitPrice * line.quantity);
  double get itemDiscount => cart.values.fold(
    0,
    (sum, line) =>
        sum +
        (line.unitPrice *
            line.quantity *
            (line.item['discount'] as num? ?? 0).toDouble() /
            100),
  );
  double get tax => cart.values.fold(
    0,
    (sum, line) =>
        sum +
        ((line.unitPrice * line.quantity -
                (line.unitPrice *
                    line.quantity *
                    (line.item['discount'] as num? ?? 0).toDouble() /
                    100)) *
            (line.item['taxRate'] as num? ?? 0).toDouble() /
            100),
  );
  double get manualDiscount => double.tryParse(discount.text) ?? 0;
  double get total => (subtotal + tax - itemDiscount - manualDiscount).clamp(
    0,
    double.infinity,
  );

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 1050;
    final menu = _menu();
    final checkout = _checkout();
    return wide
        ? Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 3, child: menu),
              const SizedBox(width: 16),
              SizedBox(width: 390, child: checkout),
            ],
          )
        : Stack(
            children: [
              Padding(
                padding: EdgeInsets.only(bottom: cart.isNotEmpty ? 88 : 0),
                child: Column(
                  children: [
                    menu,
                    const SizedBox(height: 16),
                    checkout,
                  ],
                ),
              ),
              if (cart.isNotEmpty)
                Positioned(
                  left: 12,
                  right: 12,
                  bottom: 12,
                  child: _floatingCartBar(context, checkout),
                ),
            ],
          );
  }

  void _openMobileCheckout(BuildContext context, Widget checkoutWidget) {
    HapticFeedback.selectionClick();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, scrollController) => Container(
          decoration: const BoxDecoration(
            color: HospitalityColors.canvas,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  child: checkoutWidget,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _floatingCartBar(BuildContext context, Widget checkoutWidget) {
    final count = cart.values.fold(0, (sum, line) => sum + line.quantity);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _openMobileCheckout(context, checkoutWidget),
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
            border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: HospitalityColors.saffron,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Rs ${total.toStringAsFixed(0)}',
                      style: const TextStyle(
                        color: Color(0xFFFCD34D),
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      tableId != null ? 'Table selected' : 'Tap to select table & punch KOT',
                      style: const TextStyle(color: Colors.white70, fontSize: 11),
                    ),
                  ],
                ),
              ),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: HospitalityColors.saffron,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                ),
                onPressed: () => _openMobileCheckout(context, checkoutWidget),
                icon: const Icon(Icons.receipt_long_rounded, size: 18),
                label: const Text('Review', style: TextStyle(fontWeight: FontWeight.w800)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _menu() {
    final query = search.text.trim().toLowerCase();
    final categories = <String>{};
    for (final item in widget.menu) {
      if (item['categoryId'] is Map && item['categoryId']['name'] != null) {
        categories.add(item['categoryId']['name'].toString());
      }
    }
    final availableItems = widget.menu.where((item) {
      if (item['isAvailable'] == false) return false;
      if (vegOnly && item['isVeg'] == false) return false;
      if (selectedCategory != 'all') {
        final catName = item['categoryId'] is Map ? item['categoryId']['name']?.toString() : null;
        if (catName != selectedCategory) return false;
      }
      if (query.isEmpty) return true;
      return [
        item['name'],
        item['nameHi'],
        item['categoryId'] is Map ? item['categoryId']['name'] : '',
      ].join(' ').toLowerCase().contains(query);
    }).toList();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _box(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: HospitalityColors.softSaffron,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.point_of_sale_rounded,
                  color: HospitalityColors.saffron,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Choose items',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    Text(
                      availableItems.length.toString() + ' available dishes',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          TextField(
            controller: search,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search_rounded),
              hintText: 'Search menu items',
              isDense: true,
            ),
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                FilterChip(
                  label: const Text('All Dishes'),
                  selected: selectedCategory == 'all',
                  selectedColor: HospitalityColors.softSaffron,
                  checkmarkColor: HospitalityColors.saffronDark,
                  onSelected: (_) => setState(() => selectedCategory = 'all'),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  avatar: const Icon(Icons.eco_rounded, color: Color(0xFF16A34A), size: 16),
                  label: const Text('Pure Veg'),
                  selected: vegOnly,
                  selectedColor: const Color(0xFFDCFCE7),
                  onSelected: (val) => setState(() => vegOnly = val),
                ),
                for (final cat in categories) ...[
                  const SizedBox(width: 8),
                  FilterChip(
                    label: Text(cat),
                    selected: selectedCategory == cat,
                    selectedColor: HospitalityColors.softSaffron,
                    checkmarkColor: HospitalityColors.saffronDark,
                    onSelected: (_) => setState(() => selectedCategory = cat),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (availableItems.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 34),
              child: Center(
                child: Text(
                  query.isEmpty
                      ? 'No available menu items'
                      : 'No matching dishes',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth >= 760 ? 2 : 1;
                final gap = 10.0;
                final width =
                    (constraints.maxWidth - gap * (columns - 1)) / columns;
                return Wrap(
                  spacing: gap,
                  runSpacing: gap,
                  children: availableItems
                      .map(
                        (item) =>
                            SizedBox(width: width, child: _posMenuCard(item)),
                      )
                      .toList(),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _posMenuCard(Map<String, dynamic> item) {
    final image = RestaurantApi.mediaUrl(item['imageUrl'] ?? item['image']);
    final category = item['categoryId'] is Map
        ? (item['categoryId']['name'] ?? 'Menu').toString()
        : 'Menu';
    final inCart = cart.entries
        .where((e) => '${e.value.item['_id']}' == '${item['_id']}')
        .fold(0, (sum, e) => sum + e.value.quantity);

    return Material(
      color: inCart > 0
          ? HospitalityColors.softSaffron.withValues(alpha: 0.35)
          : HospitalityColors.canvas,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(HospitalityRadius.small),
        side: BorderSide(
          color: inCart > 0 ? HospitalityColors.saffron : HospitalityColors.outline,
          width: inCart > 0 ? 1.5 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          final hasVariants = (item['variants'] as List? ?? const []).isNotEmpty;
          final hasModifiers = (item['modifiers'] as List? ?? const []).isNotEmpty;
          if (hasVariants || hasModifiers) {
            _configure(item);
          } else {
            _quickAdd(item);
          }
        },
        child: SizedBox(
          height: 88,
          child: Row(
            children: [
              SizedBox(
                width: 78,
                height: 88,
                child: image.isEmpty
                    ? ColoredBox(
                        color: HospitalityColors.softSaffron,
                        child: Icon(
                          item['isVeg'] == false
                              ? Icons.set_meal_rounded
                              : Icons.eco_rounded,
                          color: HospitalityColors.saffron,
                        ),
                      )
                    : Image.network(
                        image,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const ColoredBox(
                          color: HospitalityColors.softSaffron,
                          child: Icon(
                            Icons.restaurant_rounded,
                            color: HospitalityColors.saffron,
                          ),
                        ),
                      ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 8,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        (item['name'] ?? 'Menu item').toString(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        category,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const Spacer(),
                      Text(
                        'Rs ' + (item['basePrice'] ?? 0).toString(),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: HospitalityColors.saffronDark,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 9),
                child: inCart > 0
                    ? Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: HospitalityColors.saffron,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '$inCart',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                          ),
                        ),
                      )
                    : const Icon(
                        Icons.add_circle_rounded,
                        color: HospitalityColors.saffron,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _checkout() => Container(
    padding: const EdgeInsets.all(18),
    decoration: _box(),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Current order',
          style: GoogleFonts.playfairDisplay(
            fontSize: 23,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 14),
        DropdownButtonFormField<String?>(
          initialValue: tableId,
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'Order type / table',
            border: OutlineInputBorder(),
          ),
          items: [
            const DropdownMenuItem<String?>(
              value: null,
              child: Text('Takeaway'),
            ),
            ...widget.tables
                .where((table) => table['status'] != 'Cleaning')
                .map(
                  (table) => DropdownMenuItem<String?>(
                    value: '${table['_id']}',
                    child: Text(
                      (table['name'] ?? 'Table').toString() +
                          ' - ' +
                          (table['status'] ?? 'Available').toString(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
          ],
          onChanged: (value) => setState(() => tableId = value),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: customerName,
          decoration: const InputDecoration(
            labelText: 'Customer name',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: customerPhone,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
            labelText: 'Mobile (optional)',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 14),
        if (cart.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Text(
              'Add menu items to begin.',
              textAlign: TextAlign.center,
            ),
          )
        else
          ...cart.entries.map((entry) => _cartLine(entry.key, entry.value)),
        const Divider(height: 28),
        TextField(
          controller: discount,
          keyboardType: TextInputType.number,
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(
            labelText: 'Manual discount (Rs)',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 14),
        _amount('Subtotal', subtotal),
        _amount('Menu discount', -itemDiscount),
        _amount('GST', tax),
        _amount('Manual discount', -manualDiscount),
        const Divider(),
        _amount('Total', total, bold: true),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: busy || cart.isEmpty ? null : () => _submit(false),
                child: const Text('Send order'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton(
                onPressed: busy || cart.isEmpty ? null : () => _submit(true),
                child: busy
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: HospitalityColors.surface,
                        ),
                      )
                    : const Text('Pay & send'),
              ),
            ),
          ],
        ),
      ],
    ),
  );
  Widget _cartLine(String key, _PosLine line) => ListTile(
    contentPadding: EdgeInsets.zero,
    title: Text(line.item['name'].toString()),
    subtitle: Text(
      [if (line.variant.isNotEmpty) line.variant, ...line.addOns].join(', '),
    ),
    trailing: Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        IconButton(
          onPressed: () => _quantity(key, -1),
          icon: const Icon(Icons.remove_circle_outline),
        ),
        Text('${line.quantity}'),
        IconButton(
          onPressed: () => _quantity(key, 1),
          icon: const Icon(Icons.add_circle_outline),
        ),
        Text('Rs ${(line.unitPrice * line.quantity).toStringAsFixed(0)}'),
      ],
    ),
  );
  Widget _amount(String label, double value, {bool bold = false}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(fontWeight: bold ? FontWeight.w700 : null),
          ),
        ),
        Text(
          '${value < 0 ? '- ' : ''}Rs ${value.abs().toStringAsFixed(2)}',
          style: TextStyle(fontWeight: bold ? FontWeight.w700 : null),
        ),
      ],
    ),
  );
  BoxDecoration _box() => BoxDecoration(
    color: HospitalityColors.surface,
    borderRadius: BorderRadius.circular(HospitalityRadius.medium),
    border: Border.all(color: HospitalityColors.outline),
  );

  Future<void> _configure(Map<String, dynamic> item) async {
    final variants = (item['variants'] as List? ?? const [])
        .whereType<Map>()
        .toList();
    final modifiers = (item['modifiers'] as List? ?? const [])
        .whereType<Map>()
        .toList();
    String variant = '';
    final selected = <String>{};
    int quantity = 1;
    final add = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (_, setDialog) => AlertDialog(
          title: Text('${item['name']}'),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (variants.isNotEmpty)
                  DropdownButtonFormField<String>(
                    initialValue: variant.isEmpty ? null : variant,
                    decoration: const InputDecoration(labelText: 'Variant'),
                    items: variants
                        .map(
                          (v) => DropdownMenuItem(
                            value: '${v['name']}',
                            child: Text(
                              (v['name'] ?? '').toString() +
                                  ' - Rs ' +
                                  (v['price'] ?? 0).toString(),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) =>
                        setDialog(() => variant = value ?? ''),
                  ),
                if (modifiers.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Add-ons',
                      style: GoogleFonts.dmSans(fontWeight: FontWeight.w700),
                    ),
                  ),
                  Wrap(
                    children: modifiers.map((m) {
                      final name = '${m['name']}';
                      return FilterChip(
                        label: Text('$name +Rs ${m['price'] ?? 0}'),
                        selected: selected.contains(name),
                        onSelected: (on) => setDialog(
                          () => on ? selected.add(name) : selected.remove(name),
                        ),
                      );
                    }).toList(),
                  ),
                ],
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      onPressed: quantity > 1
                          ? () => setDialog(() => quantity--)
                          : null,
                      icon: const Icon(Icons.remove_circle_outline),
                    ),
                    Text('$quantity'),
                    IconButton(
                      onPressed: () => setDialog(() => quantity++),
                      icon: const Icon(Icons.add_circle_outline),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
    if (add != true) return;
    final variantData = variants
        .cast<Map>()
        .where((v) => '${v['name']}' == variant)
        .firstOrNull;
    final addOnPrice = modifiers
        .where((m) => selected.contains('${m['name']}'))
        .fold<double>(
          0,
          (sum, m) => sum + (m['price'] as num? ?? 0).toDouble(),
        );
    final unit =
        (variantData?['price'] as num? ?? item['basePrice'] as num? ?? 0)
            .toDouble() +
        addOnPrice;
    final key =
        '${item['_id']}|$variant|${(selected.toList()..sort()).join('+')}';
    setState(
      () => cart[key] = _PosLine(
        item: item,
        quantity: (cart[key]?.quantity ?? 0) + quantity,
        variant: variant,
        addOns: selected.toList(),
        unitPrice: unit,
      ),
    );
  }

  void _quantity(String key, int delta) {
    final line = cart[key]!;
    setState(() {
      final next = line.quantity + delta;
      if (next <= 0)
        cart.remove(key);
      else
        cart[key] = line.copyWith(next);
    });
  }

  Future<void> _submit(bool pay) async {
    if (widget.branchId == null) return;
    Map<String, dynamic>? payment;
    if (pay) {
      payment = await _paymentDialog();
      if (payment == null) return;
    }
    setState(() => busy = true);
    try {
      final order = await RestaurantApi.createOrder({
        'branchId': widget.branchId,
        'tableId': tableId,
        'customerName': customerName.text.trim(),
        'customerPhone': customerPhone.text.trim(),
        'manualDiscount': manualDiscount,
        'items': cart.values
            .map(
              (line) => {
                'menuItem': line.item['_id'],
                'quantity': line.quantity,
                'selectedVariant': line.variant,
                'selectedAddOns': line.addOns,
              },
            )
            .toList(),
      });
      Map<String, dynamic>? bill;
      if (pay) {
        bill = await RestaurantApi.createBill('', payment!);
      }
      if (!mounted) return;
      if (pay && bill != null) {
        await _showReceipt(order, bill, payment!);
      }
      if (!mounted) return;
      setState(() {
        cart.clear();
        discount.text = '0';
        customerName.clear();
        customerPhone.clear();
        tableId = null;
      });
      widget.reload();
      if (!mounted) return;
      _message(
        pay ? 'Order paid and sent to kitchen.' : 'Order sent to kitchen.',
      );
    } catch (error) {
      if (mounted) _message(RestaurantApi.messageFor(error));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<Map<String, dynamic>?> _paymentDialog() async {
    String method = 'Cash';
    final first = TextEditingController();
    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (_, setDialog) => AlertDialog(
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 20,
          ),
          title: Text('Collect Rs ${total.toStringAsFixed(2)}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: method,
                items: ['Cash', 'Card', 'UPI', 'Wallet', 'Split']
                    .map(
                      (value) =>
                          DropdownMenuItem(value: value, child: Text(value)),
                    )
                    .toList(),
                onChanged: (value) => setDialog(() => method = value ?? 'Cash'),
              ),
              if (method == 'Split')
                TextField(
                  controller: first,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Cash amount (balance as UPI)',
                  ),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (method == 'Split') {
                  final cash = double.tryParse(first.text) ?? 0;
                  final upi = double.parse((total - cash).toStringAsFixed(2));
                  if (cash <= 0 || upi <= 0) {
                    return;
                  }
                  Navigator.pop(dialogContext, {
                    'paymentMethod': 'Split',
                    'splitPayments': [
                      {'paymentMethod': 'Cash', 'amount': cash},
                      {'paymentMethod': 'UPI', 'amount': upi},
                    ],
                  });
                } else {
                  Navigator.pop(dialogContext, {'paymentMethod': method});
                }
              },
              child: const Text('Confirm'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showReceipt(
    Map<String, dynamic> order,
    Map<String, dynamic> bill,
    Map<String, dynamic> payment,
  ) => showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
      title: const Row(
        children: [
          CircleAvatar(
            backgroundColor: HospitalityColors.softLeaf,
            child: Icon(Icons.check_rounded, color: HospitalityColors.leaf),
          ),
          SizedBox(width: 11),
          Expanded(child: Text('Payment complete')),
        ],
      ),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _receiptRow(
              'Order',
              (order['orderNumber'] ?? order['_id'] ?? '').toString(),
            ),
            _receiptRow(
              'Payment',
              (payment['paymentMethod'] ?? 'Paid').toString(),
            ),
            _receiptRow(
              'Amount',
              'Rs ' + (bill['total'] ?? order['total'] ?? total).toString(),
            ),
            if (tableId != null)
              Padding(
                padding: const EdgeInsets.only(top: 14),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(11),
                  decoration: BoxDecoration(
                    color: HospitalityColors.softSaffron,
                    borderRadius: BorderRadius.circular(
                      HospitalityRadius.small,
                    ),
                  ),
                  child: const Text(
                    'Table session is closed and the table is ready for cleaning handoff.',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('Done'),
        ),
      ],
    ),
  );

  Widget _receiptRow(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 7),
    child: Row(
      children: [
        Expanded(
          child: Text(label, style: Theme.of(context).textTheme.bodySmall),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
        ),
      ],
    ),
  );
  void _message(String text) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(text), behavior: SnackBarBehavior.floating),
  );
}

class _PosLine {
  const _PosLine({
    required this.item,
    required this.quantity,
    required this.variant,
    required this.addOns,
    required this.unitPrice,
  });
  final Map<String, dynamic> item;
  final int quantity;
  final String variant;
  final List<String> addOns;
  final double unitPrice;
  _PosLine copyWith(int quantity) => _PosLine(
    item: item,
    quantity: quantity,
    variant: variant,
    addOns: addOns,
    unitPrice: unitPrice,
  );
}
