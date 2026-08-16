import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';

import 'api_client.dart';

class RestaurantApi {
  RestaurantApi._();

  static Dio get _client => ApiClient.instance;
  static String mediaUrl(Object? value) {
    final raw = value?.toString().trim() ?? '';
    if (raw.isEmpty || raw == 'no-logo.png') return '';
    final uri = Uri.tryParse(raw);
    if (uri != null && uri.hasScheme) return raw;
    final api = Uri.parse(ApiClient.baseUrl);
    final origin = '${api.scheme}://${api.authority}';
    return raw.startsWith('/') ? '$origin$raw' : '$origin/$raw';
  }

  static Future<String> uploadImage(Uint8List bytes, String fileName) async {
    final extension = fileName.split('.').last.toLowerCase();
    final subtype = extension == 'jpg' ? 'jpeg' : extension;
    if (!['jpeg', 'png', 'webp'].contains(subtype)) {
      throw StateError('Choose a JPEG, PNG or WebP image.');
    }
    if (bytes.length > 3 * 1024 * 1024) {
      throw StateError('Image must be smaller than 3 MB.');
    }
    final response = await _client.post<Map<String, dynamic>>(
      '/uploads/images',
      data: FormData.fromMap({
        'image': MultipartFile.fromBytes(
          bytes,
          filename: fileName,
          contentType: MediaType('image', subtype),
        ),
      }),
    );
    final data = response.data?['data'];
    final url = data is Map ? data['url']?.toString() ?? '' : '';
    if (url.isEmpty) throw StateError('Image upload did not return a URL.');
    return url;
  }

  static Future<Map<String, dynamic>> login(
    String phone,
    String password,
  ) async {
    final response = await _client.post<Map<String, dynamic>>(
      '/auth/login',
      data: {'phone': phone, 'password': password},
    );
    return response.data ?? const {};
  }

  static Future<Map<String, dynamic>> registerCustomer({
    required String name,
    required String phone,
    required String password,
  }) async {
    final response = await _client.post<Map<String, dynamic>>(
      '/auth/register/customer',
      data: {'name': name, 'phone': phone, 'password': password},
    );
    return response.data ?? const {};
  }

  static Future<Map<String, dynamic>> registerRestaurantOwner({
    required String ownerName,
    required String restaurantName,
    required String phone,
    required String email,
    required String password,
    required String address,
  }) async {
    final response = await _client.post<Map<String, dynamic>>(
      '/auth/register/restaurant',
      data: {
        'ownerName': ownerName,
        'restaurantName': restaurantName,
        'phone': phone,
        if (email.isNotEmpty) 'email': email,
        'password': password,
        'address': address,
      },
    );
    return response.data ?? const {};
  }

  static Future<Map<String, dynamic>> loginCustomerWithGoogle({
    String? idToken,
    String? accessToken,
    String? email,
    String? name,
    String? photoUrl,
  }) async {
    final response = await _client.post<Map<String, dynamic>>(
      '/auth/google/customer',
      data: {
        'idToken': idToken,
        'accessToken': accessToken,
        'email': email,
        'name': name,
        'photoUrl': photoUrl,
      },
    );
    return response.data ?? const {};
  }

  static Future<List<Map<String, dynamic>>> getMenuItems({
    String? branchId,
  }) async {
    final response = await _client.get<Map<String, dynamic>>(
      '/menu/items',
      queryParameters: branchId == null ? null : {'branchId': branchId},
    );
    return _records(response.data);
  }

  static Future<List<Map<String, dynamic>>> getBranches(
    String restaurantId,
  ) async {
    final response = await _client.get<Map<String, dynamic>>(
      '/restaurants/$restaurantId/branches',
    );
    return _records(response.data);
  }

  static Future<List<Map<String, dynamic>>> getCategories({
    String? branchId,
  }) async {
    final response = await _client.get<Map<String, dynamic>>(
      '/menu/categories',
      queryParameters: branchId == null ? null : {'branchId': branchId},
    );
    return _records(response.data);
  }

  static Future<Map<String, dynamic>> createCategory(
    Map<String, dynamic> body,
  ) async {
    final response = await _client.post<Map<String, dynamic>>(
      '/menu/categories',
      data: body,
    );
    return Map<String, dynamic>.from(
      response.data?['data'] as Map? ?? const {},
    );
  }

