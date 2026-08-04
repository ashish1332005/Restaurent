class CustomerSavedCard {
  const CustomerSavedCard({
    required this.label,
    required this.brand,
    required this.last4,
    required this.expiryMonth,
    required this.expiryYear,
  });

  final String label;
  final String brand;
  final String last4;
  final String expiryMonth;
  final String expiryYear;

  String get maskedNumber => '•••• •••• •••• $last4';
  String get expiryLabel => '$expiryMonth/$expiryYear';

  Map<String, dynamic> toMap() {
    return {
      'label': label,
      'brand': brand,
      'last4': last4,
      'expiryMonth': expiryMonth,
      'expiryYear': expiryYear,
    };
  }

  factory CustomerSavedCard.fromMap(Map<String, dynamic> map) {
    return CustomerSavedCard(
      label: map['label']?.toString() ?? 'Saved Card',
      brand: map['brand']?.toString() ?? 'Card',
      last4: map['last4']?.toString() ?? '0000',
      expiryMonth: map['expiryMonth']?.toString() ?? '00',
      expiryYear: map['expiryYear']?.toString() ?? '00',
    );
  }
}

class CustomerProfile {
  const CustomerProfile({
    required this.name,
    required this.email,
    required this.phone,
    required this.address,
    required this.savedCards,
    this.avatarUrl = '',
    this.id,
  });

  final String? id;
  final String name;
  final String email;
  final String phone;
  final String address;
  final List<CustomerSavedCard> savedCards;
  final String avatarUrl;

  String get firstInitial {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return 'U';
    return trimmed[0].toUpperCase();
  }

  CustomerProfile copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? address,
    List<CustomerSavedCard>? savedCards,
    String? avatarUrl,
  }) {
    return CustomerProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      savedCards: savedCards ?? this.savedCards,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'address': address,
      'savedCards': savedCards.map((card) => card.toMap()).toList(),
      'avatarUrl': avatarUrl,
    };
  }

  factory CustomerProfile.fromMap(Map<String, dynamic> map) {
    final rawCards =
        (map['savedCards'] as List?)
            ?.whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList(growable: false) ??
        const <Map<String, dynamic>>[];

    return CustomerProfile(
      id: map['id']?.toString() ?? map['_id']?.toString(),
      name: map['name']?.toString() ?? '',
      email: map['email']?.toString() ?? '',
      phone: map['phone']?.toString() ?? '',
      address: map['address']?.toString() ?? '',
      savedCards: rawCards
          .map(CustomerSavedCard.fromMap)
          .toList(growable: false),
      avatarUrl: map['avatarUrl']?.toString() ?? '',
    );
  }
}
