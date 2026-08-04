import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/storage/local_storage.dart';
import '../../../../core/theme/app_theme.dart';
import '../widgets/receipt_printer_dialog.dart';

class _MenuProduct {
  const _MenuProduct(this.name, this.price, this.icon);
  final String name;
  final double price;
  final IconData icon;
}

class _CartLine {
  _CartLine(this.product, {this.quantity = 1});
  final _MenuProduct product;
  int quantity;
  double get total => product.price * quantity;
}

class POSDashboardScreen extends StatefulWidget {
  const POSDashboardScreen({super.key});

  @override
  State<POSDashboardScreen> createState() => _POSDashboardScreenState();
}

class _POSDashboardScreenState extends State<POSDashboardScreen> {
  static const _products = <_MenuProduct>[
    _MenuProduct('Butter Chicken', 320, Icons.ramen_dining),
    _MenuProduct('Jeera Rice', 160, Icons.rice_bowl),
    _MenuProduct('Garlic Naan', 60, Icons.bakery_dining),
    _MenuProduct('Coca Cola', 50, Icons.local_drink),
    _MenuProduct('Paneer Tikka', 280, Icons.kebab_dining),
    _MenuProduct('Gulab Jamun', 90, Icons.cake),
  ];

  final List<_CartLine> _cart = [];
  final List<String> _completedOrders = [];
  String _paymentMethod = 'Cash';
  final String _orderType = 'Dine-In';
  String _tableLabel = 'Table T1';
  String? _loadedOrderId;

  double get _subtotal => _cart.fold(0, (sum, line) => sum + line.total);
  double get _tax => _subtotal * .05;
  double get _total => _subtotal + _tax;
  String _money(double value) =>
      'â‚¹${value.toStringAsFixed(value % 1 == 0 ? 0 : 2)}';

