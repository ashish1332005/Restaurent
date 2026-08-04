import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/storage/local_storage.dart';
import 'inventory_screen.dart';
import 'menu_flow_screen.dart';
import 'offers_screen.dart';
import 'orders_flow_screen.dart';
import 'reports_screen.dart';
import 'reservations_screen.dart';
import 'settings_screen.dart';
import 'staff_management_screen.dart';
import 'table_management_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

enum AdminView {
  subscription, // Screen 1
  dashboard, // Screen 2
  menu, // Screen 3
  tables, // Screen 4
  orders, // Screen 5
  staff, // Screen 6
  inventory, // Screen 7
  offers, // Screen 8
  reservations, // Screen 9
  reports, // Screen 10
  settings, // Screen 11
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  AdminView _currentView = AdminView.dashboard;
  int _mobileNavIndex =
      0; // 0: Dashboard, 1: Orders, 2: POS, 3: Reservations, 4: More

  static const Color _orange = Color(0xFFFF4D0A);
  static const Color _bgLight = Color(0xFFFAFAFB);
  static const Color _textDark = Color(0xFF111827);
  static const Color _textMuted = Color(0xFF687385);
  static const Color _green = Color(0xFF1FA971);

  void _switchView(AdminView view) {
    setState(() {
      _currentView = view;
      if (view == AdminView.dashboard) _mobileNavIndex = 0;
      if (view == AdminView.orders) _mobileNavIndex = 1;
      if (view == AdminView.reservations) _mobileNavIndex = 3;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.sizeOf(context).width >= 900;

    return Scaffold(
      backgroundColor: _bgLight,
      appBar: isDesktop ? null : _buildAppBar(),
      body: isDesktop ? _buildDesktopLayout() : _buildCurrentViewBody(),
      bottomNavigationBar: isDesktop ? null : _buildMobileBottomNavBar(),
    );
  }

  // ================= DESKTOP SIDEBAR LAYOUT =================
  Widget _buildDesktopLayout() {
    return Row(
      children: [
        // Sidebar
        Container(
          width: 260,
          color: const Color(0xFF111827),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _orange,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.restaurant_menu_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Spice Affair',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Owner Admin Suite',
                          style: TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Divider(color: Color(0xFF1E293B), height: 1),
              const SizedBox(height: 12),
              _sidebarItem(
                Icons.card_membership_rounded,
                '1. Subscription',
                AdminView.subscription,
              ),
              _sidebarItem(
                Icons.space_dashboard_rounded,
                '2. Dashboard',
                AdminView.dashboard,
              ),
              _sidebarItem(
                Icons.menu_book_rounded,
                '3. Menu Management',
                AdminView.menu,
              ),
              _sidebarItem(
                Icons.table_restaurant_rounded,
                '4. Table Management',
                AdminView.tables,
              ),
              _sidebarItem(
                Icons.receipt_long_rounded,
                '5. Live Orders',
                AdminView.orders,
              ),
              _sidebarItem(
                Icons.groups_rounded,
                '6. Staff Management',
                AdminView.staff,
              ),
              _sidebarItem(
                Icons.inventory_2_rounded,
                '7. Inventory',
                AdminView.inventory,
              ),
              _sidebarItem(
                Icons.local_offer_rounded,
                '8. Offers & Coupons',
                AdminView.offers,
              ),
              _sidebarItem(
                Icons.event_seat_rounded,
                '9. Reservations',
                AdminView.reservations,
              ),
              _sidebarItem(
                Icons.insert_chart_rounded,
                '10. Reports & Analytics',
                AdminView.reports,
              ),
              _sidebarItem(
                Icons.settings_rounded,
                '11. Settings',
                AdminView.settings,
              ),
              const Spacer(),
              ListTile(
                leading: const Icon(Icons.logout_rounded, color: Colors.red),
                title: const Text(
                  'Logout',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onTap: () async {
                  await LocalStorage.clearToken();
                  if (mounted) context.go('/login');
                },
              ),
            ],
          ),
        ),
        // Content Area
        Expanded(
          child: Column(
            children: [
              Container(
                height: 60,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                color: Colors.white,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _getViewTitle(),
                      style: const TextStyle(
                        color: _textDark,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _green.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Pro Plan (Active)',
                            style: TextStyle(
                              color: _green,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        IconButton(
                          icon: const Icon(Icons.notifications_outlined),
                          onPressed: () {},
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1200),
                    child: _buildCurrentViewBody(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _sidebarItem(IconData icon, String label, AdminView targetView) {
    final isSelected = _currentView == targetView;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        color: isSelected ? _orange : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isSelected ? Colors.white : const Color(0xFF94A3B8),
          size: 18,
        ),
        title: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFFCBD5E1),
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
        onTap: () => _switchView(targetView),
      ),
    );
  }

  String _getViewTitle() {
    switch (_currentView) {
      case AdminView.subscription:
        return '1. Subscription';
      case AdminView.dashboard:
        return '2. Dashboard';
      case AdminView.menu:
        return '3. Menu Management';
      case AdminView.tables:
        return '4. Table Management';
      case AdminView.orders:
        return '5. Live Orders';
      case AdminView.staff:
        return '6. Staff Management';
      case AdminView.inventory:
        return '7. Inventory';
      case AdminView.offers:
        return '8. Offers & Coupons';
      case AdminView.reservations:
        return '9. Reservations';
      case AdminView.reports:
        return '10. Reports';
      case AdminView.settings:
        return '11. Settings';
    }
  }

  // ================= MOBILE APP BAR =================
  PreferredSizeWidget _buildAppBar() {
    final onDashboard = _currentView == AdminView.dashboard;
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      surfaceTintColor: Colors.white,
      leading: onDashboard
          ? IconButton(
              icon: const Icon(Icons.menu_rounded, color: _textDark),
              onPressed: _showMoreSheetsMenu,
            )
          : IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: _textDark),
              onPressed: () => _switchView(AdminView.dashboard),
            ),
      titleSpacing: 0,
      title: onDashboard
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF7A1A), _orange],
                    ),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: _orange.withValues(alpha: 0.20),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.restaurant_menu_rounded,
                    color: Colors.white,
                    size: 19,
                  ),
                ),
                const SizedBox(width: 10),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: 'Resto',
                            style: TextStyle(color: _textDark),
                          ),
                          TextSpan(
                            text: 'Hub',
                            style: TextStyle(color: _orange),
                          ),
                        ],
                      ),
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      'Sharma Restaurant',
                      style: TextStyle(
                        color: _textMuted,
                        fontSize: 11,
                        height: 0.95,
                      ),
                    ),
                  ],
                ),
              ],
            )
          : Text(
              _getViewTitle(),
              style: const TextStyle(
                color: _textDark,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
      actions: [
        if (onDashboard)
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                icon: const Icon(
                  Icons.notifications_none_rounded,
                  color: _textDark,
                ),
                onPressed: () {},
              ),
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Color(0xFFFF2D2D),
                    shape: BoxShape.circle,
                  ),
                  child: const Text(
                    '8',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ],
          ),
        const SizedBox(width: 8),
      ],
    );
  }

  // ================= SCREEN BODY ROUTER =================
  Widget _buildCurrentViewBody() {
    switch (_currentView) {
      case AdminView.subscription:
        return _buildScreen1Subscription();
      case AdminView.dashboard:
        return _buildScreen2Dashboard();
      case AdminView.menu:
        return const MenuFlowScreen();
      case AdminView.tables:
        return const TableManagementScreen();
      case AdminView.orders:
        return const OrdersFlowScreen();
      case AdminView.staff:
        return const StaffManagementScreen();
      case AdminView.inventory:
        return const InventoryScreen();
      case AdminView.offers:
        return const OffersScreen();
      case AdminView.reservations:
        return const ReservationsScreen();
      case AdminView.reports:
        return const ReportsScreen();
      case AdminView.settings:
        return const SettingsScreen();
    }
  }

  // ================= 1. SUBSCRIPTION SCREEN =================
  Widget _buildScreen1Subscription() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.restaurant_rounded, color: _orange, size: 24),
                      SizedBox(width: 8),
                      Text(
                        'RestoHub Pro Plan',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _green.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'ACTIVE',
                      style: TextStyle(
                        color: _green,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'All-in-one management for restaurants of any size.',
                style: TextStyle(color: _textMuted, fontSize: 12),
              ),
              const SizedBox(height: 16),
              const Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '₹500',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: _textDark,
                    ),
                  ),
                  Text(
                    '/month Billed monthly',
                    style: TextStyle(color: _textMuted, fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _checkItem('All Premium Features'),
              _checkItem('Unlimited Orders'),
              _checkItem('Advanced Reports'),
              _checkItem('Priority Support'),
              const Divider(height: 24),
              _detailRow('Plan Status', 'Active'),
              const SizedBox(height: 6),
              _detailRow('Renewal Date', '15 Jun 2025'),
              const SizedBox(height: 6),
              _detailRow('Payment Method', 'UPI **** 4546'),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _orange,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () => context.go('/subscription'),
                  child: const Text(
                    'Renew Now',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _textDark,
                    side: const BorderSide(color: Color(0xFFCBD5E1)),
                  ),
                  onPressed: () => _switchView(AdminView.reports),
                  child: const Text(
                    'View Billing History',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: TextButton.icon(
            onPressed: () {},
            icon: const Icon(
              Icons.help_outline_rounded,
              color: _textMuted,
              size: 16,
            ),
            label: const Text(
              'Need help? Contact Support',
              style: TextStyle(color: _textMuted, fontSize: 12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _checkItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          const Icon(Icons.check_circle_rounded, color: _green, size: 16),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(
              color: _textDark,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: _textMuted, fontSize: 13)),
        Text(
          value,
          style: const TextStyle(
            color: _textDark,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  // ================= 2. DASHBOARD SCREEN =================
  Widget _buildScreen2Dashboard() {
    final isWide = MediaQuery.sizeOf(context).width >= 720;
    return ListView(
      padding: EdgeInsets.fromLTRB(isWide ? 24 : 16, 12, isWide ? 24 : 16, 24),
      children: [
        _ownerHeroCard(isWide),
        const SizedBox(height: 16),
        _kpiSummaryCard(isWide),
        const SizedBox(height: 16),
        if (isWide)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 5, child: _salesOverviewCard()),
              const SizedBox(width: 16),
              Expanded(flex: 4, child: _topItemsCard()),
            ],
          )
        else ...[
          _salesOverviewCard(),
          const SizedBox(height: 16),
          _topItemsCard(),
        ],
        const SizedBox(height: 16),
        _liveOrdersCard(),
        const SizedBox(height: 16),
        _quickActionsGrid(isWide),
      ],
    );
  }

  Widget _ownerHeroCard(bool isWide) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE8EEF7)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A0F172A),
            blurRadius: 26,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 52,
                width: 52,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF7A1A), _orange],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.restaurant_rounded,
                  color: Colors.white,
                  size: 27,
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Good morning, Ashish ðŸ‘‹',
                      style: TextStyle(
                        color: _textDark,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      "Here's what's happening at Sharma Restaurant today.",
                      style: TextStyle(color: _textMuted, fontSize: 13),
                    ),
                  ],
                ),
              ),
              if (isWide) _datePill(),
            ],
          ),
          if (!isWide) ...[
            const SizedBox(height: 16),
            Align(alignment: Alignment.centerLeft, child: _datePill()),
          ],
        ],
      ),
    );
  }

  Widget _datePill() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Today',
            style: TextStyle(color: _textDark, fontWeight: FontWeight.w800),
          ),
          SizedBox(width: 6),
          Icon(Icons.keyboard_arrow_down_rounded, color: _textMuted, size: 18),
        ],
      ),
    );
  }

  Widget _kpiSummaryCard(bool isWide) {
    final metrics = [
      _OwnerMetric(
        'Total Sales',
        '₹24,560',
        '18.6%',
        Icons.currency_rupee_rounded,
        const Color(0xFF16A34A),
      ),
      _OwnerMetric(
        'Orders',
        '128',
        '12.4%',
        Icons.shopping_bag_outlined,
        const Color(0xFF2563EB),
      ),
      _OwnerMetric(
        'New Customers',
        '32',
        '8.2%',
        Icons.group_add_outlined,
        const Color(0xFF8B5CF6),
      ),
      _OwnerMetric(
        'Avg. Order Value',
        '₹192',
        '6.5%',
        Icons.bar_chart_rounded,
        const Color(0xFFF97316),
      ),
    ];
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE8EEF7)),
      ),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: metrics.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: isWide ? 4 : 2,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: isWide ? 1.8 : 1.45,
        ),
        itemBuilder: (_, index) => _metricTile(metrics[index]),
      ),
    );
  }

  Widget _metricTile(_OwnerMetric metric) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFBFCFF),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  metric.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: metric.color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(metric.icon, color: metric.color, size: 18),
              ),
            ],
          ),
          Text(
            metric.value,
            style: const TextStyle(
              color: _textDark,
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
          Row(
            children: [
              const Icon(Icons.trending_up_rounded, color: _green, size: 15),
              const SizedBox(width: 4),
              Text(
                metric.change,
                style: const TextStyle(
                  color: _green,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _salesOverviewCard() {
    return _dashboardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(
            'Sales Overview',
            'View report',
            () => _switchView(AdminView.reports),
          ),
          const SizedBox(height: 18),
          const Text(
            '₹24,560',
            style: TextStyle(
              color: _textDark,
              fontSize: 30,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Text('Total Sales', style: TextStyle(color: _textMuted)),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _green.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: const Text(
                  'â†‘ 18.6%',
                  style: TextStyle(
                    color: _green,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          SizedBox(height: 150, child: _miniSalesChart()),
          const SizedBox(height: 8),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('12 AM', style: TextStyle(color: _textMuted, fontSize: 11)),
              Text('6 AM', style: TextStyle(color: _textMuted, fontSize: 11)),
              Text('12 PM', style: TextStyle(color: _textMuted, fontSize: 11)),
              Text('6 PM', style: TextStyle(color: _textMuted, fontSize: 11)),
              Text('11 PM', style: TextStyle(color: _textMuted, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniSalesChart() {
    return CustomPaint(painter: _SalesChartPainter(), child: Container());
  }

  Widget _topItemsCard() {
    final items = [
      (
        'Paneer Tikka',
        '42',
        Icons.lunch_dining_rounded,
        const Color(0xFFFFEDD5),
      ),
      ('Veg Biryani', '38', Icons.rice_bowl_rounded, const Color(0xFFE0F2FE)),
      ('Cheese Burger', '31', Icons.fastfood_rounded, const Color(0xFFFEF3C7)),
      ('Cold Coffee', '26', Icons.local_cafe_rounded, const Color(0xFFEDE9FE)),
      ('Masala Dosa', '21', Icons.restaurant_rounded, const Color(0xFFDCFCE7)),
    ];
    return _dashboardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(
            'Top Items',
            'View all',
            () => _switchView(AdminView.menu),
          ),
          const SizedBox(height: 14),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 7),
              child: Row(
                children: [
                  Container(
                    height: 42,
                    width: 42,
                    decoration: BoxDecoration(
                      color: item.$4,
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Icon(item.$3, color: _orange, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      item.$1,
                      style: const TextStyle(
                        color: _textDark,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Text(
                    item.$2,
                    style: const TextStyle(
                      color: _green,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _liveOrdersCard() {
    final orders = [
      _LiveOrder(
        '#ORD-1058',
        'Table 08 • Dine In',
        'Preparing',
        '2 items',
        '₹450',
        const Color(0xFFFF3D00),
      ),
      _LiveOrder(
        '#ORD-1057',
        'Table 03 • Dine In',
        'Confirmed',
        '3 items',
        '₹680',
        const Color(0xFF2563EB),
      ),
      _LiveOrder(
        '#ORD-1056',
        'Takeaway',
        'Ready',
        '2 items',
        '₹320',
        const Color(0xFFF59E0B),
      ),
    ];
    return _dashboardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(
            'Live Orders',
            'View all orders',
            () => _switchView(AdminView.orders),
          ),
          const SizedBox(height: 8),
          ...orders.map((order) => _liveOrderRow(order)),
        ],
      ),
    );
  }

  Widget _liveOrderRow(_LiveOrder order) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => _switchView(AdminView.orders),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Container(
              height: 46,
              width: 46,
              decoration: BoxDecoration(
                color: _green.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.shopping_bag_outlined, color: _green),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    order.id,
                    style: const TextStyle(
                      color: _textDark,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    order.subtitle,
                    style: const TextStyle(color: _textMuted, fontSize: 12),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: order.color.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Text(
                order.status,
                style: TextStyle(
                  color: order.color,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  order.items,
                  style: const TextStyle(color: _textMuted, fontSize: 11),
                ),
                const SizedBox(height: 3),
                Text(
                  order.total,
                  style: const TextStyle(
                    color: _textDark,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right_rounded, color: _textMuted),
          ],
        ),
      ),
    );
  }

  Widget _quickActionsGrid(bool isWide) {
    final actions = [
      _QuickAction(
        Icons.restaurant_menu_rounded,
        'Menu\nManagement',
        _orange,
        () => _switchView(AdminView.menu),
      ),
      _QuickAction(
        Icons.table_restaurant_rounded,
        'Table\nManagement',
        const Color(0xFF2563EB),
        () => _switchView(AdminView.tables),
      ),
      _QuickAction(
        Icons.shopping_bag_outlined,
        'Orders',
        _green,
        () => _switchView(AdminView.orders),
      ),
      _QuickAction(
        Icons.groups_rounded,
        'Staff\nManagement',
        const Color(0xFF8B5CF6),
        () => _switchView(AdminView.staff),
      ),
      _QuickAction(
        Icons.inventory_2_outlined,
        'Inventory',
        const Color(0xFFF97316),
        () => _switchView(AdminView.inventory),
      ),
      _QuickAction(
        Icons.local_offer_outlined,
        'Offers &\nCoupons',
        const Color(0xFFFF477E),
        () => _switchView(AdminView.offers),
      ),
      _QuickAction(
        Icons.event_available_rounded,
        'Reservations',
        const Color(0xFF06B6D4),
        () => _switchView(AdminView.reservations),
      ),
      _QuickAction(
        Icons.bar_chart_rounded,
        'Reports',
        const Color(0xFF2563EB),
        () => _switchView(AdminView.reports),
      ),
      _QuickAction(
        Icons.workspace_premium_rounded,
        'Subscription',
        const Color(0xFF8B5CF6),
        () => _switchView(AdminView.subscription),
      ),
      _QuickAction(
        Icons.settings_rounded,
        'Settings',
        const Color(0xFF687385),
        () => _switchView(AdminView.settings),
      ),
    ];
    return _dashboardCard(
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: actions.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: isWide ? 5 : 3,
          crossAxisSpacing: 12,
          mainAxisSpacing: 14,
          childAspectRatio: isWide ? 1.15 : 0.98,
        ),
        itemBuilder: (_, index) {
          final action = actions[index];
          return InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: action.onTap,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  height: 58,
                  width: 58,
                  decoration: BoxDecoration(
                    color: action.color.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(action.icon, color: action.color, size: 27),
                ),
                const SizedBox(height: 10),
                Text(
                  action.label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _textDark,
                    fontWeight: FontWeight.w800,
                    fontSize: 12.5,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _dashboardCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE8EEF7)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x080F172A),
            blurRadius: 22,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _sectionHeader(String title, String action, VoidCallback onTap) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: _textDark,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        TextButton(
          onPressed: onTap,
          style: TextButton.styleFrom(foregroundColor: _orange),
          child: Text(
            action,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
      ],
    );
  }

  // ================= MOBILE NAVIGATION & MENU SHEET =================
  Widget _buildMobileBottomNavBar() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Color(0x140F172A),
            blurRadius: 24,
            offset: Offset(0, -8),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: NavigationBar(
          height: 72,
          selectedIndex: _mobileNavIndex,
          backgroundColor: Colors.transparent,
          elevation: 0,
          indicatorColor: _orange.withValues(alpha: 0.12),
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          onDestinationSelected: (index) {
            if (index == 0) _switchView(AdminView.dashboard);
            if (index == 1) _switchView(AdminView.orders);
            if (index == 2) context.go('/pos');
            if (index == 3) _switchView(AdminView.reservations);
            if (index == 4) _showMoreSheetsMenu();
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(Icons.dashboard_rounded, color: _orange),
              label: 'Dashboard',
            ),
            NavigationDestination(
              icon: Icon(Icons.receipt_long_outlined),
              selectedIcon: Icon(Icons.receipt_long_rounded, color: _orange),
              label: 'Orders',
            ),
            NavigationDestination(
              icon: Icon(Icons.point_of_sale_outlined),
              selectedIcon: Icon(Icons.point_of_sale_rounded, color: _orange),
              label: 'POS',
            ),
            NavigationDestination(
              icon: Icon(Icons.event_available_outlined),
              selectedIcon: Icon(Icons.event_available_rounded, color: _orange),
              label: 'Reservations',
            ),
            NavigationDestination(
              icon: Icon(Icons.more_horiz_rounded),
              selectedIcon: Icon(Icons.more_horiz_rounded, color: _orange),
              label: 'More',
            ),
          ],
        ),
      ),
    );
  }

  void _showMoreSheetsMenu() {
    final actions = [
      _QuickAction(
        Icons.menu_book_rounded,
        'Menu\nManagement',
        _orange,
        () => _switchView(AdminView.menu),
      ),
      _QuickAction(
        Icons.table_restaurant_rounded,
        'Table\nManagement',
        const Color(0xFF2563EB),
        () => _switchView(AdminView.tables),
      ),
      _QuickAction(
        Icons.groups_rounded,
        'Staff\nManagement',
        const Color(0xFF8B5CF6),
        () => _switchView(AdminView.staff),
      ),
      _QuickAction(
        Icons.inventory_2_rounded,
        'Inventory',
        const Color(0xFFF97316),
        () => _switchView(AdminView.inventory),
      ),
      _QuickAction(
        Icons.local_offer_rounded,
        'Offers &\nCoupons',
        const Color(0xFFFF477E),
        () => _switchView(AdminView.offers),
      ),
      _QuickAction(
        Icons.bar_chart_rounded,
        'Reports',
        const Color(0xFF2563EB),
        () => _switchView(AdminView.reports),
      ),
      _QuickAction(
        Icons.workspace_premium_rounded,
        'Subscription',
        const Color(0xFF8B5CF6),
        () => _switchView(AdminView.subscription),
      ),
      _QuickAction(
        Icons.settings_rounded,
        'Settings',
        const Color(0xFF687385),
        () => _switchView(AdminView.settings),
      ),
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 48,
                  height: 5,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Restaurant Tools',
                style: TextStyle(
                  color: _textDark,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Manage menu, tables, staff, offers, reports and settings.',
                style: TextStyle(color: _textMuted, fontSize: 13),
              ),
              const SizedBox(height: 18),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: actions.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 12,
                  childAspectRatio: .82,
                ),
                itemBuilder: (_, index) {
                  final action = actions[index];
                  return InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      Navigator.pop(ctx);
                      action.onTap();
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFBFCFF),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE8EEF7)),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            height: 42,
                            width: 42,
                            decoration: BoxDecoration(
                              color: action.color.withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              action.icon,
                              color: action.color,
                              size: 22,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            action.label,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: _textDark,
                              fontWeight: FontWeight.w800,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OwnerMetric {
  const _OwnerMetric(
    this.label,
    this.value,
    this.change,
    this.icon,
    this.color,
  );

  final String label;
  final String value;
  final String change;
  final IconData icon;
  final Color color;
}

class _LiveOrder {
  const _LiveOrder(
    this.id,
    this.subtitle,
    this.status,
    this.items,
    this.total,
    this.color,
  );

  final String id;
  final String subtitle;
  final String status;
  final String items;
  final String total;
  final Color color;
}

class _QuickAction {
  const _QuickAction(this.icon, this.label, this.color, this.onTap);

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
}

class _SalesChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final points = <Offset>[
      Offset(0, size.height * .78),
      Offset(size.width * .08, size.height * .65),
      Offset(size.width * .15, size.height * .70),
      Offset(size.width * .23, size.height * .56),
      Offset(size.width * .32, size.height * .61),
      Offset(size.width * .42, size.height * .36),
      Offset(size.width * .50, size.height * .46),
      Offset(size.width * .58, size.height * .28),
      Offset(size.width * .68, size.height * .42),
      Offset(size.width * .78, size.height * .30),
      Offset(size.width * .88, size.height * .18),
      Offset(size.width, size.height * .12),
    ];

    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (final point in points.skip(1)) {
      path.lineTo(point.dx, point.dy);
    }

    final fillPath = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    final fillPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0x33FF5500), Color(0x00FF5500)],
      ).createShader(Offset.zero & size);
    canvas.drawPath(fillPath, fillPaint);

    final gridPaint = Paint()
      ..color = const Color(0xFFE2E8F0)
      ..strokeWidth = 1;
    canvas.drawLine(
      Offset(0, size.height),
      Offset(size.width, size.height),
      gridPaint,
    );

    final linePaint = Paint()
      ..color = const Color(0xFFFF4D0A)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, linePaint);

    final dot = points.last;
    canvas.drawCircle(dot, 6, Paint()..color = Colors.white);
    canvas.drawCircle(dot, 4, Paint()..color = const Color(0xFFFF4D0A));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
