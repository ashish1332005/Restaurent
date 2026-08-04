import 'package:hive/hive.dart';

class LocalStorage {
  static const String _boxName = 'app_preferences';
  static const String _tokenKey = 'jwt_token';
  static const String _roleKey = 'user_role';
  static const String _lastCustomerOrderKey = 'last_customer_order';
  static const String _customerOrderHistoryKey = 'customer_order_history';
  static const String _customerProfileKey = 'customer_profile';
  static const String _subscriptionKey = 'saas_subscription';
  static const String _staffListKey = 'staff_members_list';

  static Future<void> init() async {
    await Hive.openBox(_boxName);
  }

  static Future<void> saveToken(String token) async {
    final box = Hive.box(_boxName);
    await box.put(_tokenKey, token);
  }

  static Future<void> saveRole(String role) async {
    await Hive.box(_boxName).put(_roleKey, role);
  }

  static String? getRole() => Hive.box(_boxName).get(_roleKey) as String?;

  static String? getToken() {
    final box = Hive.box(_boxName);
    return box.get(_tokenKey);
  }

  static Future<void> saveLastCustomerOrder(
    List<Map<String, dynamic>> items,
  ) async {
    await Hive.box(_boxName).put(_lastCustomerOrderKey, items);
  }

  static List<Map<String, dynamic>> getLastCustomerOrder() {
    final value = Hive.box(_boxName).get(_lastCustomerOrderKey);
    if (value is! List) return const [];
    return value
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList(growable: false);
  }

  static Future<void> saveCustomerOrderHistory(
    List<Map<String, dynamic>> orders,
  ) async {
    await Hive.box(_boxName).put(_customerOrderHistoryKey, orders);
  }

  static List<Map<String, dynamic>> getCustomerOrderHistory() {
    final value = Hive.box(_boxName).get(_customerOrderHistoryKey);
    if (value is! List) return const [];
    return value
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList(growable: false);
  }

  static Future<void> saveCustomerProfile(Map<String, dynamic> profile) async {
    await Hive.box(_boxName).put(_customerProfileKey, profile);
  }

  static Map<String, dynamic>? getCustomerProfile() {
    final value = Hive.box(_boxName).get(_customerProfileKey);
    if (value is! Map) return null;
    return Map<String, dynamic>.from(value);
  }

  static Future<void> saveSubscriptionStatus({
    required bool isActive,
    String planName = 'Enterprise Pro',
    int price = 500,
  }) async {
    final box = Hive.box(_boxName);
    final expiry = DateTime.now().add(const Duration(days: 30)).toIso8601String();
    await box.put(_subscriptionKey, {
      'isActive': isActive,
      'planName': planName,
      'price': price,
      'expiry': expiry,
      'activatedAt': DateTime.now().toIso8601String(),
    });
  }

  static bool isSubscriptionActive() {
    final box = Hive.box(_boxName);
    final data = box.get(_subscriptionKey);
    if (data is Map) {
      return data['isActive'] == true;
    }
    // Default for existing session/demo admin accounts
    return false;
  }

  static Map<String, dynamic>? getSubscriptionDetails() {
    final box = Hive.box(_boxName);
    final value = box.get(_subscriptionKey);
    if (value is! Map) return null;
    return Map<String, dynamic>.from(value);
  }

  static Future<void> saveStaffList(List<Map<String, dynamic>> staffList) async {
    final box = Hive.box(_boxName);
    await box.put(_staffListKey, staffList);
  }

