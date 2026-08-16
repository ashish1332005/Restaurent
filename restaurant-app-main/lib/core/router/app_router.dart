import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../storage/local_storage.dart';
import '../../ui_reset/ui_reset_screen.dart';
import '../../features/admin/presentation/admin_dashboard_screen.dart';
import '../../features/admin/presentation/super_admin_dashboard_screen.dart';
import '../../features/auth/presentation/admin_login_screen.dart';
import '../../features/auth/presentation/restaurant_register_screen.dart';
import '../../features/system/presentation/system_pages.dart';

bool _isValidSessionToken(String? token) {
  if (token == null || token.isEmpty) return false;
  const enableDemoAuth = bool.fromEnvironment(
    'ENABLE_DEMO_AUTH',
    defaultValue: false,
  );
  if (enableDemoAuth && token.startsWith('local_')) return true;
  return token.split('.').length == 3;
}

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final location = state.matchedLocation;
      final publicAuth =
          location == '/admin/login' || location == '/admin/register';
      final protected =
          location == '/admin' ||
          (location.startsWith('/admin/') && !publicAuth) ||
          location.startsWith('/super-admin') ||
          location == '/subscription';
      if (location == '/') {
        final token = LocalStorage.getToken();
        final role = LocalStorage.getRole() ?? '';
        if (_isValidSessionToken(token)) {
          return role == 'Super Admin' ? '/super-admin' : '/admin';
        }
        return '/admin/login';
      }
      if (!protected) return null;
      final token = LocalStorage.getToken();
      final role = LocalStorage.getRole() ?? '';
      final signedIn = _isValidSessionToken(token);
      const operational = {
        'Admin',
        'Restaurant Admin',
        'Manager',
        'Super Admin',
        'Cashier',
        'Kitchen',
        'Waiter',
      };
      if (location == '/admin/login') {
        if (!signedIn || !operational.contains(role)) return null;
        return role == 'Super Admin' ? '/super-admin' : '/admin';
      }
      if (!signedIn || !operational.contains(role)) return '/admin/login';
      if (location.startsWith('/super-admin') && role != 'Super Admin') {
        return '/admin';
      }
      if (location == '/admin' && role == 'Super Admin') return '/super-admin';
      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (context, state) => const UiResetScreen()),
      GoRoute(
        path: '/table/:code',
        builder: (context, state) =>
            UiResetScreen(initialTableCode: state.pathParameters['code']),
      ),
      GoRoute(
        path: '/admin/login',
        builder: (context, state) => const AdminLoginScreen(),
      ),
      GoRoute(
        path: '/admin/register',
        builder: (context, state) => const RestaurantRegisterScreen(),
      ),
      GoRoute(
        path: '/admin',
        builder: (context, state) => const AdminDashboardScreen(),
      ),
      GoRoute(
        path: '/super-admin',
        builder: (context, state) => const SuperAdminDashboardScreen(),
        routes: [
          GoRoute(
            path: ':section',
            builder: (context, state) => SuperAdminDashboardScreen(
              initialSection: state.pathParameters['section'] ?? 'overview',
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/subscription',
        builder: (context, state) => const SubscriptionScreen(),
      ),
      GoRoute(
        path: '/legal/privacy',
        builder: (context, state) =>
            const LegalDocumentScreen(document: 'privacy'),
      ),
      GoRoute(
        path: '/legal/terms',
        builder: (context, state) =>
            const LegalDocumentScreen(document: 'terms'),
      ),
      GoRoute(
        path: '/offline',
        builder: (context, state) => const OfflineScreen(),
      ),
      GoRoute(
        path: '/:path(.*)',
        builder: (context, state) => const AppErrorScreen(),
      ),
    ],
  );
});
