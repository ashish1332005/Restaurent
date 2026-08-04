import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/storage/local_storage.dart';

class SuperAdminDashboardScreen extends StatefulWidget {
  const SuperAdminDashboardScreen({super.key});

  @override
  State<SuperAdminDashboardScreen> createState() =>
      _SuperAdminDashboardScreenState();
}

enum SuperAdminView {
  dashboard,
  restaurantsList,
  restaurantDetails,
  manageSubscription,
  extendSubscription,
  transactions,
  addRestaurant,
  profile,
}

class _SuperAdminDashboardScreenState extends State<SuperAdminDashboardScreen> {
  SuperAdminView _currentView = SuperAdminView.dashboard;
  int _bottomNavIndex = 0; // 0: Dashboard, 1: Restaurants, 2: Subscriptions, 3: Profile

  List<Map<String, dynamic>> _restaurants = [];
  Map<String, dynamic>? _selectedRestaurant;
  String _searchQuery = '';
  String _restaurantFilterTab = 'All'; // 'All', 'Active', 'Inactive'
  int _selectedExtendMonths = 1;

  static const Color _primaryOrange = Color(0xFFFF5500);
  static const Color _bgLight = Color(0xFFF8FAFC);
  static const Color _textDark = Color(0xFF0F172A);
  static const Color _textMuted = Color(0xFF64748B);

