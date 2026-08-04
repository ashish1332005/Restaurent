import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/restaurant_api.dart';
import '../../../../core/theme/app_theme.dart';
import '../../application/customer_cart_provider.dart';

class CustomerCouponsScreen extends ConsumerStatefulWidget {
  const CustomerCouponsScreen({super.key});

  @override
  ConsumerState<CustomerCouponsScreen> createState() =>
      _CustomerCouponsScreenState();
}

class _CustomerCouponsScreenState extends ConsumerState<CustomerCouponsScreen> {
  late Future<List<_CouponView>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<_CouponView>> _load() async =>
      (await RestaurantApi.getAvailableCoupons())
          .map(_CouponView.fromJson)
          .toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.textPrimaryLight,
        title: const Text(
          'Coupons',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: FutureBuilder<List<_CouponView>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _MessageState(
              icon: Icons.cloud_off_rounded,
              title: RestaurantApi.messageFor(snapshot.error!),
              buttonLabel: 'Try again',
              onPressed: () {
                setState(() {
                  _future = _load();
                });
              },
            );
          }
          final coupons = snapshot.data ?? const [];
          if (coupons.isEmpty) {
            return const _MessageState(
              icon: Icons.local_offer_outlined,
              title: 'No deals found',
            );
          }
          return RefreshIndicator(
            onRefresh: () async {
              final request = _load();
              setState(() {
                _future = request;
              });
              await request;
            },
            child: ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: coupons.length,
              separatorBuilder: (_, _) => const SizedBox(height: 18),
              itemBuilder: (_, index) => _CouponCard(
                coupon: coupons[index],
                onApply: () => _apply(coupons[index]),
              ),
            ),
          );
        },
      ),
    );
  }

  void _apply(_CouponView coupon) {
    final mapped = CustomerCoupon(
      code: coupon.code,
      title: coupon.description,
      description: coupon.description,
      type: coupon.type == 'percentage'
          ? CustomerCouponType.percentage
          : CustomerCouponType.flat,
      value: coupon.value,
      minSubtotal: coupon.minOrder,
      maxDiscount: coupon.maxDiscount,
    );
    final subtotal = ref.read(customerCartSummaryProvider).subtotal;
    if (!mapped.isEligible(subtotal)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Add items worth ${formatPrice(coupon.minOrder)} to use this coupon.',
          ),
        ),
      );
      return;
    }
    ref.read(customerCouponProvider.notifier).applyCoupon(mapped);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('${coupon.code} applied')));
    context.push('/cart');
  }
}

class _CouponCard extends StatefulWidget {
  const _CouponCard({required this.coupon, required this.onApply});
  final _CouponView coupon;
  final VoidCallback onApply;
  @override
  State<_CouponCard> createState() => _CouponCardState();
}

class _CouponCardState extends State<_CouponCard> {
  bool expanded = false;
  @override
  Widget build(BuildContext context) {
    final coupon = widget.coupon;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final narrow = constraints.maxWidth < 390;
          final details = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFD5D8DE)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.percent_rounded,
                      color: Color(0xFF075C9E),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey, width: 1.5),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        coupon.code,
                        style: const TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.w900,
                          letterSpacing: .6,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                coupon.description,
                style: const TextStyle(
                  fontSize: 17,
                  color: Color(0xFF666666),
                  height: 1.45,
                ),
              ),
              TextButton.icon(
                onPressed: () => setState(() => expanded = !expanded),
                iconAlignment: IconAlignment.end,
                icon: Icon(
                  expanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                ),
                label: const Text('More Details'),
              ),
              if (expanded)
                Text(
                  'Minimum order ${formatPrice(coupon.minOrder)} • Valid until ${coupon.expiryLabel}',
                  style: const TextStyle(
                    color: AppTheme.textSecondaryLight,
                    fontSize: 12,
                  ),
                ),
            ],
          );
          final action = Column(
            children: [
              Text(
                coupon.savingLabel,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF098A26),
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: narrow ? double.infinity : 145,
                child: ElevatedButton(
                  onPressed: widget.onApply,
                  child: const Text('Apply'),
                ),
              ),
            ],
          );
          if (narrow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [details, const Divider(height: 28), action],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(flex: 3, child: details),
              const SizedBox(height: 190, child: VerticalDivider()),
              const SizedBox(width: 18),
              Expanded(flex: 2, child: action),
            ],
          );
        },
      ),
    );
  }
}

class _MessageState extends StatelessWidget {
  const _MessageState({
    required this.icon,
    required this.title,
    this.buttonLabel,
    this.onPressed,
  });
  final IconData icon;
  final String title;
  final String? buttonLabel;
  final VoidCallback? onPressed;
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 58, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
          if (buttonLabel != null) ...[
            const SizedBox(height: 16),
            OutlinedButton(onPressed: onPressed, child: Text(buttonLabel!)),
          ],
        ],
      ),
    ),
  );
}

class _CouponView {
  const _CouponView({
    required this.code,
    required this.description,
    required this.type,
    required this.value,
    required this.minOrder,
    required this.maxDiscount,
    required this.expiresAt,
  });
  final String code, description, type;
  final double value, minOrder;
  final double? maxDiscount;
  final DateTime expiresAt;
  factory _CouponView.fromJson(Map<String, dynamic> json) => _CouponView(
    code: json['code']?.toString() ?? '',
    description: json['description']?.toString() ?? '',
    type: json['discountType']?.toString() ?? 'flat',
    value: (json['discountValue'] as num?)?.toDouble() ?? 0,
    minOrder: (json['minOrder'] as num?)?.toDouble() ?? 0,
    maxDiscount: (json['maxDiscount'] as num?)?.toDouble(),
    expiresAt:
        DateTime.tryParse(json['expiresAt']?.toString() ?? '') ??
        DateTime.now(),
  );
  String get savingLabel => type == 'percentage'
      ? 'Save $value%${maxDiscount == null ? '' : '\nup to ${formatPrice(maxDiscount!)}'}'
      : 'Save\n${formatPrice(value)}';
  String get expiryLabel =>
      '${expiresAt.day}/${expiresAt.month}/${expiresAt.year}';
}
