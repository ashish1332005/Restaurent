import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/network/restaurant_api.dart';
import '../../../core/storage/local_storage.dart';
import '../../../core/theme/hospitality_theme.dart';
import '../../../core/theme/royal_admin_ui.dart';
import 'admin_operations_panel.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});
  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final scaffoldKey = GlobalKey<ScaffoldState>();
  int selected = 0;
  late final String role;
  late Future<List<List<Map<String, dynamic>>>> data;
  List<Map<String, dynamic>> branches = const [];
  String? branchId;
  bool branchesLoading = true;
  // Every admin page shares the same brand-level top bar.
  // Only operational pages add a larger royal hero below it.
  bool get _usesRoyalTopBar => true;
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
      border: Border.all(color: const Color(0xFFE6DED2)),
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
  Widget _royalBranchPicker() => PopupMenuButton<String>(
    tooltip: 'Select branch',
    initialValue: branchId,
    onSelected: _selectBranch,
    itemBuilder: (_) => branches
        .map(
          (branch) => PopupMenuItem<String>(
            value: (branch['_id'] ?? '').toString(),
            child: Text(branch['name']?.toString() ?? 'Main branch'),
          ),
        )
        .toList(),
    child: Container(
      constraints: const BoxConstraints(maxWidth: 190),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        border: Border.all(color: RoyalAdminColors.gold.withValues(alpha: .55)),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.account_balance_outlined,
            color: RoyalAdminColors.goldLight,
            size: 19,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              branches
                      .where(
                        (branch) =>
                            (branch['_id'] ?? '').toString() == branchId,
                      )
                      .map(
                        (branch) => branch['name']?.toString() ?? 'Main branch',
                      )
                      .firstOrNull ??
                  'Main branch',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 4),
          const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: RoyalAdminColors.goldLight,
            size: 18,
          ),
        ],
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 1050;
    return Scaffold(
      key: scaffoldKey,
      backgroundColor: HospitalityColors.canvas,
      drawer: wide ? null : Drawer(child: SafeArea(child: _nav(true))),
      bottomNavigationBar: wide ? null : _mobileNavigation(),
      body: Row(
        children: [
          if (wide) SizedBox(width: 224, child: _nav(false)),
          Expanded(child: _body(wide)),
        ],
      ),
    );
  }

  Widget _nav(bool drawer) => ColoredBox(
    color: HospitalityColors.ink,
    child: Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
          child: Row(
            children: [
              const CircleAvatar(
                backgroundColor: HospitalityColors.saffron,
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
                selectedTileColor: RoyalAdminColors.navySoft,
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
  Widget _mobileNavigation() {
    final allowed = _allowedPages(role);
    final primary = allowed.length <= 4
        ? allowed
        : allowed.where((page) => page <= 3).toList();
    final showMore = allowed.length > primary.length;
    final selectedIndex = primary.contains(selected)
        ? primary.indexOf(selected)
        : primary.length;
    return NavigationBar(
      height: 66,
      selectedIndex: selectedIndex,
      onDestinationSelected: (value) {
        if (value < primary.length) {
          setState(() => selected = primary[value]);
        } else {
          scaffoldKey.currentState?.openDrawer();
        }
      },
      destinations: [
        ...primary.map(
          (page) => NavigationDestination(
            icon: Icon(items[page].$1),
            selectedIcon: Icon(items[page].$1),
            label: items[page].$2,
          ),
        ),
        if (showMore)
          const NavigationDestination(
            icon: Icon(Icons.grid_view_rounded),
            label: 'More',
          ),
      ],
    );
  }

  Widget _body(bool wide) => CustomScrollView(
    slivers: [
      SliverAppBar(
        pinned: true,
        toolbarHeight: 62,
        backgroundColor: _usesRoyalTopBar
            ? RoyalAdminColors.navy
            : HospitalityColors.canvas,
        foregroundColor: _usesRoyalTopBar
            ? Colors.white
            : HospitalityColors.ink,
        surfaceTintColor: Colors.transparent,
        title: selected == 0 && branches.isNotEmpty
            ? _royalBranchPicker()
            : Text(
                items[selected].$2,
                style: GoogleFonts.dmSans(
                  color: _usesRoyalTopBar
                      ? Colors.white
                      : HospitalityColors.ink,
                  fontWeight: FontWeight.w700,
                ),
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
          else if (branches.isNotEmpty && wide && selected != 0)
            _branchSelector(),
          if (!wide && branches.isNotEmpty && selected != 0)
            PopupMenuButton<String>(
              tooltip: 'Select branch',
              icon: const Icon(Icons.store_mall_directory_outlined),
              initialValue: branchId,
              onSelected: _selectBranch,
              itemBuilder: (_) => branches
                  .map(
                    (branch) => PopupMenuItem<String>(
                      value: (branch['_id'] ?? '').toString(),
                      child: Text((branch['name'] ?? 'Branch').toString()),
                    ),
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
        padding: selected == 0 || selected == 1 || selected == 3
            ? EdgeInsets.zero
            : EdgeInsets.all(wide ? 28 : 18),
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
      final ready = orders.where((order) => order['status'] == 'Ready').length;
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
              'favorites': <String, int>{},
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
          if (phone.isNotEmpty) {
            final favourites =
                customerVisits[phone]!['favorites'] as Map<String, int>;
            favourites[name] =
                (favourites[name] ?? 0) +
                (item['quantity'] as num? ?? 0).toInt();
          }
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
          _royalDashboardHeader(active: active, now: now),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 0),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final columns = constraints.maxWidth >= 390 ? 4 : 2;
                    final gap = 10.0;
                    final width =
                        (constraints.maxWidth - gap * (columns - 1)) / columns;
                    return Wrap(
                      spacing: gap,
                      runSpacing: gap,
                      children: [
                        SizedBox(
                          width: width,
                          child: RoyalMetricCard(
                            icon: Icons.currency_rupee_rounded,
                            iconColor: const Color(0xFF21854A),
                            label:
                                'Today'
                                's sales',
                            value: 'Rs ${sales.toStringAsFixed(0)}',
                            detail: 'Paid today',
                          ),
                        ),
                        SizedBox(
                          width: width,
                          child: RoyalMetricCard(
                            icon: Icons.shopping_bag_outlined,
                            iconColor: const Color(0xFF245DE8),
                            label: 'Active orders',
                            value: '$active',
                            detail: '$pending new',
                          ),
                        ),
                        SizedBox(
                          width: width,
                          child: RoyalMetricCard(
                            icon: Icons.table_restaurant_outlined,
                            iconColor: const Color(0xFF7140C5),
                            label: 'Occupied tables',
                            value: '$occupied / ${tables.length}',
                            detail: 'Live dining',
                          ),
                        ),
                        SizedBox(
                          width: width,
                          child: RoyalMetricCard(
                            icon: Icons.receipt_long_outlined,
                            iconColor: const Color(0xFFD16B22),
                            label: 'Avg. bill value',
                            value: paid.isEmpty
                                ? 'Rs 0'
                                : 'Rs ${(sales / paid.length).toStringAsFixed(0)}',
                            detail: 'Today',
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 22),
                const RoyalSectionHeading(
                  title: 'Live overview',
                  actionLabel: 'View all',
                ),
                const SizedBox(height: 10),
                _royalGrid([
                  RoyalInsightTile(
                    icon: Icons.assignment_outlined,
                    color: const Color(0xFF1D9250),
                    title: 'Active orders',
                    value: '$active',
                  ),
                  RoyalInsightTile(
                    icon: Icons.room_service_outlined,
                    color: const Color(0xFF2764D9),
                    title: 'Ready orders',
                    value: '$ready',
                  ),
                  RoyalInsightTile(
                    icon: Icons.receipt_long_outlined,
                    color: const Color(0xFFD65031),
                    title: 'Unpaid orders',
                    value: '${unpaid.length}',
                  ),
                  RoyalInsightTile(
                    icon: Icons.soup_kitchen_outlined,
                    color: const Color(0xFF7140C5),
                    title: 'Kitchen pending',
                    value: '$pending',
                  ),
                ]),
                const SizedBox(height: 22),
                RoyalSectionHeading(
                  title: 'Insights',
                  actionLabel: 'This week',
                  onAction: () {},
                ),
                const SizedBox(height: 10),
                _royalGrid([
                  RoyalInsightTile(
                    icon: Icons.workspace_premium_outlined,
                    color: const Color(0xFF5D9E30),
                    title: 'Top selling dishes',
                    value: '${rankedDishes.length} tracked',
                  ),
                  RoyalInsightTile(
                    icon: Icons.trending_down_rounded,
                    color: const Color(0xFFD66A2C),
                    title: 'Low selling dishes',
                    value: '${lowSelling.length} tracked',
                  ),
                  RoyalInsightTile(
                    icon: Icons.groups_outlined,
                    color: const Color(0xFF2378D4),
                    title: 'Repeat customers',
                    value: '${regulars.length} guests',
                  ),
                  RoyalInsightTile(
                    icon: Icons.favorite_border_rounded,
                    color: const Color(0xFFE64D75),
                    title: 'Favourite dishes',
                    value: '${dishSales.length} dishes',
                  ),
                  RoyalInsightTile(
                    icon: Icons.account_balance_wallet_outlined,
                    color: const Color(0xFF6E43C1),
                    title: 'Paid vs pending',
                    value: '${paid.length} / ${unpaid.length}',
                  ),
                  RoyalInsightTile(
                    icon: Icons.pending_actions_outlined,
                    color: const Color(0xFF285DE5),
                    title: 'Pending orders',
                    value: '$pending',
                  ),
                  RoyalInsightTile(
                    icon: Icons.cleaning_services_outlined,
                    color: const Color(0xFF119A9C),
                    title: 'Cleaning tables',
                    value: '$cleaning',
                  ),
                  RoyalInsightTile(
                    icon: Icons.inventory_2_outlined,
                    color: const Color(0xFF6F7782),
                    title: 'Unavailable items',
                    value: '$unavailable',
                  ),
                ]),
                const SizedBox(height: 22),
                RoyalSectionHeading(
                  title: 'Top selling dishes',
                  actionLabel: 'Full report',
                  onAction: () => setState(() => selected = 10),
                ),
                const SizedBox(height: 10),
                RoyalAdminSurface(
                  child: rankedDishes.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: Text(
                            'Orders will reveal your top-selling dishes here.',
                          ),
                        )
                      : Column(
                          children: rankedDishes.take(3).toList().indexed.map((
                            entry,
                          ) {
                            final dish = entry.$2;
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: CircleAvatar(
                                backgroundColor: const Color(0xFFFFF0D3),
                                child: Text('${entry.$1 + 1}'),
                              ),
                              title: Text(
                                dish.key,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Text('${dish.value} orders'),
                              trailing: const Icon(
                                Icons.chevron_right_rounded,
                                color: RoyalAdminColors.gold,
                              ),
                            );
                          }).toList(),
                        ),
                ),
              ],
            ),
          ),
        ],
      );
    },
  );

  Widget _royalDashboardHeader({
    required int active,
    required DateTime now,
  }) => SizedBox(
    height: 212,
    width: double.infinity,
    child: DecoratedBox(
      decoration: const BoxDecoration(color: RoyalAdminColors.navy),
      child: Stack(
        children: [
          const Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(painter: _RoyalArchPainter()),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 60, 24, 18),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Namaste, Owner',
                        style: GoogleFonts.playfairDisplay(
                          color: RoyalAdminColors.goldLight,
                          fontSize: 23,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 5),
                      const Text(
                        'Here is what is happening at your\nrestaurant today.',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                      const Spacer(),
                      Text(
                        '$active active orders',
                        style: const TextStyle(
                          color: Color(0xFF9BE6B4),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  margin: const EdgeInsets.only(top: 22),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 11,
                  ),
                  decoration: BoxDecoration(
                    color: RoyalAdminColors.ivory,
                    border: Border.all(
                      color: RoyalAdminColors.gold.withValues(alpha: .65),
                    ),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.calendar_month_outlined,
                        color: RoyalAdminColors.gold,
                        size: 19,
                      ),
                      const SizedBox(width: 7),
                      Text(
                        '${now.day} ${_monthName(now.month)} ${now.year}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
  Widget _royalGrid(List<Widget> children) => LayoutBuilder(
    builder: (context, constraints) {
      final columns = constraints.maxWidth >= 900 ? 4 : 2;
      final gap = 10.0;
      final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
      return Wrap(
        spacing: gap,
        runSpacing: gap,
        children: children
            .map((child) => SizedBox(width: width, child: child))
            .toList(),
      );
    },
  );

  String _monthName(int month) => const [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ][month - 1];
  // ignore: unused_element
  Widget _insightCard(
    String title,
    String subtitle,
    IconData icon,
    double width,
    List<(String, String)> rows,
    Color accent,
  ) => Container(
    width: width,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: HospitalityColors.surface,
      borderRadius: BorderRadius.circular(HospitalityRadius.medium),
      border: Border.all(color: HospitalityColors.outline),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: .1),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(icon, color: accent, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        if (rows.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              'No data yet',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          )
        else
          ...rows.indexed.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: HospitalityColors.canvas,
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: Text(
                      '${entry.$1 + 1}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      entry.$2.$1,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      entry.$2.$2,
                      textAlign: TextAlign.right,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: accent),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    ),
  );

  // ignore: unused_element
  Widget _metric(
    String label,
    String value,
    IconData icon,
    double width,
    Color iconBackground,
    Color iconColor,
  ) => Container(
    width: width,
    constraints: const BoxConstraints(minHeight: 116),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: HospitalityColors.surface,
      borderRadius: BorderRadius.circular(HospitalityRadius.medium),
      border: Border.all(color: HospitalityColors.outline),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: iconBackground,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 19),
            ),
            const Spacer(),
            const Icon(
              Icons.north_east_rounded,
              size: 15,
              color: HospitalityColors.mutedInk,
            ),
          ],
        ),
        const SizedBox(height: 12),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(value, style: Theme.of(context).textTheme.headlineSmall),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    ),
  );
}

class _RoyalArchPainter extends CustomPainter {
  const _RoyalArchPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final gold = Paint()
      ..color = RoyalAdminColors.gold.withValues(alpha: .58)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    final faint = Paint()
      ..color = RoyalAdminColors.gold.withValues(alpha: .14)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final center = size.width / 2;
    final arch = Path()
      ..moveTo(16, 92)
      ..cubicTo(16, 28, center - 92, 48, center, 8)
      ..cubicTo(center + 92, 48, size.width - 16, 28, size.width - 16, 92);
    canvas.drawPath(arch, gold);
    canvas.drawLine(const Offset(16, 0), const Offset(16, 92), faint);
    canvas.drawLine(
      Offset(size.width - 16, 0),
      Offset(size.width - 16, 92),
      faint,
    );
    canvas.drawCircle(Offset(center, 34), 13, faint);
    canvas.drawCircle(const Offset(16, 92), 4, gold);
    canvas.drawCircle(Offset(size.width - 16, 92), 4, gold);
  }

  @override
  bool shouldRepaint(covariant _RoyalArchPainter oldDelegate) => false;
}
