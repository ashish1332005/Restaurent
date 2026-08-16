import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
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
  static const String _restaurantDetailsKey = 'restaurant_details';
  static const String _inventoryItemsKey = 'simple_inventory_items';
  static const String _qrCustomerLedgerKey = 'qr_customer_ledger';
  static const String _publishedMenuItemsKey = 'published_menu_items';
  static const String _menuBrandingKey = 'published_menu_branding';
  static const String _restaurantTablesKey = 'restaurant_tables';
  static const String _customerTableSessionKey = 'customer_table_session';

  static Future<void> init() async {
    await Hive.openBox(_boxName);
  }

  static Map<String, dynamic> createPasswordCredential(String password) {
    final saltBytes = List<int>.generate(
      16,
      (_) => Random.secure().nextInt(256),
    );
    final salt = base64UrlEncode(saltBytes);
    return {
      'passwordSalt': salt,
      'passwordHash': _hashPassword(password, salt),
    };
  }

  static bool verifyPassword({
    required String password,
    required String? salt,
    required String? hash,
  }) {
    if (password.isEmpty ||
        salt == null ||
        salt.isEmpty ||
        hash == null ||
        hash.isEmpty) {
      return false;
    }
    return _hashPassword(password, salt) == hash;
  }

  static String _hashPassword(String password, String salt) {
    return sha256.convert(utf8.encode('$salt:$password')).toString();
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
    String? expiresAt,
  }) async {
    final box = Hive.box(_boxName);
    await box.put(_subscriptionKey, {
      'isActive': isActive,
      'planName': planName,
      'price': price,
      'expiry': expiresAt,
      'activatedAt': DateTime.now().toIso8601String(),
    });
  }

  static bool isSubscriptionActive() {
    final data = Hive.box(_boxName).get(_subscriptionKey);
    if (data is! Map || data['isActive'] != true) return false;
    final expiry = DateTime.tryParse('${data['expiry'] ?? ''}');
    return expiry == null || expiry.isAfter(DateTime.now());
  }

  static Map<String, dynamic>? getSubscriptionDetails() {
    final box = Hive.box(_boxName);
    final value = box.get(_subscriptionKey);
    if (value is! Map) return null;
    return Map<String, dynamic>.from(value);
  }

  static Future<void> saveStaffList(
    List<Map<String, dynamic>> staffList,
  ) async {
    final box = Hive.box(_boxName);
    await box.put(_staffListKey, staffList);
  }

  static List<Map<String, dynamic>> getStaffList() {
    final box = Hive.box(_boxName);
    final value = box.get(_staffListKey);
    if (value is! List) {
      const initialList = <Map<String, dynamic>>[];
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

  static Future<void> updateStaffMember(
    String id,
    Map<String, dynamic> updated,
  ) async {
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

  static Map<String, dynamic>? findOwnerByCredentials(
    String phone,
    String password,
  ) {
    final restaurant = getRestaurantDetails();
    final ownerPhone =
        restaurant['phone']?.toString().replaceAll(RegExp(r'\D'), '') ?? '';
    final salt = (restaurant['adminPasswordSalt'] ?? restaurant['passwordSalt'])
        ?.toString();
    final hash = (restaurant['adminPasswordHash'] ?? restaurant['passwordHash'])
        ?.toString();
    if (ownerPhone == phone &&
        verifyPassword(password: password, salt: salt, hash: hash)) {
      return restaurant;
    }
    return null;
  }

  static Map<String, dynamic>? findStaffByCredentials(
    String phone,
    String password,
  ) {
    final list = getStaffList();
    for (final staff in list) {
      final staffPhone =
          staff['phone']?.toString().replaceAll(RegExp(r'\D'), '') ?? '';
      final salt = staff['passwordSalt']?.toString();
      final hash = staff['passwordHash']?.toString();
      if (staffPhone == phone &&
          verifyPassword(password: password, salt: salt, hash: hash)) {
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
          'plan': 'Enterprise Pro (Rs. 500/mo)',
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
          'plan': 'Enterprise Pro (Rs. 500/mo)',
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
          'plan': 'Enterprise Pro (Rs. 500/mo)',
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
          'plan': 'Enterprise Pro (Rs. 500/mo)',
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

  static Future<void> updateRestaurantSubscriptionStatus(
    String id,
    String newStatus,
  ) async {
    final box = Hive.box(_boxName);
    final list = getSuperAdminRestaurants().map((r) {
      if (r['id'] == id) {
        return {...r, 'status': newStatus};
      }
      return r;
    }).toList();
    await box.put(_superAdminPlatformKey, list);
  }

  static Future<void> saveActiveOrders(
    List<Map<String, dynamic>> orders,
  ) async {
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
          'status':
              'Preparing', // Pending, Preparing, Ready, Served, Completed, Cancelled
          'paymentStatus': 'Unpaid',
          'notes': 'Extra butter on naan',
          'createdAt': DateTime.now()
              .subtract(const Duration(minutes: 12))
              .toIso8601String(),
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
          'createdAt': DateTime.now()
              .subtract(const Duration(minutes: 25))
              .toIso8601String(),
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
          'createdAt': DateTime.now()
              .subtract(const Duration(minutes: 4))
              .toIso8601String(),
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

  static Future<void> updateLiveOrderStatus(
    String orderId,
    String status,
  ) async {
    final list = getActiveOrders().map((order) {
      if (order['id'] == orderId) {
        return {...order, 'status': status};
      }
      return order;
    }).toList();
    await saveActiveOrders(list);
  }

  static Future<void> settleOrderPayment(
    String orderId,
    String paymentMode,
  ) async {
    String? paidTableCode;
    final list = getActiveOrders().map((order) {
      if (order['id'] == orderId) {
        paidTableCode = order['tableNo']?.toString();
        return {
          ...order,
          'paymentStatus': 'Paid',
          'paymentMode': paymentMode,
          'status': 'Completed',
          'paidAt': DateTime.now().toIso8601String(),
          'sessionClosed': true,
        };
      }
      return order;
    }).toList();
    await saveActiveOrders(list);
    if (paidTableCode != null) {
      final normalized = paidTableCode!
          .replaceAll(RegExp(r'table', caseSensitive: false), '')
          .replaceAll(RegExp(r'[^0-9A-Za-z-]'), '')
          .replaceFirst(RegExp(r'^T'), '');
      final tables = getRestaurantTables().map((table) {
        final tableName =
            table['name']?.toString().replaceFirst(RegExp(r'^T'), '') ?? '';
        if (tableName.toLowerCase() == normalized.toLowerCase()) {
          return {...table, 'status': 'Available'};
        }
        return table;
      }).toList();
      await saveRestaurantTables(tables);
    }
  }

  static List<Map<String, dynamic>> getRestaurantTables() {
    final box = Hive.box(_boxName);
    final value = box.get(_restaurantTablesKey);
    if (value is List) {
      return value
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    }
    final initial = [
      {'name': '01', 'capacity': 2, 'status': 'Available', 'shape': 'square'},
      {'name': '02', 'capacity': 4, 'status': 'Available', 'shape': 'square'},
      {'name': '03', 'capacity': 4, 'status': 'Occupied', 'shape': 'square'},
      {'name': '04', 'capacity': 6, 'status': 'Reserved', 'shape': 'circle'},
      {'name': '05', 'capacity': 2, 'status': 'Available', 'shape': 'circle'},
      {'name': '06', 'capacity': 4, 'status': 'Occupied', 'shape': 'square'},
      {'name': '07', 'capacity': 6, 'status': 'Available', 'shape': 'square'},
      {'name': '08', 'capacity': 8, 'status': 'Available', 'shape': 'round'},
    ];
    box.put(_restaurantTablesKey, initial);
    return initial;
  }

  static Future<void> saveRestaurantTables(
    List<Map<String, dynamic>> tables,
  ) async {
    await Hive.box(_boxName).put(_restaurantTablesKey, tables);
  }

  static String _safeRestaurantName(dynamic value) {
    final name = value?.toString().trim() ?? '';
    const demoNames = {
      'The Royal Spices',
      'The Royal Spices Restaurant',
      'Sharma Restaurant',
      'Dhanop Maa Caterers',
    };
    if (name.isEmpty || demoNames.contains(name)) {
      return 'Restaurant Workspace';
    }
    return name;
  }

  static Future<void> saveRestaurantDetails(
    Map<String, dynamic> details,
  ) async {
    final box = Hive.box(_boxName);
    await box.put(_restaurantDetailsKey, details);
  }

  static Map<String, dynamic> getRestaurantDetails() {
    final box = Hive.box(_boxName);
    final value = box.get(_restaurantDetailsKey);
    if (value is Map) {
      final details = Map<String, dynamic>.from(value);
      final name = _safeRestaurantName(details['name']);
      return {...details, 'name': name};
    }
    return {
      'name': 'Restaurant Workspace',
      'ownerName': 'Owner',
      'phone': '',
      'email': '',
      'address': 'Add restaurant address',
      'latitude': 25.3478,
      'longitude': 74.6367,
      'allowedOrderRadius': 100.0,
      'gstNumber': '',
      'logo': '',
      'openingTime': '09:00 AM',
      'closingTime': '11:00 PM',
      'plan': 'Trial Setup',
      'status': 'Setup Required',
    };
  }

  static Map<String, dynamic> getMenuBranding() {
    final value = Hive.box(_boxName).get(_menuBrandingKey);
    final restaurant = getRestaurantDetails();
    if (value is Map) {
      return {
        'restaurantName': _safeRestaurantName(restaurant['name']),
        'logoUrl': restaurant['logo'] ?? '',
        'primaryColorHex': '#D9A328',
        ...Map<String, dynamic>.from(value),
      };
    }
    return {
      'restaurantName': _safeRestaurantName(restaurant['name']),
      'tagline': 'Fresh food, faster service',
      'logoUrl': restaurant['logo'] ?? '',
      'primaryColorHex': '#D9A328',
      'template': 'classic',
    };
  }

  static Future<void> saveMenuBranding(Map<String, dynamic> branding) async {
    await Hive.box(
      _boxName,
    ).put(_menuBrandingKey, {...getMenuBranding(), ...branding});
  }

  static List<Map<String, dynamic>> getPublishedMenuItems() {
    final box = Hive.box(_boxName);
    final value = box.get(_publishedMenuItemsKey);
    if (value is List) {
      return value
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    }
    final initial = [
      {
        'id': 'menu_1',
        'name': 'Paneer Butter Masala',
        'category': 'Main Course',
        'description': 'Creamy tomato gravy with soft paneer cubes.',
        'price': 280.0,
        'imageUrl': '',
        'isVeg': true,
        'isAvailable': true,
      },
      {
        'id': 'menu_2',
        'name': 'Chicken Biryani',
        'category': 'Main Course',
        'description': 'Aromatic dum biryani served with raita.',
        'price': 320.0,
        'imageUrl': '',
        'isVeg': false,
        'isAvailable': true,
      },
      {
        'id': 'menu_3',
        'name': 'Garlic Naan',
        'category': 'Breads',
        'description': 'Tandoor naan with garlic butter.',
        'price': 70.0,
        'imageUrl': '',
        'isVeg': true,
        'isAvailable': true,
      },
      {
        'id': 'menu_4',
        'name': 'Cold Coffee',
        'category': 'Drinks',
        'description': 'Chilled cafe-style coffee.',
        'price': 120.0,
        'imageUrl': '',
        'isVeg': true,
        'isAvailable': true,
      },
    ];
    box.put(_publishedMenuItemsKey, initial);
    return initial;
  }

  static Future<void> savePublishedMenuItems(
    List<Map<String, dynamic>> items,
  ) async {
    await Hive.box(_boxName).put(_publishedMenuItemsKey, items);
  }

  static Future<void> upsertPublishedMenuItem(Map<String, dynamic> item) async {
    final items = getPublishedMenuItems().toList();
    final id =
        item['id']?.toString() ??
        'menu_${DateTime.now().millisecondsSinceEpoch}';
    final normalized = {
      'id': id,
      'name': item['name'] ?? 'Menu item',
      'category': item['category'] ?? 'Main Course',
      'description': item['description'] ?? '',
      'price': (item['price'] as num?)?.toDouble() ?? 0.0,
      'imageUrl': item['imageUrl'] ?? '',
      'isVeg': item['isVeg'] != false,
      'isAvailable': item['isAvailable'] != false,
    };
    final index = items.indexWhere((row) => row['id'] == id);
    if (index == -1) {
      items.insert(0, normalized);
    } else {
      items[index] = {...items[index], ...normalized};
    }
    await savePublishedMenuItems(items);
  }

  static List<Map<String, dynamic>> getInventoryItems() {
    final box = Hive.box(_boxName);
    final value = box.get(_inventoryItemsKey);
    if (value is List) {
      return value
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    }
    final initial = [
      {
        'id': 'inv_1',
        'name': 'Paneer',
        'category': 'Dairy',
        'stock': 8.0,
        'unit': 'kg',
        'low': 3.0,
        'supplier': 'Local Dairy',
      },
      {
        'id': 'inv_2',
        'name': 'Rice',
        'category': 'Grains',
        'stock': 18.0,
        'unit': 'kg',
        'low': 10.0,
        'supplier': 'Metro Foods',
      },
      {
        'id': 'inv_3',
        'name': 'Chicken',
        'category': 'Meat',
        'stock': 5.0,
        'unit': 'kg',
        'low': 6.0,
        'supplier': 'Fresh Meat Co',
      },
      {
        'id': 'inv_4',
        'name': 'Cooking Oil',
        'category': 'Grocery',
        'stock': 12.0,
        'unit': 'litre',
        'low': 5.0,
        'supplier': 'Wholesale Mart',
      },
    ];
    box.put(_inventoryItemsKey, initial);
    return initial;
  }

  static Future<void> saveInventoryItems(
    List<Map<String, dynamic>> items,
  ) async {
    await Hive.box(_boxName).put(_inventoryItemsKey, items);
  }

  static Future<void> addInventoryItem(Map<String, dynamic> item) async {
    final items = getInventoryItems().toList();
    items.insert(0, item);
    await saveInventoryItems(items);
  }

  static Future<void> adjustInventoryStock(String id, double delta) async {
    final items = getInventoryItems().map((item) {
      if (item['id'] == id) {
        final current = (item['stock'] as num?)?.toDouble() ?? 0;
        return {
          ...item,
          'stock': (current + delta).clamp(0, 999999).toDouble(),
        };
      }
      return item;
    }).toList();
    await saveInventoryItems(items);
  }

  static Future<void> recordQrCustomerOrder({
    required String name,
    required String phone,
    required String tableNo,
    required List<Map<String, dynamic>> items,
    required double total,
  }) async {
    final box = Hive.box(_boxName);
    final value = box.get(_qrCustomerLedgerKey);
    final list = value is List
        ? value
              .whereType<Map>()
              .map((item) => Map<String, dynamic>.from(item))
              .toList()
        : <Map<String, dynamic>>[];
    final normalizedPhone = phone.replaceAll(RegExp(r'\D'), '');
    list.insert(0, {
      'id': 'cust_${DateTime.now().millisecondsSinceEpoch}',
      'name': name,
      'phone': normalizedPhone,
      'tableNo': tableNo,
      'items': items,
      'total': total,
      'createdAt': DateTime.now().toIso8601String(),
    });
    await box.put(_qrCustomerLedgerKey, list);
  }

  static List<Map<String, dynamic>> getQrCustomerLedger() {
    final value = Hive.box(_boxName).get(_qrCustomerLedgerKey);
    if (value is! List) return const [];
    return value
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  static Map<String, dynamic> getOwnerSalesSummary() {
    final orders = getActiveOrders();
    final customers = getQrCustomerLedger();
    final today = DateTime.now();
    bool sameDay(String? raw) {
      final date = DateTime.tryParse(raw ?? '');
      return date != null &&
          date.year == today.year &&
          date.month == today.month &&
          date.day == today.day;
    }

    final todayOrders = orders
        .where((order) => sameDay(order['createdAt']?.toString()))
        .toList();
    final dailySale = todayOrders.fold<double>(
      0,
      (sum, order) => sum + ((order['total'] as num?)?.toDouble() ?? 0),
    );
    final itemStats = <String, Map<String, dynamic>>{};
    for (final order in orders) {
      final rawItems = order['items'];
      if (rawItems is! List) continue;
      for (final raw in rawItems.whereType<Map>()) {
        final name = raw['name']?.toString() ?? 'Menu item';
        final qty = (raw['qty'] as num?)?.toInt() ?? 1;
        final price = (raw['price'] as num?)?.toDouble() ?? 0;
        final stat = itemStats.putIfAbsent(
          name,
          () => {'name': name, 'qty': 0, 'revenue': 0.0},
        );
        stat['qty'] = (stat['qty'] as int) + qty;
        stat['revenue'] = (stat['revenue'] as double) + qty * price;
      }
    }
    final topItems = itemStats.values.toList()
      ..sort((a, b) => (b['qty'] as int).compareTo(a['qty'] as int));
    final visitsByPhone = <String, Map<String, dynamic>>{};
    for (final customer in customers) {
      final phone = customer['phone']?.toString() ?? '';
      if (phone.isEmpty) continue;
      final stat = visitsByPhone.putIfAbsent(
        phone,
        () => {
          'phone': phone,
          'name': customer['name'] ?? 'Guest',
          'visits': 0,
          'spend': 0.0,
        },
      );
      stat['visits'] = (stat['visits'] as int) + 1;
      stat['spend'] =
          (stat['spend'] as double) +
          ((customer['total'] as num?)?.toDouble() ?? 0);
    }
    final repeatCustomers =
        visitsByPhone.values.where((c) => (c['visits'] as int) > 1).toList()
          ..sort((a, b) => (b['visits'] as int).compareTo(a['visits'] as int));
    return {
      'dailySale': dailySale,
      'todayOrders': todayOrders.length,
      'topItems': topItems.take(5).toList(),
      'repeatCustomers': repeatCustomers.take(5).toList(),
    };
  }

  static Map<String, dynamic>? getCustomerTableSession() {
    final value = Hive.box(_boxName).get(_customerTableSessionKey);
    if (value is! Map) return null;
    return Map<String, dynamic>.from(value);
  }

  static Future<void> saveCustomerTableSession(
    Map<String, dynamic> session,
  ) async => Hive.box(_boxName).put(_customerTableSessionKey, session);

  static Future<void> clearCustomerTableSession() async =>
      Hive.box(_boxName).delete(_customerTableSessionKey);
  static Future<void> clearToken() async {
    final box = Hive.box(_boxName);
    await box.delete(_tokenKey);
    await box.delete(_roleKey);
    await box.delete(_lastCustomerOrderKey);
    await box.delete(_customerOrderHistoryKey);
    await box.delete(_customerProfileKey);
  }
}
