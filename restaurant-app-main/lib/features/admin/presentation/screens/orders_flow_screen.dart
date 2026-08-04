import 'package:flutter/material.dart';

enum OrderFlowSubView {
  overview,
  liveList,
  orderDetail,
  updateStatus,
  dineInDetail,
  deliveryDetail,
  completedHistory,
}

class OrdersFlowScreen extends StatefulWidget {
  const OrdersFlowScreen({super.key});

  @override
  State<OrdersFlowScreen> createState() => _OrdersFlowScreenState();
}

class _OrdersFlowScreenState extends State<OrdersFlowScreen> {
  OrderFlowSubView _currentSubView = OrderFlowSubView.overview;

  Map<String, dynamic> _activeOrder = {
    'id': '#RH-10045',
    'customer': 'Aarav Mehta',
    'phone': '+91 98765 43210',
    'table': 'Table 5',
    'guests': 3,
    'time': '18 May 2025, 10:32 AM',
    'type': 'Dine-in',
    'status': 'Placed',
    'amount': 1362,
    'items': [
      {'name': 'Paneer Butter Masala', 'qty': 1, 'price': 380},
      {'name': 'Garlic Naan', 'qty': 2, 'price': 120},
      {'name': 'Veg Biryani', 'qty': 1, 'price': 320},
      {'name': 'Sweet Lime Soda', 'qty': 1, 'price': 140},
      {'name': 'Tiramisu', 'qty': 1, 'price': 290},
    ],
    'instructions': 'No onion, please make it medium spicy.',
    'waiter': 'Rakesh',
    'subtotal': 1250,
    'taxes': 112,
  };

  String _overviewFilter = 'All';
  String _liveFilter = 'All';
  String _historyFilter = 'All';
  final String _selectedDateRange = '18 May 2025';

  // Aesthetic Palette
  static const Color _orange = Color(0xFFFF4D0A);
  static const Color _bgLight = Color(0xFFFAFAFB);
  static const Color _cardBg = Colors.white;
  static const Color _borderSoft = Color(0xFFE8EDF3);
  static const Color _textDark = Color(0xFF111827);
  static const Color _textMuted = Color(0xFF687385);

