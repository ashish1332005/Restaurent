import 'package:dio/dio.dart';

import 'api_client.dart';

class RestaurantApi {
  RestaurantApi._();

  static Dio get _client => ApiClient.instance;

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

  static Future<List<Map<String, dynamic>>> getMenuItems() async {
    final response = await _client.get<Map<String, dynamic>>('/menu/items');
    return _records(response.data);
  }

  static Future<List<Map<String, dynamic>>> getTables() async {
    final response = await _client.get<Map<String, dynamic>>('/tables');
    return _records(response.data);
  }

  static Future<List<Map<String, dynamic>>> getOrders({String? status}) async {
    final response = await _client.get<Map<String, dynamic>>(
      '/orders',
      queryParameters: status == null ? null : {'status': status},
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

  static Future<void> updateOrderStatus(String id, String status) async {
    await _client.patch<void>('/orders/$id/status', data: {'status': status});
  }

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

  static List<Map<String, dynamic>> _records(Map<String, dynamic>? payload) {
    final data = payload?['data'];
    if (data is! List) return const [];
    return data
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  static String messageFor(Object error) {
    if (error is DioException) {
      final body = error.response?.data;
      if (body is Map && body['message'] != null) {
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