  void _notify(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _addProduct(_MenuProduct product) {
    setState(() {
      final index = _cart.indexWhere(
        (line) => line.product.name == product.name,
      );
      if (index < 0) {
        _cart.add(_CartLine(product));
      } else {
        _cart[index].quantity++;
      }
    });
  }

  Future<void> _showMenu() async {
    final selected = await showDialog<_MenuProduct>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Add item'),
        content: SizedBox(
          width: 420,
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: _products.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (_, index) {
              final item = _products[index];
              return ListTile(
                leading: Icon(item.icon, color: AppTheme.primaryColor),
                title: Text(item.name),
                trailing: Text(_money(item.price)),
                onTap: () => Navigator.pop(dialogContext, item),
              );
            },
          ),
        ),
      ),
    );
    if (selected != null) _addProduct(selected);
  }

  Future<void> _showLiveOrders() async {
    final orders = LocalStorage.getActiveOrders()
        .where((order) => order['paymentStatus'] != 'Paid')
        .toList();
    if (orders.isEmpty) return _notify('No live QR/table orders found');

    final selected = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Live table orders'),
        content: SizedBox(
          width: 480,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: orders.length,
            itemBuilder: (_, index) {
              final order = orders[index];
              return ListTile(
                leading: const Icon(Icons.receipt_long_rounded),
                title: Text('${order['id']} â€¢ ${order['tableNo']}'),
                subtitle: Text(
                  '${order['status']} â€¢ ${order['paymentStatus']}',
                ),
                trailing: Text(
                  _money(((order['total'] as num?) ?? 0).toDouble()),
                ),
                onTap: () => Navigator.pop(dialogContext, order),
              );
            },
          ),
        ),
      ),
    );
    if (selected == null) return;

    setState(() {
      _loadedOrderId = selected['id']?.toString();
      _tableLabel = selected['tableNo']?.toString() ?? 'Table QR';
      _cart.clear();
      final rawItems = (selected['items'] as List?) ?? const [];
      for (final raw in rawItems.whereType<Map>()) {
        final name =
            raw['name']?.toString() ?? raw['title']?.toString() ?? 'Menu Item';
        final price = ((raw['price'] as num?) ?? 0).toDouble();
        final qty = ((raw['qty'] as num?) ?? (raw['quantity'] as num?) ?? 1)
            .toInt();
        _cart.add(
          _CartLine(
            _MenuProduct(name, price, Icons.restaurant_menu),
            quantity: qty,
          ),
        );
      }
    });
    _notify('${selected['id']} loaded for billing');
  }

  Future<void> _checkout() async {
    if (_cart.isEmpty) return _notify('Add or load an order before checkout');
    final orderId = _loadedOrderId ?? 'ORD-${1001 + _completedOrders.length}';
    final receipt =
        '$orderId â€¢ ${_money(_total)} â€¢ $_paymentMethod â€¢ PAID';
    await LocalStorage.settleOrderPayment(orderId, _paymentMethod);
    final cartSnapshot = _cart
        .map(
          (c) => {
            'name': c.product.name,
            'quantity': c.quantity,
            'price': c.product.price,
          },
        )
        .toList();
    final subtotalVal = _subtotal;
    final cgstVal = _tax / 2;
    final sgstVal = _tax / 2;
    final totalVal = _total;
    setState(() {
      _completedOrders.insert(0, receipt);
      _cart.clear();
      _loadedOrderId = null;
      _tableLabel = 'Table T1';
    });
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => ReceiptPrinterDialog(
        orderId: orderId,
        tableNo: _tableLabel,
        waiterName: 'Reception',
        items: cartSnapshot,
        subtotal: subtotalVal,
        cgst: cgstVal,
        sgst: sgstVal,
        total: totalVal,
        paymentMethod: _paymentMethod,
      ),
    );
  }

  Future<void> _logout() async {
    await LocalStorage.clearToken();
    if (mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBackgroundLight,
      appBar: AppBar(
        title: const Text('Reception Billing'),
        actions: [
          IconButton(
            onPressed: _logout,
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 1000;
          if (wide) {
            return Row(
              children: [
                SizedBox(width: 430, child: _cartPanel()),
                Expanded(child: _paymentPanel()),
              ],
            );
          }
          return ListView(
            padding: const EdgeInsets.all(18),
            children: [
              SizedBox(height: 560, child: _cartPanel()),
              const SizedBox(height: 18),
              _paymentPanel(),
            ],
          );
        },
      ),
    );
  }

  Widget _cartPanel() {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _loadedOrderId == null
                        ? _tableLabel
                        : '$_tableLabel â€¢ $_loadedOrderId',
                  ),
                ),
                Chip(label: Text(_orderType)),
              ],
            ),
          ),
          Expanded(
            child: _cart.isEmpty
                ? const Center(
                    child: Text(
                      'Cart is empty\nLoad QR order or add item',
                      textAlign: TextAlign.center,
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _cart.length,
                    itemBuilder: (_, index) => _cartItem(index),
                  ),
          ),
          Row(
            children: [
              Expanded(
                child: TextButton.icon(
                  onPressed: _showMenu,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Item'),
                ),
              ),
              Expanded(
                child: TextButton.icon(
                  onPressed: _showLiveOrders,
                  icon: const Icon(Icons.qr_code_rounded),
                  label: const Text('Live Orders'),
                ),
              ),
            ],
          ),
          _footer(),
        ],
      ),
    );
  }

  Widget _cartItem(int index) {
    final line = _cart[index];
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Text(
            '${line.quantity}x',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(line.product.name)),
          Text(_money(line.total)),
          IconButton(
            onPressed: () => setState(() => _cart.removeAt(index)),
            icon: const Icon(Icons.close, size: 18),
          ),
        ],
      ),
    );
  }

  Widget _footer() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _totalRow('Subtotal', _money(_subtotal)),
          _totalRow('GST (5%)', _money(_tax)),
          const Divider(height: 24),
          _totalRow('Total', _money(_total), strong: true),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _checkout,
              child: Text('Print Bill ${_money(_total)}'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _totalRow(String label, String amount, {bool strong = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: strong ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            amount,
            style: TextStyle(
              fontWeight: strong ? FontWeight.bold : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _paymentPanel() {
    return Container(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Payment',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          Text(
            'Selected: $_paymentMethod',
            style: const TextStyle(color: AppTheme.textSecondaryLight),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 14,
            runSpacing: 14,
            children: [
              _paymentCard(Icons.money, 'Cash', Colors.green),
              _paymentCard(Icons.credit_card, 'Card', Colors.blue),
              _paymentCard(Icons.qr_code_scanner, 'UPI', Colors.orange),
              _paymentCard(
                Icons.account_balance_wallet,
                'Wallet',
                Colors.purple,
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (_completedOrders.isNotEmpty) ...[
            const Text(
              'Recent paid bills',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            ..._completedOrders
                .take(5)
                .map(
                  (order) => ListTile(
                    leading: const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                    ),
                    title: Text(order),
                  ),
                ),
          ],
        ],
      ),
    );
  }

  Widget _paymentCard(IconData icon, String label, Color color) {
    final selected = _paymentMethod == label;
    return SizedBox(
      width: 150,
      height: 116,
      child: Card(
        elevation: selected ? 2 : 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
            color: selected ? color : AppTheme.borderLight,
            width: selected ? 2 : 1,
          ),
        ),
        child: InkWell(
          onTap: () => setState(() => _paymentMethod = label),
          borderRadius: BorderRadius.circular(14),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 34, color: color),
              const SizedBox(height: 10),
              Text(label),
            ],
          ),
        ),
      ),
    );
  }
}
