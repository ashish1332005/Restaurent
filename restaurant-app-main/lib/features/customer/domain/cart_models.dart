enum FulfillmentType {
  delivery,
  pickup,
}

class CartItem {
  const CartItem({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.unitPrice,
    required this.quantity,
    this.modifiers = const [],
  });

  final String id;
  final String title;
  final String description;
  final String imageUrl;
  final double unitPrice;
  final int quantity;
  final List<String> modifiers;

  double get totalPrice => unitPrice * quantity;

  CartItem copyWith({
    String? id,
    String? title,
    String? description,
    String? imageUrl,
    double? unitPrice,
    int? quantity,
    List<String>? modifiers,
  }) {
    return CartItem(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      unitPrice: unitPrice ?? this.unitPrice,
      quantity: quantity ?? this.quantity,
      modifiers: modifiers ?? this.modifiers,
    );
  }
}

class CartState {
  const CartState({
    this.items = const [],
    this.fulfillmentType = FulfillmentType.delivery,
  });

  final List<CartItem> items;
  final FulfillmentType fulfillmentType;

  static const double offerThreshold = 1000;
  static const double deliveryFee = 35;
  static const double platformFee = 12;
  static const double serviceChargeRate = 0.05;
  static const double taxRate = 0.025;

  int get distinctItemCount => items.length;

  int get totalQuantity =>
      items.fold(0, (total, item) => total + item.quantity);

  double get subtotal =>
      items.fold(0, (total, item) => total + item.totalPrice);

  double get serviceCharge => subtotal * serviceChargeRate;

  double get fulfillmentCharge =>
      fulfillmentType == FulfillmentType.delivery ? deliveryFee : 0;

  double get cgst => subtotal * taxRate;

  double get sgst => subtotal * taxRate;

  double get total =>
      subtotal + serviceCharge + fulfillmentCharge + platformFee + cgst + sgst;

  double get remainingForOffer {
    final remaining = offerThreshold - subtotal;
    return remaining > 0 ? remaining : 0;
  }

  double get offerProgress {
    if (subtotal <= 0) {
      return 0;
    }

    if (subtotal >= offerThreshold) {
      return 1;
    }

    return subtotal / offerThreshold;
  }

  CartState copyWith({
    List<CartItem>? items,
    FulfillmentType? fulfillmentType,
  }) {
    return CartState(
      items: items ?? this.items,
      fulfillmentType: fulfillmentType ?? this.fulfillmentType,
    );
  }
}

String formatCartCurrency(double amount) {
  final rounded = amount.roundToDouble();
  final hasDecimals = (amount - rounded).abs() > 0.009;
  return 'Rs. ${amount.toStringAsFixed(hasDecimals ? 2 : 0)}';
}
