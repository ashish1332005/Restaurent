import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../storage/local_storage.dart';

class ApiClient {
  static const String defaultLiveUrl =
      'https://restaurent-2-xq6f.onrender.com/api/v1';

  static String normalizeUrl(String raw) {
    var clean = raw.trim().replaceFirst(RegExp(r'/+$'), '');
    if (!clean.endsWith('/api/v1')) {
      clean = '$clean/api/v1';
    }
    return clean;
  }

  static String get baseUrl {
    final stored = LocalStorage.getServerUrl();
    if (stored != null && stored.isNotEmpty) return normalizeUrl(stored);
    const configured = String.fromEnvironment('API_BASE_URL');
    if (configured.trim().isNotEmpty) return normalizeUrl(configured);
    if (kIsWeb) {
      final host = Uri.base.host.isEmpty ? 'localhost' : Uri.base.host;
      if (host != 'localhost' && host != '127.0.0.1') {
        return defaultLiveUrl;
      }
      return 'http://$host:5000/api/v1';
    }
    return defaultLiveUrl;
  }

  static void updateBaseUrl(String newUrl) {
    final clean = normalizeUrl(newUrl);
    _dio.options.baseUrl = clean;
  }

  static final Dio _dio = Dio(
    BaseOptions(
      baseUrl: defaultLiveUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Content-Type': 'application/json'},
    ),
  );

  static void init() {
    _dio.options.baseUrl = baseUrl;
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          options.baseUrl = baseUrl;
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
