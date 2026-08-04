import 'package:flutter_riverpod/flutter_riverpod.dart';

class CustomerAddress {
  const CustomerAddress({
    required this.id,
    required this.label,
    required this.title,
    required this.subtitle,
    required this.deliveryHint,
  });

  final String id;
  final String label;
  final String title;
  final String subtitle;
  final String deliveryHint;
}

class CustomerAddressNotifier extends Notifier<CustomerAddress> {
  @override
  CustomerAddress build() => customerSavedAddresses.first;

  void selectAddress(CustomerAddress address) {
    state = address;
  }
}

const customerSavedAddresses = <CustomerAddress>[
  CustomerAddress(
    id: 'home',
    label: 'Home',
    title: '21 MG Road, Indore',
    subtitle: 'Near Apollo Square, 2nd floor, ring bell 302',
    deliveryHint: 'Fastest delivery window for this address is 28 to 32 min.',
  ),
  CustomerAddress(
    id: 'office',
    label: 'Office',
    title: 'Orbit Mall Business Tower, Indore',
    subtitle: '5th floor reception, ask for Kartik Sharma',
    deliveryHint: 'Office deliveries are handed over at the lobby reception.',
  ),
  CustomerAddress(
    id: 'friends-place',
    label: 'Friends',
    title: '78 Saket Nagar, Indore',
    subtitle: 'Blue gate villa, call before arrival',
    deliveryHint: 'Rider should call on arrival because the gate stays closed.',
  ),
];

final customerSelectedAddressProvider =
    NotifierProvider<CustomerAddressNotifier, CustomerAddress>(
      CustomerAddressNotifier.new,
    );
