import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/local_storage.dart';
import '../domain/models/customer_menu_item.dart';

enum CustomerOrderType { delivery, pickup }

enum CustomerCouponType { percentage, flat }

enum CustomerDietaryMode { veg, nonVeg }

class CustomerOrderTypeNotifier extends Notifier<CustomerOrderType> {
  @override
  CustomerOrderType build() => CustomerOrderType.delivery;

  void setOrderType(CustomerOrderType orderType) {
    state = orderType;
  }
}

class CustomerDietaryPreferenceNotifier extends Notifier<CustomerDietaryMode> {
  @override
  CustomerDietaryMode build() => CustomerDietaryMode.veg;

  void setMode(CustomerDietaryMode mode) {
    state = mode;
  }
}

class CustomerCartItem {
  const CustomerCartItem({
    required this.menuItem,
    required this.quantity,
    required this.modifiers,
  });

  final CustomerMenuItem menuItem;
  final int quantity;
  final List<String> modifiers;

  double get totalPrice => menuItem.price * quantity;

  CustomerCartItem copyWith({
    CustomerMenuItem? menuItem,
    int? quantity,
    List<String>? modifiers,
  }) {
    return CustomerCartItem(
      menuItem: menuItem ?? this.menuItem,
      quantity: quantity ?? this.quantity,
      modifiers: modifiers ?? this.modifiers,
    );
  }
}

class CustomerOrderHistoryEntry {
  const CustomerOrderHistoryEntry({
    required this.id,
    required this.placedAt,
    required this.orderType,
    required this.paymentMethod,
    required this.status,
    required this.total,
    required this.items,
    required this.destinationLabel,
    required this.etaLabel,
  });

  final String id;
  final DateTime placedAt;
  final CustomerOrderType orderType;
  final String paymentMethod;
  final String status;
  final double total;
  final List<CustomerCartItem> items;
  final String destinationLabel;
  final String etaLabel;

  int get itemCount =>
      items.fold<int>(0, (count, item) => count + item.quantity);
}

class CustomerCartSummary {
  const CustomerCartSummary({
    required this.itemCount,
    required this.subtotal,
    required this.discount,
    required this.discountedSubtotal,
    required this.serviceCharge,
    required this.cgst,
    required this.sgst,
    required this.total,
    required this.offerThreshold,
    required this.amountToUnlockOffer,
    required this.offerProgress,
    this.appliedCoupon,
  });

  final int itemCount;
  final double subtotal;
  final double discount;
  final double discountedSubtotal;
  final double serviceCharge;
  final double cgst;
  final double sgst;
  final double total;
  final double offerThreshold;
  final double amountToUnlockOffer;
  final double offerProgress;
  final CustomerCoupon? appliedCoupon;
}

class CustomerCoupon {
  const CustomerCoupon({
    required this.code,
    required this.title,
    required this.description,
    required this.type,
    required this.value,
    required this.minSubtotal,
    this.maxDiscount,
  });

  final String code;
  final String title;
  final String description;
  final CustomerCouponType type;
  final double value;
  final double minSubtotal;
  final double? maxDiscount;

  bool isEligible(double subtotal) => subtotal >= minSubtotal;

  double calculateDiscount(double subtotal) {
    if (!isEligible(subtotal)) {
      return 0;
    }

    final rawDiscount = switch (type) {
      CustomerCouponType.percentage => subtotal * (value / 100),
      CustomerCouponType.flat => value,
    };

    final cappedDiscount = maxDiscount == null
        ? rawDiscount
        : math.min(rawDiscount, maxDiscount!);

    return math.min(cappedDiscount, subtotal);
  }
}

class CustomerCouponNotifier extends Notifier<CustomerCoupon?> {
  @override
  CustomerCoupon? build() => null;

  void applyCoupon(CustomerCoupon coupon) {
    state = coupon;
  }

  void removeCoupon() {
    state = null;
  }

  void clearIfInvalid(double subtotal) {
    final coupon = state;
    if (coupon != null && !coupon.isEligible(subtotal)) {
      state = null;
    }
  }
}

class CustomerCartNotifier extends Notifier<List<CustomerCartItem>> {
  @override
  List<CustomerCartItem> build() => const [];

  void addItem(CustomerMenuItem menuItem) {
    final existingIndex = state.indexWhere(
      (item) => item.menuItem.id == menuItem.id,
    );

    if (existingIndex == -1) {
      state = [
        ...state,
        CustomerCartItem(
          menuItem: menuItem,
          quantity: 1,
          modifiers: menuItem.defaultModifiers,
        ),
      ];
      _syncPreview(menuItem);
      _syncCouponEligibility();
      return;
    }

    final updatedItems = [...state];
    final existingItem = updatedItems[existingIndex];
    updatedItems[existingIndex] = existingItem.copyWith(
      quantity: existingItem.quantity + 1,
    );
    state = updatedItems;
    _syncPreview(menuItem);
    _syncCouponEligibility();
  }

