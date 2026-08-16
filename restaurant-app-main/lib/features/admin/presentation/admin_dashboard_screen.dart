import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/network/restaurant_api.dart';
import '../../../core/storage/local_storage.dart';
import 'admin_operations_panel.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});
  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int selected = 0;
  late final String role;
  late Future<List<List<Map<String, dynamic>>>> data;
  List<Map<String, dynamic>> branches = const [];
  String? branchId;
  bool branchesLoading = true;
  static const items = <(IconData, String)>[
    (Icons.dashboard_rounded, 'Dashboard'),
    (Icons.receipt_long_rounded, 'Orders'),
    (Icons.restaurant_menu_rounded, 'Menu'),
    (Icons.table_restaurant_rounded, 'Tables'),
    (Icons.soup_kitchen_rounded, 'Kitchen'),
    (Icons.point_of_sale_rounded, 'POS'),
    (Icons.room_service_rounded, 'Waiter'),
    (Icons.inventory_2_rounded, 'Inventory'),
    (Icons.groups_rounded, 'Staff'),
    (Icons.schedule_rounded, 'Attendance'),
    (Icons.analytics_rounded, 'Reports'),
    (Icons.settings_rounded, 'Settings'),
  ];
  @override
  void initState() {
    super.initState();
    role = LocalStorage.getRole() ?? '';
    selected = _allowedPages(role).first;
    final profile = LocalStorage.getCustomerProfile() ?? const {};
    final storedBranch = '${profile['branchId'] ?? ''}'.trim();
    branchId = storedBranch.isEmpty ? null : storedBranch;
    data = _load();
    if ({
      'Admin',
      'Restaurant Admin',
      'Manager',
      'Super Admin',
    }.contains(role)) {
      _loadBranches();
    } else {
      branchesLoading = false;
    }
  }

  List<int> _allowedPages(String value) => switch (value) {
    'Kitchen' => const [4, 7],
    'Waiter' => const [1, 6],
    'Cashier' => const [1, 5],
    'Admin' ||
    'Restaurant Admin' ||
    'Manager' ||
    'Super Admin' => List<int>.generate(items.length, (index) => index),
    _ => const [0],
  };
  Future<List<List<Map<String, dynamic>>>> _load() => Future.wait([
    RestaurantApi.getOrders(branchId: branchId),
    RestaurantApi.getMenuItems(branchId: branchId),
    RestaurantApi.getTables(branchId: branchId),
  ]);

  Future<void> _loadBranches() async {
    final profile = LocalStorage.getCustomerProfile() ?? const {};
    final restaurantId = '${profile['restaurantId'] ?? ''}'.trim();
    if (restaurantId.isEmpty) {
      if (mounted) setState(() => branchesLoading = false);
      return;
    }
    try {
      final records = await RestaurantApi.getBranches(restaurantId);
      if (!mounted) return;
      final ids = records.map((branch) => '${branch['_id']}').toSet();
      final nextBranch = branchId != null && ids.contains(branchId)
          ? branchId
          : records.isEmpty
          ? null
          : '${records.first['_id']}';
      setState(() {
        branches = records;
        branchesLoading = false;
        branchId = nextBranch;
        data = _load();
      });
      if (nextBranch != null) {
        await LocalStorage.saveCustomerProfile({
          ...profile,
          'branchId': nextBranch,
        });
      }
    } catch (_) {
      if (mounted) setState(() => branchesLoading = false);
    }
  }

  Future<void> _selectBranch(String? value) async {
    if (value == null || value == branchId) return;
    final profile = LocalStorage.getCustomerProfile() ?? const {};
    await LocalStorage.saveCustomerProfile({...profile, 'branchId': value});
    if (!mounted) return;
    setState(() {
      branchId = value;
      data = _load();
    });
  }

  Widget _branchSelector() => Container(
    constraints: const BoxConstraints(maxWidth: 180),
    padding: const EdgeInsets.symmetric(horizontal: 10),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFFECE2D9)),
    ),
    child: DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: branchId,
        isExpanded: true,
        icon: const Icon(Icons.keyboard_arrow_down),
        items: branches
            .map(
              (branch) => DropdownMenuItem(
                value: '${branch['_id']}',
                child: Text(
                  '${branch['name'] ?? 'Branch'}',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            )
            .toList(),
        onChanged: _selectBranch,
      ),
    ),
  );
  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 900;
    return Scaffold(
      backgroundColor: const Color(0xFFF8F5F0),
      drawer: wide ? null : Drawer(child: SafeArea(child: _nav(true))),
      body: Row(
        children: [
          if (wide) SizedBox(width: 248, child: _nav(false)),
          Expanded(child: _body(wide)),
        ],
      ),
    );
  }

  Widget _nav(bool drawer) => ColoredBox(
    color: const Color(0xFF241711),
    child: Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(22),
          child: Row(
            children: [
              const CircleAvatar(
                backgroundColor: Color(0xFFD66A2C),
                child: Icon(Icons.restaurant, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Text(
                'Mehmaan',
                style: GoogleFonts.playfairDisplay(
                  color: Colors.white,
                  fontSize: 21,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            itemCount: _allowedPages(role).length,
            itemBuilder: (_, i) {
              final page = _allowedPages(role)[i];
              return ListTile(
                selected: selected == page,
                selectedTileColor: const Color(0xFFD66A2C),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                leading: Icon(items[page].$1, color: Colors.white70),
                title: Text(
                  items[page].$2,
                  style: GoogleFonts.dmSans(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onTap: () {
                  setState(() => selected = page);
                  if (drawer) Navigator.pop(context);
                },
              );
            },
          ),
        ),
      ],
    ),
  );
  Widget _body(bool wide) => CustomScrollView(
    slivers: [
      SliverAppBar(
        pinned: true,
        backgroundColor: const Color(0xFFF8F5F0),
        surfaceTintColor: Colors.transparent,
        title: Text(
          items[selected].$2,
          style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.w700),
        ),
        actions: [
          if (branchesLoading)
            const Padding(
              padding: EdgeInsets.all(14),
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else if (branches.isNotEmpty && wide)
            _branchSelector(),
          if (!wide && branches.isNotEmpty)
            PopupMenuButton<String>(
              tooltip: 'Select branch',
              icon: const Icon(Icons.store_mall_directory_outlined),
              initialValue: branchId,
              onSelected: _selectBranch,
              itemBuilder: (_) => branches
                  .map(
                    (branch) =>
                        PopupMenuItem<String>(value: '', child: Text('')),
                  )
                  .toList(),
            ),
          IconButton(
            onPressed: () => setState(() => data = _load()),
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            tooltip: 'Sign out',
            onPressed: () async {
              await LocalStorage.clearToken();
              if (!mounted) return;
              context.go('/admin/login');
            },
            icon: const Icon(Icons.logout_rounded),
          ),
          const SizedBox(width: 10),
        ],
      ),
      SliverPadding(
        padding: EdgeInsets.all(wide ? 28 : 18),
        sliver: SliverToBoxAdapter(
          child: selected == 0
              ? _dashboard()
              : selected <= 11
              ? AdminOperationsPanel(
                  page: selected,
                  data: data,
                  reload: () => setState(() => data = _load()),
                  branchId: branchId,
                )
              : const SizedBox.shrink(),
        ),
      ),
    ],
  );
  Widget _dashboard() => FutureBuilder<List<List<Map<String, dynamic>>>>(
    future: data,
    builder: (_, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(
          child: Padding(
            padding: EdgeInsets.all(50),
            child: CircularProgressIndicator(),
          ),
        );
      }
      if (snapshot.hasError) {
        return Center(child: Text(RestaurantApi.messageFor(snapshot.error!)));
      }
      final orders = snapshot.data![0];
      final menu = snapshot.data![1];
      final tables = snapshot.data![2];
      final allPaid = orders
          .where((order) => order['paymentStatus'] == 'Paid')
          .toList();
      final now = DateTime.now();
      final paid = allPaid.where((order) {
        final createdAt = DateTime.tryParse('${order['createdAt'] ?? ''}');
        return createdAt != null &&
            createdAt.year == now.year &&
            createdAt.month == now.month &&
            createdAt.day == now.day;
      }).toList();
      final unpaid = orders
          .where(
            (order) =>
                order['paymentStatus'] != 'Paid' &&
                order['status'] != 'Cancelled',
          )
          .toList();
      final active = orders
          .where((order) => !['Paid', 'Cancelled'].contains(order['status']))
          .length;
      final occupied = tables
          .where((table) => table['status'] == 'Occupied')
          .length;
      final sales = paid.fold<double>(
        0,
        (sum, order) => sum + (order['total'] as num? ?? 0).toDouble(),
      );
      final dishSales = <String, int>{};
      final customerVisits = <String, Map<String, dynamic>>{};
      for (final order in allPaid) {
        final phone = '${order['customerPhone'] ?? ''}'.trim();
        if (phone.isNotEmpty) {
          final customer = customerVisits.putIfAbsent(
            phone,
            () => {
              'name': order['customerName'] ?? 'Guest',
              'visits': 0,
              'spend': 0.0,
            },
          );
          customer['visits'] = (customer['visits'] as int) + 1;
          customer['spend'] =
              (customer['spend'] as double) +
              (order['total'] as num? ?? 0).toDouble();
        }
        for (final raw in (order['items'] as List? ?? const [])) {
          if (raw is! Map) continue;
          final item = Map<String, dynamic>.from(raw);
          final menuItem = item['menuItem'];
          final name = menuItem is Map
              ? '${menuItem['name'] ?? 'Menu item'}'
              : '${item['name'] ?? 'Menu item'}';
          dishSales[name] =
              (dishSales[name] ?? 0) + (item['quantity'] as num? ?? 0).toInt();
        }
      }
      final rankedDishes = dishSales.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      final menuNames = menu
          .map((item) => '${item['name'] ?? 'Menu item'}')
          .toList();
      final lowSelling = menuNames
        ..sort((a, b) => (dishSales[a] ?? 0).compareTo(dishSales[b] ?? 0));
      final regulars =
          customerVisits.values
              .where((customer) => (customer['visits'] as int) > 1)
              .toList()
            ..sort(
              (a, b) => (b['visits'] as int).compareTo(a['visits'] as int),
            );
      final cleaning = tables
          .where((table) => table['status'] == 'Cleaning')
          .length;
      final unavailable = menu
          .where((item) => item['isAvailable'] == false)
          .length;
      final pending = orders
          .where((order) => order['status'] == 'Pending')
          .length;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Good hospitality starts with a clear view.',
            style: GoogleFonts.dmSans(color: const Color(0xFF806E64)),
          ),
          const SizedBox(height: 22),
          Wrap(
            spacing: 14,
            runSpacing: 14,
            children: [
              _metric(
                "Today's sales",
                'Rs ${sales.toStringAsFixed(0)}',
                Icons.currency_rupee,
              ),
              _metric('Active orders', '$active', Icons.receipt_long),
              _metric(
                'Occupied tables',
                '$occupied/${tables.length}',
                Icons.table_restaurant,
              ),
              _metric(
                'Average bill',
                paid.isEmpty
                    ? 'Rs 0'
                    : 'Rs ${(sales / paid.length).toStringAsFixed(0)}',
                Icons.payments_outlined,
              ),
            ],
          ),
          const SizedBox(height: 22),
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth >= 850
                  ? (constraints.maxWidth - 16) / 2
                  : constraints.maxWidth;
              return Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  _insightCard(
                    'Top selling dishes',
                    Icons.trending_up,
                    width,
                    rankedDishes
                        .take(5)
                        .map((dish) => '${dish.key}  ·  ${dish.value} sold')
                        .toList(),
                  ),
                  _insightCard(
                    'Low selling dishes',
                    Icons.trending_down,
                    width,
                    lowSelling
                        .take(5)
                        .map((name) => '$name  ·  ${dishSales[name] ?? 0} sold')
                        .toList(),
                  ),
                  _insightCard(
                    'Repeat customers',
                    Icons.groups_outlined,
                    width,
                    regulars
                        .take(5)
                        .map(
                          (customer) =>
                              '${customer['name']}  ·  ${customer['visits']} visits',
                        )
                        .toList(),
                  ),
                  _insightCard(
                    'Payment summary (today)',
                    Icons.account_balance_wallet_outlined,
                    width,
                    [
                      'Paid orders  ·  ${paid.length}',
                      'Awaiting payment  ·  ${unpaid.length}',
                      'Paid revenue  ·  Rs ${sales.toStringAsFixed(0)}',
                    ],
                  ),
                  _insightCard(
                    'Needs attention',
                    Icons.notifications_active_outlined,
                    width,
                    [
                      'Pending orders  ·  $pending',
                      'Tables cleaning  ·  $cleaning',
                      'Unavailable items  ·  $unavailable',
                    ],
                  ),
                ],
              );
            },
          ),
        ],
      );
    },
  );

  Widget _insightCard(
    String title,
    IconData icon,
    double width,
    List<String> rows,
  ) => Container(
    width: width,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: const Color(0xFFECE2D9)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: const Color(0xFFD66A2C)),
            const SizedBox(width: 10),
            Text(
              title,
              style: GoogleFonts.playfairDisplay(
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        if (rows.isEmpty)
          Text(
            'No data yet.',
            style: GoogleFonts.dmSans(color: const Color(0xFF806E64)),
          )
        else
          ...rows.map(
            (row) => Padding(
              padding: const EdgeInsets.only(bottom: 9),
              child: Text(row, style: GoogleFonts.dmSans()),
            ),
          ),
      ],
    ),
  );
  Widget _metric(String label, String value, IconData icon) => Container(
    width: 220,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: const Color(0xFFECE2D9)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          backgroundColor: const Color(0xFFFFE7D6),
          child: Icon(icon, color: const Color(0xFFD66A2C)),
        ),
        const SizedBox(height: 16),
        Text(
          value,
          style: GoogleFonts.playfairDisplay(
            fontSize: 28,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(label, style: GoogleFonts.dmSans(color: const Color(0xFF806E64))),
      ],
    ),
  );
}
