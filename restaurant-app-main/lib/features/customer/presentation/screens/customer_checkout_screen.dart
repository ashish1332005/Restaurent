import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/restaurant_api.dart';
import '../../../../core/storage/local_storage.dart';
import '../../../../core/theme/app_theme.dart';
import '../../application/customer_address_provider.dart';
import '../../application/customer_cart_provider.dart';
import '../../application/customer_qr_session_provider.dart';
import '../widgets/customer_address_selector_sheet.dart';

class CustomerCheckoutScreen extends ConsumerStatefulWidget {
  const CustomerCheckoutScreen({super.key});

  @override
  ConsumerState<CustomerCheckoutScreen> createState() =>
      _CustomerCheckoutScreenState();
}

class _CustomerCheckoutScreenState
    extends ConsumerState<CustomerCheckoutScreen> {
  _CheckoutPaymentMethod _selectedPaymentMethod = _CheckoutPaymentMethod.upi;

  @override
  Widget build(BuildContext context) {
    final cartItems = ref.watch(customerCartProvider);
    final summary = ref.watch(customerCartSummaryProvider);
    final selectedAddress = ref.watch(customerSelectedAddressProvider);
    final orderType = ref.watch(customerOrderTypeProvider);
    final qrSession = ref.watch(customerQrSessionProvider);

    if (cartItems.isEmpty) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          backgroundColor: Colors.white,
          foregroundColor: AppTheme.textPrimaryLight,
          title: const Text('Checkout'),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 84,
                  height: 84,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFEF2F2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.shopping_bag_outlined,
                    color: AppTheme.primaryColor,
                    size: 38,
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Your cart is empty',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimaryLight,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Add dishes first, then we will guide you through checkout here.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppTheme.textSecondaryLight,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => context.go('/customer'),
                  child: const Text('Browse Menu'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final isDelivery = orderType == CustomerOrderType.delivery;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F6FB),
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 132),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(context, isDelivery),
                        const SizedBox(height: 24),
                        _buildStatusBanner(isDelivery, qrSession),
                        const SizedBox(height: 20),
                        _buildSectionCard(
                          title: isDelivery
                              ? 'Delivery details'
                              : 'Pickup details',
                          actionLabel: 'Change',
                          onActionTap: isDelivery
                              ? () => _showAddressSheet(selectedAddress)
                              : null,
                          child: Column(
                            children: [
                              _buildInfoTile(
                                icon: isDelivery
                                    ? Icons.location_on_outlined
                                    : Icons.storefront_outlined,
                                title: isDelivery
                                    ? '${selectedAddress.label} - ${selectedAddress.title}'
                                    : 'TasteHub Downtown, Vijay Nagar',
                                subtitle: isDelivery
                                    ? selectedAddress.subtitle
                                    : 'Counter pickup opens in 12 minutes. Show order ID at the express counter.',
                              ),
                              const SizedBox(height: 12),
                              _buildInfoTile(
                                icon: Icons.person_outline_rounded,
                                title: 'Kartik Sharma',
                                subtitle: '+91 98XXXXXX21',
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        _buildSectionCard(
                          title: 'Your order',
                          actionLabel: 'Add more',
                          child: Column(
                            children: [
                              for (final item in cartItems) ...[
                                _buildOrderItem(item),
                                if (item != cartItems.last)
                                  const Divider(height: 24),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        _buildSectionCard(
                          title: 'Payment method',
                          child: Column(
                            children: _CheckoutPaymentMethod.values
                                .map(
                                  (method) => Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: _buildPaymentOption(method),
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                        const SizedBox(height: 20),
                        _buildSectionCard(
                          title: 'Bill details',
                          child: Column(
                            children: [
                              _buildAmountRow(
                                'Item total',
                                formatPrice(
                                  summary.subtotal,
                                  showDecimalsForWholeNumbers: true,
                                ),
                              ),
                              if (summary.discount > 0) ...[
                                const SizedBox(height: 12),
                                _buildAmountRow(
                                  'Coupon (${summary.appliedCoupon?.code ?? 'Offer'})',
                                  '- ${formatPrice(summary.discount, showDecimalsForWholeNumbers: true)}',
                                  valueColor: const Color(0xFF16A34A),
                                ),
                              ],
                              const SizedBox(height: 12),
                              _buildAmountRow(
                                'Service charge',
                                formatPrice(
                                  summary.serviceCharge,
                                  showDecimalsForWholeNumbers: true,
                                ),
                              ),
                              const SizedBox(height: 12),
                              _buildAmountRow(
                                'CGST',
                                formatPrice(
                                  summary.cgst,
                                  showDecimalsForWholeNumbers: true,
                                ),
                              ),
                              const SizedBox(height: 12),
                              _buildAmountRow(
                                'SGST',
                                formatPrice(
                                  summary.sgst,
                                  showDecimalsForWholeNumbers: true,
                                ),
                              ),
                              const SizedBox(height: 16),
                              const Divider(),
                              const SizedBox(height: 12),
                              _buildAmountRow(
                                'Total payable',
                                formatPrice(
                                  summary.total,
                                  showDecimalsForWholeNumbers: true,
                                ),
                                isTotal: true,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        _buildSectionCard(
                          title: 'Delivery promise',
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 42,
                                height: 42,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFFFF7ED),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.verified_user_outlined,
                                  color: Color(0xFFEA580C),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  isDelivery
                                      ? selectedAddress.deliveryHint
                                      : 'Pickup slot is reserved for the next 20 minutes. We will keep the order warm and notify you when it is bagged.',
                                  style: const TextStyle(
                                    color: AppTheme.textSecondaryLight,
                                    height: 1.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _buildBottomBar(
                context,
                summary,
                orderType,
                selectedAddress,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDelivery) {
    final compact = MediaQuery.sizeOf(context).width < 520;
    return Row(
      children: [
        _TopActionButton(
          icon: Icons.arrow_back_rounded,
          onTap: () => context.pop(),
        ),
        SizedBox(width: compact ? 8 : 12),
        Expanded(
          child: const Text(
            'Checkout',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimaryLight,
            ),
          ),
        ),
        _TopActionButton(
          icon: Icons.search_rounded,
          onTap: () => context.push('/customer/search'),
        ),
        SizedBox(width: compact ? 6 : 10),
        InkWell(
          onTap: () {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                const SnackBar(
                  content: Text(
                    'Share checkout feature will be available soon.',
                  ),
                ),
              );
          },
          borderRadius: BorderRadius.circular(999),
          child: Container(
            width: compact ? 52 : null,
            height: 52,
            padding: compact
                ? EdgeInsets.zero
                : const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: compact
                ? const Icon(
                    Icons.share_outlined,
                    size: 21,
                    color: AppTheme.textPrimaryLight,
                  )
                : const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.share_outlined,
                        size: 20,
                        color: AppTheme.textPrimaryLight,
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
    );
  }

  Widget _buildStatusBanner(bool isDelivery, dynamic qrSession) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF111827), Color(0xFF7C2D12)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              isDelivery
                  ? Icons.delivery_dining_rounded
                  : Icons.shopping_bag_outlined,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isDelivery
                      ? 'Delivery ETA 28-32 min'
                      : 'Pickup ETA 12-15 min',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 17,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isDelivery
                      ? 'Kitchen starts the order as soon as payment completes.'
                      : 'We will prep fast and keep it ready at the express shelf.',
                  style: const TextStyle(
                    color: Color(0xFFE5E7EB),
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

  Widget _buildSectionCard({
    required String title,
    String? actionLabel,
    VoidCallback? onActionTap,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimaryLight,
                  ),
                ),
              ),
              if (actionLabel != null)
                InkWell(
                  onTap: onActionTap,
                  borderRadius: BorderRadius.circular(999),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 4,
                    ),
                    child: Text(
                      actionLabel,
                      style: TextStyle(
                        color: onActionTap == null
                            ? AppTheme.textSecondaryLight
                            : AppTheme.primaryColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: Color(0xFFFEF2F2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppTheme.primaryColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimaryLight,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
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

  Widget _buildOrderItem(CustomerCartItem item) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Image.network(
            item.menuItem.imageUrl,
            width: 62,
            height: 62,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                width: 62,
                height: 62,
                color: const Color(0xFFFEF2F2),
                child: const Icon(
                  Icons.restaurant_menu_rounded,
                  color: AppTheme.primaryColor,
                ),
              );
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.menuItem.title,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimaryLight,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${item.quantity} x ${formatPrice(item.menuItem.price, showDecimalsForWholeNumbers: true)}',
                style: const TextStyle(color: AppTheme.textSecondaryLight),
              ),
              if (item.modifiers.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  item.modifiers.join(', '),
                  style: const TextStyle(
                    color: AppTheme.textSecondaryLight,
                    height: 1.4,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: 12),
        Text(
          formatPrice(item.totalPrice, showDecimalsForWholeNumbers: true),
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimaryLight,
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentOption(_CheckoutPaymentMethod method) {
    final isSelected = _selectedPaymentMethod == method;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedPaymentMethod = method;
        });
      },
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFEF2F2) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : const Color(0xFFE5E7EB),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(method.icon, color: method.color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    method.label,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimaryLight,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    method.subtitle,
                    style: const TextStyle(color: AppTheme.textSecondaryLight),
                  ),
                ],
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? AppTheme.primaryColor
                      : const Color(0xFFD1D5DB),
                  width: 2,
                ),
                color: isSelected ? AppTheme.primaryColor : Colors.white,
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAmountRow(
    String label,
    String value, {
    Color? valueColor,
    bool isTotal = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: isTotal
                ? AppTheme.textPrimaryLight
                : AppTheme.textSecondaryLight,
            fontWeight: isTotal ? FontWeight.w700 : FontWeight.w500,
            fontSize: isTotal ? 16 : 14,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color:
                valueColor ??
                (isTotal ? const Color(0xFF16A34A) : AppTheme.textPrimaryLight),
            fontWeight: FontWeight.w700,
            fontSize: isTotal ? 18 : 14,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar(
    BuildContext context,
    CustomerCartSummary summary,
    CustomerOrderType orderType,
    CustomerAddress selectedAddress,
  ) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.98),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 22,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: InkWell(
          onTap: () =>
              _placeOrder(context, orderType, selectedAddress, summary.total),
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
                        ? 'Choose address at next step'
                        : 'Confirm pickup details',
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

  Future<void> _placeOrder(
    BuildContext context,
    CustomerOrderType orderType,
    CustomerAddress selectedAddress,
    double total,
  ) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: const Text('Order confirmed'),
          content: Text(
            orderType == CustomerOrderType.delivery
                ? 'Your order is in the kitchen queue now. We will start sharing live delivery updates in the orders page.'
                : 'Your pickup slot is booked. We will notify you as soon as the bag is ready at the counter.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Close'),
            ),
            ElevatedButton(
              onPressed: () async {
                final orderItems = ref.read(customerCartProvider);
                final qrSession = ref.read(customerQrSessionProvider);
                final destinationLabel = qrSession != null
                    ? 'Table ${qrSession.tableNo}'
                    : orderType == CustomerOrderType.delivery
                    ? '${selectedAddress.label} - ${selectedAddress.title}'
                    : 'TasteHub Downtown, Vijay Nagar';
                await ref
                    .read(customerLastOrderProvider.notifier)
                    .save(orderItems);

                final liveOrderId =
                    'ORD-${1000 + DateTime.now().millisecond % 900}';
                await LocalStorage.createLiveOrder({
                  'id': liveOrderId,
                  'tableNo': qrSession != null
                      ? 'Table ${qrSession.tableNo}'
                      : orderType == CustomerOrderType.pickup
                      ? 'Pickup'
                      : 'Takeaway',
                  'waiterName': 'Customer QR Self-Order',
                  'items': orderItems
                      .map(
                        (item) => {
                          'name': item.menuItem.title,
                          'qty': item.quantity,
                          'price': item.menuItem.price,
                        },
                      )
                      .toList(),
                  'total': total,
                  'status': 'Pending',
                  'paymentStatus':
                      _selectedPaymentMethod == _CheckoutPaymentMethod.cod
                      ? 'Unpaid'
                      : 'Paid',
                  'notes': qrSession != null
                      ? 'Placed via Table ${qrSession.tableNo} QR Scan'
                      : 'Placed via Customer App',
                  'createdAt': DateTime.now().toIso8601String(),
                });

                await _tryCreateBackendOrder(
                  orderItems,
                  summary: ref.read(customerCartSummaryProvider),
                  qrSession: qrSession,
                );

                await ref
                    .read(customerOrderHistoryProvider.notifier)
                    .saveOrder(
                      items: orderItems,
                      orderType: orderType,
                      paymentMethod: _selectedPaymentMethod.label,
                      total: total,
                      destinationLabel: destinationLabel,
                      etaLabel: orderType == CustomerOrderType.delivery
                          ? 'ETA 28-32 min'
                          : 'Pickup in 12-15 min',
                      status: orderType == CustomerOrderType.delivery
                          ? 'Preparing'
                          : 'Ready for pickup',
                    );
                if (!dialogContext.mounted || !context.mounted) return;
                ref.read(customerCartProvider.notifier).clear();
                Navigator.of(dialogContext).pop();
                if (mounted) {
                  context.go('/customer/orders');
                }
              },
              child: const Text('Track order'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _tryCreateBackendOrder(
    List<CustomerCartItem> orderItems, {
    required CustomerCartSummary summary,
    required dynamic qrSession,
  }) async {
    try {
      await RestaurantApi.createOrder({
        'orderType': qrSession != null ? 'Dine-In' : 'Takeaway',
        'tableCode': qrSession?.tableNo,
        'items': orderItems
            .map(
              (item) => {
                'menuItem': item.menuItem.id,
                'quantity': item.quantity,
                'price': item.menuItem.price,
                'notes': item.modifiers.join(', '),
              },
            )
            .toList(),
        'subTotal': summary.subtotal,
        'tax': summary.cgst + summary.sgst,
        'discount': summary.discount,
        'total': summary.total,
        'kitchenNotes': qrSession != null
            ? 'Customer QR order for Table ${qrSession.tableNo}'
            : 'Customer app order',
      });
    } catch (_) {
      // Keep local live-order bridge working when backend/auth is unavailable.
    }
  }

  Future<void> _showAddressSheet(CustomerAddress selectedAddress) async {
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

class _TopActionButton extends StatelessWidget {
  const _TopActionButton({required this.icon, required this.onTap});

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
        ),
        child: Icon(icon, color: AppTheme.textPrimaryLight, size: 28),
      ),
    );
  }
}

enum _CheckoutPaymentMethod {
  upi(
    label: 'UPI',
    subtitle: 'Pay instantly with any UPI app',
    icon: Icons.qr_code_2_rounded,
    color: Color(0xFF2563EB),
    ctaNote: 'Instant confirmation',
  ),
  card(
    label: 'Card',
    subtitle: 'Credit, debit, and saved cards',
    icon: Icons.credit_card_rounded,
    color: Color(0xFF7C3AED),
    ctaNote: 'Secure card processing',
  ),
  wallet(
    label: 'Wallet',
    subtitle: 'Use cashback and wallet balance first',
    icon: Icons.account_balance_wallet_rounded,
    color: Color(0xFF059669),
    ctaNote: 'Wallet balance applied if available',
  ),
  cod(
    label: 'Cash on delivery',
    subtitle: 'Pay when the rider reaches you',
    icon: Icons.payments_outlined,
    color: Color(0xFFEA580C),
    ctaNote: 'Keep exact change ready',
  );

  const _CheckoutPaymentMethod({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.ctaNote,
  });

  final String label;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String ctaNote;
}
