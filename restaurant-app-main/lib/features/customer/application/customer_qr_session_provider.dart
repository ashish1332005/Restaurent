import 'package:flutter_riverpod/flutter_riverpod.dart';

class CustomerQrSession {
  const CustomerQrSession({
    required this.tableNo,
    required this.restaurantName,
    required this.logoUrl,
    required this.primaryColorHex,
    required this.guestName,
    required this.guestPhone,
  });

  final String tableNo;
  final String restaurantName;
  final String logoUrl;
  final String primaryColorHex;
  final String guestName;
  final String guestPhone;
}

class CustomerQrSessionNotifier extends Notifier<CustomerQrSession?> {
  @override
  CustomerQrSession? build() => null;

  void startTableSession({
    required String tableNo,
    String restaurantName = 'Restaurant Workspace',
    String logoUrl = '',
    String primaryColorHex = '#006B3C',
    String guestName = '',
    String guestPhone = '',
  }) {
    state = CustomerQrSession(
      tableNo: tableNo,
      restaurantName: restaurantName,
      logoUrl: logoUrl,
      primaryColorHex: primaryColorHex,
      guestName: guestName,
      guestPhone: guestPhone,
    );
  }

  void clear() => state = null;
}

final customerQrSessionProvider =
    NotifierProvider<CustomerQrSessionNotifier, CustomerQrSession?>(
      CustomerQrSessionNotifier.new,
    );

