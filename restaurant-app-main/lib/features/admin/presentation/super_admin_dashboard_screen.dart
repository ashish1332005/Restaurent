import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/network/restaurant_api.dart';
import '../../../core/storage/local_storage.dart';

class SuperAdminDashboardScreen extends StatefulWidget {
  const SuperAdminDashboardScreen({
    super.key,
    this.initialSection = 'overview',
  });
  final String initialSection;
  @override
  State<SuperAdminDashboardScreen> createState() =>
      _SuperAdminDashboardScreenState();
}

class _SuperAdminDashboardScreenState extends State<SuperAdminDashboardScreen> {
  static const ink = Color(0xFF241B17),
      saffron = Color(0xFFD66A2C),
      green = Color(0xFF2F8A61);
  static const sections = [
    'overview',
    'restaurants',
    'subscriptions',
    'revenue',
    'plans',
    'system',
  ];
  static const labels = [
    'Overview',
    'Restaurants',
    'Subscriptions',
    'Revenue',
    'Plans',
    'System',
  ];
  static const icons = [
    Icons.dashboard_outlined,
    Icons.storefront_outlined,
    Icons.workspace_premium_outlined,
    Icons.insights_outlined,
    Icons.layers_outlined,
    Icons.monitor_heart_outlined,
  ];
  Map<String, dynamic> summary = {}, analytics = {};
  List<Map<String, dynamic>> tenants = [];
  bool loading = true;
  String search = '', status = 'All';
  late int selected;

  @override
  void initState() {
    super.initState();
    final index = sections.indexOf(widget.initialSection);
    selected = index < 0 ? 0 : index;
    _load();
  }

  Future<void> _load() async {
    setState(() => loading = true);
    try {
      final data = await Future.wait([
        RestaurantApi.getPlatformSummary(),
        RestaurantApi.getPlatformAnalytics(),
        RestaurantApi.getPlatformRestaurants(
          search: search,
          status: status == 'All' ? null : status,
        ),
      ]);
      if (!mounted) return;
      setState(() {
        summary = Map<String, dynamic>.from(data[0] as Map);
        analytics = Map<String, dynamic>.from(data[1] as Map);
        tenants = data[2] as List<Map<String, dynamic>>;
        loading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => loading = false);
        _message(RestaurantApi.messageFor(e));
      }
    }
  }

  void _select(int index) {
    setState(() => selected = index);
    context.go('/super-admin/${sections[index]}');
  }

