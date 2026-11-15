import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/animations/flutterfx/animated_price_ticker.dart';
import '../../core/animations/flutterfx/bouncy_tap.dart';
import '../../core/animations/flutterfx/celebrate_particles.dart';

class CheckoutModalSheet extends StatefulWidget {
  const CheckoutModalSheet({
    super.key,
    required this.cartEntries,
    required this.menuItems,
    required this.choiceFor,
    required this.configuredUnitPrice,
    required this.subtotal,
    required this.customerNameController,
    required this.customerPhoneController,
    required this.tableCode,
    required this.tableName,
    required this.restaurantName,
    required this.preferHindi,
    required this.availableCoins,
    required this.onPlaceOrder,
    this.initialNotes = '',
    this.initialCoupon = '',
  });

  final List<MapEntry<String, int>> cartEntries;
  final List<Map<String, dynamic>> menuItems;
  final Map<String, dynamic> Function(String key) choiceFor;
  final double Function(Map<String, dynamic> item, Map<String, dynamic> choice) configuredUnitPrice;
  final double subtotal;
  final TextEditingController customerNameController;
  final TextEditingController customerPhoneController;
  final String tableCode;
  final String tableName;
  final String restaurantName;
  final bool preferHindi;
  final int availableCoins;
  final Future<void> Function({
    required String notes,
    required String couponCode,
    required int redeemPoints,
  }) onPlaceOrder;
  final String initialNotes;
  final String initialCoupon;

  @override
  State<CheckoutModalSheet> createState() => _CheckoutModalSheetState();
}

class _CheckoutModalSheetState extends State<CheckoutModalSheet> {
  final _couponController = TextEditingController();
  final _notesController = TextEditingController();
  final Set<String> _selectedQuickNotes = {};
  final GlobalKey<CelebrateParticlesState> _celebrateKey = GlobalKey();

  String? _appliedCoupon;
  double _couponDiscount = 0;
  bool _useLoyaltyCoins = false;
  int _redeemPoints = 0;
  bool _submitting = false;

  static const saffron = Color(0xFFC99232);
  static const ink = Color(0xFF071A31);
  static const leaf = Color(0xFF237A59);