  static Future<void> updateCategory(
    String id,
    Map<String, dynamic> body,
  ) async => _client.patch<void>('/menu/categories/$id', data: body);
  static Future<void> deleteCategory(String id) async =>
      _client.delete<void>('/menu/categories/$id');

  static Future<Map<String, dynamic>> createMenuItem(
    Map<String, dynamic> body,
  ) async {
    final response = await _client.post<Map<String, dynamic>>(
      '/menu/items',
      data: body,
    );
    return Map<String, dynamic>.from(
      response.data?['data'] as Map? ?? const {},
    );
  }

  static Future<void> updateMenuItem(
    String id,
    Map<String, dynamic> body,
  ) async => _client.patch<void>('/menu/items/$id', data: body);
  static Future<void> setMenuItemAvailability(
    String id,
    bool isAvailable,
  ) async => _client.patch<void>(
    '/menu/items/$id/availability',
    data: {'isAvailable': isAvailable},
  );
  static Future<void> deleteMenuItem(String id) async =>
      _client.delete<void>('/menu/items/$id');

  static Future<void> bulkUpdateMenuItems({
    required String branchId,
    required List<String> ids,
    required String action,
    required Object value,
  }) async => _client.patch<void>(
    '/menu/items/bulk',
    data: {'branchId': branchId, 'ids': ids, 'action': action, 'value': value},
  );

  static Future<void> duplicateMenuItem(String id) async =>
      _client.post<void>('/menu/items/$id/duplicate');

  static Future<void> reorderMenuItems(
    String branchId,
    List<Map<String, dynamic>> items,
  ) async => _client.patch<void>(
    '/menu/items/reorder',
    data: {'branchId': branchId, 'items': items},
  );

  static Future<void> reorderCategories(
    String branchId,
    List<Map<String, dynamic>> categories,
  ) async => _client.patch<void>(
    '/menu/categories/reorder',
    data: {'branchId': branchId, 'categories': categories},
  );

  static Future<List<Map<String, dynamic>>> getMenuHistory(
    String branchId, {
    String? itemId,
  }) async {
    final response = await _client.get<Map<String, dynamic>>(
      '/menu/history',
      queryParameters: {
        'branchId': branchId,
        if (itemId != null) 'itemId': itemId,
        'limit': 100,
      },
    );
    return _records(response.data);
  }

  static Future<void> restoreMenuHistory(String historyId) async =>
      _client.post<void>('/menu/history/$historyId/restore');
  static Future<List<Map<String, dynamic>>> getTables({
    String? branchId,
  }) async {
    final response = await _client.get<Map<String, dynamic>>(
      '/tables',
      queryParameters: branchId == null ? null : {'branchId': branchId},
    );
    return _records(response.data);
  }

  static Future<List<Map<String, dynamic>>> getOrders({
    String? status,
    String? branchId,
  }) async {
    final query = <String, dynamic>{
      if (status != null) 'status': status,
      if (branchId != null) 'branchId': branchId,
    };
    final response = await _client.get<Map<String, dynamic>>(
      '/orders',
      queryParameters: query.isEmpty ? null : query,
    );
    return _records(response.data);
  }

  static Future<List<Map<String, dynamic>>> getAvailableCoupons() async {
    final response = await _client.get<Map<String, dynamic>>(
      '/coupons/available',
    );
    return _records(response.data);
  }

  static Future<List<Map<String, dynamic>>> getAdminCoupons() async {
    final response = await _client.get<Map<String, dynamic>>('/coupons');
    return _records(response.data);
  }

  static Future<void> createCoupon(Map<String, dynamic> body) async {
    await _client.post<void>('/coupons', data: body);
  }

  static Future<void> updateCoupon(String id, Map<String, dynamic> body) async {
    await _client.patch<void>('/coupons/$id', data: body);
  }

  static Future<void> deleteCoupon(String id) async {
    await _client.delete<void>('/coupons/$id');
  }

  static Future<Map<String, dynamic>> createOrder(
    Map<String, dynamic> body,
  ) async {
    final response = await _client.post<Map<String, dynamic>>(
      '/orders',
      data: body,
    );
    return Map<String, dynamic>.from(
      response.data?['data'] as Map? ?? const {},
    );
  }