  void increment(String menuItemId) {
    CustomerMenuItem? touchedItem;
    state = [
      for (final item in state)
        if (item.menuItem.id == menuItemId)
          item.copyWith(quantity: item.quantity + 1)
        else
          item,
    ];
    for (final item in state) {
      if (item.menuItem.id == menuItemId) {
        touchedItem = item.menuItem;
        break;
      }
    }
    _syncPreview(touchedItem);
    _syncCouponEligibility();
  }

  void decrement(String menuItemId) {
    final updatedItems = <CustomerCartItem>[];
    CustomerMenuItem? touchedItem;

    for (final item in state) {
      if (item.menuItem.id != menuItemId) {
        updatedItems.add(item);
        continue;
      }

      if (item.quantity > 1) {
        touchedItem = item.menuItem;
        updatedItems.add(item.copyWith(quantity: item.quantity - 1));
      }
    }

    state = updatedItems;
    _syncPreview(touchedItem);
    _syncCouponEligibility();
  }

  void remove(String menuItemId) {
    state = state.where((item) => item.menuItem.id != menuItemId).toList();
    _syncPreview();
    _syncCouponEligibility();
  }

  void clear() {
    state = const [];
    ref.read(customerCartPreviewProvider.notifier).clear();
    ref.read(customerCouponProvider.notifier).removeCoupon();
  }

  void addOrderItems(List<CustomerCartItem> orderItems) {
    final updatedItems = [...state];

    for (final orderItem in orderItems) {
      final existingIndex = updatedItems.indexWhere(
        (item) => item.menuItem.id == orderItem.menuItem.id,
      );
      if (existingIndex == -1) {
        updatedItems.add(orderItem.copyWith());
      } else {
        final existingItem = updatedItems[existingIndex];
        updatedItems[existingIndex] = existingItem.copyWith(
          quantity: existingItem.quantity + orderItem.quantity,
          modifiers: orderItem.modifiers,
        );
      }
    }

    state = updatedItems;
    _syncPreview(updatedItems.isEmpty ? null : orderItems.last.menuItem);
    _syncCouponEligibility();
  }

  void _syncCouponEligibility() {
    final subtotal = state.fold<double>(
      0,
      (sum, item) => sum + item.totalPrice,
    );
    ref.read(customerCouponProvider.notifier).clearIfInvalid(subtotal);
  }

  void _syncPreview([CustomerMenuItem? menuItem]) {
    final previewNotifier = ref.read(customerCartPreviewProvider.notifier);
    if (state.isEmpty) {
      previewNotifier.clear();
      return;
    }

    previewNotifier.show(menuItem ?? state.last.menuItem);
  }
}

class CustomerLastOrderNotifier extends Notifier<List<CustomerCartItem>?> {
  @override
  List<CustomerCartItem>? build() {
    final storedItems = LocalStorage.getLastCustomerOrder();
    if (storedItems.isEmpty) return null;

    return storedItems.map(_cartItemFromMap).toList(growable: false);
  }

  Future<void> save(List<CustomerCartItem> items) async {
    if (items.isEmpty) return;
    state = items.map((item) => item.copyWith()).toList(growable: false);
    await LocalStorage.saveLastCustomerOrder(
      items.map(_cartItemToMap).toList(growable: false),
    );
  }
}

