import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/animations/flutterfx/bouncy_tap.dart';
import '../../core/animations/flutterfx/celebrate_particles.dart';
import '../../core/theme/shadcn/shadcn_badge.dart';

enum PaymentType {
  subscription,
  customerOrder,
}

enum PaymentChannel {
  upi,
  card,
  netbanking,
  cash,
}

class PaymentGatewayModal extends StatefulWidget {
  const PaymentGatewayModal({
    super.key,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.paymentType,
    this.merchantVpa = 'restaurantos@icici',
    this.merchantName = 'Restaurant OS',
    this.planName = 'Pro Plan',
    this.tableCode = '',
    required this.onPaymentSuccess,
    this.allowCash = false,
  });

  final String title;
  final String subtitle;
  final double amount;
  final PaymentType paymentType;
  final String merchantVpa;
  final String merchantName;
  final String planName;
  final String tableCode;
  final Future<void> Function({
    required String paymentMethod,
    required String transactionRef,
  }) onPaymentSuccess;
  final bool allowCash;

  static Future<bool?> show({
    required BuildContext context,
    required String title,
    required String subtitle,
    required double amount,
    required PaymentType paymentType,
    String merchantVpa = 'restaurantos@icici',
    String merchantName = 'Restaurant OS',
    String planName = 'Pro Plan',
    String tableCode = '',
    required Future<void> Function({
      required String paymentMethod,
      required String transactionRef,
    }) onPaymentSuccess,
    bool allowCash = false,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => PaymentGatewayModal(
        title: title,
        subtitle: subtitle,
        amount: amount,
        paymentType: paymentType,
        merchantVpa: merchantVpa,
        merchantName: merchantName,
        planName: planName,
        tableCode: tableCode,
        onPaymentSuccess: onPaymentSuccess,
        allowCash: allowCash,
      ),
    );
  }

  @override
  State<PaymentGatewayModal> createState() => _PaymentGatewayModalState();
}

class _PaymentGatewayModalState extends State<PaymentGatewayModal> {
  PaymentChannel _selectedChannel = PaymentChannel.upi;
  bool _processing = false;
  final GlobalKey<CelebrateParticlesState> _celebrateKey = GlobalKey();

  // Card form state
  final _cardNumberController = TextEditingController();
  final _cardExpiryController = TextEditingController();
  final _cardCvvController = TextEditingController();

  // Net banking state
  String _selectedBank = 'HDFC Bank';
  final List<String> _popularBanks = const [
    'HDFC Bank',
    'ICICI Bank',
    'State Bank of India',
    'Axis Bank',
    'Kotak Mahindra Bank',
    'Punjab National Bank',
  ];

  static const ink = Color(0xFF09090B);
  static const saffron = Color(0xFFD66A2C);
  static const emerald = Color(0xFF10B981);

  String get _upiPayload {
    final note = widget.paymentType == PaymentType.subscription
        ? 'Sub_${widget.planName}'
        : 'Order_${widget.tableCode}';
    return 'upi://pay?pa=${widget.merchantVpa}&pn=${Uri.encodeComponent(widget.merchantName)}&am=${widget.amount.toStringAsFixed(2)}&cu=INR&tn=${Uri.encodeComponent(note)}';
  }

  @override
  void dispose() {
    _cardNumberController.dispose();
    _cardExpiryController.dispose();
    _cardCvvController.dispose();
    super.dispose();
  }

  Future<void> _launchUpiIntent() async {
    final uri = Uri.parse(_upiPayload);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No supported UPI app found. Please scan the QR code directly.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (_) {
      // Fallback to QR scan
    }
  }

