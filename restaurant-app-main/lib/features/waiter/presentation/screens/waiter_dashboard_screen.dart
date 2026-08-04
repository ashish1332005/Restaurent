import 'package:flutter/material.dart';

class WaiterDashboardScreen extends StatefulWidget {
  const WaiterDashboardScreen({super.key});

  @override
  State<WaiterDashboardScreen> createState() => _WaiterDashboardScreenState();
}

class _WaiterDashboardScreenState extends State<WaiterDashboardScreen> {
  static const _orange = Color(0xFFFF4D0A);
  static const _bg = Color(0xFFFAFAFB);
  static const _ink = Color(0xFF111827);
  static const _muted = Color(0xFF687385);
  static const _border = Color(0xFFE8EDF3);
  static const _green = Color(0xFF16A34A);
  static const _amber = Color(0xFFF59E0B);
  static const _red = Color(0xFFEF4444);

  final List<_WaiterTable> _tables = [
    const _WaiterTable(
      id: '01',
      guests: 2,
      status: _TableStatus.available,
      orderId: '',
      total: 0,
      note: 'Ready for seating',
    ),
    const _WaiterTable(
      id: '02',
      guests: 4,
      status: _TableStatus.occupied,
      orderId: '#ORD-1051',
      total: 520,
      note: 'Taking starters',
    ),
    const _WaiterTable(
      id: '03',
      guests: 4,
      status: _TableStatus.preparing,
      orderId: '#ORD-1052',
      total: 870,
      note: 'Kitchen preparing',
    ),
    const _WaiterTable(
      id: '04',
      guests: 6,
      status: _TableStatus.ready,
      orderId: '#ORD-1053',
      total: 1240,
      note: 'Serve main course',
    ),
    const _WaiterTable(
      id: '05',
      guests: 2,
      status: _TableStatus.reserved,
      orderId: '',
      total: 0,
      note: '7:30 PM booking',
    ),
    const _WaiterTable(
      id: '06',
      guests: 3,
      status: _TableStatus.occupied,
      orderId: '#ORD-1054',
      total: 640,
      note: 'Need water refill',
    ),
    const _WaiterTable(
      id: '07',
      guests: 2,
      status: _TableStatus.available,
      orderId: '',
      total: 0,
      note: 'Ready',
    ),
    const _WaiterTable(
      id: '08',
      guests: 5,
      status: _TableStatus.preparing,
      orderId: '#ORD-1055',
      total: 1590,
      note: 'Extra spicy request',
    ),
    const _WaiterTable(
      id: '09',
      guests: 4,
      status: _TableStatus.cleaning,
      orderId: '',
      total: 0,
      note: 'Cleaning in progress',
    ),
  ];

  final List<_MenuItem> _menu = const [
    _MenuItem(
      name: 'Paneer Butter Masala',
      category: 'Main Course',
      price: 240,
      veg: true,
    ),
    _MenuItem(
      name: 'Dal Tadka',
      category: 'Main Course',
      price: 160,
      veg: true,
    ),
    _MenuItem(
      name: 'Chicken Biryani',
      category: 'Main Course',
      price: 280,
      veg: false,
    ),
    _MenuItem(name: 'Garlic Naan', category: 'Breads', price: 70, veg: true),
    _MenuItem(
      name: 'Veg Sandwich',
      category: 'Starters',
      price: 150,
      veg: true,
    ),
    _MenuItem(
      name: 'French Fries',
      category: 'Starters',
      price: 120,
      veg: true,
    ),
    _MenuItem(name: 'Cold Coffee', category: 'Drinks', price: 120, veg: true),
    _MenuItem(
      name: 'Sweet Lime Soda',
      category: 'Drinks',
      price: 90,
      veg: true,
    ),
  ];

  final Map<String, List<_CartItem>> _cartByTable = {
    '03': [
      _CartItem(
        item: _MenuItem(
          name: 'Paneer Butter Masala',
          category: 'Main Course',
          price: 240,
          veg: true,
        ),
        qty: 1,
      ),
      _CartItem(
        item: _MenuItem(
          name: 'Garlic Naan',
          category: 'Breads',
          price: 70,
          veg: true,
        ),
        qty: 2,
      ),
    ],
    '08': [
      _CartItem(
        item: _MenuItem(
          name: 'Chicken Biryani',
          category: 'Main Course',
          price: 280,
          veg: false,
        ),
        qty: 2,
      ),
    ],
  };

  int _navIndex = 0;
  String _selectedTable = '03';
  String _menuCategory = 'All';

