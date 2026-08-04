import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/cart_models.dart';

final cartProvider =
    NotifierProvider<CartNotifier, CartState>(CartNotifier.new);

class CartNotifier extends Notifier<CartState> {
  @override
  CartState build() => const CartState();

  void addItem(CartItem item) {
    final existingIndex = state.items.indexWhere(
      (cartItem) => cartItem.id == item.id,
    );

    if (existingIndex == -1) {
      state = state.copyWith(items: [...state.items, item]);
      return;
    }

    final updatedItems = [...state.items];
    final existingItem = updatedItems[existingIndex];
    updatedItems[existingIndex] = existingItem.copyWith(
      quantity: existingItem.quantity + item.quantity,
    );
    state = state.copyWith(items: updatedItems);
  }

  void incrementItem(String itemId) {
    state = state.copyWith(
      items: state.items
          .map(
            (item) => item.id == itemId
                ? item.copyWith(quantity: item.quantity + 1)
                : item,
          )
          .toList(),
    );
  }

  void decrementItem(String itemId) {
    final updatedItems = <CartItem>[];

    for (final item in state.items) {
      if (item.id != itemId) {
        updatedItems.add(item);
        continue;
      }

      if (item.quantity > 1) {
        updatedItems.add(item.copyWith(quantity: item.quantity - 1));
      }
    }

    state = state.copyWith(items: updatedItems);
  }

  void removeItem(String itemId) {
    state = state.copyWith(
      items: state.items.where((item) => item.id != itemId).toList(),
    );
  }

  void clearCart() {
    state = state.copyWith(items: const []);
  }

  void setFulfillmentType(FulfillmentType fulfillmentType) {
    state = state.copyWith(fulfillmentType: fulfillmentType);
  }
}
