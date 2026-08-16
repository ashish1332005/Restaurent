import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/network/restaurant_api.dart';

const _ink = Color(0xFF241B17);
const _saffron = Color(0xFFD66A2C);
const _green = Color(0xFF2F8A61);
const _paper = Color(0xFFFFF9F3);

class LegalDocumentScreen extends StatelessWidget {
  const LegalDocumentScreen({super.key, required this.document});
  final String document;

  @override
  Widget build(BuildContext context) {
    final privacy = document == 'privacy';
    final sections = privacy ? _privacy : _terms;
    return Scaffold(
      backgroundColor: _paper,
      appBar: AppBar(
        backgroundColor: _ink,
        foregroundColor: Colors.white,
        title: Text(privacy ? 'Privacy Policy' : 'Terms of Service'),
      ),
      body: SelectionArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 780),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _legalIcon(
                      privacy
                          ? Icons.privacy_tip_outlined
                          : Icons.gavel_outlined,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      privacy ? 'Privacy Policy' : 'Terms of Service',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 34,
                        fontWeight: FontWeight.w700,
                        color: _ink,
                      ),
                    ),
                    const Text(
                      'Last updated: 15 August 2026',
                      style: TextStyle(color: Color(0xFF806E64)),
                    ),
                    const SizedBox(height: 24),
                    ...sections.map(
                      (section) => Padding(
                        padding: const EdgeInsets.only(bottom: 22),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              section.$1,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 7),
                            Text(
                              section.$2,
                              style: const TextStyle(
                                height: 1.55,
                                color: Color(0xFF5E4C43),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Divider(height: 32),
                    const Text(
                      'Questions can be sent to the support contact published by your restaurant or SaaS administrator.',
                      style: TextStyle(color: Color(0xFF806E64)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static const _privacy = <(String, String)>[
    (
      'Information we collect',
      'We process account details, customer name and mobile number, table and order activity, service requests, payment references, device diagnostics and location only when a restaurant requires proximity verification.',
    ),
    (
      'How information is used',
      'Information is used to operate table ordering, prepare and serve orders, create bills, prevent duplicate sessions, support restaurants, improve reliability and meet legal obligations.',
    ),
    (
      'Restaurant responsibility',
      'Each restaurant is an independent tenant and controls its own customer, menu, staff and order records. Restaurants must use this information only for legitimate hospitality operations.',
    ),
    (
      'Payments',
      'Card, UPI and wallet credentials are handled by the selected payment provider. The app stores payment identifiers and status, not full card or UPI credentials.',
    ),
    (
      'Sharing and processors',
      'Data may be shared with infrastructure, payment and operational service providers only as needed to deliver the service. Tenant data is not sold.',
    ),
    (
      'Retention and security',
      'Records are retained for operational, accounting and legal needs. Access controls, tenant isolation, encrypted transport and signed payment verification are used to protect information.',
    ),
    (
      'Your choices',
      'Customers may contact the restaurant for access, correction or deletion requests, subject to accounting and legal retention requirements. Location permission can be denied, but ordering may then be unavailable where proximity verification is required.',
    ),
  ];
  static const _terms = <(String, String)>[
    (
      'Service scope',
      'The platform provides restaurant management, QR table ordering, billing and related SaaS tools. Individual restaurants remain responsible for food, pricing, availability, service and refunds.',
    ),
    (
      'Accounts and access',
      'Users must provide accurate details, protect their credentials and use only the role and restaurant access assigned to them. Sharing administrative credentials is prohibited.',
    ),
    (
      'Orders and table sessions',
      'QR orders are tied to the scanned table and an active customer session. Menu availability and final totals are confirmed by the restaurant. Misuse or fraudulent ordering may result in session termination.',
    ),
    (
      'Payments and subscriptions',
      'Customer payments are confirmed only after provider or cashier verification. Restaurant SaaS access depends on the selected subscription plan, payment status and expiry date.',
    ),
    (
      'Acceptable use',
      'Users may not disrupt the service, bypass tenant controls, access another restaurant’s data, submit unlawful content or attempt payment fraud.',
    ),
    (
      'Availability',
      'Reasonable efforts are made to keep the platform available, but uninterrupted operation is not guaranteed. Planned maintenance, provider outages and internet failures may affect access.',
    ),
    (
      'Changes and termination',
      'Features, plans and these terms may change with notice where required. Access may be suspended for non-payment, security risk, unlawful use or material breach.',
    ),
  ];
}

Widget _legalIcon(IconData icon) => Container(
  width: 62,
  height: 62,
  decoration: BoxDecoration(
    color: const Color(0xFFFFE7D6),
    borderRadius: BorderRadius.circular(18),
  ),
  child: Icon(icon, color: _saffron, size: 31),
);

class AppErrorScreen extends StatelessWidget {
  const AppErrorScreen({
    super.key,
    this.title = 'Page not found',
    this.message = 'The page you requested is unavailable.',
  });
  final String title;
  final String message;
  @override
  Widget build(BuildContext context) => _StatePage(
    icon: Icons.error_outline_rounded,
    color: _saffron,
    title: title,
    message: message,
    primaryLabel: 'Go home',
    onPrimary: () => context.go('/'),
    secondaryLabel: 'Try again',
    onSecondary: () => context.pop(),
  );
}

class OfflineScreen extends StatefulWidget {
  const OfflineScreen({super.key});
  @override
  State<OfflineScreen> createState() => _OfflineScreenState();
}

class _OfflineScreenState extends State<OfflineScreen> {
  bool checking = false;
  Future<void> _retry() async {
    setState(() => checking = true);
    try {
      final online = await RestaurantApi.checkServerHealth();
      if (!mounted) return;
      if (online) {
        context.go('/');
        return;
      }
      _message('Server is still unavailable.');
    } catch (_) {
      if (mounted) _message('Internet connection check failed.');
    }
    if (mounted) setState(() => checking = false);
  }

  void _message(String text) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(text), behavior: SnackBarBehavior.floating),
  );
  @override
  Widget build(BuildContext context) => _StatePage(
    icon: Icons.cloud_off_outlined,
    color: const Color(0xFF3B74B9),
    title: 'You are offline',
    message:
        'Check Wi-Fi or mobile data, then reconnect. Your active table session remains saved on this device.',
    primaryLabel: checking ? 'Checking…' : 'Try again',
    onPrimary: checking ? null : _retry,
    secondaryLabel: 'Open home',
    onSecondary: () => context.go('/'),
  );
}

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});
  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  Map<String, dynamic> data = {};
  bool loading = true, submitting = false;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => loading = true);
    try {
      final value = await RestaurantApi.getMySubscription();
      if (mounted) {
        setState(() {
          data = value;
          loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => loading = false);
        _message(RestaurantApi.messageFor(e));
      }
    }
  }

  Future<void> _renew() async {
    setState(() => submitting = true);
    try {
      await RestaurantApi.createSubscriptionCheckout();
      await _load();
      _message('Renewal request created. Super Admin will verify the payment.');
    } catch (e) {
      _message(RestaurantApi.messageFor(e));
    } finally {
      if (mounted) setState(() => submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final subscription = Map<String, dynamic>.from(
      data['subscription'] as Map? ?? const {},
    );
    final payments = (data['payments'] as List? ?? const [])
        .whereType<Map>()
        .toList();
    final status = '${subscription['status'] ?? 'Unavailable'}';
    final active = ['Active', 'Trial'].contains(status);
    return Scaffold(
      backgroundColor: const Color(0xFFF7F2EC),
      appBar: AppBar(
        backgroundColor: _ink,
        foregroundColor: Colors.white,
        title: const Text('Subscription'),
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator(color: _saffron))
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 820),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: _ink,
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      active
                                          ? Icons.verified
                                          : Icons.workspace_premium_outlined,
                                      color: active
                                          ? const Color(0xFF75D6AE)
                                          : const Color(0xFFFFB477),
                                    ),
                                    const Spacer(),
                                    _status(status, active),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                Text(
                                  '${subscription['plan'] ?? 'Restaurant'} plan',
                                  style: GoogleFonts.playfairDisplay(
                                    color: Colors.white,
                                    fontSize: 29,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  '${subscription['currency'] ?? 'INR'} ${subscription['amount'] ?? 0} per billing cycle',
                                  style: const TextStyle(color: Colors.white70),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Valid until ${_date(subscription['expiresAt'])}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                FilledButton.icon(
                                  onPressed: submitting ? null : _renew,
                                  style: FilledButton.styleFrom(
                                    backgroundColor: _saffron,
                                    minimumSize: const Size.fromHeight(50),
                                  ),
                                  icon: const Icon(Icons.autorenew),
                                  label: Text(
                                    submitting
                                        ? 'Creating request…'
                                        : active
                                        ? 'Renew subscription'
                                        : 'Request activation',
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'Payment history',
                            style: GoogleFonts.playfairDisplay(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: _ink,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            decoration: _box(),
                            child: payments.isEmpty
                                ? const Padding(
                                    padding: EdgeInsets.all(28),
                                    child: Text(
                                      'No subscription payments yet.',
                                      textAlign: TextAlign.center,
                                    ),
                                  )
                                : Column(
                                    children: payments.map((raw) {
                                      final payment = Map<String, dynamic>.from(
                                        raw,
                                      );
                                      final paid = payment['status'] == 'Paid';
                                      return ListTile(
                                        leading: Icon(
                                          paid
                                              ? Icons.check_circle
                                              : Icons.schedule,
                                          color: paid ? _green : _saffron,
                                        ),
                                        title: Text(
                                          '${payment['currency'] ?? 'INR'} ${payment['amount'] ?? 0}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        subtitle: Text(
                                          '${payment['provider'] ?? 'Manual'} · ${_date(payment['paidAt'] ?? payment['createdAt'])}',
                                        ),
                                        trailing: Text(
                                          '${payment['status']}',
                                          style: TextStyle(
                                            color: paid ? _green : _saffron,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                          ),
                          const SizedBox(height: 18),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              TextButton(
                                onPressed: () => context.push('/legal/terms'),
                                child: const Text('Terms'),
                              ),
                              const Text('·'),
                              TextButton(
                                onPressed: () => context.push('/legal/privacy'),
                                child: const Text('Privacy'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _status(String text, bool active) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: (active ? _green : _saffron).withValues(alpha: .18),
      borderRadius: BorderRadius.circular(18),
    ),
    child: Text(
      text,
      style: TextStyle(
        color: active ? const Color(0xFF75D6AE) : const Color(0xFFFFB477),
        fontWeight: FontWeight.w700,
      ),
    ),
  );
  String _date(dynamic raw) =>
      raw == null ? 'not set' : '$raw'.split('T').first;
  BoxDecoration _box() => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(18),
    border: Border.all(color: const Color(0xFFECE2D9)),
  );
  void _message(String text) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(text), behavior: SnackBarBehavior.floating),
      );
    }
  }
}

class _StatePage extends StatelessWidget {
  const _StatePage({
    required this.icon,
    required this.color,
    required this.title,
    required this.message,
    required this.primaryLabel,
    required this.onPrimary,
    required this.secondaryLabel,
    required this.onSecondary,
  });
  final IconData icon;
  final Color color;
  final String title, message, primaryLabel, secondaryLabel;
  final VoidCallback? onPrimary, onSecondary;
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: _paper,
    body: SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Column(
              children: [
                _legalIcon(icon),
                const SizedBox(height: 20),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 31,
                    fontWeight: FontWeight.w700,
                    color: _ink,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(height: 1.5, color: Color(0xFF806E64)),
                ),
                const SizedBox(height: 25),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: onPrimary,
                    style: FilledButton.styleFrom(
                      backgroundColor: color,
                      minimumSize: const Size.fromHeight(50),
                    ),
                    child: Text(primaryLabel),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(onPressed: onSecondary, child: Text(secondaryLabel)),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
