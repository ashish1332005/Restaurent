import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/restaurant_api.dart';
import '../../../core/storage/local_storage.dart';
import '../domain/models/customer_profile.dart';

class CustomerProfileSaveResult {
  const CustomerProfileSaveResult({
    required this.profile,
    required this.savedToServer,
  });

  final CustomerProfile profile;
  final bool savedToServer;
}

class CustomerProfileNotifier extends AsyncNotifier<CustomerProfile> {
  @override
  Future<CustomerProfile> build() async {
    final local = LocalStorage.getCustomerProfile();
    final localProfile = local == null
        ? _defaultProfile()
        : CustomerProfile.fromMap(local);

    try {
      final remote = await _loadRemoteProfile();
      if (remote == null) {
        return localProfile;
      }
      final merged = _mergeProfile(remote, localProfile);
      await LocalStorage.saveCustomerProfile(merged.toMap());
      return merged;
    } catch (_) {
      return localProfile;
    }
  }

  Future<CustomerProfileSaveResult> saveProfile({
    required String name,
    required String email,
    required String phone,
    required String address,
  }) async {
    final current = state.asData?.value ?? _defaultProfile();
    final updated = current.copyWith(
      name: name.trim(),
      email: email.trim(),
      phone: phone.trim(),
      address: address.trim(),
    );

    state = AsyncData(updated);
    await LocalStorage.saveCustomerProfile(updated.toMap());

    try {
      final remote = await _saveRemoteProfile(updated);
      if (remote == null) {
        return CustomerProfileSaveResult(
          profile: updated,
          savedToServer: false,
        );
      }
      final merged = _mergeProfile(remote, updated);
      state = AsyncData(merged);
      await LocalStorage.saveCustomerProfile(merged.toMap());
      return CustomerProfileSaveResult(profile: merged, savedToServer: true);
    } on DioException {
      return CustomerProfileSaveResult(profile: updated, savedToServer: false);
    } catch (_) {
      return CustomerProfileSaveResult(profile: updated, savedToServer: false);
    }
  }

  Future<CustomerProfile?> _loadRemoteProfile() async {
    if (_hasJwtToken()) {
      return CustomerProfile.fromMap(await RestaurantApi.getCurrentProfile());
    }

    final remote = await RestaurantApi.getDemoProfile(_demoKey());
    if (remote == null) {
      return null;
    }
    return CustomerProfile.fromMap(remote);
  }

  Future<CustomerProfile?> _saveRemoteProfile(CustomerProfile updated) async {
    final body = {
      'name': updated.name,
      'email': updated.email,
      'phone': updated.phone,
      'address': updated.address,
      'avatarUrl': updated.avatarUrl,
      'savedCards': updated.savedCards.map((card) => card.toMap()).toList(),
    };

    if (_hasJwtToken()) {
      return CustomerProfile.fromMap(
        await RestaurantApi.updateCurrentProfile(body),
      );
    }

    return CustomerProfile.fromMap(
      await RestaurantApi.updateDemoProfile(_demoKey(), body),
    );
  }

  CustomerProfile _mergeProfile(
    CustomerProfile remote,
    CustomerProfile fallback,
  ) {
    return remote.copyWith(
      savedCards: remote.savedCards.isEmpty
          ? fallback.savedCards
          : remote.savedCards,
      avatarUrl: remote.avatarUrl.isEmpty
          ? fallback.avatarUrl
          : remote.avatarUrl,
      address: remote.address.isEmpty ? fallback.address : remote.address,
      phone: remote.phone.isEmpty ? fallback.phone : remote.phone,
      email: remote.email.isEmpty ? fallback.email : remote.email,
      name: remote.name.isEmpty ? fallback.name : remote.name,
    );
  }

  CustomerProfile _defaultProfile() {
    final token = LocalStorage.getToken()?.trim() ?? '';
    final normalizedPhone = RegExp(r'^\d{10}$').hasMatch(token)
        ? '+91 $token'
        : '+91 91169 01749';
    final email = token.contains('@') ? token : 'kartik@tastehub.com';

    return CustomerProfile(
      name: 'Kartik Sharma',
      email: email,
      phone: normalizedPhone,
      address: '21 MG Road, R K Colony, Bhilwara',
      avatarUrl: '',
      savedCards: const [
        CustomerSavedCard(
          label: 'Primary Card',
          brand: 'Visa',
          last4: '4242',
          expiryMonth: '09',
          expiryYear: '28',
        ),
        CustomerSavedCard(
          label: 'Office Card',
          brand: 'Mastercard',
          last4: '8851',
          expiryMonth: '11',
          expiryYear: '27',
        ),
      ],
    );
  }

  bool _hasJwtToken() {
    final token = LocalStorage.getToken();
    if (token == null) return false;
    return token.split('.').length == 3;
  }

  String _demoKey() {
    final raw = LocalStorage.getToken()?.trim().toLowerCase() ?? 'customer';
    final sanitized = raw.replaceAll(RegExp(r'[^a-z0-9@._-]+'), '-');
    return sanitized.isEmpty ? 'customer' : sanitized;
  }
}

final customerProfileProvider =
    AsyncNotifierProvider<CustomerProfileNotifier, CustomerProfile>(
      CustomerProfileNotifier.new,
    );
