import 'package:flutter_riverpod/flutter_riverpod.dart';

class CustomerQrSession {
  const CustomerQrSession({
    required this.tableNo,
    required this.restaurantName,
    required this.logoUrl,
    required this.primaryColorHex,
  });

  final String tableNo;
  final String restaurantName;
  final String logoUrl;
  final String primaryColorHex;
}

class CustomerQrSessionNotifier extends Notifier<CustomerQrSession?> {
  @override
  CustomerQrSession? build() => null;

  void startTableSession({
    required String tableNo,
    String restaurantName = 'Sharma Restaurant',
    String logoUrl = '',
    String primaryColorHex = '#FF4D0A',
  }) {
    state = CustomerQrSession(
      tableNo: tableNo,
      restaurantName: restaurantName,
      logoUrl: logoUrl,
      primaryColorHex: primaryColorHex,
    );
  }

  void clear() => state = null;
}

final customerQrSessionProvider =
    NotifierProvider<CustomerQrSessionNotifier, CustomerQrSession?>(
      CustomerQrSessionNotifier.new,
    );