class CustomerOrderHistoryNotifier
    extends Notifier<List<CustomerOrderHistoryEntry>> {
  @override
  List<CustomerOrderHistoryEntry> build() {
    final storedOrders = LocalStorage.getCustomerOrderHistory();
    if (storedOrders.isNotEmpty) {
      return storedOrders
          .map(_orderHistoryEntryFromMap)
          .toList(growable: false);
    }

    final lastOrder = LocalStorage.getLastCustomerOrder();
    if (lastOrder.isEmpty) {
      return const [];
    }

    final migratedItems = lastOrder.map(_cartItemFromMap).toList(
      growable: false,
    );
    final inferredPlacedAt = DateTime.now().subtract(const Duration(hours: 2));

    return [
      CustomerOrderHistoryEntry(
        id: _buildOrderId(inferredPlacedAt),
        placedAt: inferredPlacedAt,
        orderType: CustomerOrderType.delivery,
        paymentMethod: 'UPI',
        status: 'Delivered',
        total: migratedItems.fold<double>(
          0,
          (sum, item) => sum + item.totalPrice,
        ),
        items: migratedItems,
        destinationLabel: 'Home delivery',
        etaLabel: 'Delivered successfully',
      ),
    ];
  }

  Future<void> saveOrder({
    required List<CustomerCartItem> items,
    required CustomerOrderType orderType,
    required String paymentMethod,
    required double total,
    required String destinationLabel,
    required String etaLabel,
    required String status,
  }) async {
    if (items.isEmpty) return;

    final placedAt = DateTime.now();
    final entry = CustomerOrderHistoryEntry(
      id: _buildOrderId(placedAt),
      placedAt: placedAt,
      orderType: orderType,
      paymentMethod: paymentMethod,
      status: status,
      total: total,
      items: items.map((item) => item.copyWith()).toList(growable: false),
      destinationLabel: destinationLabel,
      etaLabel: etaLabel,
    );

    state = [entry, ...state];
    await LocalStorage.saveCustomerOrderHistory(
      state.map(_orderHistoryEntryToMap).toList(growable: false),
    );
  }
}

class CustomerCartPreviewNotifier extends Notifier<CustomerMenuItem?> {
  @override
  CustomerMenuItem? build() => null;

  void show(CustomerMenuItem menuItem) {
    state = menuItem;
  }

  void clear() {
    state = null;
  }
}

Map<String, dynamic> _cartItemToMap(CustomerCartItem item) {
  final menuItem = item.menuItem;
  return {
    'id': menuItem.id,
    'title': menuItem.title,
    'category': menuItem.category,
    'description': menuItem.description,
    'price': menuItem.price,
    'imageUrl': menuItem.imageUrl,
    'isVeg': menuItem.isVeg,
    'defaultModifiers': menuItem.defaultModifiers,
    'quantity': item.quantity,
    'modifiers': item.modifiers,
  };
}

Map<String, dynamic> _orderHistoryEntryToMap(CustomerOrderHistoryEntry entry) {
  return {
    'id': entry.id,
    'placedAt': entry.placedAt.toIso8601String(),
    'orderType': entry.orderType.name,
    'paymentMethod': entry.paymentMethod,
    'status': entry.status,
    'total': entry.total,
    'destinationLabel': entry.destinationLabel,
    'etaLabel': entry.etaLabel,
    'items': entry.items.map(_cartItemToMap).toList(growable: false),
  };
}

CustomerCartItem _cartItemFromMap(Map<String, dynamic> value) {
  List<String> stringsFor(String key) =>
      (value[key] as List?)?.map((item) => item.toString()).toList() ??
      const [];

  return CustomerCartItem(
    menuItem: CustomerMenuItem(
      id: value['id']?.toString() ?? '',
      title: value['title']?.toString() ?? 'Menu item',
      category: value['category']?.toString() ?? 'Other',
      description: value['description']?.toString() ?? '',
      price: (value['price'] as num?)?.toDouble() ?? 0,
      imageUrl: value['imageUrl']?.toString() ?? '',
      isVeg: value['isVeg'] == true,
      defaultModifiers: stringsFor('defaultModifiers'),
    ),
    quantity: (value['quantity'] as num?)?.toInt() ?? 1,
    modifiers: stringsFor('modifiers'),
  );
}

CustomerOrderHistoryEntry _orderHistoryEntryFromMap(Map<String, dynamic> value) {
  final rawItems =
      (value['items'] as List?)
          ?.whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList(growable: false) ??
      const <Map<String, dynamic>>[];
  final placedAt =
      DateTime.tryParse(value['placedAt']?.toString() ?? '') ?? DateTime.now();
  final orderType =
      value['orderType'] == CustomerOrderType.pickup.name
          ? CustomerOrderType.pickup
          : CustomerOrderType.delivery;

  return CustomerOrderHistoryEntry(
    id: value['id']?.toString() ?? _buildOrderId(placedAt),
    placedAt: placedAt,
    orderType: orderType,
    paymentMethod: value['paymentMethod']?.toString() ?? 'UPI',
    status: value['status']?.toString() ?? 'Preparing',
    total: (value['total'] as num?)?.toDouble() ?? 0,
    destinationLabel:
        value['destinationLabel']?.toString() ?? 'TasteHub customer order',
    etaLabel: value['etaLabel']?.toString() ?? 'Updates coming soon',
    items: rawItems.map(_cartItemFromMap).toList(growable: false),
  );
}

