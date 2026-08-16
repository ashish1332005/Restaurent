import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../core/network/restaurant_api.dart';
import '../../../core/storage/local_storage.dart';

class CustomerAuthSession {
  CustomerAuthSession._();

  static Future<String> loginWithPassword({
    required String phone,
    required String password,
  }) async {
    const enableDemoAuth = bool.fromEnvironment(
      'ENABLE_DEMO_AUTH',
      defaultValue: false,
    );

    final owner = enableDemoAuth
        ? LocalStorage.findOwnerByCredentials(phone, password)
        : null;
    if (owner != null) {
      const role = 'Admin';
      await LocalStorage.clearToken();
      await LocalStorage.saveToken(
        'local_owner_${DateTime.now().millisecondsSinceEpoch}',
      );
      await LocalStorage.saveRole(role);
      await LocalStorage.saveCustomerProfile({
        'name': owner['ownerName']?.toString() ?? 'Restaurant Owner',
        'phone': owner['phone']?.toString() ?? phone,
        'email': owner['email']?.toString() ?? '',
        'role': role,
        'restaurantName': owner['name']?.toString() ?? 'Restaurant',
      });
      return role;
    }

    final staff = enableDemoAuth
        ? LocalStorage.findStaffByCredentials(phone, password)
        : null;
    if (staff != null) {
      if (staff['status'] != 'Active') {
        throw StateError('Access denied. This staff account is disabled.');
      }
      final role = staff['role']?.toString() ?? 'Waiter';
      await LocalStorage.clearToken();
      await LocalStorage.saveToken(
        'local_staff_${staff['id']}_${DateTime.now().millisecondsSinceEpoch}',
      );
      await LocalStorage.saveRole(role);
      await LocalStorage.saveCustomerProfile({
        'id': staff['id'],
        'name': staff['name'],
        'phone': staff['phone'],
        'role': role,
        'shift': staff['shift'],
      });
      return role;
    }

    try {
      final response = await RestaurantApi.login(phone, password);
      return _persistAuthenticatedCustomer(response);
    } catch (error) {
      if (enableDemoAuth && phone == '9999999999' && password == '123456') {
        const role = 'Super Admin';
        await LocalStorage.clearToken();
        await LocalStorage.saveToken(
          'demo_super_admin_${DateTime.now().millisecondsSinceEpoch}',
        );
        await LocalStorage.saveRole(role);
        await LocalStorage.saveCustomerProfile({
          'name': 'Super Admin',
          'phone': phone,
          'role': role,
        });
        return role;
      }
      throw StateError('Invalid mobile number or password.');
    }
  }

  static Future<String> registerWithPassword({
    required String name,
    required String phone,
    required String password,
  }) async {
    final response = await RestaurantApi.registerCustomer(
      name: name,
      phone: phone,
      password: password,
    );
    return _persistAuthenticatedCustomer(
      response,
      fallbackProfile: {'name': name, 'phone': phone},
    );
  }

  static Future<String> registerRestaurantOwner({
    required String ownerName,
    required String restaurantName,
    required String phone,
    required String email,
    required String password,
    required String address,
  }) async {
    final response = await RestaurantApi.registerRestaurantOwner(
      ownerName: ownerName,
      restaurantName: restaurantName,
      phone: phone,
      email: email,
      password: password,
      address: address,
    );
    final payload = Map<String, dynamic>.from(
      response['data'] as Map? ?? const {},
    );
    final user = Map<String, dynamic>.from(payload['user'] as Map? ?? const {});
    return _persistAuthenticatedCustomer(
      {
        'token': response['token'],
        'data': {
          ...user,
          'role': user['role'] ?? 'Restaurant Admin',
          'restaurantId': (payload['restaurant'] as Map?)?['_id'],
          'branchId': (payload['branch'] as Map?)?['_id'],
          'subscriptionStatus':
              (payload['subscription'] as Map?)?['status'] ?? 'Pending Payment',
          'subscriptionPlan':
              (payload['subscription'] as Map?)?['plan'] ?? 'Basic',
          'restaurantIsActive':
              (payload['restaurant'] as Map?)?['isActive'] == true,
        },
      },
      fallbackProfile: {'name': ownerName, 'phone': phone, 'email': email},
    );
  }