  static final List<BoxShadow> _cardShadow = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.03),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];

  Color _getStatusBg(String status) {
    switch (status.toLowerCase()) {
      case 'placed':
        return const Color(0xFFEFF6FF);
      case 'confirmed':
        return const Color(0xFFFEF3C7);
      case 'preparing':
        return const Color(0xFFFFF7ED);
      case 'ready':
        return const Color(0xFFF0FDF4);
      case 'served':
      case 'completed':
      case 'delivered':
        return const Color(0xFFE8EDF3);
      case 'cancelled':
        return const Color(0xFFFEF2F2);
      default:
        return const Color(0xFFE8EDF3);
    }
  }

  Color _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'placed':
        return const Color(0xFF2563EB);
      case 'confirmed':
        return const Color(0xFFD97706);
      case 'preparing':
        return const Color(0xFFEA580C);
      case 'ready':
        return const Color(0xFF16A34A);
      case 'served':
      case 'completed':
      case 'delivered':
        return const Color(0xFF475569);
      case 'cancelled':
        return const Color(0xFFDC2626);
      default:
        return const Color(0xFF475569);
    }
  }

  final List<Map<String, dynamic>> _sampleOrders = [
    {
      'id': '#RH-10045',
      'customer': 'Aarav Mehta',
      'phone': '+91 98765 43210',
      'table': 'Table 5',
      'guests': 3,
      'time': '10:32 AM',
      'fullTime': '18 May 2025, 10:32 AM',
      'type': 'Dine-in',
      'status': 'Placed',
      'amount': 1250,
      'itemsCount': 3,
      'items': [
        {'name': 'Paneer Butter Masala', 'qty': 1, 'price': 380},
        {'name': 'Garlic Naan', 'qty': 2, 'price': 120},
        {'name': 'Veg Biryani', 'qty': 1, 'price': 320},
      ],
      'instructions': 'No onion, please make it medium spicy.',
      'waiter': 'Rakesh',
      'subtotal': 1250,
      'taxes': 112,
    },
    {
      'id': '#RH-10044',
      'customer': 'Neha Sharma',
      'phone': '+91 97654 32109',
      'table': 'Takeaway',
      'guests': 1,
      'time': '10:30 AM',
      'fullTime': '18 May 2025, 10:30 AM',
      'type': 'Takeaway',
      'status': 'Preparing',
      'amount': 720,
      'itemsCount': 2,
      'items': [
        {'name': 'Hakka Noodle', 'qty': 1, 'price': 240},
        {'name': 'Chilli Paneer', 'qty': 1, 'price': 480},
      ],
      'instructions': 'Pack extra green chutney.',
      'subtotal': 650,
      'taxes': 70,
    },
    {
      'id': '#RH-10043',
      'customer': 'Rohan Verma',
      'phone': '+91 91234 56789',
      'table': 'Table 2',
      'guests': 4,
      'time': '10:28 AM',
      'fullTime': '18 May 2025, 10:28 AM',
      'type': 'Dine-in',
      'status': 'Ready',
      'amount': 980,
      'itemsCount': 4,
      'items': [
        {'name': 'Margherita Pizza', 'qty': 2, 'price': 760},
        {'name': 'Alfredo Pasta', 'qty': 1, 'price': 420},
        {'name': 'Lemon Iced Tea', 'qty': 2, 'price': 160},
        {'name': 'Chocolate Brownie', 'qty': 1, 'price': 180},
      ],
      'instructions': 'Extra parmesan on pasta.',
      'waiter': 'Rakesh',
      'subtotal': 1520,
      'taxes': 137,
    },
    {
      'id': '#RH-10042',
      'customer': 'Sneha Iyer',
      'phone': '+91 99000 11223',
      'table': 'Table 8',
      'guests': 3,
      'time': '10:25 AM',
      'fullTime': '18 May 2025, 10:25 AM',
      'type': 'Dine-in',
      'status': 'Served',
      'amount': 1180,
      'itemsCount': 3,
      'items': [
        {'name': 'Dal Makhani', 'qty': 1, 'price': 350},
        {'name': 'Jeera Rice', 'qty': 2, 'price': 220},
        {'name': 'Butter Naan', 'qty': 4, 'price': 240},
      ],
      'instructions': '',
      'waiter': 'Amit',
      'subtotal': 1050,
      'taxes': 130,
    },
    {
      'id': '#RH-10041',
      'customer': 'Vikram Singh',
      'phone': '+91 98765 43210',
      'address': '12, Green Park, New Delhi - 110016',
      'table': 'Delivery',
      'guests': 2,
      'time': '10:23 AM',
      'fullTime': '18 May 2025, 10:23 AM',
      'type': 'Delivery',
      'status': 'Preparing',
      'paymentMethod': 'Online (UPI)',
      'paymentStatus': 'Paid',
      'amount': 650,
      'itemsCount': 5,
      'items': [
        {'name': 'Chicken Dum Biryani', 'qty': 1, 'price': 450},
        {'name': 'Mirchi Ka Salan', 'qty': 1, 'price': 120},
        {'name': 'Raita', 'qty': 1, 'price': 80},
      ],
      'instructions': 'Please ring the bell. Leave at the door.',
      'subtotal': 600,
      'taxes': 50,
    },
  ];

  void _navigateToDetail(Map<String, dynamic> order) {
    setState(() {
      _activeOrder = order;
      if (order['type'] == 'Delivery') {
        _currentSubView = OrderFlowSubView.deliveryDetail;
      } else if (order['type'] == 'Dine-in') {
        _currentSubView = OrderFlowSubView.dineInDetail;
      } else {
        _currentSubView = OrderFlowSubView.orderDetail;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _bgLight,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: _buildCurrentSubView(),
      ),
    );
  }

  Widget _buildCurrentSubView() {
    switch (_currentSubView) {
      case OrderFlowSubView.overview:
        return _buildScreen1Overview();
      case OrderFlowSubView.liveList:
        return _buildScreen2LiveOrdersList();
      case OrderFlowSubView.orderDetail:
        return _buildScreen3OrderDetail();
      case OrderFlowSubView.updateStatus:
        return _buildScreen4UpdateStatus();
      case OrderFlowSubView.dineInDetail:
        return _buildScreen5DineInDetail();
      case OrderFlowSubView.deliveryDetail:
        return _buildScreen6DeliveryDetail();
      case OrderFlowSubView.completedHistory:
        return _buildScreen8CompletedOrders();
    }
  }

  // ================= 1. ORDERS OVERVIEW (Spacious & Clean) =================
  Widget _buildScreen1Overview() {
    return SingleChildScrollView(
      key: const ValueKey('Screen1'),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Orders',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: _textDark,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Today, $_selectedDateRange',
                    style: const TextStyle(
                      color: _textMuted,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  _actionIconButton(
                    Icons.search_rounded,
                    () => setState(
                      () => _currentSubView = OrderFlowSubView.liveList,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _actionIconButton(Icons.tune_rounded, _showFiltersModal),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Uncrowded Status Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: ['All', 'Placed', 'Preparing', 'Ready', 'Served'].map((
                st,
              ) {
                final isSel = _overviewFilter == st;
                return Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: ChoiceChip(
                    label: Text(st),
                    selected: isSel,
                    selectedColor: _orange,
                    backgroundColor: Colors.white,
                    side: BorderSide(color: isSel ? _orange : _borderSoft),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    labelStyle: TextStyle(
                      color: isSel ? Colors.white : _textMuted,
                      fontWeight: isSel ? FontWeight.w800 : FontWeight.w600,
                      fontSize: 13,
                    ),
                    onSelected: (val) => setState(() => _overviewFilter = st),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 22),

          // Metric Cards Grid (Airy & Spacious)
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: 1.65,
            children: [
              _spaciousMetricTile(
                'Total Orders',
                '42',
                '+18%',
                const Color(0xFF22C55E),
                const Color(0xFFF0FDF4),
              ),
              _spaciousMetricTile(
                'Live Orders',
                '17',
                '+12%',
                const Color(0xFF2563EB),
                const Color(0xFFEFF6FF),
              ),
              _spaciousMetricTile(
                'Revenue',
                '₹ 28,450',
                '+15%',
                const Color(0xFF16A34A),
                const Color(0xFFF0FDF4),
              ),
              _spaciousMetricTile(
                'Average Order',
                '₹ 678',
                '+8%',
                const Color(0xFFEA580C),
                const Color(0xFFFFF7ED),
              ),
            ],
          ),
          const SizedBox(height: 26),

          // Live Orders Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Live Orders',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: _textDark,
                  letterSpacing: -0.3,
                ),
              ),
              TextButton(
                onPressed: () =>
                    setState(() => _currentSubView = OrderFlowSubView.liveList),
                child: const Text(
                  'View all',
                  style: TextStyle(
                    color: _orange,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Live Orders Cards List
          ..._sampleOrders
              .take(4)
              .map((ord) => _buildCleanOrderSummaryCard(ord)),

          const SizedBox(height: 16),
          // History Button
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
              side: const BorderSide(color: _borderSoft),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              backgroundColor: Colors.white,
            ),
            onPressed: () => setState(
              () => _currentSubView = OrderFlowSubView.completedHistory,
            ),
            icon: const Icon(Icons.history_rounded, color: _textDark, size: 20),
            label: const Text(
              'View Order History',
              style: TextStyle(
                color: _textDark,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionIconButton(IconData icon, VoidCallback onTap) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _borderSoft),
        boxShadow: _cardShadow,
      ),
      child: IconButton(
        icon: Icon(icon, color: _textDark, size: 20),
        onPressed: onTap,
      ),
    );
  }

  Widget _spaciousMetricTile(
    String title,
    String value,
    String badge,
    Color accentColor,
    Color bgTint,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _borderSoft),
        boxShadow: _cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: _textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: bgTint,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  badge,
                  style: TextStyle(
                    color: accentColor,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: _textDark,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCleanOrderSummaryCard(Map<String, dynamic> ord) {
    final status = ord['status'] as String;
    return GestureDetector(
      onTap: () => _navigateToDetail(ord),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _cardBg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _borderSoft),
          boxShadow: _cardShadow,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _orange.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.receipt_long_rounded,
                color: _orange,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        ord['id'],
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          color: _textDark,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        ord['time'],
                        style: const TextStyle(color: _textMuted, fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${ord['customer']} • ${ord['table']}',
                    style: const TextStyle(
                      color: _textMuted,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '₹ ${ord['amount']}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                    color: _textDark,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusBg(status),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      color: _getStatusText(status),
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ================= 2. LIVE ORDERS LIST =================
  Widget _buildScreen2LiveOrdersList() {
    final filtered = _liveFilter == 'All'
        ? _sampleOrders
        : _sampleOrders
              .where(
                (o) =>
                    o['status'].toString().toLowerCase() ==
                    _liveFilter.toLowerCase(),
              )
              .toList();

    return SingleChildScrollView(
      key: const ValueKey('Screen2'),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _actionIconButton(
                Icons.arrow_back_rounded,
                () =>
                    setState(() => _currentSubView = OrderFlowSubView.overview),
              ),
              const SizedBox(width: 12),
              const Text(
                'Live Orders',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: _textDark,
                ),
              ),
              const Spacer(),
              _actionIconButton(Icons.tune_rounded, _showFiltersModal),
            ],
          ),
          const SizedBox(height: 16),

          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: ['All', 'Placed', 'Preparing', 'Ready', 'Served'].map((
                st,
              ) {
                final isSel = _liveFilter == st;
                return Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: ChoiceChip(
                    label: Text(st),
                    selected: isSel,
                    selectedColor: _orange,
                    backgroundColor: Colors.white,
                    side: BorderSide(color: isSel ? _orange : _borderSoft),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    labelStyle: TextStyle(
                      color: isSel ? Colors.white : _textMuted,
                      fontWeight: isSel ? FontWeight.w800 : FontWeight.w600,
                      fontSize: 12,
                    ),
                    onSelected: (val) => setState(() => _liveFilter = st),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 20),

          ...filtered.map((ord) {
            final status = ord['status'] as String;
            return Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _cardBg,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: _borderSoft),
                boxShadow: _cardShadow,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        ord['id'],
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          color: _textDark,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusBg(status),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          status,
                          style: TextStyle(
                            color: _getStatusText(status),
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    ord['customer'],
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: _textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '${ord['table']} • ${ord['itemsCount']} items',
                        style: const TextStyle(color: _textMuted, fontSize: 13),
                      ),
                      const Spacer(),
                      Text(
                        '₹ ${ord['amount']}',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                          color: _textDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: _borderSoft),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          onPressed: () => _navigateToDetail(ord),
                          child: const Text(
                            'View Details',
                            style: TextStyle(
                              color: _textDark,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      IconButton(
                        icon: const Icon(
                          Icons.more_horiz_rounded,
                          color: _textMuted,
                        ),
                        onPressed: () => _showOrderActionsSheet(ord),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ================= 3. ORDER DETAIL =================
  Widget _buildScreen3OrderDetail() {
    final ord = _activeOrder;
    final items = ord['items'] as List<dynamic>;

    return SingleChildScrollView(
      key: const ValueKey('Screen3'),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _actionIconButton(
                Icons.arrow_back_rounded,
                () =>
                    setState(() => _currentSubView = OrderFlowSubView.liveList),
              ),
              const SizedBox(width: 12),
              const Text(
                'Order Detail',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: _textDark,
                ),
              ),
              const Spacer(),
              _actionIconButton(
                Icons.print_outlined,
                () => _showToast('Printing KOT...'),
              ),
            ],
          ),
          const SizedBox(height: 18),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: _borderSoft),
              boxShadow: _cardShadow,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ord['id'],
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                        color: _textDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      ord['fullTime'] ?? '18 May 2025, 10:32 AM',
                      style: const TextStyle(color: _textMuted, fontSize: 12),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusBg(ord['status']),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    ord['status'],
                    style: TextStyle(
                      color: _getStatusText(ord['status']),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: _borderSoft),
              boxShadow: _cardShadow,
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  backgroundColor: Color(0xFFE8EDF3),
                  child: Icon(Icons.person_outline_rounded, color: _textDark),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Customer',
                        style: TextStyle(color: _textMuted, fontSize: 11),
                      ),
                      Text(
                        ord['customer'],
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.table_restaurant_rounded,
                      size: 18,
                      color: _textMuted,
                    ),
                    Text(
                      ord['table'],
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 18),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.groups_outlined,
                      size: 18,
                      color: _textMuted,
                    ),
                    Text(
                      'Guests ${ord['guests']}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          const Text(
            'Items',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: _textDark,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: _borderSoft),
              boxShadow: _cardShadow,
            ),
            child: Column(
              children: items.map((it) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8EDF3),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${it['qty']}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          it['name'],
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      Text(
                        '₹ ${it['price']}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),

          if ((ord['instructions'] ?? '').toString().isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Special Instructions',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: Color(0xFFB45309),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    ord['instructions'],
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF78350F),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: _borderSoft),
              boxShadow: _cardShadow,
            ),
            child: Column(
              children: [
                _summaryRow(
                  'Subtotal (${items.length} items)',
                  '₹ ${ord['subtotal'] ?? 1250}',
                ),
                const SizedBox(height: 8),
                _summaryRow('Taxes & Charges', '₹ ${ord['taxes'] ?? 112}'),
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 17,
                      ),
                    ),
                    Text(
                      '₹ ${ord['amount']}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 19,
                        color: _textDark,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(color: _orange, width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () => setState(
                    () => _currentSubView = OrderFlowSubView.updateStatus,
                  ),
                  icon: const Icon(
                    Icons.system_update_alt_rounded,
                    color: _orange,
                    size: 18,
                  ),
                  label: const Text(
                    'Update Status',
                    style: TextStyle(
                      color: _orange,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: _orange,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () => _showToast('KOT printed successfully!'),
                  icon: const Icon(
                    Icons.print_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                  label: const Text(
                    'Print KOT',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: () => _showOrderActionsSheet(ord),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: _borderSoft),
                    boxShadow: _cardShadow,
                  ),
                  child: const Icon(Icons.more_horiz_rounded, color: _textDark),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ================= 4. UPDATE STATUS =================
  Widget _buildScreen4UpdateStatus() {
    final ord = _activeOrder;
    final currentStatus = ord['status'] as String;

    final statuses = [
      {'name': 'Placed', 'time': '18 May 2025, 10:32 AM', 'done': true},
      {
        'name': 'Confirmed',
        'time': 'Pending',
        'done': currentStatus != 'Placed',
      },
      {
        'name': 'Preparing',
        'time': 'Pending',
        'done': currentStatus == 'Ready' || currentStatus == 'Served',
      },
      {'name': 'Ready', 'time': 'Pending', 'done': currentStatus == 'Served'},
      {'name': 'Served', 'time': 'Pending', 'done': currentStatus == 'Served'},
    ];

    return SingleChildScrollView(
      key: const ValueKey('Screen4'),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _actionIconButton(
                Icons.arrow_back_rounded,
                () => setState(
                  () => _currentSubView = OrderFlowSubView.orderDetail,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Update Status',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: _textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _borderSoft),
              boxShadow: _cardShadow,
            ),
            child: Row(
              children: [
                Text(
                  ord['id'],
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(width: 8),
                const Text('•', style: TextStyle(color: _textMuted)),
                const SizedBox(width: 8),
                Text(
                  ord['customer'],
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 8),
                const Text('•', style: TextStyle(color: _textMuted)),
                const SizedBox(width: 8),
                Text(ord['table'], style: const TextStyle(color: _textMuted)),
              ],
            ),
          ),
          const SizedBox(height: 28),

          ...statuses.asMap().entries.map((entry) {
            final idx = entry.key;
            final item = entry.value;
            final isDone = item['done'] as bool;
            final isLast = idx == statuses.length - 1;

            return IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    children: [
                      Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isDone
                              ? const Color(0xFF2563EB)
                              : Colors.white,
                          border: Border.all(
                            color: isDone
                                ? const Color(0xFF2563EB)
                                : _borderSoft,
                            width: 2,
                          ),
                        ),
                        child: isDone
                            ? const Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 16,
                              )
                            : null,
                      ),
                      if (!isLast)
                        Expanded(
                          child: Container(
                            width: 2,
                            color: isDone
                                ? const Color(0xFF2563EB)
                                : const Color(0xFFE2E8F0),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 28),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['name'] as String,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                              color: isDone ? _textDark : _textMuted,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item['time'] as String,
                            style: const TextStyle(
                              fontSize: 13,
                              color: _textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),

          const SizedBox(height: 20),

          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFF2563EB),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2563EB).withValues(alpha: 0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Next Step',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getNextStepTitle(currentStatus),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    shape: const CircleBorder(),
                    padding: const EdgeInsets.all(16),
                    backgroundColor: Colors.white,
                  ),
                  onPressed: () {
                    setState(() {
                      ord['status'] = _getNextStatus(currentStatus);
                    });
                    _showToast('Order status updated!');
                  },
                  child: const Icon(
                    Icons.arrow_forward_rounded,
                    color: Color(0xFF2563EB),
                    size: 22,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getNextStepTitle(String st) {
    if (st == 'Placed') return 'Confirm Order';
    if (st == 'Confirmed') return 'Start Preparing';
    if (st == 'Preparing') return 'Mark as Ready';
    if (st == 'Ready') return 'Mark as Served';
    return 'Completed';
  }

  String _getNextStatus(String st) {
    if (st == 'Placed') return 'Confirmed';
    if (st == 'Confirmed') return 'Preparing';
    if (st == 'Preparing') return 'Ready';
    if (st == 'Ready') return 'Served';
    return 'Served';
  }

  // ================= 5. DINE-IN ORDER DETAIL =================
  Widget _buildScreen5DineInDetail() {
    final ord = _activeOrder;
    final items = ord['items'] as List<dynamic>;

    return SingleChildScrollView(
      key: const ValueKey('Screen5'),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _actionIconButton(
                Icons.arrow_back_rounded,
                () =>
                    setState(() => _currentSubView = OrderFlowSubView.liveList),
              ),
              const SizedBox(width: 12),
              const Text(
                'Dine-in Order Detail',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: _textDark,
                ),
              ),
              const Spacer(),
              _actionIconButton(
                Icons.print_outlined,
                () => _showToast('Printing KOT...'),
              ),
            ],
          ),
          const SizedBox(height: 18),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ord['id'],
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 20,
                    ),
                  ),
                  Text(
                    ord['fullTime'] ?? '18 May 2025, 10:28 AM',
                    style: const TextStyle(color: _textMuted, fontSize: 12),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: _getStatusBg('Ready'),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Ready',
                  style: TextStyle(
                    color: _getStatusText('Ready'),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _borderSoft),
              boxShadow: _cardShadow,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      const Text(
                        'Table',
                        style: TextStyle(color: _textMuted, fontSize: 11),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        ord['table'],
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(
                  height: 28,
                  child: VerticalDivider(color: _borderSoft),
                ),
                Expanded(
                  child: Column(
                    children: [
                      const Text(
                        'Guests',
                        style: TextStyle(color: _textMuted, fontSize: 11),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${ord['guests']}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(
                  height: 28,
                  child: VerticalDivider(color: _borderSoft),
                ),
                Expanded(
                  child: Column(
                    children: [
                      const Text(
                        'Waiter',
                        style: TextStyle(color: _textMuted, fontSize: 11),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        ord['waiter'] ?? 'Rakesh',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          const Text(
            'Items',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: _borderSoft),
              boxShadow: _cardShadow,
            ),
            child: Column(
              children: items.map((it) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Text(
                        '${it['qty']}x',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          it['name'],
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      Text(
                        '₹ ${it['price']}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: _borderSoft),
              boxShadow: _cardShadow,
            ),
            child: Column(
              children: [
                _summaryRow('Subtotal (6 items)', '₹ 1,520'),
                const SizedBox(height: 6),
                _summaryRow('Taxes & Charges', '₹ 137'),
                const Divider(height: 24),
                _summaryRow('Total', '₹ 1,657', isBold: true),
              ],
            ),
          ),
          const SizedBox(height: 24),

          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(color: _orange),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () => _showToast('Bill requested'),
                  child: const Text(
                    'Request Bill',
                    style: TextStyle(
                      color: _orange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: _orange,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () => _showToast('Printing KOT...'),
                  child: const Text(
                    'Print KOT',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.more_horiz_rounded),
                onPressed: () => _showOrderActionsSheet(ord),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ================= 6. TAKEAWAY / DELIVERY ORDER DETAIL =================
  Widget _buildScreen6DeliveryDetail() {
    final ord = _activeOrder;

    return SingleChildScrollView(
      key: const ValueKey('Screen6'),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _actionIconButton(
                Icons.arrow_back_rounded,
                () =>
                    setState(() => _currentSubView = OrderFlowSubView.liveList),
              ),
              const SizedBox(width: 12),
              const Text(
                'Delivery Order Detail',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: _textDark,
                ),
              ),
              const Spacer(),
              _actionIconButton(
                Icons.phone_outlined,
                () => _showToast('Calling customer...'),
              ),
            ],
          ),
          const SizedBox(height: 18),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                ord['id'] ?? '#RH-10041',
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 20,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: _getStatusBg('Preparing'),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Preparing',
                  style: TextStyle(
                    color: _getStatusText('Preparing'),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: _borderSoft),
              boxShadow: _cardShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const CircleAvatar(
                      radius: 20,
                      backgroundColor: Color(0xFFE8EDF3),
                      child: Icon(
                        Icons.person_outline_rounded,
                        color: _textDark,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ord['customer'] ?? 'Vikram Singh',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        Text(
                          ord['phone'] ?? '98765 43210',
                          style: const TextStyle(
                            color: _textMuted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(
                        Icons.phone_rounded,
                        color: _orange,
                        size: 22,
                      ),
                      onPressed: () {},
                    ),
                  ],
                ),
                const Divider(height: 24),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      color: _textMuted,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        ord['address'] ?? '12, Green Park, New Delhi - 110016',
                        style: const TextStyle(
                          fontSize: 13,
                          color: _textDark,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Payment Method',
                      style: TextStyle(color: _textMuted, fontSize: 12),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Paid (Online UPI)',
                        style: TextStyle(
                          color: Color(0xFF166534),
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _borderSoft),
              boxShadow: _cardShadow,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text(
                  '5 Items',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                Text(
                  '₹ 650 >',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          const Text(
            'Order Timeline',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          const SizedBox(height: 14),
          _timelineStep('Placed', '10:21 AM', isDone: true),
          _timelineStep('Confirmed', '10:22 AM', isDone: true),
          _timelineStep('Preparing', '10:23 AM', isActive: true),
          _timelineStep('Out for Delivery', 'Pending', isPending: true),
          _timelineStep('Delivered', 'Pending', isPending: true, isLast: true),
        ],
      ),
    );
  }

  Widget _timelineStep(
    String title,
    String time, {
    bool isDone = false,
    bool isActive = false,
    bool isPending = false,
    bool isLast = false,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDone
                      ? const Color(0xFF2563EB)
                      : (isActive ? _orange : Colors.white),
                  border: Border.all(
                    color: isDone
                        ? const Color(0xFF2563EB)
                        : (isActive ? _orange : _borderSoft),
                    width: 2,
                  ),
                ),
                child: isDone
                    ? const Icon(Icons.check, size: 12, color: Colors.white)
                    : null,
              ),
              if (!isLast)
                Expanded(
                  child: Container(width: 2, color: const Color(0xFFE2E8F0)),
                ),
            ],
          ),
          const SizedBox(width: 14),
          Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Row(
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: isPending ? _textMuted : _textDark,
                  ),
                ),
                const SizedBox(width: 14),
                Text(
                  time,
                  style: const TextStyle(color: _textMuted, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ================= 7. SEARCH & FILTERS MODAL =================
  void _showFiltersModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        String filterStatus = 'All';
        String filterOrderType = 'All';
        String filterPayment = 'All';
        bool highPriority = false;

        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                24,
                24,
                24,
                MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Filters',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: _textDark,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          setModalState(() {
                            filterStatus = 'All';
                            filterOrderType = 'All';
                            filterPayment = 'All';
                            highPriority = false;
                          });
                        },
                        child: const Text(
                          'Reset',
                          style: TextStyle(
                            color: _orange,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  const Text(
                    'Status',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: filterStatus,
                    decoration: InputDecoration(
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    items: ['All', 'Placed', 'Preparing', 'Ready', 'Served']
                        .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                        .toList(),
                    onChanged: (v) =>
                        setModalState(() => filterStatus = v ?? 'All'),
                  ),
                  const SizedBox(height: 16),

                  const Text(
                    'Order Type',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: filterOrderType,
                    decoration: InputDecoration(
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    items: ['All', 'Dine-in', 'Takeaway', 'Delivery']
                        .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                        .toList(),
                    onChanged: (v) =>
                        setModalState(() => filterOrderType = v ?? 'All'),
                  ),
                  const SizedBox(height: 16),

                  const Text(
                    'Payment Status',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: filterPayment,
                    decoration: InputDecoration(
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    items: ['All', 'Paid', 'Pending', 'Failed']
                        .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                        .toList(),
                    onChanged: (v) =>
                        setModalState(() => filterPayment = v ?? 'All'),
                  ),
                  const SizedBox(height: 16),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'High Priority Orders',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                      Switch(
                        value: highPriority,
                        activeThumbColor: _orange,
                        onChanged: (val) =>
                            setModalState(() => highPriority = val),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            side: const BorderSide(color: _borderSoft),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text(
                            'Clear All',
                            style: TextStyle(
                              color: _textDark,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: _orange,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () {
                            Navigator.pop(ctx);
                            _showToast('Filters applied!');
                          },
                          child: const Text(
                            'Apply Filters',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ================= 8. COMPLETED ORDERS =================
  Widget _buildScreen8CompletedOrders() {
    return SingleChildScrollView(
      key: const ValueKey('Screen8'),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _actionIconButton(
                Icons.arrow_back_rounded,
                () =>
                    setState(() => _currentSubView = OrderFlowSubView.overview),
              ),
              const SizedBox(width: 12),
              const Text(
                'Completed Orders',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: _textDark,
                ),
              ),
              const Spacer(),
              _actionIconButton(Icons.tune_rounded, _showFiltersModal),
            ],
          ),
          const SizedBox(height: 16),

          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: ['All', 'Today', 'Yesterday', 'This Week', 'Custom']
                  .map((t) {
                    final isSel = _historyFilter == t;
                    return Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: ChoiceChip(
                        label: Text(t),
                        selected: isSel,
                        selectedColor: _orange,
                        backgroundColor: Colors.white,
                        side: BorderSide(color: isSel ? _orange : _borderSoft),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        labelStyle: TextStyle(
                          color: isSel ? Colors.white : _textMuted,
                          fontWeight: isSel ? FontWeight.w800 : FontWeight.w600,
                          fontSize: 12,
                        ),
                        onSelected: (val) => setState(() => _historyFilter = t),
                      ),
                    );
                  })
                  .toList(),
            ),
          ),
          const SizedBox(height: 20),

          ..._sampleOrders.take(3).map((ord) {
            return Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: _borderSoft),
                boxShadow: _cardShadow,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        ord['id'],
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        ord['fullTime'] ?? '18 May, 09:45 AM',
                        style: const TextStyle(color: _textMuted, fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        ord['customer'],
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        '₹ ${ord['amount']}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '${ord['table']} • ${ord['itemsCount']} items',
                        style: const TextStyle(color: _textMuted, fontSize: 13),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8EDF3),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Served',
                          style: TextStyle(
                            color: Color(0xFF475569),
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _historyAction(
                        Icons.receipt_long_outlined,
                        'Invoice',
                        () => _showToast('Generating invoice...'),
                      ),
                      _historyAction(
                        Icons.refresh_rounded,
                        'Reorder',
                        () => _showToast('Order duplicated!'),
                      ),
                      _historyAction(
                        Icons.visibility_outlined,
                        'View',
                        () => _navigateToDetail(ord),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _historyAction(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, size: 18, color: _textMuted),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: _textDark,
            ),
          ),
        ],
      ),
    );
  }

  // ================= 9. ORDER ACTIONS SHEET =================
  void _showOrderActionsSheet(Map<String, dynamic> ord) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Order Actions',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: _textDark,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${ord['id']} • ${ord['customer']} • ${ord['table']}',
                style: const TextStyle(color: _textMuted, fontSize: 13),
              ),
              const SizedBox(height: 20),
              _actionListTile(
                Icons.print_outlined,
                'Print KOT',
                () => _closeAndToast(ctx, 'KOT Printed'),
              ),
              _actionListTile(
                Icons.receipt_long_outlined,
                'Reprint Invoice',
                () => _closeAndToast(ctx, 'Invoice Printed'),
              ),
              _actionListTile(
                Icons.cancel_outlined,
                'Cancel Order',
                () => _closeAndToast(ctx, 'Order Cancelled'),
                isRed: true,
              ),
              _actionListTile(
                Icons.currency_exchange_rounded,
                'Refund Request',
                () => _closeAndToast(ctx, 'Refund requested'),
              ),
              _actionListTile(
                Icons.two_wheeler_rounded,
                'Assign Delivery',
                () => _closeAndToast(ctx, 'Assigned delivery boy'),
              ),
              _actionListTile(
                Icons.phone_outlined,
                'Contact Customer',
                () => _closeAndToast(ctx, 'Calling customer'),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _actionListTile(
    IconData icon,
    String title,
    VoidCallback onTap, {
    bool isRed = false,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: isRed ? Colors.red : _textDark, size: 22),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 15,
          color: isRed ? Colors.red : _textDark,
        ),
      ),
      trailing: const Icon(
        Icons.chevron_right_rounded,
        color: _textMuted,
        size: 22,
      ),
      onTap: onTap,
    );
  }

  void _closeAndToast(BuildContext ctx, String msg) {
    Navigator.pop(ctx);
    _showToast(msg);
  }

  Widget _summaryRow(String label, String val, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: isBold ? _textDark : _textMuted,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            fontSize: isBold ? 15 : 13,
          ),
        ),
        Text(
          val,
          style: TextStyle(
            color: _textDark,
            fontWeight: isBold ? FontWeight.w900 : FontWeight.bold,
            fontSize: isBold ? 17 : 14,
          ),
        ),
      ],
    );
  }

  void _showToast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        duration: const Duration(seconds: 2),
        backgroundColor: _textDark,
      ),
    );
  }
}