  static Future<Map<String, dynamic>> createBill(
    String orderId,
    Map<String, dynamic> body,
  ) async {
    final response = await _client.post<Map<String, dynamic>>(
      '/orders/$orderId/bill',
      data: body,
    );
    return Map<String, dynamic>.from(
      response.data?['data'] as Map? ?? const {},
    );
  }

  static Future<void> updateOrderStatus(String id, String status) async {
    await _client.patch<void>('/orders/$id/status', data: {'status': status});
  }

  static Future<Map<String, dynamic>> createTable(
    Map<String, dynamic> body,
  ) async {
    final response = await _client.post<Map<String, dynamic>>(
      '/tables',
      data: body,
    );
    return Map<String, dynamic>.from(
      response.data?['data'] as Map? ?? const {},
    );
  }

  static Future<void> updateTable(String id, Map<String, dynamic> body) async =>
      _client.patch<void>('/tables/$id', data: body);
  static Future<void> deleteTable(String id) async =>
      _client.delete<void>('/tables/$id');

  static Future<Map<String, dynamic>> rotateTableQr(String id) async {
    final response = await _client.post<Map<String, dynamic>>(
      '/tables/$id/qr/rotate',
    );
    return Map<String, dynamic>.from(
      response.data?['data'] as Map? ?? const {},
    );
  }

  static Future<void> setTableQrActive(String id, bool isActive) async =>
      _client.patch<void>(
        '/tables/$id/qr/status',
        data: {'isActive': isActive},
      );
  static Future<void> updateTableStatus(String id, String status) async {
    await _client.patch<void>('/tables/$id/status', data: {'status': status});
  }

  static Future<List<Map<String, dynamic>>> getServiceRequests({
    String? branchId,
    String? status,
  }) async {
    final response = await _client.get<Map<String, dynamic>>(
      '/service-requests',
      queryParameters: {
        if (branchId != null) 'branchId': branchId,
        if (status != null) 'status': status,
      },
    );
    return _records(response.data);
  }

  static Future<void> updateServiceRequest(String id, String status) async =>
      _client.patch<void>('/service-requests/$id', data: {'status': status});
  static Future<List<Map<String, dynamic>>> getInventory({
    String? branchId,
  }) async {
    final response = await _client.get<Map<String, dynamic>>(
      '/inventory',
      queryParameters: branchId == null ? null : {'branchId': branchId},
    );
    return _records(response.data);
  }

  static Future<List<Map<String, dynamic>>> getInventoryMovements({
    String? branchId,
  }) async {
    final response = await _client.get<Map<String, dynamic>>(
      '/inventory/movements',
      queryParameters: branchId == null ? null : {'branchId': branchId},
    );
    return _records(response.data);
  }

  static Future<void> updateInventoryStock(Map<String, dynamic> body) async =>
      _client.patch<void>('/inventory', data: body);

  static Future<void> updateMenuRecipe(
    String menuItemId,
    List<Map<String, dynamic>> recipe,
  ) async => _client.patch<void>(
    '/menu/items/$menuItemId/recipe',
    data: {'recipe': recipe},
  );
  static Future<List<Map<String, dynamic>>> getStaffUsers({
    String? branchId,
  }) async {
    final response = await _client.get<Map<String, dynamic>>(
      '/users',
      queryParameters: branchId == null ? null : {'branchId': branchId},
    );
    return _records(response.data);
  }

  static Future<List<Map<String, dynamic>>> getAssignableRoles() async {
    final response = await _client.get<Map<String, dynamic>>(
      '/users/roles/assignable',
    );
    return _records(response.data);
  }

  static Future<void> createStaffUser(Map<String, dynamic> body) async =>
      _client.post<void>('/users', data: body);

  static Future<void> updateStaffUser(
    String id,
    Map<String, dynamic> body,
  ) async => _client.put<void>('/users/$id', data: body);
  static Future<List<Map<String, dynamic>>> getAttendance({
    required String branchId,
    required String date,
  }) async {
    final response = await _client.get<Map<String, dynamic>>(
      '/attendance',
      queryParameters: {'branchId': branchId, 'date': date},
    );
    return _records(response.data);
  }

  static Future<void> scheduleShift(Map<String, dynamic> body) async =>
      _client.post<void>('/attendance', data: body);