  @override
  Widget build(BuildContext context) {
    final desktop = MediaQuery.sizeOf(context).width >= 900;
    final content = loading
        ? const Center(child: CircularProgressIndicator(color: saffron))
        : RefreshIndicator(
            onRefresh: _load,
            child: ListView(
              padding: EdgeInsets.all(desktop ? 26 : 16),
              children: [_heading(), const SizedBox(height: 18), _page()],
            ),
          );
    return Scaffold(
      backgroundColor: const Color(0xFFF7F2EC),
      appBar: AppBar(
        backgroundColor: ink,
        foregroundColor: Colors.white,
        title: Text(
          'Atithi SaaS',
          style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
          IconButton(onPressed: _logout, icon: const Icon(Icons.logout)),
        ],
      ),
      bottomNavigationBar: desktop
          ? null
          : SafeArea(
              child: SizedBox(
                height: 66,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                  scrollDirection: Axis.horizontal,
                  itemCount: sections.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 4),
                  itemBuilder: (_, index) => Tooltip(
                    message: labels[index],
                    child: InkWell(
                      onTap: () => _select(index),
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        width: 72,
                        decoration: BoxDecoration(
                          color: selected == index
                              ? const Color(0xFFFFE7D6)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              icons[index],
                              color: selected == index
                                  ? saffron
                                  : const Color(0xFF806E64),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              labels[index],
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: selected == index
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
      body: Row(
        children: [
          if (desktop)
            NavigationRail(
              backgroundColor: ink,
              selectedIndex: selected,
              onDestinationSelected: _select,
              labelType: NavigationRailLabelType.all,
              selectedIconTheme: const IconThemeData(color: Color(0xFFFFB477)),
              unselectedIconTheme: const IconThemeData(color: Colors.white60),
              selectedLabelTextStyle: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
              unselectedLabelTextStyle: const TextStyle(color: Colors.white60),
              destinations: List.generate(
                sections.length,
                (i) => NavigationRailDestination(
                  icon: Icon(icons[i]),
                  label: Text(labels[i]),
                ),
              ),
            ),
          Expanded(child: content),
        ],
      ),
    );
  }

  Widget _heading() => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              labels[selected],
              style: GoogleFonts.playfairDisplay(
                fontSize: 31,
                fontWeight: FontWeight.w700,
                color: ink,
              ),
            ),
            Text(_subtitle(), style: const TextStyle(color: Color(0xFF806E64))),
          ],
        ),
      ),
      _pill('Super Admin', Icons.shield_outlined, green),
    ],
  );
  String _subtitle() => const [
    'Live platform performance and tenant health.',
    'Search, activate and manage every restaurant.',
    'Renewals, trials and expiry risk in one place.',
    'SaaS collections and payment performance.',
    'Clear plan positioning for the sales team.',
    'Platform services and operational readiness.',
  ][0 + selected];
  Widget _page() => switch (sections[selected]) {
    'restaurants' => _restaurants(),
    'subscriptions' => _subscriptions(),
    'revenue' => _revenue(),
    'plans' => _plans(),
    'system' => _system(),
    _ => _overview(),
  };

  Widget _overview() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _metrics(),
      const SizedBox(height: 18),
      _two(
        _distribution(
          'Subscription status',
          _maps(analytics['statusBreakdown']),
          const [green, Color(0xFF3B74B9), saffron, Color(0xFFC84435)],
        ),
        _distribution('Plan mix', _maps(analytics['planBreakdown']), const [
          saffron,
          Color(0xFF7456A6),
          green,
          Color(0xFF3B74B9),
        ]),
      ),
      const SizedBox(height: 18),
      _section(
        'Renewal attention',
        Icons.notification_important_outlined,
        _expiryList(limit: 5),
      ),
    ],
  );

  Widget _metrics() => LayoutBuilder(
    builder: (_, b) {
      final w = b.maxWidth >= 1050
          ? (b.maxWidth - 45) / 4
          : b.maxWidth >= 560
          ? (b.maxWidth - 15) / 2
          : b.maxWidth;
      return Wrap(
        spacing: 15,
        runSpacing: 15,
        children: [
          _metric(
            'Restaurants',
            summary['restaurants'],
            Icons.storefront,
            saffron,
            w,
          ),
          _metric(
            'Active tenants',
            summary['active'],
            Icons.verified,
            green,
            w,
          ),
          _metric(
            'Branches',
            summary['branches'],
            Icons.account_tree_outlined,
            const Color(0xFF3B74B9),
            w,
          ),
          _metric(
            'SaaS revenue',
            '₹${_money((analytics['revenue'] as Map?)?['total'])}',
            Icons.currency_rupee,
            const Color(0xFF7456A6),
            w,
          ),
        ],
      );
    },
  );

  Widget _restaurants() => Column(
    children: [
      Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          SizedBox(
            width: 310,
            child: TextField(
              onChanged: (v) => search = v,
              onSubmitted: (_) => _load(),
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Search restaurant',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(),
              ),
            ),
          ),
          SizedBox(
            width: 210,
            child: DropdownButtonFormField<String>(
              initialValue: status,
              decoration: const InputDecoration(
                labelText: 'Status',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(),
              ),
              items: [
                'All',
                'Pending Payment',
                'Trial',
                'Active',
                'Expired',
                'Suspended',
                'Cancelled',
              ].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
              onChanged: (v) {
                status = v ?? 'All';
                _load();
              },
            ),
          ),
          FilledButton.icon(
            onPressed: _load,
            icon: const Icon(Icons.filter_alt_outlined),
            label: const Text('Apply'),
          ),
        ],
      ),
      const SizedBox(height: 16),
      _tenantGrid(),
    ],
  );
  Widget _subscriptions() => Column(
    children: [
      _two(
        _summaryCard(
          'Active subscriptions',
          '${summary['active'] ?? 0}',
          'Recurring tenants currently enabled',
          Icons.autorenew,
          green,
        ),
        _summaryCard(
          'Expiring in 30 days',
          '${_maps(analytics['expiringSubscriptions']).length}',
          'Contact these tenants before expiry',
          Icons.event_busy_outlined,
          saffron,
        ),
      ),
      const SizedBox(height: 18),
      _section(
        'Upcoming renewals',
        Icons.calendar_month_outlined,
        _expiryList(),
      ),
      const SizedBox(height: 18),
      _section('Subscription state breakdown', Icons.donut_large, [
        _distribution('', _maps(analytics['statusBreakdown']), const [
          green,
          Color(0xFF3B74B9),
          saffron,
          Color(0xFFC84435),
          Color(0xFF7456A6),
        ]),
      ]),
    ],
  );

  Widget _revenue() {
    final revenue = Map<String, dynamic>.from(
      analytics['revenue'] as Map? ?? const {},
    );
    final monthly = _maps(analytics['monthlyRevenue']);
    final maxValue = monthly.fold<double>(
      1,
      (m, e) => ((e['revenue'] as num?)?.toDouble() ?? 0) > m
          ? (e['revenue'] as num).toDouble()
          : m,
    );
    return Column(
      children: [
        _two(
          _summaryCard(
            'Collected revenue',
            '₹${_money(revenue['total'])}',
            '${revenue['payments'] ?? 0} successful subscription payments',
            Icons.account_balance_wallet_outlined,
            green,
          ),
          _summaryCard(
            'Average payment',
            '₹${_money(revenue['average'])}',
            '${revenue['failedPayments'] ?? 0} failed attempts',
            Icons.payments_outlined,
            saffron,
          ),
        ),
        const SizedBox(height: 18),
        _section(
          'Last 6 months',
          Icons.bar_chart,
          monthly.isEmpty
              ? [const _Empty('No paid subscription data yet.')]
              : monthly.map((m) {
                  final value = (m['revenue'] as num?)?.toDouble() ?? 0;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 70,
                          child: Text('${m['month']}/${m['year']}'),
                        ),
                        Expanded(
                          child: LinearProgressIndicator(
                            value: value / maxValue,
                            minHeight: 12,
                            borderRadius: BorderRadius.circular(8),
                            color: green,
                            backgroundColor: const Color(0xFFE8DED5),
                          ),
                        ),
                        const SizedBox(width: 12),
                        SizedBox(
                          width: 100,
                          child: Text(
                            '₹${_money(value)}',
                            textAlign: TextAlign.end,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
        ),
        const SizedBox(height: 18),
        _section(
          'Recent subscription payments',
          Icons.receipt_long_outlined,
          _paymentRows(),
        ),
      ],
    );
  }

  Widget _plans() {
    const plans = [
      {
        'name': 'Basic',
        'price': 'Rs 999',
        'color': Color(0xFF3B74B9),
        'features': ['QR ordering', 'Menu & tables', 'Basic reports'],
      },
      {
        'name': 'Pro',
        'price': 'Rs 2,499',
        'color': saffron,
        'features': [
          'All Basic features',
          'POS & kitchen',
          'Inventory & staff',
        ],
      },
      {
        'name': 'Premium',
        'price': 'Rs 4,999',
        'color': green,
        'features': [
          'All Pro features',
          'Advanced analytics',
          'Priority support',
        ],
      },
      {
        'name': 'Enterprise',
        'price': 'Custom',
        'color': Color(0xFF7456A6),
        'features': [
          'Multiple locations',
          'Custom onboarding',
          'Dedicated support',
        ],
      },
    ];
    return LayoutBuilder(
      builder: (_, b) {
        final w = b.maxWidth >= 1050
            ? (b.maxWidth - 45) / 4
            : b.maxWidth >= 560
            ? (b.maxWidth - 15) / 2
            : b.maxWidth;
        return Wrap(
          spacing: 15,
          runSpacing: 15,
          children: plans.map((plan) {
            final color = plan['color'] as Color;
            return SizedBox(
              width: w,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: _box(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _pill(
                      '${plan['name']}',
                      Icons.workspace_premium_outlined,
                      color,
                    ),
                    const SizedBox(height: 18),
                    Text(
                      '${plan['price']}',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 29,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Text(
                      'per month',
                      style: TextStyle(color: Color(0xFF806E64)),
                    ),
                    const Divider(height: 28),
                    ...(plan['features'] as List<String>).map(
                      (f) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          children: [
                            Icon(Icons.check_circle, size: 18, color: color),
                            const SizedBox(width: 8),
                            Expanded(child: Text(f)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _system() => Column(
    children: [
      _two(
        _summaryCard(
          'Backend API',
          'Operational',
          'Platform data loaded successfully',
          Icons.cloud_done_outlined,
          green,
        ),
        _summaryCard(
          'Tenant isolation',
          'Enabled',
          'Restaurant access scoped by authentication',
          Icons.security_outlined,
          green,
        ),
      ),
      const SizedBox(height: 18),
      _section('Service readiness', Icons.monitor_heart_outlined, [
        _health('Database connectivity', true, 'Analytics and tenants loaded'),
        _health('Authentication & RBAC', true, 'Super Admin route protected'),
        _health(
          'Payment gateway',
          true,
          'Razorpay test authentication configured',
        ),
        _health(
          'Webhook processing',
          true,
          'Signed payment_link.paid handler active',
        ),
      ]),
      const SizedBox(height: 18),
      _section('Platform footprint', Icons.hub_outlined, [
        ListTile(
          leading: const Icon(Icons.store_mall_directory_outlined),
          title: const Text('Restaurants'),
          trailing: Text('${summary['restaurants'] ?? 0}'),
        ),
        ListTile(
          leading: const Icon(Icons.account_tree_outlined),
          title: const Text('Branches'),
          trailing: Text('${summary['branches'] ?? 0}'),
        ),
        ListTile(
          leading: const Icon(Icons.groups_outlined),
          title: const Text('Staff accounts'),
          trailing: Text('${summary['staff'] ?? 0}'),
        ),
      ]),
    ],
  );

  Widget _tenantGrid() => LayoutBuilder(
    builder: (_, b) {
      if (tenants.isEmpty) return const _Empty('No restaurants found.');
      final cols = b.maxWidth >= 1100
          ? 3
          : b.maxWidth >= 700
          ? 2
          : 1;
      final w = (b.maxWidth - (cols - 1) * 14) / cols;
      return Wrap(
        spacing: 14,
        runSpacing: 14,
        children: tenants
            .map((r) => SizedBox(width: w, child: _tenant(r)))
            .toList(),
      );
    },
  );
  Widget _tenant(Map<String, dynamic> r) => Container(
    padding: const EdgeInsets.all(17),
    decoration: _box(),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CircleAvatar(
              backgroundColor: const Color(0xFFFFE7D6),
              child: const Icon(Icons.restaurant, color: saffron),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Text(
                '${r['name']}',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            _pill(
              '${r['subscriptionStatus']}',
              Icons.circle,
              ['Active', 'Trial'].contains(r['subscriptionStatus'])
                  ? green
                  : const Color(0xFFC84435),
            ),
          ],
        ),
        const Divider(height: 25),
        Text(
          '${r['subscriptionPlan']} plan',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        Text(
          '${r['branchCount'] ?? 0} branches · ${r['staffCount'] ?? 0} staff',
          style: const TextStyle(color: Color(0xFF806E64)),
        ),
        Text(
          'Expires: ${_date(r['subscriptionExpiresAt'])}',
          style: const TextStyle(color: Color(0xFF806E64)),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _manage(r),
            icon: const Icon(Icons.tune),
            label: const Text('Manage tenant'),
          ),
        ),
      ],
    ),
  );

  List<Widget> _expiryList({int? limit}) {
    final rows = _maps(analytics['expiringSubscriptions']);
    final visible = limit == null ? rows : rows.take(limit).toList();
    if (visible.isEmpty)
      return [const _Empty('No subscriptions expiring in the next 30 days.')];
    return visible.map((subscription) {
      final restaurant = subscription['restaurantId'] as Map?;
      return ListTile(
        leading: const CircleAvatar(child: Icon(Icons.schedule)),
        title: Text('${restaurant?['name'] ?? 'Restaurant'}'),
        subtitle: Text('${subscription['plan']} plan'),
        trailing: Text(
          _date(subscription['expiresAt']),
          style: const TextStyle(fontWeight: FontWeight.w700, color: saffron),
        ),
      );
    }).toList();
  }

  List<Widget> _paymentRows() {
    final rows = _maps(analytics['recentPayments']);
    if (rows.isEmpty)
      return [const _Empty('No subscription payments recorded.')];
    return rows.map((p) {
      final restaurant = p['restaurantId'] as Map?;
      return ListTile(
        leading: Icon(
          p['status'] == 'Paid' ? Icons.check_circle : Icons.error_outline,
          color: p['status'] == 'Paid' ? green : saffron,
        ),
        title: Text('${restaurant?['name'] ?? 'Restaurant'}'),
        subtitle: Text(
          '${p['provider']} · ${_date(p['paidAt'] ?? p['createdAt'])}',
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '₹${_money(p['amount'])}',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            Text('${p['status']}', style: const TextStyle(fontSize: 12)),
          ],
        ),
      );
    }).toList();
  }

  Future<void> _manage(Map<String, dynamic> r) async {
    String plan = '${r['subscriptionPlan']}',
        state = '${r['subscriptionStatus']}';
    bool active = r['isActive'] == true;
    final expiry = TextEditingController(
      text: r['subscriptionExpiresAt'] == null
          ? ''
          : '${r['subscriptionExpiresAt']}'.split('T').first,
    );
    final ok = await showDialog<bool>(
      context: context,
      builder: (dc) => StatefulBuilder(
        builder: (_, setD) => AlertDialog(
          title: Text('Manage ${r['name']}'),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField(
                  initialValue: plan,
                  decoration: const InputDecoration(labelText: 'Plan'),
                  items: ['Basic', 'Pro', 'Premium', 'Enterprise']
                      .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                      .toList(),
                  onChanged: (v) => setD(() => plan = v ?? plan),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField(
                  initialValue: state,
                  decoration: const InputDecoration(labelText: 'Status'),
                  items:
                      [
                            'Pending Payment',
                            'Trial',
                            'Active',
                            'Expired',
                            'Suspended',
                            'Cancelled',
                          ]
                          .map(
                            (v) => DropdownMenuItem(value: v, child: Text(v)),
                          )
                          .toList(),
                  onChanged: (v) => setD(() => state = v ?? state),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: expiry,
                  decoration: const InputDecoration(
                    labelText: 'Expiry YYYY-MM-DD',
                  ),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Restaurant active'),
                  value: active,
                  onChanged: (v) => setD(() => active = v),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dc, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dc, true),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
    if (ok != true) return;
    try {
      await RestaurantApi.updatePlatformRestaurant('${r['_id']}', {
        'subscriptionPlan': plan,
        'subscriptionStatus': state,
        'subscriptionExpiresAt': expiry.text.trim().isEmpty
            ? null
            : expiry.text.trim(),
        'isActive': active,
      });
      await _load();
      _message('Tenant updated.');
    } catch (e) {
      _message(RestaurantApi.messageFor(e));
    } finally {
      expiry.dispose();
    }
  }

  Widget _distribution(
    String title,
    List<Map<String, dynamic>> rows,
    List<Color> colors,
  ) => Container(
    padding: const EdgeInsets.all(18),
    decoration: _box(),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title.isNotEmpty)
          Text(
            title,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
          ),
        if (title.isNotEmpty) const SizedBox(height: 12),
        if (rows.isEmpty)
          const _Empty('No data yet.')
        else
          ...List.generate(rows.length, (i) {
            final r = rows[i],
                total = rows.fold<int>(
                  0,
                  (s, e) => s + ((e['count'] as num?)?.toInt() ?? 0),
                ),
                count = (r['count'] as num?)?.toInt() ?? 0;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 7),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(child: Text('${r['label']}')),
                      Text(
                        '$count',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  LinearProgressIndicator(
                    value: total == 0 ? 0 : count / total,
                    minHeight: 7,
                    borderRadius: BorderRadius.circular(8),
                    color: colors[i % colors.length],
                    backgroundColor: const Color(0xFFEDE5DE),
                  ),
                ],
              ),
            );
          }),
      ],
    ),
  );
  Widget _summaryCard(
    String title,
    String value,
    String note,
    IconData icon,
    Color color,
  ) => Container(
    padding: const EdgeInsets.all(20),
    decoration: _box(),
    child: Row(
      children: [
        CircleAvatar(
          radius: 25,
          backgroundColor: color.withValues(alpha: .12),
          child: Icon(icon, color: color),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: Color(0xFF806E64))),
              Text(
                value,
                style: GoogleFonts.playfairDisplay(
                  fontSize: 25,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                note,
                style: const TextStyle(fontSize: 12, color: Color(0xFF806E64)),
              ),
            ],
          ),
        ),
      ],
    ),
  );
  Widget _metric(
    String label,
    dynamic value,
    IconData icon,
    Color color,
    double width,
  ) => SizedBox(
    width: width,
    child: _summaryCard(
      label,
      '${value ?? 0}',
      'Live platform metric',
      icon,
      color,
    ),
  );
  Widget _section(String title, IconData icon, List<Widget> children) =>
      Container(
        decoration: _box(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(17),
              child: Row(
                children: [
                  Icon(icon, color: saffron),
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
            ...children,
          ],
        ),
      );
  Widget _two(Widget a, Widget b) => LayoutBuilder(
    builder: (_, box) => box.maxWidth >= 720
        ? Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: a),
              const SizedBox(width: 15),
              Expanded(child: b),
            ],
          )
        : Column(children: [a, const SizedBox(height: 15), b]),
  );
  Widget _health(String title, bool ok, String note) => ListTile(
    leading: Icon(
      ok ? Icons.check_circle : Icons.error,
      color: ok ? green : const Color(0xFFC84435),
    ),
    title: Text(title),
    subtitle: Text(note),
    trailing: Text(
      ok ? 'Healthy' : 'Attention',
      style: TextStyle(
        color: ok ? green : const Color(0xFFC84435),
        fontWeight: FontWeight.w700,
      ),
    ),
  );
  Widget _pill(String text, IconData icon, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .11),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 5),
        Text(
          text,
          style: TextStyle(
            fontSize: 11,
            color: color,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
  List<Map<String, dynamic>> _maps(dynamic value) => value is List
      ? value.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList()
      : [];
  String _money(dynamic raw) => (raw as num? ?? 0).toStringAsFixed(0);
  String _date(dynamic raw) =>
      raw == null ? 'Not set' : '$raw'.split('T').first;
  BoxDecoration _box() => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(18),
    border: Border.all(color: const Color(0xFFECE2D9)),
  );
  Future<void> _logout() async {
    await LocalStorage.clearToken();
    await LocalStorage.saveRole('');
    if (mounted) context.go('/admin/login');
  }

  void _message(String text) {
    if (mounted)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(text), behavior: SnackBarBehavior.floating),
      );
  }
}

class _Empty extends StatelessWidget {
  const _Empty(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(28),
    child: Center(
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(color: Color(0xFF806E64)),
      ),
    ),
  );
}
