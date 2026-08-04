import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/admin/presentation/screens/admin_dashboard_screen.dart';
import '../../features/admin/presentation/screens/super_admin_dashboard_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/signup_screen.dart';
import '../../features/auth/presentation/screens/subscription_screen.dart';
import '../../features/customer/presentation/screens/customer_cart_screen.dart';
import '../../features/customer/presentation/screens/customer_categories_screen.dart';
import '../../features/customer/presentation/screens/customer_checkout_screen.dart';
import '../../features/customer/presentation/screens/customer_coupons_screen.dart';
import '../../features/customer/presentation/screens/customer_dashboard_screen.dart';
import '../../features/customer/presentation/screens/customer_feature_screen.dart';
import '../../features/customer/presentation/screens/customer_menu_screen.dart';
import '../../features/customer/presentation/screens/customer_profile_screen.dart';
import '../../features/customer/presentation/screens/customer_reorder_screen.dart';
import '../../features/customer/presentation/screens/customer_scanner_screen.dart';
import '../../features/kitchen/presentation/screens/kitchen_dashboard_screen.dart';
import '../../features/legal/presentation/screens/legal_policy_screen.dart';
import '../../features/pos/presentation/screens/pos_dashboard_screen.dart';
import '../../features/waiter/presentation/screens/waiter_dashboard_screen.dart';
import '../storage/local_storage.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      final token = LocalStorage.getToken();
      final currentPath = state.uri.toString();
      final isLogin = currentPath == '/login' || currentPath == '/signup';

      // 1. Strict Super Admin Security Guard
      if (currentPath == '/super-admin') {
        if (token == null) return '/login';
        final role = LocalStorage.getRole()?.toLowerCase() ?? '';
        if (!role.contains('super')) {
          return '/login';
        }
      }

      // 2. Unauthenticated user trying to access protected staff/admin routes
      if (token == null) {
        final protectedRoutes = ['/admin', '/super-admin', '/subscription', '/waiter', '/kitchen', '/cashier'];
        if (protectedRoutes.contains(currentPath)) {
          return '/login';
        }
        return null;
      }

      // 3. Authenticated User Redirection from Login
      final role = LocalStorage.getRole()?.toLowerCase() ?? '';
      final isSubscribed = LocalStorage.isSubscriptionActive();

      if (isLogin) {
        if (role.contains('super')) {
          return '/super-admin';
        }
        if (role.contains('admin') || role == 'manager' || role == 'owner') {
          return isSubscribed ? '/admin' : '/subscription';
        }
        if (role == 'waiter') return '/waiter';
        if (role.contains('kitchen') || role == 'chef') return '/kitchen';
        if (role == 'cashier') return '/cashier';
        return '/customer';
      }

      // 4. Protect admin route if subscription is unpaid
      if (currentPath == '/admin' && (role.contains('admin') || role == 'owner')) {
        if (!isSubscribed) return '/subscription';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: '/terms-of-service',
        builder: (context, state) => const LegalPolicyScreen.termsOfService(),
      ),
      GoRoute(
        path: '/privacy-policy',
        builder: (context, state) => const LegalPolicyScreen.privacyPolicy(),
      ),
      GoRoute(
        path: '/content-policy',
        builder: (context, state) => const LegalPolicyScreen.contentPolicy(),
      ),
      GoRoute(
        path: '/subscription',
        name: 'subscription',
        builder: (context, state) => const SubscriptionScreen(),
      ),
      GoRoute(
        path: '/super-admin',
        name: 'super-admin',
        builder: (context, state) => const SuperAdminDashboardScreen(),
      ),
      GoRoute(
        path: '/admin',
        name: 'admin',
        builder: (context, state) => const AdminDashboardScreen(),
      ),
      GoRoute(
        path: '/waiter',
        name: 'waiter',
        builder: (context, state) => const WaiterDashboardScreen(),
      ),
      GoRoute(
        path: '/kitchen',
        name: 'kitchen',
        builder: (context, state) => const KitchenDashboardScreen(),
      ),
      GoRoute(
        path: '/cashier',
        name: 'cashier',
        builder: (context, state) => const POSDashboardScreen(),
      ),
      GoRoute(
        path: '/customer',
        name: 'customer',
        builder: (context, state) => const CustomerDashboardScreen(),
      ),
      GoRoute(
        path: '/cart',
        name: 'cart',
        builder: (context, state) => const CustomerCartScreen(),
      ),
      GoRoute(
        path: '/customer/checkout',
        name: 'customer-checkout',
        builder: (context, state) => const CustomerCheckoutScreen(),
      ),
      GoRoute(
        path: '/customer/menu',
        builder: (context, state) => const CustomerMenuScreen(),
      ),
      GoRoute(
        path: '/customer/category/:category',
        builder: (context, state) =>
            CustomerMenuScreen(categorySlug: state.pathParameters['category']),
      ),
      GoRoute(
        path: '/customer/categories',
        builder: (context, state) => const CustomerCategoriesScreen(),
      ),
      GoRoute(
        path: '/customer/scanner',
        builder: (context, state) => const CustomerScannerScreen(),
      ),
      GoRoute(
        path: '/customer/search',
        builder: (context, state) =>
            const CustomerFeatureScreen(featureKey: 'search'),
      ),
      GoRoute(
        path: '/customer/orders',
        builder: (context, state) =>
            const CustomerFeatureScreen(featureKey: 'orders'),
      ),
      GoRoute(
        path: '/customer/reorder',
        builder: (context, state) => const CustomerReorderScreen(),
      ),
      GoRoute(
        path: '/customer/reservations',
        builder: (context, state) =>
            const CustomerFeatureScreen(featureKey: 'reservations'),
      ),
      GoRoute(
        path: '/customer/offers',
        builder: (context, state) => const CustomerCouponsScreen(),
      ),
      GoRoute(
        path: '/customer/wallet',
        builder: (context, state) =>
            const CustomerFeatureScreen(featureKey: 'wallet'),
      ),
      GoRoute(
        path: '/customer/notifications',
        builder: (context, state) =>
            const CustomerFeatureScreen(featureKey: 'notifications'),
      ),
      GoRoute(
        path: '/customer/profile',
        builder: (context, state) => const CustomerProfileScreen(),
      ),
      GoRoute(
        path: '/customer/favorites',
        builder: (context, state) =>
            const CustomerFeatureScreen(featureKey: 'favorites'),
      ),
    ],
  );
});