  static Future<void> clockAttendance(String id, bool clockIn) async => _client
      .post<void>('/attendance/$id/${clockIn ? 'clock-in' : 'clock-out'}');
  static Future<Map<String, dynamic>> getSalesReport(
    Map<String, dynamic> query,
  ) async {
    final response = await _client.get<Map<String, dynamic>>(
      '/reports/sales',
      queryParameters: query,
    );
    return Map<String, dynamic>.from(
      response.data?['data'] as Map? ?? const {},
    );
  }

  static Future<Map<String, dynamic>> getMenuPerformanceReport(
    Map<String, dynamic> query,
  ) async {
    final response = await _client.get<Map<String, dynamic>>(
      '/reports/menu-performance',
      queryParameters: query,
    );
    return Map<String, dynamic>.from(
      response.data?['data'] as Map? ?? const {},
    );
  }

  static Future<List<Map<String, dynamic>>> getCustomerInsightsReport(
    Map<String, dynamic> query,
  ) async {
    final response = await _client.get<Map<String, dynamic>>(
      '/reports/customers',
      queryParameters: query,
    );
    return _records(response.data);
  }

  static Future<List<Map<String, dynamic>>> getRestaurants() async {
    final response = await _client.get<Map<String, dynamic>>('/restaurants');
    return _records(response.data);
  }

  static Future<void> updateRestaurantSettings(
    String id,
    Map<String, dynamic> body,
  ) async => _client.patch<void>('/restaurants/$id/settings', data: body);

  static Future<void> updateBranchSettings(
    String id,
    Map<String, dynamic> body,
  ) async =>
      _client.patch<void>('/restaurants/branches/$id/settings', data: body);
  static Future<Map<String, dynamic>> getMySubscription() async {
    final response = await _client.get<Map<String, dynamic>>(
      '/payments/subscription',
    );
    return Map<String, dynamic>.from(
      response.data?['data'] as Map? ?? const {},
    );
  }

  static Future<Map<String, dynamic>> createSubscriptionCheckout({
    String provider = 'Manual',
    String paymentMethod = 'Manual',
  }) async {
    final response = await _client.post<Map<String, dynamic>>(
      '/payments/checkout',
      data: {'provider': provider, 'paymentMethod': paymentMethod},
    );
    return Map<String, dynamic>.from(
      response.data?['data'] as Map? ?? const {},
    );
  }

  static Future<bool> checkServerHealth() async {
    final root = ApiClient.baseUrl.replaceFirst(RegExp(r'/api/v1/?$'), '');
    final response = await Dio().get<Map<String, dynamic>>(
      '$root/health',
      options: Options(
        receiveTimeout: const Duration(seconds: 8),
        sendTimeout: const Duration(seconds: 8),
      ),
    );
    return response.statusCode == 200 && response.data?['success'] == true;
  }

  static Future<Map<String, dynamic>> getPlatformSummary() async {
    final response = await _client.get<Map<String, dynamic>>(
      '/platform/summary',
    );
    return Map<String, dynamic>.from(
      response.data?['data'] as Map? ?? const {},
    );
  }

  static Future<Map<String, dynamic>> getPlatformAnalytics() async {
    final response = await _client.get<Map<String, dynamic>>(
      '/platform/analytics',
    );
    return Map<String, dynamic>.from(
      response.data?['data'] as Map? ?? const {},
    );
  }

  static Future<List<Map<String, dynamic>>> getPlatformRestaurants({
    String? search,
    String? status,
  }) async {
    final response = await _client.get<Map<String, dynamic>>(
      '/platform/restaurants',
      queryParameters: {
        'limit': 100,
        if (search != null && search.isNotEmpty) 'search': search,
        if (status != null && status.isNotEmpty) 'status': status,
      },
    );
    return _records(response.data);
  }

  static Future<void> updatePlatformRestaurant(
    String id,
    Map<String, dynamic> body,
  ) async => _client.patch<void>('/platform/restaurants/$id', data: body);
  static Future<Map<String, dynamic>> getCurrentProfile() async {
    final response = await _client.get<Map<String, dynamic>>('/auth/me');
    return Map<String, dynamic>.from(
      response.data?['data'] as Map? ?? const {},
    );
  }