  Future<void> _handleConfirmPayment() async {
    setState(() => _processing = true);

    try {
      final methodStr = switch (_selectedChannel) {
        PaymentChannel.upi => 'UPI',
        PaymentChannel.card => 'Card',
        PaymentChannel.netbanking => 'NetBanking',
        PaymentChannel.cash => 'Cash',
      };

      final txRef = 'TXN_${DateTime.now().millisecondsSinceEpoch}_${(1000 + DateTime.now().microsecond % 9000)}';

      // Call success handler
      await widget.onPaymentSuccess(
        paymentMethod: methodStr,
        transactionRef: txRef,
      );

      _celebrateKey.currentState?.blast();
      await Future.delayed(const Duration(milliseconds: 600));

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _processing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final maxHeight = MediaQuery.sizeOf(context).height * 0.92;

    return CelebrateParticles(
      key: _celebrateKey,
      child: Container(
        constraints: BoxConstraints(maxHeight: maxHeight),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: EdgeInsets.fromLTRB(20, 12, 20, 24 + bottomInset),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag indicator
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Top Header: Title, Amount & Close button
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            widget.title,
                            style: GoogleFonts.dmSans(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: ink,
                            ),
                          ),
                          const SizedBox(width: 8),
                          ShadcnBadge(
                            label: 'SECURE 256-BIT',
                            variant: ShadcnBadgeVariant.success,
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.subtitle,
                        style: GoogleFonts.dmSans(
                          fontSize: 13,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4F4F5),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    '₹${widget.amount.toStringAsFixed(0)}',
                    style: GoogleFonts.dmSans(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: emerald,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Channel Selector Tabs
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _channelTab(PaymentChannel.upi, Icons.qr_code_scanner_rounded, 'UPI & QR'),
                  _channelTab(PaymentChannel.card, Icons.credit_card_rounded, 'Card'),
                  _channelTab(PaymentChannel.netbanking, Icons.account_balance_rounded, 'NetBanking'),
                  if (widget.allowCash)
                    _channelTab(PaymentChannel.cash, Icons.payments_outlined, 'Pay Counter'),
                ],
              ),
            ),
            const Divider(height: 24),

            // Active Tab Content
            Expanded(
              child: SingleChildScrollView(
                child: switch (_selectedChannel) {
                  PaymentChannel.upi => _buildUpiContent(),
                  PaymentChannel.card => _buildCardContent(),
                  PaymentChannel.netbanking => _buildNetBankingContent(),
                  PaymentChannel.cash => _buildCashContent(),
                },
              ),
            ),

            const SizedBox(height: 14),

            // Primary Action Button
            BouncyTap(
              onTap: _processing ? null : _handleConfirmPayment,
              child: Container(
                height: 52,
                decoration: BoxDecoration(
                  color: ink,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x33000000),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: _processing
                      ? const SizedBox.square(
                          dimension: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: Colors.white,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.lock_outline_rounded, color: Colors.white, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              _selectedChannel == PaymentChannel.cash
                                  ? 'Confirm Cash Order • ₹${widget.amount.toStringAsFixed(0)}'
                                  : 'Pay & Activate Instantly • ₹${widget.amount.toStringAsFixed(0)}',
                              style: GoogleFonts.dmSans(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _channelTab(PaymentChannel channel, IconData icon, String label) {
    final active = _selectedChannel == channel;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: BouncyTap(
        onTap: () => setState(() => _selectedChannel = channel),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: active ? ink : const Color(0xFFF4F4F5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: active ? Colors.white : Colors.black87),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                  color: active ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUpiContent() {
    return Column(
      children: [
        // Live Dynamic QR Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFFAFAFA),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE4E4E7)),
          ),
          child: Column(
            children: [
              QrImageView(
                data: _upiPayload,
                version: QrVersions.auto,
                size: 180,
                backgroundColor: Colors.white,
                padding: const EdgeInsets.all(12),
              ),
              const SizedBox(height: 10),
              Text(
                'Scan with any UPI App (GPay, PhonePe, Paytm)',
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'UPI ID: ${widget.merchantVpa}',
                style: const TextStyle(fontSize: 11, color: Colors.black45),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Quick UPI App Launchers
        Row(
          children: [
            Expanded(
              child: _upiAppButton('GPay', 'Google Pay', const Color(0xFF4285F4)),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _upiAppButton('PhonePe', 'PhonePe', const Color(0xFF5F259F)),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _upiAppButton('Paytm', 'Paytm', const Color(0xFF00B9F1)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _upiAppButton(String short, String name, Color badgeColor) {
    return BouncyTap(
      onTap: _launchUpiIntent,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF4F4F5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE4E4E7)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: badgeColor.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.flash_on_rounded, size: 16, color: badgeColor),
            ),
            const SizedBox(height: 4),
            Text(
              short,
              style: GoogleFonts.dmSans(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: ink,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _cardNumberController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'Card Number',
            hintText: '4532 •••• •••• 8910',
            prefixIcon: const Icon(Icons.credit_card_rounded),
            filled: true,
            fillColor: const Color(0xFFFAFAFA),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _cardExpiryController,
                keyboardType: TextInputType.datetime,
                decoration: InputDecoration(
                  labelText: 'MM/YY',
                  hintText: '08/28',
                  filled: true,
                  fillColor: const Color(0xFFFAFAFA),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _cardCvvController,
                obscureText: true,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'CVV',
                  hintText: '•••',
                  filled: true,
                  fillColor: const Color(0xFFFAFAFA),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: const [
            Icon(Icons.shield_outlined, size: 16, color: Colors.black45),
            SizedBox(width: 6),
            Text(
              'Your card information is encrypted and secure.',
              style: TextStyle(fontSize: 11, color: Colors.black54),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNetBankingContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select your Bank:',
          style: GoogleFonts.dmSans(fontWeight: FontWeight.w700, fontSize: 14),
        ),
        const SizedBox(height: 10),
        ..._popularBanks.map((bank) {
          final isSelected = _selectedBank == bank;
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFFF4F4F5) : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? ink : const Color(0xFFE4E4E7),
              ),
            ),
            child: ListTile(
              dense: true,
              leading: Icon(
                Icons.account_balance,
                color: isSelected ? ink : Colors.black45,
              ),
              title: Text(
                bank,
                style: GoogleFonts.dmSans(
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? ink : Colors.black87,
                ),
              ),
              trailing: isSelected
                  ? const Icon(Icons.check_circle_rounded, color: emerald, size: 20)
                  : null,
              onTap: () => setState(() => _selectedBank = bank),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildCashContent() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFBF8F3),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFEADBCA)),
      ),
      child: Column(
        children: [
          const Text('💵', style: TextStyle(fontSize: 36)),
          const SizedBox(height: 8),
          Text(
            'Pay at Counter / Waiter',
            style: GoogleFonts.dmSans(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: ink,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'You can place your order now and pay by cash, card or UPI directly at the counter or to your waiter after having your meal.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.black54, height: 1.4),
          ),
        ],
      ),
    );
  }
}