  static List<Map<String, dynamic>> getStaffList() {
    final box = Hive.box(_boxName);
    final value = box.get(_staffListKey);
    if (value is! List) {
      // Default initial mock staff list if empty
      final initialList = [
        {
          'id': 'st_01',
          'name': 'Michael Scott',
          'phone': '9876543210',
          'password': '123456',
          'role': 'Manager',
          'shift': 'Morning',
          'status': 'Active',
          'createdAt': DateTime.now().toIso8601String(),
        },
        {
          'id': 'st_02',
          'name': 'Jim Halpert',
          'phone': '9876543211',
          'password': '123456',
          'role': 'Waiter',
          'shift': 'Evening',
          'status': 'Active',
          'createdAt': DateTime.now().toIso8601String(),
        },
        {
          'id': 'st_03',
          'name': 'Pam Beesly',
          'phone': '9876543212',
          'password': '123456',
          'role': 'Cashier',
          'shift': 'Morning',
          'status': 'Active',
          'createdAt': DateTime.now().toIso8601String(),
        },
        {
          'id': 'st_04',
          'name': 'Dwight Schrute',
          'phone': '9876543213',
          'password': '123456',
          'role': 'Kitchen',
          'shift': 'Full Day',
          'status': 'Active',
          'createdAt': DateTime.now().toIso8601String(),
        },
      ];
      box.put(_staffListKey, initialList);
      return initialList;
    }
    return value
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  static Future<void> addStaffMember(Map<String, dynamic> staff) async {
    final list = getStaffList().toList();
    list.insert(0, staff);
    await saveStaffList(list);
  }

  static Future<void> updateStaffMember(String id, Map<String, dynamic> updated) async {
    final list = getStaffList().map((item) {
      if (item['id'] == id) {
        return {...item, ...updated};
      }
      return item;
    }).toList();
    await saveStaffList(list);
  }

  static Future<void> deleteStaffMember(String id) async {
    final list = getStaffList().where((item) => item['id'] != id).toList();
    await saveStaffList(list);
  }

  static const String _superAdminPlatformKey = 'super_admin_restaurants';
  static const String _liveOrdersKey = 'live_restaurant_orders';

  static Map<String, dynamic>? findStaffByCredentials(String phone, String password) {
    final list = getStaffList();
    for (final staff in list) {
      if (staff['phone'] == phone && staff['password'] == password) {
        return staff;
      }
    }
    return null;
  }

  static List<Map<String, dynamic>> getSuperAdminRestaurants() {
    final box = Hive.box(_boxName);
    final value = box.get(_superAdminPlatformKey);
    if (value is! List) {
      final initialList = [
        {
          'id': 'rest_001',
          'name': 'The Royal Spices Restaurant',
          'ownerName': 'Ashish Sharma',
          'phone': '9876543210',
          'email': 'owner@royalspices.com',
          'plan': 'Enterprise Pro (₹500/mo)',
          'status': 'Active', // Active, Pending Payment, Suspended
          'totalOrders': 1420,
          'totalRevenue': 425000,
          'joinedDate': '2026-01-15',
          'activeStaff': 18,
        },
        {
          'id': 'rest_002',
          'name': 'Bistro Cafe & Bistro',
          'ownerName': 'Rajesh Gupta',
          'phone': '9811223344',
          'email': 'contact@bistrocafe.com',
          'plan': 'Enterprise Pro (₹500/mo)',
          'status': 'Active',
          'totalOrders': 890,
          'totalRevenue': 267000,
          'joinedDate': '2026-03-01',
          'activeStaff': 12,
        },
        {
          'id': 'rest_003',
          'name': 'Spice Garden Fine Dine',
          'ownerName': 'Ananya Verma',
          'phone': '9822334455',
          'email': 'ananya@spicegarden.in',
          'plan': 'Enterprise Pro (₹500/mo)',
          'status': 'Pending Payment',
          'totalOrders': 310,
          'totalRevenue': 93000,
          'joinedDate': '2026-06-10',
          'activeStaff': 6,
        },
        {
          'id': 'rest_004',
          'name': 'Ocean Catch Seafood',
          'ownerName': 'Vikram Singh',
          'phone': '9833445566',
          'email': 'vikram@oceancatch.com',
          'plan': 'Enterprise Pro (₹500/mo)',
          'status': 'Suspended',
          'totalOrders': 150,
          'totalRevenue': 45000,
          'joinedDate': '2026-05-20',
          'activeStaff': 4,
        },
      ];
      box.put(_superAdminPlatformKey, initialList);
      return initialList;
    }
    return value
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  static Future<void> updateRestaurantSubscriptionStatus(String id, String newStatus) async {
    final box = Hive.box(_boxName);
    final list = getSuperAdminRestaurants().map((r) {
      if (r['id'] == id) {
        return {...r, 'status': newStatus};
      }
      return r;
    }).toList();
    await box.put(_superAdminPlatformKey, list);
  }

  static Future<void> saveActiveOrders(List<Map<String, dynamic>> orders) async {
    final box = Hive.box(_boxName);
    await box.put(_liveOrdersKey, orders);
  }

  static List<Map<String, dynamic>> getActiveOrders() {
    final box = Hive.box(_boxName);
    final value = box.get(_liveOrdersKey);
    if (value is! List) {
      final initialOrders = [
        {
          'id': 'ORD-101',
          'tableNo': 'T-04',
          'waiterName': 'Jim Halpert',
          'items': [
            {'name': 'Paneer Butter Masala', 'qty': 2, 'price': 280},
            {'name': 'Butter Naan', 'qty': 4, 'price': 45},
            {'name': 'Mango Lassi', 'qty': 2, 'price': 90},
          ],
          'total': 800,
          'status': 'Preparing', // Pending, Preparing, Ready, Served, Completed, Cancelled
          'paymentStatus': 'Unpaid',
          'notes': 'Extra butter on naan',
          'createdAt': DateTime.now().subtract(const Duration(minutes: 12)).toIso8601String(),
        },
        {
          'id': 'ORD-102',
          'tableNo': 'T-07',
          'waiterName': 'Jim Halpert',
          'items': [
            {'name': 'Chicken Biryani', 'qty': 2, 'price': 320},
            {'name': 'Cold Coffee', 'qty': 2, 'price': 120},
          ],
          'total': 880,
          'status': 'Ready',
          'paymentStatus': 'Bill Requested',
          'notes': 'Spicy Biryani',
          'createdAt': DateTime.now().subtract(const Duration(minutes: 25)).toIso8601String(),
        },
        {
          'id': 'ORD-103',
          'tableNo': 'T-02',
          'waiterName': 'Michael Scott',
          'items': [
            {'name': 'Margherita Pizza', 'qty': 1, 'price': 350},
            {'name': 'Garlic Bread', 'qty': 1, 'price': 150},
          ],
          'total': 500,
          'status': 'Pending',
          'paymentStatus': 'Unpaid',
          'notes': 'Cheese burst',
          'createdAt': DateTime.now().subtract(const Duration(minutes: 4)).toIso8601String(),
        },
      ];
      box.put(_liveOrdersKey, initialOrders);
      return initialOrders;
    }
    return value
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  static Future<void> createLiveOrder(Map<String, dynamic> order) async {
    final list = getActiveOrders().toList();
    list.insert(0, order);
    await saveActiveOrders(list);
  }

  static Future<void> updateLiveOrderStatus(String orderId, String status) async {
    final list = getActiveOrders().map((order) {
      if (order['id'] == orderId) {
        return {...order, 'status': status};
      }
      return order;
    }).toList();
    await saveActiveOrders(list);
  }

  static Future<void> settleOrderPayment(String orderId, String paymentMode) async {
    final list = getActiveOrders().map((order) {
      if (order['id'] == orderId) {
        return {
          ...order,
          'paymentStatus': 'Paid',
          'paymentMode': paymentMode,
          'status': 'Completed',
          'paidAt': DateTime.now().toIso8601String(),
        };
      }
      return order;
    }).toList();
    await saveActiveOrders(list);
  }

  static Future<void> clearToken() async {
    final box = Hive.box(_boxName);
    await box.delete(_tokenKey);
    await box.delete(_roleKey);
    await box.delete(_lastCustomerOrderKey);
    await box.delete(_customerOrderHistoryKey);
    await box.delete(_customerProfileKey);
  }
}
