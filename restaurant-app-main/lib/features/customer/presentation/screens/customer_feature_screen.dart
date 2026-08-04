import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/storage/local_storage.dart';
import '../../../../core/theme/app_theme.dart';
import '../../application/customer_cart_provider.dart';
import '../widgets/customer_ui.dart';

class CustomerFeatureScreen extends ConsumerWidget {
  const CustomerFeatureScreen({super.key, required this.featureKey});

  final String featureKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = _featureConfigs[featureKey] ?? _featureConfigs['search']!;
    final orderHistory = ref.watch(customerOrderHistoryProvider);
    final orderMetrics = _OrderMetrics.fromHistory(orderHistory);
    final isOrdersPage = featureKey == 'orders';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.textPrimaryLight,
        elevation: 0,
        title: Text(config.title),
      ),
      body: CustomerScreenBackground(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          children: [
            CustomerHeroCard(
              eyebrow: config.eyebrow,
              title: config.heroTitle,
              subtitle: config.subtitle,
              icon: config.icon,
              accent: config.accent,
              footer: Row(
                children: [
                  CustomerMetricPill(
                    label: isOrdersPage
                        ? 'Total orders'
                        : config.primaryMetricLabel,
                    value: isOrdersPage
                        ? '${orderMetrics.totalOrders}'
                        : config.primaryMetricValue,
                  ),
                  const SizedBox(width: 12),
                  CustomerMetricPill(
                    label: isOrdersPage
                        ? 'Last payment'
                        : config.secondaryMetricLabel,
                    value: isOrdersPage
                        ? orderMetrics.lastPaymentLabel
                        : config.secondaryMetricValue,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            if (featureKey == 'search') ...[
              CustomerSectionCard(
                title: 'Search faster',
                subtitle:
                    'Jump straight into dishes, cuisines, and your most common cravings.',
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search dishes, restaurants, cuisines...',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: IconButton(
                      onPressed: () => context.push('/customer/menu'),
                      icon: const Icon(Icons.arrow_forward_rounded),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
            if (isOrdersPage) ...[
              _OrderHistorySection(
                orders: orderHistory,
                accent: config.accent,
                onReorder: (entry) {
                  ref
                      .read(customerCartProvider.notifier)
                      .addOrderItems(entry.items);
                  ScaffoldMessenger.of(context)
                    ..hideCurrentSnackBar()
                    ..showSnackBar(
                      SnackBar(
                        content: Text(
                          '${entry.itemCount} items added back to your cart.',
                        ),
                      ),
                    );
                  context.push('/customer/cart');
                },
              ),
              const SizedBox(height: 20),
              CustomerSectionCard(
                title: 'Order insights',
                subtitle: 'Quick details from your recent TasteHub activity.',
                action: CustomerBadgeChip(
                  label: orderMetrics.liveStatusLabel,
                  icon: Icons.timelapse_rounded,
                  color: config.accent,
                ),
                child: Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    CustomerBadgeChip(
                      label: orderMetrics.lastOrderTypeLabel,
                      icon: Icons.shopping_bag_outlined,
                      color: const Color(0xFF2563EB),
                    ),
                    CustomerBadgeChip(
                      label: orderMetrics.totalSpendLabel,
                      icon: Icons.currency_rupee_rounded,
                      color: const Color(0xFF16A34A),
                    ),
                    CustomerBadgeChip(
                      label: orderMetrics.latestStatusLabel,
                      icon: Icons.local_shipping_outlined,
                      color: const Color(0xFFEA580C),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ] else ...[
              CustomerSectionCard(
                title: config.sectionTitle,
                subtitle: config.sectionSubtitle,
                action: config.sectionBadge == null
                    ? null
                    : CustomerBadgeChip(
                        label: config.sectionBadge!,
                        icon: config.sectionBadgeIcon,
                        color: config.accent,
                      ),
                child: Column(
                  children: [
                    for (var i = 0; i < config.cards.length; i++) ...[
                      _InfoCard(card: config.cards[i], accent: config.accent),
                      if (i < config.cards.length - 1)
                        const SizedBox(height: 14),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
            if (!isOrdersPage && config.highlights.isNotEmpty) ...[
              CustomerSectionCard(
                title: 'Quick highlights',
                subtitle:
                    'A few focused signals from this panel that matter most right now.',
                child: Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: config.highlights
                      .map(
                        (highlight) => CustomerBadgeChip(
                          label: highlight,
                          icon: Icons.bolt_rounded,
                          color: config.accent,
                        ),
                      )
                      .toList(),
                ),
              ),
              const SizedBox(height: 20),
            ],
            if (featureKey == 'profile') ...[
              OutlinedButton.icon(
                onPressed: () async {
                  await LocalStorage.clearToken();
                  if (context.mounted) {
                    context.go('/login');
                  }
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFDC2626),
                  side: const BorderSide(color: Color(0xFFFCA5A5)),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                icon: const Icon(Icons.logout_rounded),
                label: const Text('Logout'),
              ),
              const SizedBox(height: 20),
            ],
            if (config.primaryActionLabel != null)
              ElevatedButton(
                onPressed: () {
                  final actionPath = config.primaryActionPath;
                  if (actionPath != null) {
                    context.push(actionPath);
                  }
                },
                child: Text(config.primaryActionLabel!),
              ),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.card, required this.accent});

  final _FeatureCard card;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: card.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(card.icon, color: card.color, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  card.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimaryLight,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  card.description,
                  style: const TextStyle(
                    color: AppTheme.textSecondaryLight,
                    height: 1.45,
                  ),
                ),
                if (card.badge != null) ...[
                  const SizedBox(height: 12),
                  CustomerBadgeChip(
                    label: card.badge!,
                    icon: Icons.star_outline_rounded,
                    color: accent,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderHistorySection extends StatelessWidget {
  const _OrderHistorySection({
    required this.orders,
    required this.accent,
    required this.onReorder,
  });

  final List<CustomerOrderHistoryEntry> orders;
  final Color accent;
  final ValueChanged<CustomerOrderHistoryEntry> onReorder;

  @override
  Widget build(BuildContext context) {
    return CustomerSectionCard(
      title: 'Order history',
      subtitle:
          'Every placed order with date, payment mode, status, and item details.',
      action: CustomerBadgeChip(
        label: orders.isEmpty ? 'No orders yet' : '${orders.length} orders',
        icon: Icons.receipt_long_rounded,
        color: accent,
      ),
      child: orders.isEmpty
          ? _EmptyOrdersState(accent: accent)
          : Column(
              children: [
                for (var i = 0; i < orders.length; i++) ...[
                  _OrderHistoryCard(
                    order: orders[i],
                    accent: accent,
                    onReorder: () => onReorder(orders[i]),
                  ),
                  if (i < orders.length - 1) const SizedBox(height: 14),
                ],
              ],
            ),
    );
  }
}

class _EmptyOrdersState extends StatelessWidget {
  const _EmptyOrdersState({required this.accent});

  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(Icons.shopping_bag_outlined, color: accent),
          ),
          const SizedBox(height: 14),
          const Text(
            'No order history yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimaryLight,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Your placed orders will start appearing here in clean cards with payment and timing details.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.textSecondaryLight, height: 1.45),
          ),
        ],
      ),
    );
  }
}

class _OrderHistoryCard extends StatelessWidget {
  const _OrderHistoryCard({
    required this.order,
    required this.accent,
    required this.onReorder,
  });

  final CustomerOrderHistoryEntry order;
  final Color accent;
  final VoidCallback onReorder;

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(order.status);
    final visibleItems = order.items.take(4).toList(growable: false);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFCFDFE),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE6ECF3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Order #${order.id}',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimaryLight,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _formatOrderDate(order.placedAt),
                      style: const TextStyle(
                        color: AppTheme.textSecondaryLight,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              CustomerBadgeChip(
                label: order.status,
                icon: Icons.circle,
                color: statusColor,
                backgroundColor: statusColor.withValues(alpha: 0.12),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MetaChip(
                icon: order.orderType == CustomerOrderType.delivery
                    ? Icons.delivery_dining_rounded
                    : Icons.storefront_rounded,
                label: order.orderType == CustomerOrderType.delivery
                    ? 'Delivery'
                    : 'Pickup',
                color: const Color(0xFF2563EB),
              ),
              _MetaChip(
                icon: _paymentIcon(order.paymentMethod),
                label: order.paymentMethod,
                color: const Color(0xFF7C3AED),
              ),
              _MetaChip(
                icon: Icons.timelapse_rounded,
                label: order.etaLabel,
                color: accent,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            order.destinationLabel,
            style: const TextStyle(
              color: AppTheme.textPrimaryLight,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE9EEF5)),
            ),
            child: Column(
              children: [
                for (var i = 0; i < visibleItems.length; i++) ...[
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${visibleItems[i].menuItem.title} x${visibleItems[i].quantity}',
                          style: const TextStyle(
                            color: AppTheme.textPrimaryLight,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Text(
                        _formatPrice(visibleItems[i].totalPrice),
                        style: const TextStyle(
                          color: AppTheme.textPrimaryLight,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  if (i < visibleItems.length - 1) const SizedBox(height: 10),
                ],
                if (order.items.length > visibleItems.length) ...[
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '+${order.items.length - visibleItems.length} more items',
                      style: const TextStyle(
                        color: AppTheme.textSecondaryLight,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Order total',
                      style: TextStyle(
                        color: AppTheme.textSecondaryLight,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatPrice(order.total),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.textPrimaryLight,
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: onReorder,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 13,
                  ),
                ),
                icon: const Icon(Icons.replay_rounded, size: 18),
                label: const Text('Reorder'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 15),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(color: color, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _OrderMetrics {
  const _OrderMetrics({
    required this.totalOrders,
    required this.lastPaymentLabel,
    required this.totalSpendLabel,
    required this.liveStatusLabel,
    required this.lastOrderTypeLabel,
    required this.latestStatusLabel,
  });

  final int totalOrders;
  final String lastPaymentLabel;
  final String totalSpendLabel;
  final String liveStatusLabel;
  final String lastOrderTypeLabel;
  final String latestStatusLabel;

  factory _OrderMetrics.fromHistory(List<CustomerOrderHistoryEntry> orders) {
    if (orders.isEmpty) {
      return const _OrderMetrics(
        totalOrders: 0,
        lastPaymentLabel: '--',
        totalSpendLabel: 'Rs. 0',
        liveStatusLabel: 'No live order',
        lastOrderTypeLabel: 'No order type',
        latestStatusLabel: 'No status',
      );
    }

    final latestOrder = orders.first;
    final activeOrders = orders.where((order) {
      final lowered = order.status.toLowerCase();
      return !lowered.contains('delivered') && !lowered.contains('cancelled');
    }).length;
    final totalSpend = orders.fold<double>(
      0,
      (sum, order) => sum + order.total,
    );

    return _OrderMetrics(
      totalOrders: orders.length,
      lastPaymentLabel: latestOrder.paymentMethod,
      totalSpendLabel: _formatPrice(totalSpend),
      liveStatusLabel: activeOrders > 0
          ? '$activeOrders live order'
          : 'No live order',
      lastOrderTypeLabel: latestOrder.orderType == CustomerOrderType.delivery
          ? 'Last order: Delivery'
          : 'Last order: Pickup',
      latestStatusLabel: 'Latest: ${latestOrder.status}',
    );
  }
}

Color _statusColor(String status) {
  final lowered = status.toLowerCase();
  if (lowered.contains('deliver')) return const Color(0xFF16A34A);
  if (lowered.contains('ready')) return const Color(0xFF2563EB);
  if (lowered.contains('cancel')) return const Color(0xFFDC2626);
  return const Color(0xFFEA580C);
}

IconData _paymentIcon(String paymentMethod) {
  final lowered = paymentMethod.toLowerCase();
  if (lowered.contains('upi')) return Icons.qr_code_2_rounded;
  if (lowered.contains('wallet')) {
    return Icons.account_balance_wallet_rounded;
  }
  if (lowered.contains('cash')) return Icons.payments_outlined;
  return Icons.credit_card_rounded;
}

String _formatPrice(double value) {
  final hasDecimals = value != value.roundToDouble();
  return 'Rs. ${value.toStringAsFixed(hasDecimals ? 2 : 0)}';
}

String _formatOrderDate(DateTime value) {
  const months = <String>[
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  final hour = value.hour % 12 == 0 ? 12 : value.hour % 12;
  final minutes = value.minute.toString().padLeft(2, '0');
  final suffix = value.hour >= 12 ? 'PM' : 'AM';
  return '${value.day} ${months[value.month - 1]} ${value.year}, $hour:$minutes $suffix';
}

class _FeatureConfig {
  const _FeatureConfig({
    required this.title,
    required this.eyebrow,
    required this.heroTitle,
    required this.subtitle,
    required this.icon,
    required this.accent,
    required this.cards,
    required this.primaryMetricLabel,
    required this.primaryMetricValue,
    required this.secondaryMetricLabel,
    required this.secondaryMetricValue,
    required this.sectionTitle,
    required this.sectionSubtitle,
    this.sectionBadge,
    this.sectionBadgeIcon,
    this.highlights = const [],
    this.primaryActionLabel,
    this.primaryActionPath,
  });

  final String title;
  final String eyebrow;
  final String heroTitle;
  final String subtitle;
  final IconData icon;
  final Color accent;
  final List<_FeatureCard> cards;
  final String primaryMetricLabel;
  final String primaryMetricValue;
  final String secondaryMetricLabel;
  final String secondaryMetricValue;
  final String sectionTitle;
  final String sectionSubtitle;
  final String? sectionBadge;
  final IconData? sectionBadgeIcon;
  final List<String> highlights;
  final String? primaryActionLabel;
  final String? primaryActionPath;
}

class _FeatureCard {
  const _FeatureCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    this.badge,
  });

  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final String? badge;
}

const _featureConfigs = <String, _FeatureConfig>{
  'search': _FeatureConfig(
    title: 'Search',
    eyebrow: 'QUICK DISCOVERY',
    heroTitle: 'Find the next craving without slowing down.',
    subtitle:
        'Quickly find dishes, cuisines, and your previous cravings from one focused discovery panel.',
    icon: Icons.search_rounded,
    accent: Color(0xFF2563EB),
    primaryMetricLabel: 'Popular queries',
    primaryMetricValue: '12',
    secondaryMetricLabel: 'Recent looks',
    secondaryMetricValue: '6',
    sectionTitle: 'Search suggestions',
    sectionSubtitle:
        'Shortcuts that help customers jump into the right menu faster.',
    sectionBadge: 'Smart shortcuts',
    sectionBadgeIcon: Icons.auto_awesome_rounded,
    highlights: ['Pizzas trending', 'Desserts rising', 'Repeat combo detected'],
    cards: [
      _FeatureCard(
        title: 'Popular searches',
        description:
            'Pizza, burger combos, pasta bowls, desserts, and cold drinks are leading current demand.',
        icon: Icons.local_fire_department_outlined,
        color: Color(0xFFF97316),
        badge: 'Trending',
      ),
      _FeatureCard(
        title: 'Recent activity',
        description:
            'Surface recently viewed dishes and bring frequent reorders closer to the top.',
        icon: Icons.history_rounded,
        color: Color(0xFF0EA5E9),
      ),
    ],
    primaryActionLabel: 'Browse full menu',
    primaryActionPath: '/customer/menu',
  ),
  'orders': _FeatureConfig(
    title: 'Your Orders',
    eyebrow: 'ORDER TRACKING',
    heroTitle: 'Keep live orders and reorders in one calm place.',
    subtitle:
        'Track active orders and quickly reorder your favorites without hopping between tabs.',
    icon: Icons.shopping_bag_rounded,
    accent: Color(0xFFCA8A04),
    primaryMetricLabel: 'Active orders',
    primaryMetricValue: '1',
    secondaryMetricLabel: 'Saved reorders',
    secondaryMetricValue: '3',
    sectionTitle: 'Order timeline',
    sectionSubtitle:
        'The latest activity on deliveries and quick repeat orders.',
    sectionBadge: 'Live',
    sectionBadgeIcon: Icons.delivery_dining_rounded,
    highlights: [
      'ETA 18 mins',
      'Kitchen finished packing',
      'Reorder combo saved',
    ],
    cards: [
      _FeatureCard(
        title: 'Order #TH1024',
        description: 'Out for delivery right now with an ETA of 18 minutes.',
        icon: Icons.delivery_dining_rounded,
        color: Color(0xFF16A34A),
        badge: 'In transit',
      ),
      _FeatureCard(
        title: 'Reorder combo',
        description:
            'Margherita Pizza, Garlic Bread, and Cola saved for one-tap repeat.',
        icon: Icons.replay_rounded,
        color: Color(0xFF2563EB),
      ),
    ],
    primaryActionLabel: 'Order something new',
    primaryActionPath: '/customer/menu',
  ),
  'reservations': _FeatureConfig(
    title: 'Reservations',
    eyebrow: 'DINE-IN PLANNER',
    heroTitle: 'Keep table plans and visit notes easy to revisit.',
    subtitle:
        'Manage dine-in bookings, timings, and table preferences from a clearer customer-side booking view.',
    icon: Icons.event_available_rounded,
    accent: Color(0xFF9333EA),
    primaryMetricLabel: 'Upcoming visits',
    primaryMetricValue: '1',
    secondaryMetricLabel: 'Preferences saved',
    secondaryMetricValue: '2',
    sectionTitle: 'Reservation details',
    sectionSubtitle: 'Everything saved for your next dine-in plan.',
    sectionBadge: 'Booked',
    sectionBadgeIcon: Icons.check_circle_outline_rounded,
    highlights: [
      'Window table requested',
      'Reminder enabled',
      'Guest count locked',
    ],
    cards: [
      _FeatureCard(
        title: 'Saturday, July 18 • 8:00 PM',
        description:
            'Table for 4 at TasteHub Downtown is still confirmed for tonight.',
        icon: Icons.table_restaurant_rounded,
        color: Color(0xFF9333EA),
        badge: 'Confirmed',
      ),
      _FeatureCard(
        title: 'Special note',
        description:
            'Window-side seating request has been captured successfully.',
        icon: Icons.note_alt_outlined,
        color: Color(0xFFF97316),
      ),
    ],
    primaryActionLabel: 'Book a new table',
    primaryActionPath: '/customer/menu',
  ),
  'offers': _FeatureConfig(
    title: 'Offers & Coupons',
    eyebrow: 'SAVINGS BOARD',
    heroTitle: 'See the deals worth using before checkout.',
    subtitle:
        'Keep live deals, referral perks, and wallet cashback offers together in a more polished savings view.',
    icon: Icons.local_offer_rounded,
    accent: Color(0xFF059669),
    primaryMetricLabel: 'Usable offers',
    primaryMetricValue: '4',
    secondaryMetricLabel: 'Potential savings',
    secondaryMetricValue: '\u20B9240',
    sectionTitle: 'Active savings',
    sectionSubtitle: 'Current offers most relevant to your next order.',
    sectionBadge: 'Best value',
    sectionBadgeIcon: Icons.discount_outlined,
    highlights: [
      'WELCOME20 ready',
      'Night delivery free',
      'Wallet cashback live',
    ],
    cards: [
      _FeatureCard(
        title: 'WELCOME20',
        description: 'Get 20% off on your first order above Rs. 299.',
        icon: Icons.discount_outlined,
        color: Color(0xFF059669),
        badge: 'Available now',
      ),
      _FeatureCard(
        title: 'Free Delivery Night',
        description:
            'No delivery charge after 9 PM on Saturday, July 18, 2026.',
        icon: Icons.nightlight_round,
        color: Color(0xFF2563EB),
      ),
    ],
    primaryActionLabel: 'Apply offer on menu',
    primaryActionPath: '/customer/menu',
  ),
  'wallet': _FeatureConfig(
    title: 'Wallet',
    eyebrow: 'BALANCE VIEW',
    heroTitle: 'Keep credits and cashback visible before you pay.',
    subtitle:
        'Check credits, cashback history, and saved payment balance from a calmer wallet panel.',
    icon: Icons.account_balance_wallet_rounded,
    accent: Color(0xFF2563EB),
    primaryMetricLabel: 'Available balance',
    primaryMetricValue: '\u20B9420',
    secondaryMetricLabel: 'Pending cashback',
    secondaryMetricValue: '\u20B950',
    sectionTitle: 'Wallet activity',
    sectionSubtitle: 'Balance and reward signals ready for your next order.',
    sectionBadge: 'Cashback active',
    sectionBadgeIcon: Icons.savings_outlined,
    highlights: [
      'Use on next cart',
      'Cashback pending',
      'No expiry this month',
    ],
    cards: [
      _FeatureCard(
        title: 'Available balance',
        description: 'Rs. 420 is ready to use on your next order.',
        icon: Icons.account_balance_wallet_outlined,
        color: Color(0xFF2563EB),
      ),
      _FeatureCard(
        title: 'Cashback incoming',
        description:
            'Rs. 50 cashback will be added after your active delivery closes.',
        icon: Icons.savings_outlined,
        color: Color(0xFF16A34A),
      ),
    ],
  ),
  'notifications': _FeatureConfig(
    title: 'Notifications',
    eyebrow: 'UPDATES HUB',
    heroTitle: 'Keep the important updates easy to spot.',
    subtitle:
        'Stay updated on order status, deals, and reservation reminders without feeling flooded.',
    icon: Icons.notifications_none_rounded,
    accent: Color(0xFFEF4444),
    primaryMetricLabel: 'Unread alerts',
    primaryMetricValue: '2',
    secondaryMetricLabel: 'Priority updates',
    secondaryMetricValue: '1',
    sectionTitle: 'Latest notifications',
    sectionSubtitle: 'Recent events that matter most for the customer journey.',
    sectionBadge: 'Recent',
    sectionBadgeIcon: Icons.notifications_active_outlined,
    highlights: [
      'Order left kitchen',
      'Deal unlocked',
      'Visit reminder tomorrow',
    ],
    cards: [
      _FeatureCard(
        title: 'Order update',
        description:
            'Your pizza just left the kitchen and is moving into dispatch.',
        icon: Icons.restaurant_rounded,
        color: Color(0xFFF97316),
        badge: 'Fresh update',
      ),
      _FeatureCard(
        title: 'New deal',
        description:
            'Flat Rs. 100 off on combo orders is live for a limited time.',
        icon: Icons.local_offer_outlined,
        color: Color(0xFF16A34A),
      ),
    ],
  ),
  'profile': _FeatureConfig(
    title: 'Profile',
    eyebrow: 'ACCOUNT SPACE',
    heroTitle: 'Keep identity, addresses, and preferences together.',
    subtitle:
        'Manage your details, delivery addresses, and saved preferences from a neater profile panel.',
    icon: Icons.person_outline_rounded,
    accent: Color(0xFF0F172A),
    primaryMetricLabel: 'Saved addresses',
    primaryMetricValue: '2',
    secondaryMetricLabel: 'Preferences',
    secondaryMetricValue: '4',
    sectionTitle: 'Profile details',
    sectionSubtitle: 'Core personal information and delivery preferences.',
    sectionBadge: 'Secure',
    sectionBadgeIcon: Icons.verified_user_outlined,
    highlights: ['Phone verified', 'Home default', 'Notifications enabled'],
    cards: [
      _FeatureCard(
        title: 'Personal info',
        description: 'Kartik Sharma, +91 98XXXXXX21, kartik@email.com',
        icon: Icons.badge_outlined,
        color: Color(0xFF2563EB),
      ),
      _FeatureCard(
        title: 'Saved address',
        description: 'Home: 21 MG Road, Indore, Madhya Pradesh',
        icon: Icons.location_on_outlined,
        color: Color(0xFFEF4444),
      ),
    ],
  ),
  'favorites': _FeatureConfig(
    title: 'Favorites',
    eyebrow: 'SAVED TASTES',
    heroTitle: 'Keep comfort picks ready for the next order.',
    subtitle:
        'Your saved dishes and restaurants stay organized here for faster reordering.',
    icon: Icons.favorite_border_rounded,
    accent: Color(0xFFDC2626),
    primaryMetricLabel: 'Saved dishes',
    primaryMetricValue: '6',
    secondaryMetricLabel: 'Ready to reorder',
    secondaryMetricValue: '2',
    sectionTitle: 'Favorite picks',
    sectionSubtitle: 'The dishes you come back to most often.',
    sectionBadge: 'Saved',
    sectionBadgeIcon: Icons.favorite_outline_rounded,
    highlights: ['Cheesy picks', 'Weekend desserts', 'Quick reorder ready'],
    cards: [
      _FeatureCard(
        title: 'Cheesy picks',
        description:
            'Margherita Pizza and Garlic Bread saved for a quick repeat.',
        icon: Icons.favorite_outline_rounded,
        color: Color(0xFFDC2626),
        badge: 'Most reordered',
      ),
      _FeatureCard(
        title: 'Weekend treats',
        description: 'Desserts and shakes saved for your next indulgent order.',
        icon: Icons.icecream_outlined,
        color: Color(0xFFF97316),
      ),
    ],
    primaryActionLabel: 'Open full menu',
    primaryActionPath: '/customer/menu',
  ),
};