  static Future<String> loginWithGoogle() async {
    final serverClientId = const String.fromEnvironment(
      'GOOGLE_SERVER_CLIENT_ID',
    ).trim();
    final clientId = const String.fromEnvironment('GOOGLE_CLIENT_ID').trim();

    if (kIsWeb && clientId.isEmpty) {
      throw StateError(
        'Google Sign-In is not configured. Start the app with GOOGLE_CLIENT_ID.',
      );
    }
    if (!kIsWeb && serverClientId.isEmpty) {
      throw StateError(
        'Google Sign-In is not configured. Add GOOGLE_SERVER_CLIENT_ID for this app.',
      );
    }

    final googleSignIn = GoogleSignIn(
      scopes: const ['email', 'profile'],
      serverClientId: serverClientId.isEmpty ? null : serverClientId,
      clientId: clientId.isEmpty ? null : clientId,
    );

    GoogleSignInAccount? account;
    try {
      account = await googleSignIn.signIn();
    } catch (error) {
      throw StateError(
        'Google Sign-In could not start. Check OAuth client ID, package name, and signing SHA fingerprint. ($error)',
      );
    }
    if (account == null) {
      throw StateError('Google sign-in was cancelled.');
    }

    late final GoogleSignInAuthentication auth;
    try {
      auth = await account.authentication;
    } catch (error) {
      throw StateError('Google account authentication failed. ($error)');
    }
    final response = await RestaurantApi.loginCustomerWithGoogle(
      idToken: auth.idToken,
      accessToken: auth.accessToken,
      email: account.email,
      name: account.displayName,
      photoUrl: account.photoUrl,
    );

    return _persistAuthenticatedCustomer(
      response,
      fallbackProfile: {
        'name': account.displayName,
        'email': account.email,
        'avatarUrl': account.photoUrl,
      },
    );
  }

  static Future<String> _persistAuthenticatedCustomer(
    Map<String, dynamic> response, {
    Map<String, dynamic>? fallbackProfile,
  }) async {
    final token = response['token']?.toString().trim() ?? '';
    final data = Map<String, dynamic>.from(
      response['data'] as Map? ?? const {},
    );
    final role = data['role']?.toString().trim() ?? 'Customer';

    if (token.isEmpty) {
      throw StateError('Invalid authentication response');
    }

    final previousProfile = LocalStorage.getCustomerProfile() ?? const {};
    final mergedProfile = <String, dynamic>{
      'id': data['_id']?.toString(),
      'name':
          data['name']?.toString() ??
          fallbackProfile?['name']?.toString() ??
          previousProfile['name']?.toString() ??
          '',
      'email':
          data['email']?.toString() ??
          fallbackProfile?['email']?.toString() ??
          previousProfile['email']?.toString() ??
          '',
      'phone':
          data['phone']?.toString() ??
          fallbackProfile?['phone']?.toString() ??
          previousProfile['phone']?.toString() ??
          '',
      'address':
          data['address']?.toString() ?? previousProfile['address'] ?? '',
      'avatarUrl':
          data['avatarUrl']?.toString() ??
          fallbackProfile?['avatarUrl']?.toString() ??
          previousProfile['avatarUrl']?.toString() ??
          '',
      'restaurantId': data['restaurantId']?.toString() ?? '',
      'branchId': data['branchId']?.toString() ?? '',
      'role': role,
      'savedCards': previousProfile['savedCards'] as List? ?? const [],
    };

    await LocalStorage.clearToken();
    await LocalStorage.saveToken(token);
    await LocalStorage.saveRole(role);
    final subscriptionStatus =
        data['subscriptionStatus']?.toString().toLowerCase() ?? '';
    final restaurantIsActive = data['restaurantIsActive'] == true;
    final isRestaurantRole =
        role.toLowerCase().contains('admin') || role.toLowerCase() == 'manager';
    if (isRestaurantRole) {
      await LocalStorage.saveSubscriptionStatus(
        isActive:
            restaurantIsActive &&
            (subscriptionStatus == 'active' || subscriptionStatus == 'trial'),
        planName: data['subscriptionPlan']?.toString() ?? 'Restaurant Plan',
        expiresAt: data['subscriptionExpiresAt']?.toString(),
      );
    }
    await LocalStorage.saveCustomerProfile(mergedProfile);
    return role;
  }
}