String _buildOrderId(DateTime placedAt) {
  final stamp =
      '${placedAt.month.toString().padLeft(2, '0')}${placedAt.day.toString().padLeft(2, '0')}${placedAt.hour.toString().padLeft(2, '0')}${placedAt.minute.toString().padLeft(2, '0')}';
  return 'TH$stamp';
}

final customerCartProvider =
    NotifierProvider<CustomerCartNotifier, List<CustomerCartItem>>(
      CustomerCartNotifier.new,
    );

final customerLastOrderProvider =
    NotifierProvider<CustomerLastOrderNotifier, List<CustomerCartItem>?>(
      CustomerLastOrderNotifier.new,
    );

final customerOrderHistoryProvider =
    NotifierProvider<CustomerOrderHistoryNotifier, List<CustomerOrderHistoryEntry>>(
      CustomerOrderHistoryNotifier.new,
    );

final customerCouponProvider =
    NotifierProvider<CustomerCouponNotifier, CustomerCoupon?>(
      CustomerCouponNotifier.new,
    );

final customerCartPreviewProvider =
    NotifierProvider<CustomerCartPreviewNotifier, CustomerMenuItem?>(
      CustomerCartPreviewNotifier.new,
    );

final customerOrderTypeProvider =
    NotifierProvider<CustomerOrderTypeNotifier, CustomerOrderType>(
      CustomerOrderTypeNotifier.new,
    );

final customerDietaryPreferenceProvider =
    NotifierProvider<CustomerDietaryPreferenceNotifier, CustomerDietaryMode>(
      CustomerDietaryPreferenceNotifier.new,
    );

const customerAvailableCoupons = <CustomerCoupon>[
  CustomerCoupon(
    code: 'WELCOME20',
    title: '20% off on first cravings',
    description: 'Get 20% off on orders above Rs. 299 up to Rs. 120.',
    type: CustomerCouponType.percentage,
    value: 20,
    minSubtotal: 299,
    maxDiscount: 120,
  ),
  CustomerCoupon(
    code: 'FLAT75',
    title: 'Flat savings for dinner',
    description: 'Save Rs. 75 instantly on orders above Rs. 499.',
    type: CustomerCouponType.flat,
    value: 75,
    minSubtotal: 499,
  ),
  CustomerCoupon(
    code: 'PARTY10',
    title: 'Group order special',
    description: 'Unlock 10% off on orders above Rs. 799 up to Rs. 180.',
    type: CustomerCouponType.percentage,
    value: 10,
    minSubtotal: 799,
    maxDiscount: 180,
  ),
];

final customerCartItemCountProvider = Provider<int>((ref) {
  final items = ref.watch(customerCartProvider);
  return items.fold(0, (count, item) => count + item.quantity);
});

final customerCartSummaryProvider = Provider<CustomerCartSummary>((ref) {
  const serviceChargeRate = 0.05;
  const taxRate = 0.025;
  const offerThreshold = 1000.0;

  final items = ref.watch(customerCartProvider);
  final coupon = ref.watch(customerCouponProvider);
  final itemCount = items.fold(0, (count, item) => count + item.quantity);
  final subtotal = items.fold(0.0, (sum, item) => sum + item.totalPrice);
  final discount = coupon?.calculateDiscount(subtotal) ?? 0.0;
  final discountedSubtotal = math.max(subtotal - discount, 0.0);
  final serviceCharge = discountedSubtotal * serviceChargeRate;
  final cgst = discountedSubtotal * taxRate;
  final sgst = discountedSubtotal * taxRate;
  final total = discountedSubtotal + serviceCharge + cgst + sgst;
  final amountToUnlockOffer = math.max(offerThreshold - subtotal, 0.0);
  final offerProgress = subtotal <= 0
      ? 0.0
      : math.min(subtotal / offerThreshold, 1.0);

  return CustomerCartSummary(
    itemCount: itemCount,
    subtotal: subtotal,
    discount: discount,
    discountedSubtotal: discountedSubtotal,
    serviceCharge: serviceCharge,
    cgst: cgst,
    sgst: sgst,
    total: total,
    offerThreshold: offerThreshold,
    amountToUnlockOffer: amountToUnlockOffer,
    offerProgress: offerProgress,
    appliedCoupon: discount > 0 ? coupon : null,
  );
});

String formatPrice(double amount, {bool showDecimalsForWholeNumbers = false}) {
  final formatted = amount.toStringAsFixed(2);
  if (!showDecimalsForWholeNumbers && formatted.endsWith('.00')) {
    return 'Rs. ${formatted.substring(0, formatted.length - 3)}';
  }

  return 'Rs. $formatted';
}