  _WaiterTable get _activeTable =>
      _tables.firstWhere((t) => t.id == _selectedTable);
  List<_CartItem> get _activeCart =>
      _cartByTable.putIfAbsent(_selectedTable, () => []);
  int get _cartTotal =>
      _activeCart.fold(0, (sum, row) => sum + row.item.price * row.qty);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        titleSpacing: 18,
        title: Text(
          _title,
          style: const TextStyle(
            color: _ink,
            fontSize: 20,
            fontWeight: FontWeight.w900,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _showTableQr,
            icon: const Icon(Icons.qr_code_rounded, color: _ink),
          ),
          Stack(
            children: [
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.notifications_none_rounded, color: _ink),
              ),
              Positioned(
                right: 10,
                top: 10,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: _red,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: IndexedStack(
        index: _navIndex,
        children: [
          _dashboardPage(),
          _tablesPage(),
          _ordersPage(),
          _takeOrderPage(),
          _morePage(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        height: 72,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        indicatorColor: _orange.withValues(alpha: 0.12),
        selectedIndex: _navIndex,
        onDestinationSelected: (index) => setState(() => _navIndex = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded, color: _orange),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.table_restaurant_outlined),
            selectedIcon: Icon(Icons.table_restaurant_rounded, color: _orange),
            label: 'Tables',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long_rounded, color: _orange),
            label: 'Orders',
          ),
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book_rounded, color: _orange),
            label: 'Menu',
          ),
          NavigationDestination(
            icon: Icon(Icons.more_horiz_rounded),
            selectedIcon: Icon(Icons.more_horiz_rounded, color: _orange),
            label: 'More',
          ),
        ],
      ),
    );
  }

  String get _title => switch (_navIndex) {
    0 => 'Waiter Dashboard',
    1 => 'Tables',
    2 => 'Live Orders',
    3 => 'Take Order',
    _ => 'More',
  };

  Widget _page({required Widget child}) {
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 24),
        child: child,
      ),
    );
  }

  Widget _dashboardPage() {
    final active = _tables.where((t) => t.status.active).length;
    final ready = _tables.where((t) => t.status == _TableStatus.ready).length;
    return _page(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _welcomeCard(),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _statCard(
                  'Active',
                  '$active',
                  Icons.table_bar_rounded,
                  _orange,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _statCard(
                  'Ready',
                  '$ready',
                  Icons.room_service_rounded,
                  _green,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _statCard(
                  'Sales',
                  'â‚¹${_tables.fold(0, (s, t) => s + t.total)}',
                  Icons.payments_rounded,
                  _amber,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _sectionHeader(
            'Assigned Tables',
            'View All',
            () => setState(() => _navIndex = 1),
          ),
          const SizedBox(height: 12),
          _tableGrid(compact: true),
          const SizedBox(height: 20),
          _sectionHeader(
            'Recent Orders',
            'View All',
            () => setState(() => _navIndex = 2),
          ),
          const SizedBox(height: 10),
          ..._tables.where((t) => t.orderId.isNotEmpty).take(4).map(_orderTile),
        ],
      ),
    );
  }

  Widget _tablesPage() {
    return _page(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _selectedTableStrip(),
          const SizedBox(height: 16),
          _filterChips(['All', 'Available', 'Occupied', 'Preparing', 'Ready']),
          const SizedBox(height: 16),
          _tableGrid(compact: false),
          const SizedBox(height: 18),
          _tableActionCard(),
        ],
      ),
    );
  }

  Widget _ordersPage() {
    final orders = _tables.where((t) => t.orderId.isNotEmpty).toList();
    return _page(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _filterChips(['All', 'Preparing', 'Ready', 'Occupied']),
          const SizedBox(height: 14),
          ...orders.map(_orderTile),
        ],
      ),
    );
  }

  Widget _takeOrderPage() {
    final categories = ['All', 'Starters', 'Main Course', 'Breads', 'Drinks'];
    final items = _menuCategory == 'All'
        ? _menu
        : _menu.where((m) => m.category == _menuCategory).toList();
    return _page(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _selectedTableStrip(),
          const SizedBox(height: 14),
          _searchBox(),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: categories
                  .map(
                    (c) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(c),
                        selected: _menuCategory == c,
                        selectedColor: _orange,
                        backgroundColor: Colors.white,
                        side: BorderSide(
                          color: _menuCategory == c ? _orange : _border,
                        ),
                        labelStyle: TextStyle(
                          color: _menuCategory == c ? Colors.white : _ink,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                        onSelected: (_) => setState(() => _menuCategory = c),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: 14),
          ...items.map(_menuTile),
          const SizedBox(height: 92),
        ],
      ),
    );
  }

  Widget _morePage() {
    return _page(
      child: Column(
        children: [
          _qrCard(),
          const SizedBox(height: 16),
          _toolTile(
            Icons.support_agent_rounded,
            'Call Manager',
            'Ask manager for help',
          ),
          _toolTile(
            Icons.water_drop_outlined,
            'Water Refill Request',
            'Mark table water request',
          ),
          _toolTile(
            Icons.print_rounded,
            'Print Bill',
            'Send selected table bill',
          ),
          _toolTile(
            Icons.logout_rounded,
            'Log Out',
            'Exit waiter account',
            danger: true,
          ),
        ],
      ),
    );
  }

  Widget _welcomeCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: _orange.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(Icons.room_service_rounded, color: _orange),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Good evening, waiter',
                  style: TextStyle(
                    color: _ink,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Select table first, then take customer order.',
                  style: TextStyle(color: _muted, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _selectedTableStrip() {
    final table = _activeTable;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: table.status.color.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.table_restaurant_rounded,
              color: table.status.color,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Table ${table.id}',
                  style: const TextStyle(
                    color: _ink,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  '${table.guests} guests â€¢ ${table.note}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: _muted, fontSize: 12),
                ),
              ],
            ),
          ),
          _statusChip(table.status.label, table.status.color),
        ],
      ),
    );
  }

  Widget _tableGrid({required bool compact}) {
    final visible = compact ? _tables.take(6).toList() : _tables;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: visible.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: MediaQuery.sizeOf(context).width < 430
            ? 3
            : compact
            ? 3
            : 4,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: compact ? 1.18 : 1,
      ),
      itemBuilder: (_, i) => _tableTile(visible[i]),
    );
  }

  Widget _tableTile(_WaiterTable table) {
    final selected = table.id == _selectedTable;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => setState(() {
        _selectedTable = table.id;
        _navIndex = 3;
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: selected
              ? table.status.color.withValues(alpha: .12)
              : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? table.status.color : _border,
            width: selected ? 2 : 1,
          ),
          boxShadow: _shadow,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              table.id,
              style: const TextStyle(
                color: _ink,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 3),
            Icon(Icons.chair_alt_rounded, size: 16, color: table.status.color),
            const SizedBox(height: 4),
            Text(
              table.status.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: table.status.color,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              '${table.guests} guests',
              style: const TextStyle(color: _muted, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tableActionCard() {
    final table = _activeTable;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Table Actions',
            style: TextStyle(
              color: _ink,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _primaryButton(
                  'Take Order',
                  Icons.add_shopping_cart_rounded,
                  () => setState(() => _navIndex = 3),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _outlineButton(
                  'QR Code',
                  Icons.qr_code_rounded,
                  _showTableQr,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _outlineButton(
                  'Mark Ready',
                  Icons.room_service_rounded,
                  () => _updateTable(table.id, _TableStatus.ready),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _outlineButton(
                  'Print Bill',
                  Icons.print_rounded,
                  () => _toast('Bill sent to printer'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _orderTile(_WaiterTable table) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  table.orderId,
                  style: const TextStyle(
                    color: _ink,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Table ${table.id} â€¢ ${table.guests} guests',
                  style: const TextStyle(color: _muted, fontSize: 12),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _statusChip(table.status.label, table.status.color),
              const SizedBox(height: 8),
              Text(
                'â‚¹${table.total}',
                style: const TextStyle(
                  color: _ink,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(width: 6),
          const Icon(Icons.chevron_right_rounded, color: _muted),
        ],
      ),
    );
  }

  Widget _menuTile(_MenuItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: (item.veg ? _green : _red).withValues(alpha: .10),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(
              item.veg ? Icons.eco_rounded : Icons.restaurant_rounded,
              color: item.veg ? _green : _red,
              size: 19,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(
                    color: _ink,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${item.category} â€¢ â‚¹${item.price}',
                  style: const TextStyle(color: _muted, fontSize: 12),
                ),
              ],
            ),
          ),
          IconButton.filled(
            onPressed: () => _addItem(item),
            icon: const Icon(Icons.add_rounded),
            style: IconButton.styleFrom(
              backgroundColor: _orange,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _searchBox() {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: _cardDecoration(radius: 14),
      child: const Row(
        children: [
          Icon(Icons.search_rounded, color: _muted, size: 20),
          SizedBox(width: 10),
          Text('Search menu items', style: TextStyle(color: _muted)),
        ],
      ),
    );
  }

  Widget _qrCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Table QR',
              style: TextStyle(
                color: _ink,
                fontSize: 17,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _border),
            ),
            child: const Icon(Icons.qr_code_2_rounded, size: 128, color: _ink),
          ),
          const SizedBox(height: 12),
          Text(
            'Table $_selectedTable',
            style: const TextStyle(
              color: _orange,
              fontWeight: FontWeight.w900,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _toolTile(
    IconData icon,
    String title,
    String subtitle, {
    bool danger = false,
  }) {
    final color = danger ? _red : _ink;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: _cardDecoration(radius: 14),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(
          title,
          style: TextStyle(color: color, fontWeight: FontWeight.w800),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(color: _muted, fontSize: 12),
        ),
        trailing: const Icon(Icons.chevron_right_rounded, color: _muted),
        onTap: () => _toast(title),
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: _cardDecoration(radius: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const Spacer(),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _ink,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              color: _muted,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChips(List<String> chips) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: chips
            .map(
              (c) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Chip(
                  label: Text(c),
                  backgroundColor: c == 'All' ? _orange : Colors.white,
                  side: BorderSide(color: c == 'All' ? _orange : _border),
                  labelStyle: TextStyle(
                    color: c == 'All' ? Colors.white : _muted,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _sectionHeader(String title, String action, VoidCallback onTap) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: _ink,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        TextButton(
          onPressed: onTap,
          child: Text(
            action,
            style: const TextStyle(color: _orange, fontWeight: FontWeight.w900),
          ),
        ),
      ],
    );
  }

  Widget _statusChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _primaryButton(String label, IconData icon, VoidCallback onTap) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: _orange,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _outlineButton(String label, IconData icon, VoidCallback onTap) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: _ink,
        side: const BorderSide(color: _border),
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  BoxDecoration _cardDecoration({double radius = 18}) {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: _border),
      boxShadow: _shadow,
    );
  }

  static final _shadow = [
    BoxShadow(
      color: Colors.black.withValues(alpha: .035),
      blurRadius: 14,
      offset: const Offset(0, 6),
    ),
  ];

  void _addItem(_MenuItem item) {
    final cart = _activeCart;
    final index = cart.indexWhere((row) => row.item.name == item.name);
    setState(() {
      if (index == -1) {
        cart.add(_CartItem(item: item, qty: 1));
      } else {
        cart[index] = cart[index].copyWith(qty: cart[index].qty + 1);
      }
      _updateTableTotal(_selectedTable);
    });
    _toast('${item.name} added to Table $_selectedTable');
  }

  void _updateTable(String id, _TableStatus status) {
    final index = _tables.indexWhere((t) => t.id == id);
    if (index == -1) return;
    setState(
      () => _tables[index] = _tables[index].copyWith(
        status: status,
        note: status.label,
      ),
    );
    _toast('Table $id marked ${status.label}');
  }

  void _updateTableTotal(String id) {
    final index = _tables.indexWhere((t) => t.id == id);
    if (index == -1) return;
    final orderId = _tables[index].orderId.isEmpty
        ? '#ORD-${1050 + index}'
        : _tables[index].orderId;
    _tables[index] = _tables[index].copyWith(
      status: _TableStatus.occupied,
      orderId: orderId,
      total: _cartTotal,
      note: '${_activeCart.length} items in cart',
    );
  }

  void _showTableQr() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Table $_selectedTable QR'),
        content: _qrCard(),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message), backgroundColor: _ink));
  }
}

enum _TableStatus {
  available('Available', _WaiterDashboardScreenState._green, false),
  occupied('Occupied', _WaiterDashboardScreenState._orange, true),
  preparing('Preparing', _WaiterDashboardScreenState._amber, true),
  ready('Ready', _WaiterDashboardScreenState._green, true),
  reserved('Reserved', _WaiterDashboardScreenState._amber, false),
  cleaning('Cleaning', _WaiterDashboardScreenState._muted, false);

  const _TableStatus(this.label, this.color, this.active);
  final String label;
  final Color color;
  final bool active;
}

class _WaiterTable {
  const _WaiterTable({
    required this.id,
    required this.guests,
    required this.status,
    required this.orderId,
    required this.total,
    required this.note,
  });
  final String id;
  final int guests;
  final _TableStatus status;
  final String orderId;
  final int total;
  final String note;

  _WaiterTable copyWith({
    _TableStatus? status,
    String? orderId,
    int? total,
    String? note,
  }) {
    return _WaiterTable(
      id: id,
      guests: guests,
      status: status ?? this.status,
      orderId: orderId ?? this.orderId,
      total: total ?? this.total,
      note: note ?? this.note,
    );
  }
}

class _MenuItem {
  const _MenuItem({
    required this.name,
    required this.category,
    required this.price,
    required this.veg,
  });
  final String name;
  final String category;
  final int price;
  final bool veg;
}

class _CartItem {
  const _CartItem({required this.item, required this.qty});
  final _MenuItem item;
  final int qty;
  _CartItem copyWith({int? qty}) => _CartItem(item: item, qty: qty ?? this.qty);
}