  final List<String> _quickNoteOptions = const [
    '🌶️ Less Spicy',
    '🧅 No Onion/Garlic',
    '🔥 Serve Hot',
    '🧂 Less Salt',
    'Extra Napkins',
    'Cutlery please',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialCoupon.isNotEmpty) {
      _couponController.text = widget.initialCoupon;
      _applyCoupon(widget.initialCoupon);
    }
    if (widget.initialNotes.isNotEmpty) {
      _notesController.text = widget.initialNotes;
    }
  }

  @override
  void dispose() {
    _couponController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _applyCoupon(String rawCode) {
    final code = rawCode.trim().toUpperCase();
    if (code.isEmpty) return;

    double discount = 0;
    if (code == 'FLAT50') {
      discount = widget.subtotal >= 200 ? 50 : 0;
    } else if (code == 'WELCOME10') {
      discount = widget.subtotal * 0.10;
    } else if (code == 'FESTIVE20') {
      discount = (widget.subtotal * 0.20).clamp(0, 150);
    } else {
      discount = widget.subtotal >= 100 ? (widget.subtotal * 0.10).clamp(0, 100) : 0;
    }

    if (discount > 0) {
      setState(() {
        _appliedCoupon = code;
        _couponDiscount = discount;
      });
      _celebrateKey.currentState?.blast();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🎉 Coupon "$code" applied! Saved ₹${discount.toStringAsFixed(0)}'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: leaf,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid coupon or minimum order amount not met.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _removeCoupon() {
    setState(() {
      _appliedCoupon = null;
      _couponDiscount = 0;
      _couponController.clear();
    });
  }

  double get _tax => (widget.subtotal - _couponDiscount).clamp(0, double.infinity) * 0.05;

  double get _grandTotal {
    final base = (widget.subtotal - _couponDiscount + _tax);
    final withLoyalty = base - _redeemPoints;
    return withLoyalty < 0 ? 0 : withLoyalty;
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return CelebrateParticles(
      key: _celebrateKey,
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFFFFFDF9),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: EdgeInsets.fromLTRB(20, 14, 20, 20 + bottomInset),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.90,
        ),
        child: Column(
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Header
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.preferHindi ? 'आपका ऑर्डर' : 'Review Your Order',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: ink,
                        ),
                      ),
                      Text(
                        '${widget.restaurantName} • ${widget.tableName}',
                        style: GoogleFonts.dmSans(
                          fontSize: 13,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Cart Items Card
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFFF0EAE1)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ITEMS ORDERED',
                            style: GoogleFonts.dmSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                              color: Colors.black45,
                            ),
                          ),
                          const SizedBox(height: 10),
                          ...widget.cartEntries.map((entry) {
                            final choice = widget.choiceFor(entry.key);
                            final itemId = '${choice['menuItem']}';
                            final item = widget.menuItems
                                .where((e) => '${e['_id']}' == itemId)
                                .firstOrNull;
                            if (item == null) return const SizedBox.shrink();

                            final unitPrice = widget.configuredUnitPrice(item, choice);
                            final totalItemPrice = unitPrice * entry.value;
                            final variant = '${choice['selectedVariant'] ?? ''}';
                            final addOns = ((choice['selectedAddOns'] as List?) ?? const [])
                                .map((e) => '$e')
                                .toList();
                            final details = [
                              if (variant.isNotEmpty) variant,
                              if (addOns.isNotEmpty) addOns.join(', '),
                            ];

                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFF1D6),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      '${entry.value}x',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12,
                                        color: saffron,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          widget.preferHindi && (item['nameHi']?.toString().isNotEmpty ?? false)
                                              ? '${item['nameHi']}'
                                              : '${item['name'] ?? ''}',
                                          style: GoogleFonts.dmSans(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 14,
                                            color: ink,
                                          ),
                                        ),
                                        if (details.isNotEmpty)
                                          Text(
                                            details.join(' · '),
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: Colors.black54,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    '₹${totalItemPrice.toStringAsFixed(0)}',
                                    style: GoogleFonts.dmSans(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                      color: ink,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Cooking Instructions Box
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFFF0EAE1)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'COOKING INSTRUCTIONS',
                            style: GoogleFonts.dmSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                              color: Colors.black45,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: _quickNoteOptions.map((option) {
                              final isSelected = _selectedQuickNotes.contains(option);
                              return FilterChip(
                                label: Text(option),
                                selected: isSelected,
                                selectedColor: const Color(0xFFFFF1D6),
                                checkmarkColor: saffron,
                                labelStyle: TextStyle(
                                  fontSize: 11,
                                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                  color: isSelected ? saffron : Colors.black87,
                                ),
                                onSelected: (selected) {
                                  setState(() {
                                    selected
                                        ? _selectedQuickNotes.add(option)
                                        : _selectedQuickNotes.remove(option);
                                  });
                                },
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _notesController,
                            style: const TextStyle(fontSize: 13),
                            decoration: InputDecoration(
                              hintText: 'Any special kitchen instructions? (e.g. less salt)',
                              hintStyle: const TextStyle(fontSize: 12, color: Colors.black38),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              filled: true,
                              fillColor: const Color(0xFFFBF8F3),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Promo Code Box
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFFF0EAE1)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.discount_outlined, color: saffron, size: 18),
                              const SizedBox(width: 8),
                              Text(
                                'COUPONS & OFFERS',
                                style: GoogleFonts.dmSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.8,
                                  color: Colors.black45,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          if (_appliedCoupon != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE8F5E9),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: leaf),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.check_circle_rounded, color: leaf, size: 18),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Coupon "$_appliedCoupon" applied (₹${_couponDiscount.toStringAsFixed(0)} saved!)',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13,
                                        color: leaf,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: _removeCoupon,
                                    icon: const Icon(Icons.close_rounded, size: 18, color: Colors.black54),
                                  ),
                                ],
                              ),
                            )
                          else
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _couponController,
                                    textCapitalization: TextCapitalization.characters,
                                    decoration: InputDecoration(
                                      hintText: 'Enter coupon code (e.g. FLAT50)',
                                      hintStyle: const TextStyle(fontSize: 12),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                      filled: true,
                                      fillColor: const Color(0xFFFBF8F3),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide.none,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                BouncyTap(
                                  onTap: () => _applyCoupon(_couponController.text),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
                                    decoration: BoxDecoration(
                                      color: ink,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Text(
                                      'Apply',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 6,
                            children: [
                              _couponChip('FLAT50', '₹50 off on ₹200+'),
                              _couponChip('WELCOME10', '10% off'),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Loyalty Coins Toggle (If available)
                    if (widget.availableCoins > 0)
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF9ED),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: const Color(0xFFFFE0A3)),
                        ),
                        child: Row(
                          children: [
                            const Text('🪙', style: TextStyle(fontSize: 24)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Redeem Loyalty Coins',
                                    style: GoogleFonts.dmSans(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                      color: ink,
                                    ),
                                  ),
                                  Text(
                                    'Use ${widget.availableCoins} coins to save ₹${widget.availableCoins}',
                                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                                  ),
                                ],
                              ),
                            ),
                            Switch(
                              value: _useLoyaltyCoins,
                              activeColor: saffron,
                              onChanged: (val) {
                                setState(() {
                                  _useLoyaltyCoins = val;
                                  _redeemPoints = val
                                      ? widget.availableCoins.clamp(0, widget.subtotal.toInt())
                                      : 0;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    if (widget.availableCoins > 0) const SizedBox(height: 14),

                    // Customer Details Card
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFFF0EAE1)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'DINER DETAILS',
                            style: GoogleFonts.dmSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                              color: Colors.black45,
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: widget.customerNameController,
                            decoration: const InputDecoration(
                              labelText: 'Your Name',
                              prefixIcon: Icon(Icons.person_outline, size: 20),
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: widget.customerPhoneController,
                            keyboardType: TextInputType.phone,
                            maxLength: 10,
                            decoration: const InputDecoration(
                              labelText: '10-digit Mobile Number',
                              prefixIcon: Icon(Icons.phone_outlined, size: 20),
                              border: OutlineInputBorder(),
                              counterText: '',
                              isDense: true,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Bill Summary Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFFF0EAE1)),
                      ),
                      child: Column(
                        children: [
                          _summaryRow('Item Subtotal', widget.subtotal),
                          if (_couponDiscount > 0)
                            _summaryRow('Coupon Discount ($_appliedCoupon)', -_couponDiscount, isDiscount: true),
                          if (_redeemPoints > 0)
                            _summaryRow('Loyalty Coins Redeemed', -_redeemPoints.toDouble(), isDiscount: true),
                          _summaryRow('GST (5%)', _tax),
                          const Divider(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'To Pay',
                                style: GoogleFonts.dmSans(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                  color: ink,
                                ),
                              ),
                              AnimatedPriceTicker(
                                amount: _grandTotal,
                                prefix: '₹',
                                style: GoogleFonts.dmSans(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: leaf,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
            // Submit Button with BouncyTap
            BouncyTap(
              onTap: _submitting
                  ? null
                  : () async {
                      final name = widget.customerNameController.text.trim();
                      final digits = widget.customerPhoneController.text.replaceAll(RegExp(r'\D'), '');
                      if (name.length < 2 || digits.length != 10) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please enter a valid name and 10-digit mobile number.'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                        return;
                      }

                      setState(() => _submitting = true);
                      try {
                        final notesList = [
                          ..._selectedQuickNotes,
                          if (_notesController.text.trim().isNotEmpty) _notesController.text.trim(),
                        ];
                        await widget.onPlaceOrder(
                          notes: notesList.join(', '),
                          couponCode: _appliedCoupon ?? '',
                          redeemPoints: _redeemPoints,
                        );
                        _celebrateKey.currentState?.blast();
                        await Future.delayed(const Duration(milliseconds: 300));
                        if (context.mounted) Navigator.pop(context);
                      } catch (e) {
                        if (context.mounted) {
                          setState(() => _submitting = false);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(e.toString().replaceFirst('Exception: ', '')),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      }
                    },
              child: Container(
                height: 54,
                decoration: BoxDecoration(
                  color: saffron,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x33C99232),
                      blurRadius: 12,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: _submitting
                      ? const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.rocket_launch_rounded, color: Colors.white, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Send Order to Kitchen • ₹${_grandTotal.toStringAsFixed(0)}',
                              style: GoogleFonts.dmSans(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
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

  Widget _couponChip(String code, String desc) => BouncyTap(
        onTap: () {
          _couponController.text = code;
          _applyCoupon(code);
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: const Color(0xFFF4EFE6),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE2D6C5)),
          ),
          child: Text(
            '$code: $desc',
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF5A483E)),
          ),
        ),
      );

  Widget _summaryRow(String label, double amount, {bool isDiscount = false}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: GoogleFonts.dmSans(
                fontSize: 13,
                color: isDiscount ? leaf : Colors.black54,
                fontWeight: isDiscount ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
            Text(
              '${amount < 0 ? '-' : ''}₹${amount.abs().toStringAsFixed(0)}',
              style: GoogleFonts.dmSans(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDiscount ? leaf : ink,
              ),
            ),
          ],
        ),
      );
}