  static Future<Map<String, dynamic>> updateCurrentProfile(
    Map<String, dynamic> body,
  ) async {
    final response = await _client.patch<Map<String, dynamic>>(
      '/auth/me',
      data: body,
    );
    return Map<String, dynamic>.from(
      response.data?['data'] as Map? ?? const {},
    );
  }

  static Future<Map<String, dynamic>?> getDemoProfile(String demoKey) async {
    final response = await _client.get<Map<String, dynamic>>(
      '/auth/demo-profile/$demoKey',
    );
    final data = response.data?['data'];
    if (data is! Map) return null;
    return Map<String, dynamic>.from(data);
  }

  static Future<Map<String, dynamic>> updateDemoProfile(
    String demoKey,
    Map<String, dynamic> body,
  ) async {
    final response = await _client.patch<Map<String, dynamic>>(
      '/auth/demo-profile/$demoKey',
      data: body,
    );
    return Map<String, dynamic>.from(
      response.data?['data'] as Map? ?? const {},
    );
  }

  static Future<Map<String, dynamic>> getQrTable(String code) async {
    final response = await _client.get<Map<String, dynamic>>('/qr/table/$code');
    return Map<String, dynamic>.from(
      response.data?['data'] as Map? ?? const {},
    );
  }

  static Future<Map<String, dynamic>> placeQrOrder(
    String code,
    Map<String, dynamic> body, {
    String? sessionToken,
  }) async {
    final response = await _client.post<Map<String, dynamic>>(
      '/qr/table/$code/order',
      data: body,
      options: Options(
        headers: {
          if (sessionToken != null) 'x-table-session-token': sessionToken,
        },
      ),
    );
    return Map<String, dynamic>.from(
      response.data?['data'] as Map? ?? const {},
    );
  }

  static Future<Map<String, dynamic>> getQrOrderStatus(
    String code,
    String sessionToken,
  ) async {
    final response = await _client.get<Map<String, dynamic>>(
      '/qr/table/$code/order',
      options: Options(headers: {'x-table-session-token': sessionToken}),
    );
    return Map<String, dynamic>.from(
      response.data?['data'] as Map? ?? const {},
    );
  }

  static Future<void> sendQrServiceRequest(
    String code,
    String sessionToken,
    String type, {
    String? paymentMethod,
    String? menuItemId,
    String? dishName,
  }) async {
    await _client.post<void>(
      '/qr/table/$code/request',
      data: {
        'type': type,
        if (paymentMethod != null) 'paymentMethod': paymentMethod,
        if (menuItemId != null) 'menuItemId': menuItemId,
        if (dishName != null) 'dishName': dishName,
      },
      options: Options(headers: {'x-table-session-token': sessionToken}),
    );
  }

  static Future<Map<String, dynamic>> createQrPaymentLink(
    String code,
    String sessionToken,
  ) async {
    final response = await _client.post<Map<String, dynamic>>(
      '/qr/table/$code/payment-link',
      options: Options(headers: {'x-table-session-token': sessionToken}),
    );
    return Map<String, dynamic>.from(
      response.data?['data'] as Map? ?? const {},
    );
  }

  static Future<Map<String, dynamic>> getQrPaymentStatus(
    String code,
    String sessionToken,
    String paymentId,
  ) async {
    final response = await _client.get<Map<String, dynamic>>(
      '/qr/table/$code/payment/$paymentId/status',
      options: Options(headers: {'x-table-session-token': sessionToken}),
    );
    return Map<String, dynamic>.from(
      response.data?['data'] as Map? ?? const {},
    );
  }

  static List<Map<String, dynamic>> _records(Map<String, dynamic>? payload) {
    final data = payload?['data'];
    if (data is! List) return const [];
    return data
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  static String messageFor(Object error) {
    if (error is StateError) {
      return error.message.toString();
    }
    if (error is DioException) {
      final body = error.response?.data;
      if (body is Map && body['message'] != null) {
        if (error.response?.statusCode == 401) {
          return 'Your session has expired. Please sign in again.';
        }
        return body['message'].toString();
      }
      if (error.type == DioExceptionType.connectionError ||
          error.type == DioExceptionType.connectionTimeout) {
        return 'Cannot connect to the restaurant server.';
      }
    }
    return 'Something went wrong. Please try again.';
  }
}
