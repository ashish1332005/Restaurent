import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../storage/local_storage.dart';

class ApiClient {
  static String get baseUrl {
    const configured = String.fromEnvironment('API_BASE_URL');
    if (configured.trim().isNotEmpty) return configured.trim();
    if (kIsWeb) {
      final host = Uri.base.host.isEmpty ? 'localhost' : Uri.base.host;
      return 'http://$host:5000/api/v1';
    }
    return 'http://10.0.2.2:5000/api/v1';
  }

  static final Dio _dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {'Content-Type': 'application/json'},
    ),
  );

  static void init() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final token = LocalStorage.getToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (DioException e, handler) {
          // Handle global errors, token refresh, etc.
          if (e.response?.statusCode == 401) {
            LocalStorage.clearToken();
          }
          return handler.next(e);
        },
      ),
    );
  }

  static Dio get instance => _dio;
}