  // Form Controllers for Add Restaurant
  final _addNameCtrl = TextEditingController();
  final _addOwnerCtrl = TextEditingController();
  final _addPhoneCtrl = TextEditingController();
  final _addEmailCtrl = TextEditingController();
  String _selectedPlan = 'Basic Plan (₹500/mo)';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    setState(() {
      _restaurants = LocalStorage.getSuperAdminRestaurants();
      if (_restaurants.isNotEmpty && _selectedRestaurant == null) {
        _selectedRestaurant = _restaurants.first;
      }
    });
  }

  Future<void> _updateStatus(Map<String, dynamic> restaurant, String newStatus) async {
    final messenger = ScaffoldMessenger.of(context);
    await LocalStorage.updateRestaurantSubscriptionStatus(restaurant['id'], newStatus);
    _loadData();
    if (mounted) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            newStatus == 'Active'
                ? '✅ Subscription activated for "${restaurant['name']}"'
                : '⚠️ Account suspended for "${restaurant['name']}"',
          ),
          backgroundColor: newStatus == 'Active' ? const Color(0xFF1FA971) : const Color(0xFFEF4444),
        ),
      );
    }
  }

  void _navigateToView(SuperAdminView view, {Map<String, dynamic>? restaurant}) {
    setState(() {
      if (restaurant != null) {
        _selectedRestaurant = restaurant;
      }
      _currentView = view;
      if (view == SuperAdminView.dashboard) _bottomNavIndex = 0;
      if (view == SuperAdminView.restaurantsList) _bottomNavIndex = 1;
      if (view == SuperAdminView.manageSubscription || view == SuperAdminView.extendSubscription) {
        _bottomNavIndex = 2;
      }
      if (view == SuperAdminView.profile) _bottomNavIndex = 3;
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 900;
        return Scaffold(
          backgroundColor: _bgLight,
          appBar: isDesktop ? null : _buildMobileAppBar(),
          body: isDesktop ? _buildDesktopLayout() : _buildMobileLayout(),
          bottomNavigationBar: isDesktop ? null : _buildBottomNavBar(),
          floatingActionButton: (!isDesktop && _currentView == SuperAdminView.restaurantsList)
              ? FloatingActionButton(
                  backgroundColor: _primaryOrange,
                  foregroundColor: Colors.white,
                  onPressed: () => _navigateToView(SuperAdminView.addRestaurant),
                  child: const Icon(Icons.add_rounded, size: 28),
                )
              : null,
        );
      },
    );
  }

  // ================= DESKTOP LAYOUT WITH LEFT SIDEBAR =================
  Widget _buildDesktopLayout() {
    return Row(
      children: [
        // Left Navigation Sidebar
        Container(
          width: 260,
          color: const Color(0xFF0F172A),
          child: Column(
            children: [
              // Logo Header
              Container(
                padding: const EdgeInsets.all(24),
                alignment: Alignment.centerLeft,
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _primaryOrange,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.restaurant_rounded, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text('RestoHub', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
                        Text('Super Admin', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ],
                ),
              ),
              const Divider(color: Color(0xFF1E293B), height: 1),
              const SizedBox(height: 16),

              // Navigation Links
              _buildDesktopNavItem(Icons.space_dashboard_rounded, 'Dashboard', SuperAdminView.dashboard),
              _buildDesktopNavItem(Icons.storefront_rounded, 'Restaurants Directory', SuperAdminView.restaurantsList),
              _buildDesktopNavItem(Icons.card_membership_rounded, 'Subscriptions & SaaS', SuperAdminView.manageSubscription),
              _buildDesktopNavItem(Icons.add_circle_outline_rounded, 'Add New Restaurant', SuperAdminView.addRestaurant),
              _buildDesktopNavItem(Icons.person_rounded, 'Super Admin Profile', SuperAdminView.profile),

              const Spacer(),
              const Divider(color: Color(0xFF1E293B), height: 1),

              // Super Admin Profile Footer
              Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 18,
                      backgroundColor: _primaryOrange,
                      child: Icon(Icons.person, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text('Super Admin', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                          Text('superadmin@restohub.com', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11), overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.logout_rounded, color: Color(0xFFEF4444), size: 18),
                      onPressed: () async {
                        await LocalStorage.clearToken();
                        if (mounted) context.go('/login');
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Main Desktop Workspace Container
        Expanded(
          child: Column(
            children: [
              // Top Header Bar
              Container(
                height: 64,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _getDesktopTitle(),
                      style: const TextStyle(color: _textDark, fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: () => _navigateToView(SuperAdminView.addRestaurant),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _primaryOrange,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          icon: const Icon(Icons.add_rounded, size: 18),
                          label: const Text('Add Restaurant', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(width: 16),
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.notifications_outlined, color: _textDark),
                              onPressed: () {},
                            ),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(color: Color(0xFFEF4444), shape: BoxShape.circle),
                                child: const Text('3', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Desktop Content Workspace with Max Width Constraints
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

  Widget _buildDesktopNavItem(IconData icon, String label, SuperAdminView targetView) {
    final isSelected = _currentView == targetView;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: isSelected ? _primaryOrange : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        leading: Icon(icon, color: isSelected ? Colors.white : const Color(0xFF94A3B8), size: 20),
        title: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFFCBD5E1),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            fontSize: 13,
          ),
        ),
        onTap: () => _navigateToView(targetView),
      ),
    );
  }

  String _getDesktopTitle() {
    switch (_currentView) {
      case SuperAdminView.dashboard:
        return 'Platform Analytics & Overview';
      case SuperAdminView.restaurantsList:
        return 'Restaurants Directory';
      case SuperAdminView.restaurantDetails:
        return 'Restaurant Profile & Details';
      case SuperAdminView.manageSubscription:
        return 'SaaS Subscriptions & Renewals';
      case SuperAdminView.extendSubscription:
        return 'Extend SaaS Subscription';
      case SuperAdminView.transactions:
        return 'Payment & Billing History';
      case SuperAdminView.addRestaurant:
        return 'Add New Restaurant Account';
      case SuperAdminView.profile:
        return 'Super Admin Profile Settings';
    }
  }

  // ================= MOBILE LAYOUT =================
  Widget _buildMobileLayout() {
    return _buildCurrentViewBody();
  }

  PreferredSizeWidget _buildMobileAppBar() {
    String title = 'Super Admin';
    bool showBack = _currentView != SuperAdminView.dashboard &&
        _currentView != SuperAdminView.restaurantsList &&
        _currentView != SuperAdminView.profile;

    switch (_currentView) {
      case SuperAdminView.dashboard:
        title = 'Super Admin';
        break;
      case SuperAdminView.restaurantsList:
        title = 'Restaurants';
        break;
      case SuperAdminView.restaurantDetails:
        title = 'Restaurant Details';
        break;
      case SuperAdminView.manageSubscription:
        title = 'Manage Subscription';
        break;
      case SuperAdminView.extendSubscription:
        title = 'Extend Subscription';
        break;
      case SuperAdminView.transactions:
        title = 'Transactions';
        break;
      case SuperAdminView.addRestaurant:
        title = 'Add Restaurant';
        break;
      case SuperAdminView.profile:
        title = 'Profile';
        break;
    }

    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0.5,
      leading: showBack
          ? IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: _textDark),
              onPressed: () => _navigateToView(SuperAdminView.dashboard),
            )
          : IconButton(
              icon: const Icon(Icons.menu_rounded, color: _textDark),
              onPressed: () {},
            ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: _textDark, fontSize: 18, fontWeight: FontWeight.w800)),
          if (_currentView == SuperAdminView.dashboard)
            const Text('Overview of platform', style: TextStyle(color: _textMuted, fontSize: 11)),
        ],
      ),
      actions: [
        if (_currentView == SuperAdminView.dashboard)
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(icon: const Icon(Icons.notifications_outlined, color: _textDark), onPressed: () {}),
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(color: Color(0xFFEF4444), shape: BoxShape.circle),
                  child: const Text('3', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        const SizedBox(width: 8),
      ],
    );
  }

  // ================= VIEWS SWITCHER =================
  Widget _buildCurrentViewBody() {
    switch (_currentView) {
      case SuperAdminView.dashboard:
        return _buildDashboardScreen();
      case SuperAdminView.restaurantsList:
        return _buildRestaurantsListScreen();
      case SuperAdminView.restaurantDetails:
        return _buildRestaurantDetailsView();
      case SuperAdminView.manageSubscription:
        return _buildManageSubscriptionView();
      case SuperAdminView.extendSubscription:
        return _buildExtendSubscriptionView();
      case SuperAdminView.transactions:
        return _buildTransactionsView();
      case SuperAdminView.addRestaurant:
        return _buildAddRestaurantView();
      case SuperAdminView.profile:
        return _buildProfileView();
    }
  }

  // ================= SCREEN 2: DASHBOARD =================
  Widget _buildDashboardScreen() {
    final activeCount = _restaurants.where((r) => r['status'] == 'Active').length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date Range Selector Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Row(
                  children: [
                    Icon(Icons.calendar_today_rounded, size: 16, color: _textMuted),
                    SizedBox(width: 10),
                    Text('May 1 - May 31, 2025', style: TextStyle(color: _textDark, fontWeight: FontWeight.w600, fontSize: 14)),
                  ],
                ),
                Icon(Icons.keyboard_arrow_down_rounded, color: _textMuted),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Responsive Metric Cards (2x2 Grid)
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: 1.35,
            children: [
              _buildMetricCard(
                title: 'Total Restaurants',
                value: '1,248',
                badgeText: '+48 this month',
                badgeColor: const Color(0xFF1FA971),
                icon: Icons.storefront_rounded,
                iconBg: _primaryOrange.withValues(alpha: 0.15),
                iconColor: _primaryOrange,
              ),
              _buildMetricCard(
                title: 'Active Subscriptions',
                value: '$activeCount',
                badgeText: '89.06% Active',
                badgeColor: const Color(0xFF1FA971),
                icon: Icons.verified_rounded,
                iconBg: const Color(0xFF1FA971).withValues(alpha: 0.15),
                iconColor: const Color(0xFF1FA971),
              ),
              _buildMetricCard(
                title: 'Monthly Recurring Revenue',
                value: '₹${activeCount * 500}',
                badgeText: '@ ₹500 per restaurant',
                badgeColor: const Color(0xFF4B6BFB),
                icon: Icons.receipt_long_rounded,
                iconBg: const Color(0xFF4B6BFB).withValues(alpha: 0.15),
                iconColor: const Color(0xFF4B6BFB),
              ),
              _buildMetricCard(
                title: 'Expired / Suspended',
                value: '${_restaurants.length - activeCount}',
                badgeText: '10.52% inactive',
                badgeColor: const Color(0xFFEF4444),
                icon: Icons.group_off_rounded,
                iconBg: const Color(0xFFEF4444).withValues(alpha: 0.15),
                iconColor: const Color(0xFFEF4444),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Section Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('All Restaurants', style: TextStyle(color: _textDark, fontSize: 18, fontWeight: FontWeight.w800)),
              GestureDetector(
                onTap: () => _navigateToView(SuperAdminView.restaurantsList),
                child: const Text('View all', style: TextStyle(color: _primaryOrange, fontWeight: FontWeight.w700, fontSize: 13)),
              ),
            ],
          ),
          const SizedBox(height: 12),

          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _restaurants.take(4).length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) => _buildRestaurantTile(_restaurants[index]),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String badgeText,
    required Color badgeColor,
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 1))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: Text(title, style: const TextStyle(color: _textMuted, fontSize: 12, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis)),
              Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(8)), child: Icon(icon, color: iconColor, size: 18)),
            ],
          ),
          Text(value, style: const TextStyle(color: _textDark, fontSize: 22, fontWeight: FontWeight.w900)),
          Text(badgeText, style: TextStyle(color: badgeColor, fontSize: 11, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  // ================= SCREEN 3: RESTAURANTS LIST =================
  Widget _buildRestaurantsListScreen() {
    final filtered = _restaurants.where((r) {
      final matchesSearch = r['name'].toString().toLowerCase().contains(_searchQuery.toLowerCase()) ||
          r['ownerName'].toString().toLowerCase().contains(_searchQuery.toLowerCase());
      if (_restaurantFilterTab == 'Active') return matchesSearch && r['status'] == 'Active';
      if (_restaurantFilterTab == 'Inactive') return matchesSearch && r['status'] != 'Active';
      return matchesSearch;
    }).toList();

    return Column(
      children: [
        Container(
          color: Colors.white,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              SizedBox(
                height: 46,
                child: TextField(
                  onChanged: (val) => setState(() => _searchQuery = val),
                  decoration: InputDecoration(
                    hintText: 'Search restaurant...',
                    prefixIcon: const Icon(Icons.search_rounded, color: _textMuted),
                    filled: true,
                    fillColor: const Color(0xFFF1F5F9),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildTabChip('All (1,248)', 'All'),
                  const SizedBox(width: 8),
                  _buildTabChip('Active (1,112)', 'Active'),
                  const SizedBox(width: 8),
                  _buildTabChip('Inactive (136)', 'Inactive'),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: filtered.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) => _buildRestaurantTile(filtered[index]),
          ),
        ),
      ],
    );
  }

  Widget _buildTabChip(String label, String value) {
    final isSelected = _restaurantFilterTab == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _restaurantFilterTab = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? _primaryOrange : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(label, style: TextStyle(color: isSelected ? Colors.white : _textMuted, fontWeight: isSelected ? FontWeight.bold : FontWeight.w600, fontSize: 12)),
        ),
      ),
    );
  }

  Widget _buildRestaurantTile(Map<String, dynamic> restaurant) {
    final name = restaurant['name'] ?? 'Spice Villa';
    final id = restaurant['id'] ?? 'REST-1024';
    final owner = restaurant['ownerName'] ?? 'Rahul Sharma';
    final status = restaurant['status'] ?? 'Active';
    final isActive = status == 'Active';
    final isSuspended = status == 'Suspended';

    final statusBg = isActive
        ? const Color(0xFF1FA971).withValues(alpha: 0.15)
        : (isSuspended ? const Color(0xFFFFA726).withValues(alpha: 0.15) : const Color(0xFFEF4444).withValues(alpha: 0.15));
    final statusColor = isActive
        ? const Color(0xFF1FA971)
        : (isSuspended ? const Color(0xFFFFA726) : const Color(0xFFEF4444));

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: _primaryOrange.withValues(alpha: 0.15),
            child: const Icon(Icons.restaurant_rounded, color: _primaryOrange, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: GestureDetector(
              onTap: () => _navigateToView(SuperAdminView.restaurantDetails, restaurant: restaurant),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(color: _textDark, fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 2),
                  Text('$id • $owner', style: const TextStyle(color: _textMuted, fontSize: 12)),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: statusBg, borderRadius: BorderRadius.circular(8)),
            child: Text(status, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 11)),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded, color: _textMuted),
            onSelected: (action) {
              if (action == 'details') _navigateToView(SuperAdminView.restaurantDetails, restaurant: restaurant);
              if (action == 'manage') _navigateToView(SuperAdminView.manageSubscription, restaurant: restaurant);
              if (action == 'transactions') _navigateToView(SuperAdminView.transactions, restaurant: restaurant);
              if (action == 'toggle') _updateStatus(restaurant, isActive ? 'Suspended' : 'Active');
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'details', child: Text('Restaurant Details')),
              const PopupMenuItem(value: 'manage', child: Text('Manage Subscription')),
              const PopupMenuItem(value: 'transactions', child: Text('View Transactions')),
              PopupMenuItem(
                value: 'toggle',
                child: Text(
                  isActive ? 'Suspend Restaurant' : 'Activate Restaurant',
                  style: TextStyle(color: isActive ? Colors.red : Colors.green),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ================= SCREEN 4: RESTAURANT DETAILS =================
  Widget _buildRestaurantDetailsView() {
    final res = _selectedRestaurant ?? _restaurants.first;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE2E8F0))),
          child: Row(
            children: [
              const CircleAvatar(radius: 26, backgroundColor: _primaryOrange, child: Icon(Icons.restaurant_rounded, color: Colors.white)),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(res['name'] ?? 'Spice Villa', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text(res['id'] ?? 'REST-1024', style: const TextStyle(color: _textMuted, fontSize: 12)),
                ],
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: const Color(0xFF1FA971).withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                child: const Text('Active', style: TextStyle(color: Color(0xFF1FA971), fontWeight: FontWeight.bold, fontSize: 11)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE2E8F0))),
          child: Column(
            children: [
              _detailRow('Owner', res['ownerName'] ?? 'Rahul Sharma'),
              const Divider(height: 20),
              _detailRow('Contact', res['phone'] ?? '9876543210'),
              const Divider(height: 20),
              _detailRow('Email', res['email'] ?? 'rahul@spicevilla.com'),
              const Divider(height: 20),
              _detailRow('Plan', 'Basic Plan (₹500/mo)'),
              const Divider(height: 20),
              _detailRow('Renewal Date', '31 May 2025 (2 days left)'),
              const Divider(height: 20),
              _detailRow('Joined On', '15 Jan 2025'),
            ],
          ),
        ),
        const SizedBox(height: 16),

        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1FA971).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF1FA971).withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text('Subscription Status', style: TextStyle(color: _textDark, fontWeight: FontWeight.bold)),
              SizedBox(height: 4),
              Text('Active - This subscription is active and valid.', style: TextStyle(color: Color(0xFF1FA971), fontSize: 12, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
        const SizedBox(height: 16),

        _actionTile(Icons.card_membership_rounded, 'Manage Subscription', () => _navigateToView(SuperAdminView.manageSubscription, restaurant: res)),
        _actionTile(Icons.receipt_long_rounded, 'View Transactions', () => _navigateToView(SuperAdminView.transactions, restaurant: res)),
        ListTile(
          onTap: () => _updateStatus(res, 'Suspended'),
          leading: const Icon(Icons.block_rounded, color: Colors.red),
          title: const Text('Suspend Restaurant', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _detailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: _textMuted, fontSize: 13)),
        Text(value, style: const TextStyle(color: _textDark, fontWeight: FontWeight.bold, fontSize: 13)),
      ],
    );
  }

  Widget _actionTile(IconData icon, String title, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: ListTile(
        leading: Icon(icon, color: _primaryOrange),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        trailing: const Icon(Icons.chevron_right_rounded, color: _textMuted),
        onTap: onTap,
      ),
    );
  }

  // ================= SCREEN 5: MANAGE SUBSCRIPTION =================
  Widget _buildManageSubscriptionView() {
    final res = _selectedRestaurant ?? _restaurants.first;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE2E8F0))),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(res['name'] ?? 'Spice Villa', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: const Color(0xFF1FA971).withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
                    child: const Text('Active', style: TextStyle(color: Color(0xFF1FA971), fontWeight: FontWeight.bold, fontSize: 11)),
                  ),
                ],
              ),
              const Divider(height: 20),
              _detailRow('Current Plan', '₹500 / month'),
              const SizedBox(height: 8),
              _detailRow('Renewal Date', '31 May 2025 (2 days left)'),
              const SizedBox(height: 8),
              _detailRow('Payment Method', 'VISA **** 4242'),
            ],
          ),
        ),
        const SizedBox(height: 20),

        const Text('Subscription Actions', style: TextStyle(color: _textDark, fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),

        _subActionTile(icon: Icons.play_circle_fill_rounded, color: Colors.green, title: 'Activate Subscription', subtitle: 'Make this subscription active', onTap: () => _updateStatus(res, 'Active')),
        _subActionTile(icon: Icons.pause_circle_filled_rounded, color: Colors.orange, title: 'Suspend Subscription', subtitle: 'Pause this subscription', onTap: () => _updateStatus(res, 'Suspended')),
        _subActionTile(icon: Icons.calendar_month_rounded, color: Colors.purple, title: 'Extend Subscription', subtitle: 'Extend subscription period', onTap: () => _navigateToView(SuperAdminView.extendSubscription, restaurant: res)),
        _subActionTile(icon: Icons.cancel_rounded, color: Colors.red, title: 'Cancel Subscription', subtitle: 'Cancel this subscription', onTap: () => _updateStatus(res, 'Cancelled')),
      ],
    );
  }

  Widget _subActionTile({required IconData icon, required Color color, required String title, required String subtitle, required VoidCallback onTap}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: ListTile(
        leading: Icon(icon, color: color, size: 28),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: _textMuted)),
        trailing: const Icon(Icons.chevron_right_rounded, color: _textMuted),
        onTap: onTap,
      ),
    );
  }

  // ================= SCREEN 6: EXTEND SUBSCRIPTION =================
  Widget _buildExtendSubscriptionView() {
    final res = _selectedRestaurant ?? _restaurants.first;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE2E8F0))),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(res['name'] ?? 'Spice Villa', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              _detailRow('Current Plan', 'Basic Plan (₹500/month)'),
              const SizedBox(height: 4),
              _detailRow('Current Renewal Date', '31 May 2025'),
            ],
          ),
        ),
        const SizedBox(height: 20),

        const Text('Extend By', style: TextStyle(color: _textDark, fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),

        _buildExtendOption(1, '1 Month (+ ₹500)', _selectedExtendMonths, (val) => setState(() => _selectedExtendMonths = val)),
        const SizedBox(height: 8),
        _buildExtendOption(3, '3 Months (+ ₹1,500)', _selectedExtendMonths, (val) => setState(() => _selectedExtendMonths = val)),
        const SizedBox(height: 8),
        _buildExtendOption(6, '6 Months (+ ₹3,000)', _selectedExtendMonths, (val) => setState(() => _selectedExtendMonths = val)),
        const SizedBox(height: 8),
        _buildExtendOption(12, '12 Months (+ ₹6,000)', _selectedExtendMonths, (val) => setState(() => _selectedExtendMonths = val)),
        const SizedBox(height: 20),

        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(12)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text('New Renewal Date', style: TextStyle(color: _textMuted, fontSize: 13)),
              Text('30 Jun 2025', style: TextStyle(color: _textDark, fontWeight: FontWeight.bold, fontSize: 14)),
            ],
          ),
        ),
        const SizedBox(height: 24),

        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _primaryOrange, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('🎉 Subscription extended by $_selectedExtendMonths Month(s)!'), backgroundColor: const Color(0xFF1FA971)),
              );
              _navigateToView(SuperAdminView.dashboard);
            },
            child: const Text('Extend Subscription', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }

  Widget _buildExtendOption(int value, String title, int selected, ValueChanged<int> onTap) {
    final isSelected = value == selected;
    return GestureDetector(
      onTap: () => onTap(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? _primaryOrange.withValues(alpha: 0.1) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? _primaryOrange : const Color(0xFFE2E8F0), width: isSelected ? 2 : 1),
        ),
        child: Row(
          children: [
            Icon(isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded, color: isSelected ? _primaryOrange : _textMuted, size: 20),
            const SizedBox(width: 12),
            Text(title, style: TextStyle(color: _textDark, fontWeight: isSelected ? FontWeight.bold : FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  // ================= SCREEN 7: TRANSACTIONS =================
  Widget _buildTransactionsView() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE2E8F0))),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Column(
                children: const [
                  Text('Total Paid', style: TextStyle(color: _textMuted, fontSize: 12)),
                  SizedBox(height: 4),
                  Text('₹3,500', style: TextStyle(color: _textDark, fontSize: 20, fontWeight: FontWeight.w900)),
                ],
              ),
              Container(height: 30, width: 1, color: const Color(0xFFE2E8F0)),
              Column(
                children: const [
                  Text('Total Transactions', style: TextStyle(color: _textMuted, fontSize: 12)),
                  SizedBox(height: 4),
                  Text('7', style: TextStyle(color: _textDark, fontSize: 20, fontWeight: FontWeight.w900)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        const Text('Transaction History', style: TextStyle(color: _textDark, fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),

        ...['May 2025', 'Apr 2025', 'Mar 2025', 'Feb 2025', 'Jan 2025'].map((month) {
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE2E8F0))),
            child: ListTile(
              leading: const Icon(Icons.check_circle_rounded, color: Colors.green),
              title: Text('Subscription - $month'),
              subtitle: Text('01 $month'),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
                child: const Text('₹500 Paid', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 11)),
              ),
            ),
          );
        }),
      ],
    );
  }

  // ================= SCREEN 8: ADD RESTAURANT =================
  Widget _buildAddRestaurantView() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        TextField(controller: _addNameCtrl, decoration: const InputDecoration(labelText: 'Restaurant Name', hintText: 'Enter restaurant name')),
        const SizedBox(height: 14),
        TextField(controller: _addOwnerCtrl, decoration: const InputDecoration(labelText: 'Owner Name', hintText: 'Enter owner name')),
        const SizedBox(height: 14),
        TextField(controller: _addPhoneCtrl, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Contact Number', hintText: 'Enter contact number')),
        const SizedBox(height: 14),
        TextField(controller: _addEmailCtrl, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Email Address', hintText: 'Enter email address')),
        const SizedBox(height: 14),
        DropdownButtonFormField<String>(
          initialValue: _selectedPlan,
          items: const [
            DropdownMenuItem(value: 'Basic Plan (₹500/mo)', child: Text('Basic Plan (₹500/mo)')),
            DropdownMenuItem(value: 'Pro Plan (₹1,000/mo)', child: Text('Pro Plan (₹1,000/mo)')),
          ],
          onChanged: (val) => setState(() => _selectedPlan = val!),
          decoration: const InputDecoration(labelText: 'Plan'),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _primaryOrange, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            onPressed: () {
              if (_addNameCtrl.text.isNotEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('🎉 Restaurant "${_addNameCtrl.text}" added!'), backgroundColor: const Color(0xFF1FA971)),
                );
                _addNameCtrl.clear();
                _addOwnerCtrl.clear();
                _addPhoneCtrl.clear();
                _addEmailCtrl.clear();
                _navigateToView(SuperAdminView.restaurantsList);
              }
            },
            child: const Text('Add Restaurant', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }

  // ================= SCREEN 9: PROFILE =================
  Widget _buildProfileView() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFE2E8F0))),
          child: Row(
            children: [
              const CircleAvatar(radius: 28, backgroundColor: _primaryOrange, child: Icon(Icons.person_rounded, color: Colors.white, size: 32)),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('Super Admin', style: TextStyle(color: _textDark, fontSize: 18, fontWeight: FontWeight.bold)),
                  SizedBox(height: 2),
                  Text('superadmin@restohub.com', style: TextStyle(color: _textMuted, fontSize: 12)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _profileTile(Icons.person_outline_rounded, 'Profile Information'),
        _profileTile(Icons.lock_outline_rounded, 'Change Password'),
        _profileTile(Icons.notifications_none_rounded, 'Notification Settings'),
        _profileTile(Icons.shield_outlined, 'Security'),
        _profileTile(Icons.help_outline_rounded, 'Help & Support'),
        const Divider(height: 24),
        ListTile(
          onTap: () async {
            await LocalStorage.clearToken();
            if (mounted) context.go('/login');
          },
          leading: const Icon(Icons.logout_rounded, color: Colors.red),
          title: const Text('Logout', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _profileTile(IconData icon, String title) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: ListTile(
        leading: Icon(icon, color: _textDark),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        trailing: const Icon(Icons.chevron_right_rounded, color: _textMuted),
        onTap: () {},
      ),
    );
  }

  // ================= BOTTOM NAVIGATION BAR (MOBILE) =================
  Widget _buildBottomNavBar() {
    return BottomNavigationBar(
      currentIndex: _bottomNavIndex,
      onTap: (index) {
        if (index == 0) _navigateToView(SuperAdminView.dashboard);
        if (index == 1) _navigateToView(SuperAdminView.restaurantsList);
        if (index == 2) _navigateToView(SuperAdminView.manageSubscription);
        if (index == 3) _navigateToView(SuperAdminView.profile);
      },
      selectedItemColor: _primaryOrange,
      unselectedItemColor: _textMuted,
      showUnselectedLabels: true,
      type: BottomNavigationBarType.fixed,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.space_dashboard_rounded), label: 'Dashboard'),
        BottomNavigationBarItem(icon: Icon(Icons.storefront_rounded), label: 'Restaurants'),
        BottomNavigationBarItem(icon: Icon(Icons.card_membership_rounded), label: 'Subscriptions'),
        BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'Profile'),
      ],
    );
  }
}
