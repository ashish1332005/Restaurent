import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../admin/presentation/widgets/cart/action_cards.dart';
import '../../../admin/presentation/widgets/cart/cart_item_card.dart';
import '../../../admin/presentation/widgets/cart/order_instructions_section.dart';
import '../../../admin/presentation/widgets/cart/order_summary_card.dart';
import '../../../admin/presentation/widgets/cart/order_type_selector.dart';
import '../../application/customer_address_provider.dart';
import '../../application/customer_cart_provider.dart';
import '../widgets/customer_address_selector_sheet.dart';

class CustomerCartScreen extends ConsumerWidget {
  const CustomerCartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final compact = MediaQuery.sizeOf(context).width < 420;
    final cartItems = ref.watch(customerCartProvider);
    final summary = ref.watch(customerCartSummaryProvider);
    final selectedCoupon = ref.watch(customerCouponProvider);
    final selectedAddress = ref.watch(customerSelectedAddressProvider);
    final orderType = ref.watch(customerOrderTypeProvider);
    final cartNotifier = ref.read(customerCartProvider.notifier);

    final isCartEmpty = cartItems.isEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F6FB),
      body: SafeArea(
        bottom: false,
        child: isCartEmpty
            ? _EmptyCartView(
                onBrowseMenu: () => context.go('/customer'),
                onBackTap: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go('/customer');
                  }
                },
                onSearchTap: () => context.push('/customer/search'),
                onShareTap: () {
                  ScaffoldMessenger.of(context)
                    ..hideCurrentSnackBar()
                    ..showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Share cart feature will be available soon.',
                        ),
                      ),
                    );
                },
              )
            : Stack(
                children: [
                  CustomScrollView(
                    physics: const BouncingScrollPhysics(),
                    slivers: [
                      SliverToBoxAdapter(
                        child: Column(
                          children: [
                            _CheckoutTopBar(
                              onSearchTap: () =>
                                  context.push('/customer/search'),
                              onShareTap: () {
                                ScaffoldMessenger.of(context)
                                  ..hideCurrentSnackBar()
                                  ..showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Share cart feature will be available soon.',
                                      ),
                                    ),
                                  );
                              },
                              onBackTap: () {
                                if (context.canPop()) {
                                  context.pop();
                                } else {
                                  context.go('/customer');
                                }
                              },
                            ),
                            const SizedBox(height: 10),
                            _ShipmentCard(
                              itemCount: summary.itemCount,
                              cartItems: cartItems,
                              onIncrease: (id) => cartNotifier.increment(id),
                              onDecrease: (id) => cartNotifier.decrement(id),
                              onRemove: (id) => cartNotifier.remove(id),
                            ),
                            const SizedBox(height: 18),
                            Container(
                              margin: EdgeInsets.symmetric(
                                horizontal: compact ? 16 : 24,
                              ),
                              padding: const EdgeInsets.fromLTRB(
                                18,
                                18,
                                18,
                                20,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(28),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.04),
                                    blurRadius: 18,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Complete your order',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                      color: AppTheme.textPrimaryLight,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  const Text(
                                    'Delivery mode, address, offers aur final details yahin manage karo.',
                                    style: TextStyle(
                                      color: AppTheme.textSecondaryLight,
                                      height: 1.4,
                                    ),
                                  ),
                                  const SizedBox(height: 18),
                                  OrderTypeSelector(
                                    itemCount: summary.itemCount,
                                    primaryLabel: 'Delivery',
                                    secondaryLabel: 'Pickup',
                                    primarySelected:
                                        orderType == CustomerOrderType.delivery,
                                    onPrimaryTap: () {
                                      ref
                                          .read(
                                            customerOrderTypeProvider.notifier,
                                          )
                                          .setOrderType(
                                            CustomerOrderType.delivery,
                                          );
                                    },
                                    onSecondaryTap: () {
                                      ref
                                          .read(
                                            customerOrderTypeProvider.notifier,
                                          )
                                          .setOrderType(
                                            CustomerOrderType.pickup,
                                          );
                                    },
                                  ),
                                  if (orderType ==
                                      CustomerOrderType.delivery) ...[
                                    const SizedBox(height: 18),
                                    _DeliveryAddressCard(
                                      address: selectedAddress,
                                      onChangeTap: () => _showAddressSheet(
                                        context,
                                        ref,
                                        selectedAddress,
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 18),
                                  AddMoreItemsCard(
                                    onTap: () => context.go('/customer'),
                                  ),
                                  const SizedBox(height: 12),
                                  ApplyCouponCard(
                                    title:
                                        selectedCoupon != null &&
                                            summary.discount > 0
                                        ? '${selectedCoupon.code} applied'
                                        : 'Apply Coupon',
                                    subtitle:
                                        selectedCoupon != null &&
                                            summary.discount > 0
                                        ? 'You saved ${formatPrice(summary.discount, showDecimalsForWholeNumbers: true)} on this order'
                                        : 'Save more on your order',
                                    applied:
                                        selectedCoupon != null &&
                                        summary.discount > 0,
                                    onTap: () => _showCouponSheet(
                                      context,
                                      ref,
                                      summary,
                                      selectedCoupon,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                            OrderSummaryCard(summary: summary),
                            const SizedBox(height: 24),
                            const OrderInstructionsSection(),
                            const SizedBox(height: 126),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: _ChooseAddressBottomBar(
                      orderType: orderType,
                      onTap: () {
                        if (orderType == CustomerOrderType.delivery) {
                          _showAddressSheet(context, ref, selectedAddress);
                          return;
                        }
                        context.push('/customer/checkout');
                      },
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Future<void> _showCouponSheet(
    BuildContext context,
    WidgetRef ref,
    CustomerCartSummary summary,
    CustomerCoupon? selectedCoupon,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return _CouponSheet(
          summary: summary,
          selectedCoupon: selectedCoupon,
          onApply: (coupon) {
            ref.read(customerCouponProvider.notifier).applyCoupon(coupon);
            Navigator.of(sheetContext).pop();
          },
          onRemove: () {
            ref.read(customerCouponProvider.notifier).removeCoupon();
            Navigator.of(sheetContext).pop();
          },
        );
      },
    );
  }

  Future<void> _showAddressSheet(
    BuildContext context,
    WidgetRef ref,
    CustomerAddress selectedAddress,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return CustomerAddressSelectorSheet(
          selectedAddress: selectedAddress,
          onSelected: (address) {
            ref
                .read(customerSelectedAddressProvider.notifier)
                .selectAddress(address);
            Navigator.of(sheetContext).pop();
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(
                  content: Text(
                    'Delivery address changed to ${address.label}.',
                  ),
                ),
              );
          },
        );
      },
    );
  }
}

class _CheckoutTopBar extends StatelessWidget {
  const _CheckoutTopBar({
    required this.onBackTap,
    required this.onSearchTap,
    required this.onShareTap,
  });

  final VoidCallback onBackTap;
  final VoidCallback onSearchTap;
  final VoidCallback onShareTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
      child: Row(
        children: [
          _TopCircleButton(icon: Icons.arrow_back_rounded, onTap: onBackTap),
          const SizedBox(width: 14),
          const Expanded(
            child: Text(
              'Checkout',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimaryLight,
              ),
            ),
          ),
          _TopCircleButton(icon: Icons.search_rounded, onTap: onSearchTap),
          const SizedBox(width: 10),
          InkWell(
            onTap: onShareTap,
            borderRadius: BorderRadius.circular(999),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: const Color(0xFFE5E7EB)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.share_outlined,
                    color: AppTheme.textPrimaryLight,
                    size: 22,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Share',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimaryLight,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TopCircleButton extends StatelessWidget {
  const _TopCircleButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFE5E7EB)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(icon, color: AppTheme.textPrimaryLight, size: 28),
      ),
    );
  }
}

class _ShipmentCard extends StatelessWidget {
  const _ShipmentCard({
    required this.itemCount,
    required this.cartItems,
    required this.onIncrease,
    required this.onDecrease,
    required this.onRemove,
  });

  final int itemCount;
  final List<CustomerCartItem> cartItems;
  final ValueChanged<String> onIncrease;
  final ValueChanged<String> onDecrease;
  final ValueChanged<String> onRemove;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 420;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: compact ? 16 : 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
            child: Row(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.access_time_rounded,
                    color: Color(0xFF2F9E1F),
                    size: 30,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Delivery in 10 minutes',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimaryLight,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Shipment of $itemCount ${itemCount == 1 ? 'item' : 'items'}',
                        style: const TextStyle(
                          color: AppTheme.textSecondaryLight,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          const SizedBox(height: 6),
          for (final item in cartItems)
            CartItemCard(
              title: item.menuItem.title,
              price: formatPrice(item.totalPrice),
              quantity: item.quantity,
              modifiers: item.modifiers,
              imageUrl: item.menuItem.imageUrl,
              onIncrease: () => onIncrease(item.menuItem.id),
              onDecrease: () => onDecrease(item.menuItem.id),
              onRemove: () => onRemove(item.menuItem.id),
            ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}

class _ChooseAddressBottomBar extends StatelessWidget {
  const _ChooseAddressBottomBar({required this.orderType, required this.onTap});

  final CustomerOrderType orderType;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.98),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            decoration: BoxDecoration(
              color: const Color(0xFFDDF2FF),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFB8E3F7)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    orderType == CustomerOrderType.delivery
                        ? 'Choose address'
                        : 'Continue to checkout',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F4C81),
                    ),
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Color(0xFF0F4C81),
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DeliveryAddressCard extends StatelessWidget {
  const _DeliveryAddressCard({
    required this.address,
    required this.onChangeTap,
  });

  final CustomerAddress address;
  final VoidCallback onChangeTap;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 420;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: const BoxDecoration(
              color: Color(0xFFFEF2F2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.location_on_outlined,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        '${address.label} address',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimaryLight,
                        ),
                      ),
                    ),
                    SizedBox(width: compact ? 8 : 12),
                    InkWell(
                      onTap: onChangeTap,
                      borderRadius: BorderRadius.circular(999),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        child: Text(
                          'Change',
                          style: TextStyle(
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  address.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimaryLight,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  address.subtitle,
                  style: const TextStyle(
                    color: AppTheme.textSecondaryLight,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CouponSheet extends StatelessWidget {
  const _CouponSheet({
    required this.summary,
    required this.selectedCoupon,
    required this.onApply,
    required this.onRemove,
  });

  final CustomerCartSummary summary;
  final CustomerCoupon? selectedCoupon;
  final ValueChanged<CustomerCoupon> onApply;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFD1D5DB),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Apply a coupon',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryLight,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Choose a promo code for your current subtotal of ${formatPrice(summary.subtotal, showDecimalsForWholeNumbers: true)}.',
              style: const TextStyle(
                color: AppTheme.textSecondaryLight,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            ...customerAvailableCoupons.map((coupon) {
              final isEligible = coupon.isEligible(summary.subtotal);
              final isSelected =
                  selectedCoupon?.code == coupon.code && summary.discount > 0;
              final savings = coupon.calculateDiscount(summary.subtotal);

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFFF0FDF4)
                        : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF86EFAC)
                          : const Color(0xFFE5E7EB),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: const Color(0xFFE5E7EB),
                              ),
                            ),
                            child: Text(
                              coupon.code,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textPrimaryLight,
                              ),
                            ),
                          ),
                          const Spacer(),
                          if (isEligible)
                            Text(
                              'Save ${formatPrice(savings, showDecimalsForWholeNumbers: true)}',
                              style: const TextStyle(
                                color: Color(0xFF16A34A),
                                fontWeight: FontWeight.w700,
                              ),
                            )
                          else
                            Text(
                              'Need ${formatPrice(coupon.minSubtotal - summary.subtotal, showDecimalsForWholeNumbers: true)} more',
                              style: const TextStyle(
                                color: Color(0xFFDC2626),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text(
                        coupon.title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimaryLight,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        coupon.description,
                        style: const TextStyle(
                          color: AppTheme.textSecondaryLight,
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: isSelected
                              ? onRemove
                              : isEligible
                              ? () => onApply(coupon)
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isSelected
                                ? const Color(0xFF166534)
                                : AppTheme.primaryColor,
                            disabledBackgroundColor: const Color(0xFFE5E7EB),
                            disabledForegroundColor: const Color(0xFF9CA3AF),
                          ),
                          child: Text(
                            isSelected
                                ? 'Remove Coupon'
                                : isEligible
                                ? 'Apply Coupon'
                                : 'Add More Items',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _EmptyCartView extends StatelessWidget {
  const _EmptyCartView({
    required this.onBrowseMenu,
    required this.onBackTap,
    required this.onSearchTap,
    required this.onShareTap,
  });

  final VoidCallback onBrowseMenu;
  final VoidCallback onBackTap;
  final VoidCallback onSearchTap;
  final VoidCallback onShareTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _CheckoutTopBar(
          onBackTap: onBackTap,
          onSearchTap: onSearchTap,
          onShareTap: onShareTap,
        ),
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 96,
                    height: 96,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFEF2F2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.shopping_bag_outlined,
                      size: 42,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Your cart is empty',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimaryLight,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Add dishes from the home page and we will take you here for checkout.',
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      color: AppTheme.textSecondaryLight,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 28),
                  ElevatedButton(
                    onPressed: onBrowseMenu,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Browse Menu',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
