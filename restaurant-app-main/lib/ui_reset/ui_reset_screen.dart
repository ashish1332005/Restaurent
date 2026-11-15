import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/animations/flutterfx/bouncy_tap.dart';
import '../core/animations/flutterfx/fade_slide_reveal.dart';
import '../core/animations/flutterfx/pulsing_badge.dart';
import '../core/network/restaurant_api.dart';
import '../core/services/location_service.dart';
import '../core/storage/local_storage.dart';
import 'widgets/checkout_modal_sheet.dart';
import 'widgets/customer_loyalty_badge.dart';
import 'widgets/delight_feedback_sheet.dart';
import 'widgets/floating_cart_bar.dart';
import 'widgets/food_menu_card.dart';
import 'widgets/highlights_carousel.dart';
import 'widgets/live_order_timeline.dart';
import 'widgets/veg_non_veg_badge.dart';
import 'widgets/wifi_dialog.dart';

class UiResetScreen extends StatefulWidget {
  const UiResetScreen({super.key, this.initialTableCode});
  final String? initialTableCode;

  @override
  State<UiResetScreen> createState() => _UiResetScreenState();
}

class _UiResetScreenState extends State<UiResetScreen> {
  static const saffron = Color(0xFFC99232);
  static const ink = Color(0xFF071A31);
  static const leaf = Color(0xFF237A59);

  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _code = TextEditingController();
  final _search = TextEditingController();

  final Map<String, int> _cart = {};
  final Map<String, Map<String, dynamic>> _cartChoices = {};

  Map<String, dynamic>? _venue;
  Map<String, dynamic>? _order;
  Map<String, dynamic>? _customerLoyalty;

  String? _tableCode;
  String? _sessionToken;
  String _category = 'All';
  bool _loading = false;
  bool _customerReady = false;
  bool _preferHindi = false;
  bool _vegOnly = false;

  final Set<String> _dietaryFilters = {};
  final Set<String> _allergenExclusions = {};
  final Set<String> _spiceFilters = {};

  Timer? _timer;
  Timer? _paymentTimer;

  List<Map<String, dynamic>> get _menu =>
      ((_venue?['menu'] as List?) ?? const [])
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();

  String get _restaurantName =>
      ((_venue?['restaurant'] as Map?)?['name'] ?? 'Atithi Dining').toString();

  String get _restaurantLogo =>
      RestaurantApi.mediaUrl((_venue?['restaurant'] as Map?)?['logo']);

  String get _tableName =>
      ((_venue?['table'] as Map?)?['name'] ??
              (_venue?['table'] as Map?)?['tableNumber'] ??
              'Table')
          .toString();

  String get _wifiPassword =>
      ((_venue?['branch'] as Map?)?['wifiPassword'] ??
              (_venue?['restaurant'] as Map?)?['wifiPassword'] ??
              '')
          .toString();

  String get _googleReviewUrl =>
      ((_venue?['branch'] as Map?)?['googleReviewUrl'] ??
              (_venue?['restaurant'] as Map?)?['googleReviewUrl'] ??
              '')
          .toString();

  Map<String, dynamic> get _highlights =>
      ((_venue?['restaurant'] as Map?)?['highlights'] as Map?)
          ?.cast<String, dynamic>() ??
      const {};

  List<Map<String, dynamic>> get _bestsellers =>
      ((_highlights['bestsellers'] as List?) ?? const [])
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();

  List<Map<String, dynamic>> get _chefSpecials =>
      ((_highlights['chefSpecials'] as List?) ?? const [])
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();

  List<String> get _categories => [
        'All',
        ..._menu
            .map((e) => ((e['categoryId'] as Map?)?['name'] ?? 'Other').toString())
            .toSet(),
      ];

  List<Map<String, dynamic>> get _visibleMenu {
    final query = _search.text.trim().toLowerCase();
    return _menu.where((item) {
      final category =
          ((item['categoryId'] as Map?)?['name'] ?? 'Other').toString();
      if (_category != 'All' && category != _category) return false;
      if (_vegOnly && item['isVeg'] == false) return false;

      final dietary = ((item['dietaryTags'] as List?) ?? const [])
          .map((value) => '$value')
          .toSet();
      if (!_dietaryFilters.every(dietary.contains)) return false;

      final allergens = ((item['allergens'] as List?) ?? const [])
          .map((value) => '$value')
          .toSet();
      if (_allergenExclusions.any(allergens.contains)) return false;

      final spice = '${item['spiceLevel'] ?? 'None'}';
      if (_spiceFilters.isNotEmpty && !_spiceFilters.contains(spice)) {
        return false;
      }

      if (query.isEmpty) return true;
      final searchable = [
        item['name'],
        item['nameHi'],
        item['description'],
        item['descriptionHi'],
        category,
        (item['categoryId'] as Map?)?['nameHi'],
        ...dietary,
      ].whereType<Object>().map((value) => '$value'.toLowerCase()).join(' ');

      return searchable.contains(query);
    }).toList();
  }

  int get _activeFilterCount =>
      (_vegOnly ? 1 : 0) +
      _dietaryFilters.length +
      _allergenExclusions.length +
      _spiceFilters.length;

  int get _cartCount => _cart.values.fold(0, (a, b) => a + b);

  String _localized(dynamic english, dynamic hindi) {
    final primary = english?.toString().trim() ?? '';
    final translated = hindi?.toString().trim() ?? '';
    if (_preferHindi && translated.isNotEmpty) return translated;
    return primary.isNotEmpty ? primary : translated;
  }

  String _categoryLabel(String categoryName) {
    if (categoryName == 'All') return _preferHindi ? 'सभी' : 'All';
    final category = _menu
        .map((item) => item['categoryId'])
        .whereType<Map>()
        .cast<Map>()
        .where((value) => '${value['name'] ?? 'Other'}' == categoryName)
        .firstOrNull;
    return _localized(category?['name'], category?['nameHi']);
  }

  Map<String, dynamic> _choiceFor(String cartKey) =>
      _cartChoices[cartKey] ??
      <String, dynamic>{
        'menuItem': cartKey,
        'selectedVariant': '',
        'selectedAddOns': <String>[],
      };

  Map<String, dynamic>? _menuItemForCartKey(String cartKey) {
    final itemId = '${_choiceFor(cartKey)['menuItem']}';
    return _menu.where((item) => '${item['_id']}' == itemId).firstOrNull;
  }

  double _configuredUnitPrice(
    Map<String, dynamic> item,
    Map<String, dynamic> choice,
  ) {
    final variantName = '${choice['selectedVariant'] ?? ''}';
    final variants =
        ((item['variants'] as List?) ?? const []).whereType<Map>();
    final variant = variants
        .where((entry) => '${entry['name']}' == variantName)
        .firstOrNull;
    var price = (variant?['price'] as num?)?.toDouble() ??
        (item['basePrice'] as num?)?.toDouble() ??
        0;
    final selectedAddOns = ((choice['selectedAddOns'] as List?) ?? const [])
        .map((value) => '$value')
        .toSet();
    for (final modifier
        in ((item['modifiers'] as List?) ?? const []).whereType<Map>()) {
      if (selectedAddOns.contains('${modifier['name']}')) {
        price += (modifier['price'] as num?)?.toDouble() ?? 0;
      }
    }
    return price;
  }

  double get _subtotal => _cart.entries.fold(0, (sum, entry) {
        final item = _menuItemForCartKey(entry.key);
        if (item == null) return sum;
        return sum +
            _configuredUnitPrice(item, _choiceFor(entry.key)) * entry.value;
      });

  int _quantityForItem(String itemId) => _cart.entries
      .where((entry) => '${_choiceFor(entry.key)['menuItem']}' == itemId)
      .fold(0, (sum, entry) => sum + entry.value);

  Map<String, int> get _cartQuantitiesByItemId {
    final result = <String, int>{};
    for (final entry in _cart.entries) {
      final itemId = '${_choiceFor(entry.key)['menuItem']}';
      result[itemId] = (result[itemId] ?? 0) + entry.value;
    }
    return result;
  }

  @override
  void initState() {
    super.initState();
    final saved = LocalStorage.getCustomerTableSession();
    final code = widget.initialTableCode ?? saved?['tableCode']?.toString();
    _sessionToken = saved?['sessionToken']?.toString();
    _customerReady = _sessionToken != null && _sessionToken!.isNotEmpty;
    _name.text = saved?['customerName']?.toString() ?? '';
    _phone.text = saved?['customerPhone']?.toString() ?? '';
    if (code != null && code.isNotEmpty) {
      Future.microtask(() => _loadTable(code, restore: true));
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _paymentTimer?.cancel();
    _name.dispose();
    _phone.dispose();
    _code.dispose();
    _search.dispose();
    super.dispose();
  }

  String _extractCode(String raw) {
    final value = raw.trim();
    final uri = Uri.tryParse(value);
    if (uri != null && uri.hasScheme) {
      final query = uri.queryParameters['table'] ?? uri.queryParameters['code'];
      if (query != null && query.isNotEmpty) return query;
      final parts = uri.pathSegments;
      if (parts.isNotEmpty) return parts.last;
    }
    return value;
  }

  Future<void> _loadTable(String raw, {bool restore = false}) async {
    final code = _extractCode(raw);
    if (code.isEmpty) return;
    setState(() => _loading = true);
    try {
      final data = await RestaurantApi.getQrTable(code);
      if (!mounted) return;
      setState(() {
        _venue = data;
        _tableCode = code;
        _loading = false;
      });
      if (_phone.text.trim().isNotEmpty) {
        _fetchCustomerLoyalty();
      }
      if (restore && _sessionToken != null) await _refreshOrder();
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        _message(RestaurantApi.messageFor(e));
      }
    }
  }

  Future<void> _fetchCustomerLoyalty() async {
    if (_tableCode == null || _phone.text.trim().length != 10) return;
    try {
      final data = await RestaurantApi.getCustomerLoyaltyInfo(
        _tableCode!,
        _phone.text.trim(),
      );
      if (mounted) {
        setState(() => _customerLoyalty = data);
      }
    } catch (_) {
      // Ignore background loyalty fetch errors silently
    }
  }

  Future<void> _openScanner() async {
    var handled = false;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: ink,
      builder: (sheetContext) => SafeArea(
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * .72,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.qr_code_scanner, color: Colors.white),
                    const SizedBox(width: 10),
                    Text(
                      'Scan Table QR',
                      style: GoogleFonts.dmSans(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(sheetContext),
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: MobileScanner(
                    onDetect: (capture) {
                      final raw = capture.barcodes.firstOrNull?.rawValue;
                      if (!handled && raw != null) {
                        handled = true;
                        Navigator.pop(sheetContext);
                        _loadTable(raw);
                      }
                    },
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(sheetContext);
                  _manualCode();
                },
                child: const Text(
                  'Enter code instead',
                  style: TextStyle(color: Color(0xFFFFC46B)),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _manualCode() async {
    final value = await showDialog<String>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Enter Table Code'),
        content: TextField(
          controller: _code,
          autofocus: true,
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.table_restaurant),
            hintText: 'e.g. TABLE-4',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, _code.text),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
    if (value != null) _loadTable(value);
  }

  void _changeQty(String cartKey, int delta) => setState(() {
        final next = (_cart[cartKey] ?? 0) + delta;
        if (next <= 0) {
          _cart.remove(cartKey);
          _cartChoices.remove(cartKey);
        } else {
          _cart[cartKey] = next;
        }
      });

  void _decreaseMenuItem(String itemId) {
    final key = _cart.keys
        .where((value) => '${_choiceFor(value)['menuItem']}' == itemId)
        .lastOrNull;
    if (key != null) _changeQty(key, -1);
  }

  Future<void> _addMenuItem(Map<String, dynamic> item) async {
    final variants = ((item['variants'] as List?) ?? const [])
        .whereType<Map>()
        .map((entry) => Map<String, dynamic>.from(entry))
        .toList();
    final modifiers = ((item['modifiers'] as List?) ?? const [])
        .whereType<Map>()
        .map((entry) => Map<String, dynamic>.from(entry))
        .toList();
    final itemId = '${item['_id']}';

    if (variants.isEmpty && modifiers.isEmpty) {
      _cartChoices[itemId] = {
        'menuItem': itemId,
        'selectedVariant': '',
        'selectedAddOns': <String>[],
      };
      _changeQty(itemId, 1);
      return;
    }

    var selectedVariant = variants.isEmpty ? '' : '${variants.first['name']}';
    final selectedAddOns = <String>{};

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFFFFFDF9),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) => StatefulBuilder(
        builder: (_, setSheetState) {
          final choice = <String, dynamic>{
            'selectedVariant': selectedVariant,
            'selectedAddOns': selectedAddOns.toList(),
          };
          final unitPrice = _configuredUnitPrice(item, choice);
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 22),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 42,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.black26,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        VegNonVegBadge(isVeg: item['isVeg'] != false, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _localized(item['name'], item['nameHi']),
                            style: GoogleFonts.playfairDisplay(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: ink,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (variants.isNotEmpty) ...[
                      const SizedBox(height: 18),
                      Text(
                        _preferHindi
                            ? 'साइज़ / विकल्प चुनें'
                            : 'Choose Variant',
                        style: GoogleFonts.dmSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...variants.map((v) {
                        final vName = '${v['name']}';
                        final isSelected = selectedVariant == vName;
                        final vPrice = (v['price'] as num?)?.toDouble() ?? 0;
                        return BouncyTap(
                          onTap: () =>
                              setSheetState(() => selectedVariant = vName),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 6),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFFFFF1D6)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? saffron
                                    : const Color(0xFFE6DED2),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  isSelected
                                      ? Icons.radio_button_checked
                                      : Icons.radio_button_off,
                                  color: isSelected ? saffron : Colors.black38,
                                  size: 20,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    _localized(v['name'], v['nameHi']),
                                    style: TextStyle(
                                      fontWeight: isSelected
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                    ),
                                  ),
                                ),
                                Text(
                                  '₹${vPrice.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ],
                    if (modifiers.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(
                        _preferHindi ? 'ऐड-ऑन चुनें' : 'Choose Add-ons',
                        style: GoogleFonts.dmSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...modifiers.map((modifier) {
                        final name = '${modifier['name']}';
                        final isSelected = selectedAddOns.contains(name);
                        final mPrice =
                            (modifier['price'] as num?)?.toDouble() ?? 0;
                        return CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                          value: isSelected,
                          activeColor: saffron,
                          onChanged: (selected) => setSheetState(() {
                            selected == true
                                ? selectedAddOns.add(name)
                                : selectedAddOns.remove(name);
                          }),
                          title: Text(
                            _localized(modifier['name'], modifier['nameHi']),
                            style: TextStyle(
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                          ),
                          secondary: Text(
                            '+₹${mPrice.toStringAsFixed(0)}',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        );
                      }),
                    ],
                    const SizedBox(height: 20),
                    BouncyTap(
                      onTap: () => Navigator.pop(sheetContext, true),
                      child: Container(
                        height: 50,
                        decoration: BoxDecoration(
                          color: saffron,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x33C99232),
                              blurRadius: 8,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.add_shopping_cart_rounded, color: Colors.white, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              '${_preferHindi ? 'कार्ट में जोड़ें' : 'Add to Cart'} · ₹${unitPrice.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );

    if (confirmed != true) return;
    final sortedAddOns = selectedAddOns.toList()..sort();
    final cartKey =
        '$itemId::${Uri.encodeComponent(selectedVariant)}::${sortedAddOns.map(Uri.encodeComponent).join(',')}';
    _cartChoices[cartKey] = {
      'menuItem': itemId,
      'selectedVariant': selectedVariant,
      'selectedAddOns': sortedAddOns,
    };
    _changeQty(cartKey, 1);
  }

  Future<void> _openCheckoutSheet() async {
    if (_cart.isEmpty || _tableCode == null) return;

    final coins = (_customerLoyalty?['loyaltyPoints'] as num?)?.toInt() ?? 0;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => CheckoutModalSheet(
        cartEntries: _cart.entries.toList(),
        menuItems: _menu,
        choiceFor: _choiceFor,
        configuredUnitPrice: _configuredUnitPrice,
        subtotal: _subtotal,
        customerNameController: _name,
        customerPhoneController: _phone,
        tableCode: _tableCode!,
        tableName: _tableName,
        restaurantName: _restaurantName,
        preferHindi: _preferHindi,
        availableCoins: coins,
        onPlaceOrder: ({
          required String notes,
          required String couponCode,
          required int redeemPoints,
        }) async {
          await _submitOrder(
            notes: notes,
            couponCode: couponCode,
            redeemPoints: redeemPoints,
          );
        },
      ),
    );
  }

  Future<void> _submitOrder({
    required String notes,
    required String couponCode,
    required int redeemPoints,
  }) async {
    setState(() => _loading = true);
    try {
      final restaurant = _venue?['restaurant'] as Map?;
      final geo = restaurant?['geoLocation'] as Map?;
      double? latitude, longitude;
      if (geo?['latitude'] is num && geo?['longitude'] is num) {
        final pos = await LocationService.getCurrentLocation();
        if (pos == null) {
          throw Exception(
            'Location permission is required to order at this restaurant.',
          );
        }
        latitude = pos.latitude;
        longitude = pos.longitude;
      }

      final data = await RestaurantApi.placeQrOrder(_tableCode!, {
        'customerName': _name.text.trim(),
        'customerPhone': _phone.text.replaceAll(RegExp(r'\D'), ''),
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
        if (notes.isNotEmpty) 'notes': notes,
        if (couponCode.isNotEmpty) 'couponCode': couponCode,
        if (redeemPoints > 0) 'redeemPoints': redeemPoints,
        'items': _cart.entries.map((entry) {
          final choice = _choiceFor(entry.key);
          return {
            'menuItem': choice['menuItem'],
            'quantity': entry.value,
            'selectedVariant': choice['selectedVariant'] ?? '',
            'selectedAddOns': choice['selectedAddOns'] ?? const [],
          };
        }).toList(),
      }, sessionToken: _sessionToken);

      _sessionToken = data['tableSessionToken']?.toString() ?? _sessionToken;
      _order = Map<String, dynamic>.from(data['order'] as Map? ?? const {});

      await LocalStorage.saveCustomerTableSession({
        'tableCode': _tableCode,
        'sessionToken': _sessionToken,
        'customerName': _name.text.trim(),
        'customerPhone': _phone.text.replaceAll(RegExp(r'\D'), ''),
      });

      if (!mounted) return;
      setState(() {
        _cart.clear();
        _cartChoices.clear();
        _loading = false;
        _customerReady = true;
      });
      _startPolling();
      _fetchCustomerLoyalty();
      _message('Order kitchen ko bhej diya gaya hai! 🚀');
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        _message(
          e is Exception && e.toString().contains('Location permission')
              ? e.toString().replaceFirst('Exception: ', '')
              : RestaurantApi.messageFor(e),
        );
      }
      rethrow;
    }
  }

  void _startPolling() {
    _timer?.cancel();
    _timer = Timer.periodic(
      const Duration(seconds: 12),
      (_) => _refreshOrder(silent: true),
    );
  }

  Future<void> _refreshOrder({bool silent = false}) async {
    if (_tableCode == null || _sessionToken == null) return;
    try {
      final data = await RestaurantApi.getQrOrderStatus(
        _tableCode!,
        _sessionToken!,
      );
      if (!mounted) return;
      setState(
        () => _order =
            Map<String, dynamic>.from(data['order'] as Map? ?? const {}),
      );
      if (_order?['paymentStatus'] == 'Paid' || _order?['status'] == 'Paid') {
        _timer?.cancel();
        _sessionToken = null;
        await LocalStorage.clearCustomerTableSession();
      } else {
        _startPolling();
      }
    } catch (e) {
      if (e is DioException && e.response?.statusCode == 401) {
        _timer?.cancel();
        _sessionToken = null;
        await LocalStorage.clearCustomerTableSession();
      }
      if (!silent && mounted) _message(RestaurantApi.messageFor(e));
    }
  }

  Future<void> _startOnlinePayment() async {
    if (_tableCode == null || _sessionToken == null) return;
    setState(() => _loading = true);
    try {
      final data = await RestaurantApi.createQrPaymentLink(
        _tableCode!,
        _sessionToken!,
      );
      final paymentId = data['paymentId']?.toString() ?? '';
      final paymentUrl = Uri.tryParse(data['paymentUrl']?.toString() ?? '');
      if (paymentId.isEmpty ||
          paymentUrl == null ||
          !paymentUrl.isScheme('https')) {
        throw Exception('Invalid secure payment link.');
      }
      final opened = await launchUrl(
        paymentUrl,
        mode: LaunchMode.externalApplication,
      );
      if (!opened) throw Exception('Payment page could not be opened.');
      if (!mounted) return;
      setState(() => _loading = false);
      _message(
        'Payment complete karke app par wapas aayein. Status automatically verify hoga.',
      );
      var checks = 0;
      _paymentTimer?.cancel();
      _paymentTimer =
          Timer.periodic(const Duration(seconds: 5), (timer) async {
        if (++checks > 60) {
          timer.cancel();
          return;
        }
        try {
          final result = await RestaurantApi.getQrPaymentStatus(
            _tableCode!,
            _sessionToken!,
            paymentId,
          );
          if (result['status'] == 'Paid') {
            timer.cancel();
            _timer?.cancel();
            await LocalStorage.clearCustomerTableSession();
            _sessionToken = null;
            if (!mounted) return;
            setState(
              () => _order = {
                ...?_order,
                'status': 'Paid',
                'paymentStatus': 'Paid',
              },
            );
            _message('Payment verified. Dhanyavaad! 🙏');
          } else if ([
            'Failed',
            'Expired',
            'Cancelled',
          ].contains(result['status'])) {
            timer.cancel();
            _message(
              'Payment complete nahi hua. Aap dobara try kar sakte hain.',
            );
          }
        } catch (_) {}
      });
    } catch (error) {
      if (mounted) {
        setState(() => _loading = false);
        _message(
          error is Exception && error.toString().contains('payment')
              ? error.toString().replaceFirst('Exception: ', '')
              : RestaurantApi.messageFor(error),
        );
      }
    }
  }

  Future<void> _openBill() async {
    if (_sessionToken == null || _tableCode == null || _order == null) {
      _message('Active order milne ke baad bill request kar sakte hain.');
      return;
    }
    final status = '${_order?['status'] ?? ''}';
    if (!['Served', 'Bill Requested'].contains(status)) {
      _message('Food serve hone ke baad final bill request kar sakte hain.');
      return;
    }
    var method = 'Online';
    final submitted = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFFFFF9F3),
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) {
          final rawItems = (_order?['items'] as List?) ?? const [];
          final subTotal = (_order?['subTotal'] as num?)?.toDouble() ?? 0;
          final tax = (_order?['tax'] as num?)?.toDouble() ?? 0;
          final discount = (_order?['discount'] as num?)?.toDouble() ?? 0;
          final total = (_order?['total'] as num?)?.toDouble() ?? 0;
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 12, 22, 24),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 44,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.black12,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        const Icon(Icons.receipt_long_rounded, color: saffron),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Your Final Bill',
                            style: GoogleFonts.playfairDisplay(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: ink,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '$_restaurantName • $_tableName',
                      style: const TextStyle(color: Colors.black54),
                    ),
                    const SizedBox(height: 16),
                    ...rawItems.whereType<Map>().map((raw) {
                      final menuItem = raw['menuItem'];
                      final matchingItem = menuItem is Map
                          ? menuItem
                          : _menu
                              .where(
                                (item) => '${item['_id']}' == '$menuItem',
                              )
                              .firstOrNull;
                      final name = matchingItem is Map
                          ? _localized(
                              matchingItem['name'],
                              matchingItem['nameHi'],
                            )
                          : 'Menu item';
                      final quantity = (raw['quantity'] as num?)?.toInt() ?? 1;
                      final price = (raw['price'] as num?)?.toDouble() ?? 0;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                '$name × $quantity',
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                            Text(
                              '₹${(price * quantity).toStringAsFixed(2)}',
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      );
                    }),
                    const Divider(height: 24),
                    _billRow('Subtotal', subTotal),
                    _billRow('Tax (GST)', tax),
                    if (discount > 0) _billRow('Discount', -discount),
                    const SizedBox(height: 6),
                    _billRow('Total', total, strong: true),
                    const SizedBox(height: 18),
                    Text(
                      'Payment Method',
                      style: GoogleFonts.dmSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      children: [
                        for (final option in const [
                          ('Online', Icons.qr_code_2),
                          ('Card', Icons.credit_card),
                          ('Cash', Icons.payments_outlined),
                        ])
                          ChoiceChip(
                            avatar: Icon(option.$2, size: 18),
                            label: Text(option.$1),
                            selected: method == option.$1,
                            selectedColor: const Color(0xFFFFF1D6),
                            onSelected: (_) =>
                                setSheetState(() => method = option.$1),
                          ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: saffron,
                          minimumSize: const Size.fromHeight(50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: () async {
                          Navigator.pop(sheetContext, true);
                          if (method == 'Online') {
                            await _startOnlinePayment();
                          } else {
                            await _service('Bill', paymentMethod: method);
                          }
                        },
                        icon: const Icon(Icons.lock_outline),
                        label: Text(
                          'Request $method Payment • ₹${total.toStringAsFixed(2)}',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
    if (submitted == true) await _refreshOrder(silent: true);
  }

  Widget _billRow(String label, double amount, {bool strong = false}) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: strong ? 16 : 13,
                  fontWeight: strong ? FontWeight.w700 : FontWeight.w400,
                ),
              ),
            ),
            Text(
              '${amount < 0 ? '-' : ''}₹${amount.abs().toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: strong ? 18 : 13,
                fontWeight: strong ? FontWeight.w800 : FontWeight.w500,
                color: strong ? leaf : ink,
              ),
            ),
          ],
        ),
      );

  Future<void> _service(String type, {String? paymentMethod}) async {
    if (_sessionToken == null || _tableCode == null) {
      _message('Order place karne ke baad service request bhej sakte hain.');
      return;
    }
    try {
      await RestaurantApi.sendQrServiceRequest(
        _tableCode!,
        _sessionToken!,
        type,
        paymentMethod: paymentMethod,
      );
      if (type == 'Bill') await _refreshOrder(silent: true);
      _message('$type request staff ko bhej di gayi.');
    } catch (e) {
      _message(RestaurantApi.messageFor(e));
    }
  }

  Future<void> _sendWhatsAppBill() async {
    final orderId = _order?['_id']?.toString();
    if (orderId == null || orderId.isEmpty) {
      _message('No active order to send invoice for.');
      return;
    }
    try {
      await RestaurantApi.sendWhatsAppBill(orderId, phone: _phone.text.trim());
      _message('Full itemized invoice sent to WhatsApp! 📱');
    } catch (e) {
      _message(RestaurantApi.messageFor(e));
    }
  }

  Future<void> _openFeedbackSheet() async {
    if (_tableCode == null || _sessionToken == null) return;
    await DelightFeedbackSheet.show(
      context,
      restaurantName: _restaurantName,
      googleReviewUrl: _googleReviewUrl,
      onSubmitFeedback: ({
        required int overallRating,
        required int foodRating,
        required int serviceRating,
        required int ambianceRating,
        required String comment,
      }) async {
        await RestaurantApi.submitQrFeedback(_tableCode!, _sessionToken!, {
          'overallRating': overallRating,
          'foodRating': foodRating,
          'serviceRating': serviceRating,
          'ambianceRating': ambianceRating,
          'comment': comment,
        });
      },
    );
  }

  ({bool available, String label}) _availabilityFor(Map<String, dynamic> item) {
    if (item['isAvailable'] == false) {
      return (
        available: false,
        label: _preferHindi ? 'उपलब्ध नहीं' : 'Unavailable',
      );
    }
    final raw = item['availabilitySchedule'];
    if (raw is! Map) return (available: true, label: '');
    final days =
        ((raw['days'] as List?) ?? const []).map((day) => '$day').toSet();
    const dayNames = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    final now = DateTime.now();
    if (days.isNotEmpty && !days.contains(dayNames[now.weekday - 1])) {
      return (
        available: false,
        label: _preferHindi ? 'आज उपलब्ध नहीं' : 'Not served today',
      );
    }
    int? minutes(dynamic value) {
      final parts = value?.toString().split(':') ?? const [];
      if (parts.length != 2) return null;
      final hour = int.tryParse(parts[0]);
      final minute = int.tryParse(parts[1]);
      if (hour == null || minute == null) return null;
      return hour * 60 + minute;
    }

    final start = minutes(raw['startTime']);
    final end = minutes(raw['endTime']);
    if (start != null && end != null) {
      final current = now.hour * 60 + now.minute;
      final inWindow = start <= end
          ? current >= start && current <= end
          : current >= start || current <= end;
      if (!inWindow) {
        return (
          available: false,
          label: _preferHindi
              ? '${raw['startTime']}–${raw['endTime']} उपलब्ध'
              : 'Served ${raw['startTime']}–${raw['endTime']}',
        );
      }
    }
    return (available: true, label: '');
  }

  Future<void> _verifyCustomer() async {
    final digits = _phone.text.replaceAll(RegExp(r'\D'), '');
    if (_name.text.trim().length < 2 || digits.length != 10) {
      _message('Valid name aur 10-digit mobile number enter karein.');
      return;
    }
    setState(() => _loading = true);
    try {
      final restaurant = _venue?['restaurant'] as Map?;
      final geo = restaurant?['geoLocation'] as Map?;
      final position = await LocationService.getCurrentLocation();
      if (position == null) {
        throw Exception(
          'Location on karke permission allow karein. Table ordering restaurant ke andar hi available hai.',
        );
      }
      if (geo?['latitude'] is num && geo?['longitude'] is num) {
        final distance = LocationService.calculateDistanceMeters(
          (geo!['latitude'] as num).toDouble(),
          (geo['longitude'] as num).toDouble(),
          position.latitude,
          position.longitude,
        );
        final radius =
            (restaurant?['orderRadiusMeters'] as num?)?.toDouble() ?? 100;
        if (distance > radius) {
          throw Exception(
            'Aap restaurant ordering area se bahar hain. Menu order karne ke liye table ke paas rahein.',
          );
        }
      }
      if (!mounted) return;
      setState(() {
        _customerReady = true;
        _loading = false;
      });
      _fetchCustomerLoyalty();
    } catch (exception) {
      if (!mounted) return;
      setState(() => _loading = false);
      _message(exception.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _openMenuFilters() async {
    var vegOnly = _vegOnly;
    final dietary = {..._dietaryFilters};
    final excluded = {..._allergenExclusions};
    final spice = {..._spiceFilters};
    const dietaryOptions = [
      'Vegan',
      'Jain',
      'Gluten-Free',
      'Dairy-Free',
      'Nut-Free',
      'High-Protein',
    ];
    const allergenOptions = ['Milk', 'Nuts', 'Gluten', 'Soy', 'Egg', 'Sesame'];
    const spiceOptions = ['Mild', 'Medium', 'Hot', 'Extra Hot'];

    final apply = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFFFFFBF7),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) => StatefulBuilder(
        builder: (_, setSheetState) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 22),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.black26,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    _preferHindi ? 'मेन्यू फ़िल्टर' : 'Menu Filters',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    activeColor: leaf,
                    value: vegOnly,
                    onChanged: (value) => setSheetState(() => vegOnly = value),
                    title: Text(
                      _preferHindi ? 'केवल शाकाहारी' : 'Vegetarian Only',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  const Text(
                    'Dietary Preferences',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 7),
                  Wrap(
                    spacing: 7,
                    runSpacing: 7,
                    children: dietaryOptions
                        .map(
                          (tag) => FilterChip(
                            label: Text(tag),
                            selected: dietary.contains(tag),
                            selectedColor: const Color(0xFFFFF1D6),
                            checkmarkColor: saffron,
                            onSelected: (selected) => setSheetState(() {
                              selected ? dietary.add(tag) : dietary.remove(tag);
                            }),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Spice Level',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 7),
                  Wrap(
                    spacing: 7,
                    runSpacing: 7,
                    children: spiceOptions
                        .map(
                          (level) => FilterChip(
                            label: Text(level),
                            selected: spice.contains(level),
                            selectedColor: const Color(0xFFFFF1D6),
                            checkmarkColor: saffron,
                            onSelected: (selected) => setSheetState(() {
                              selected
                                  ? spice.add(level)
                                  : spice.remove(level);
                            }),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Exclude Allergens',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Dishes marked with these allergens will be hidden.',
                    style: TextStyle(color: Colors.black54, fontSize: 12),
                  ),
                  const SizedBox(height: 7),
                  Wrap(
                    spacing: 7,
                    runSpacing: 7,
                    children: allergenOptions
                        .map(
                          (allergen) => FilterChip(
                            label: Text(allergen),
                            selected: excluded.contains(allergen),
                            selectedColor: const Color(0xFFFFD8D2),
                            onSelected: (selected) => setSheetState(() {
                              selected
                                  ? excluded.add(allergen)
                                  : excluded.remove(allergen);
                            }),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      TextButton(
                        onPressed: () {
                          setSheetState(() {
                            vegOnly = false;
                            dietary.clear();
                            excluded.clear();
                            spice.clear();
                          });
                        },
                        child: const Text('Clear all'),
                      ),
                      const Spacer(),
                      FilledButton(
                        onPressed: () => Navigator.pop(sheetContext, true),
                        style: FilledButton.styleFrom(
                          backgroundColor: saffron,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Apply Filters'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    if (apply != true) return;
    setState(() {
      _vegOnly = vegOnly;
      _dietaryFilters
        ..clear()
        ..addAll(dietary);
      _allergenExclusions
        ..clear()
        ..addAll(excluded);
      _spiceFilters
        ..clear()
        ..addAll(spice);
    });
  }

  void _message(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    final availableCoins =
        (_customerLoyalty?['loyaltyPoints'] as num?)?.toInt() ?? 0;
    final visitCount = (_customerLoyalty?['visitCount'] as num?)?.toInt() ?? 1;

    return Scaffold(
      backgroundColor: const Color(0xFFFFFDF9),
      bottomNavigationBar: FloatingCartBar(
        itemCount: _cartCount,
        subtotal: _subtotal,
        onViewCart: _openCheckoutSheet,
        preferHindi: _preferHindi,
      ),
      body: SafeArea(
        child: _loading && _venue == null
            ? const Center(child: CircularProgressIndicator(color: saffron))
            : RefreshIndicator(
                onRefresh: () => _tableCode == null
                    ? Future.value()
                    : _loadTable(_tableCode!, restore: true),
                child: CustomScrollView(
                  slivers: [
                    // Top App Bar
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(18, 14, 18, 12),
                        child: Row(
                          children: [
                            if (_venue != null &&
                                _restaurantLogo.isNotEmpty) ...[
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  _restaurantLogo,
                                  width: 44,
                                  height: 44,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      const SizedBox.shrink(),
                                ),
                              ),
                              const SizedBox(width: 12),
                            ],
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _restaurantName,
                                    style: GoogleFonts.playfairDisplay(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w700,
                                      color: ink,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (_venue != null)
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 7,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFFFF1D6),
                                            borderRadius:
                                                BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            _tableName,
                                            style: const TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w800,
                                              color: saffron,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        const PulsingBadge(
                                          color: leaf,
                                          size: 7,
                                          ringScale: 2.2,
                                        ),
                                        const SizedBox(width: 4),
                                        const Text(
                                          'Kitchen Open',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: leaf,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                            ),
                            // Wi-Fi Button
                            if (_wifiPassword.isNotEmpty) ...[
                              BouncyTap(
                                onTap: () => WifiDialog.show(
                                  context,
                                  restaurantName: _restaurantName,
                                  wifiPassword: _wifiPassword,
                                ),
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFF1D6),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                    Icons.wifi_rounded,
                                    color: saffron,
                                    size: 18,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                            ],
                            // Language switcher
                            SegmentedButton<bool>(
                              showSelectedIcon: false,
                              segments: const [
                                ButtonSegment(value: false, label: Text('EN')),
                                ButtonSegment(value: true, label: Text('हिं')),
                              ],
                              selected: {_preferHindi},
                              onSelectionChanged: (val) =>
                                  setState(() => _preferHindi = val.first),
                              style: const ButtonStyle(
                                visualDensity: VisualDensity.compact,
                              ),
                            ),
                            const SizedBox(width: 6),
                            BouncyTap(
                              onTap: _openScanner,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF2ECE4),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.qr_code_scanner, size: 18, color: ink),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // No Table Scanned Prompt
                    if (_venue == null)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 18),
                          child: Column(
                            children: [
                              _hero(),
                              const SizedBox(height: 18),
                              _scanCard(),
                            ],
                          ),
                        ),
                      )
                    // Diner Verification Screen
                    else if (!_customerReady)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.all(18),
                          child: _customerEntryCard(),
                        ),
                      )
                    // Active Menu & Live Order View
                    else ...[
                      // VIP Customer Loyalty Banner
                      if (_name.text.isNotEmpty)
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 18),
                            child: FadeSlideReveal(
                              duration: const Duration(milliseconds: 350),
                              child: CustomerLoyaltyBadge(
                                customerName: _name.text,
                                loyaltyPoints: availableCoins,
                                visitCount: visitCount,
                              ),
                            ),
                          ),
                        ),

                      // Live Order Tracker Card (if active order exists)
                      if (_order != null)
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
                            child: FadeSlideReveal(
                              duration: const Duration(milliseconds: 400),
                              child: LiveOrderTimeline(
                                order: _order!,
                                onRefresh: _refreshOrder,
                                onServiceRequest: _service,
                                onRequestBill: _openBill,
                                onSendWhatsAppBill: _sendWhatsAppBill,
                                onGiveFeedback: _openFeedbackSheet,
                                preferHindi: _preferHindi,
                              ),
                            ),
                          ),
                        ),

                      // Highlights: Bestsellers & Chef's Specials
                      if (_bestsellers.isNotEmpty) ...[
                        const SliverToBoxAdapter(child: SizedBox(height: 18)),
                        SliverToBoxAdapter(
                          child: FadeSlideReveal(
                            delay: const Duration(milliseconds: 100),
                            child: HighlightsCarousel(
                              title: _preferHindi
                                  ? 'आज के बेस्टसेलर्स 🔥'
                                  : 'Popular Right Now 🔥',
                              subtitle: _preferHindi
                                  ? 'सबसे ज़्यादा पसंद'
                                  : 'Most ordered',
                              items: _bestsellers,
                              preferHindi: _preferHindi,
                              cartQuantities: _cartQuantitiesByItemId,
                              onAddItem: _addMenuItem,
                            ),
                          ),
                        ),
                      ],

                      if (_chefSpecials.isNotEmpty) ...[
                        const SliverToBoxAdapter(child: SizedBox(height: 18)),
                        SliverToBoxAdapter(
                          child: FadeSlideReveal(
                            delay: const Duration(milliseconds: 200),
                            child: HighlightsCarousel(
                              title: _preferHindi
                                  ? 'शेफ़ स्पेशल 👨‍🍳'
                                  : "Chef's Recommendations 👨‍🍳",
                              subtitle: _preferHindi
                                  ? 'खास आपके लिए'
                                  : 'Handcrafted taste',
                              items: _chefSpecials,
                              preferHindi: _preferHindi,
                              cartQuantities: _cartQuantitiesByItemId,
                              onAddItem: _addMenuItem,
                            ),
                          ),
                        ),
                      ],

                      // Search & Filter Header
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(18, 20, 18, 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _preferHindi ? 'मेन्यू सूची' : 'Explore Menu',
                                style: GoogleFonts.playfairDisplay(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  color: ink,
                                ),
                              ),
                              const SizedBox(height: 10),
                              TextField(
                                controller: _search,
                                onChanged: (_) => setState(() {}),
                                decoration: InputDecoration(
                                  hintText: _preferHindi
                                      ? 'डिश खोजें (उदा. पनीर, डोसा)'
                                      : 'Search dishes, drinks or ingredients',
                                  prefixIcon: const Icon(Icons.search),
                                  suffixIcon: IconButton(
                                    tooltip: 'Menu filters',
                                    onPressed: _openMenuFilters,
                                    icon: Badge(
                                      isLabelVisible: _activeFilterCount > 0,
                                      label: Text('$_activeFilterCount'),
                                      child: const Icon(Icons.tune),
                                    ),
                                  ),
                                  filled: true,
                                  fillColor: Colors.white,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              // Categories Pills
                              SizedBox(
                                height: 40,
                                child: ListView.separated(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: _categories.length,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(width: 8),
                                  itemBuilder: (_, i) {
                                    final c = _categories[i];
                                    final isSelected = c == _category;
                                    return ChoiceChip(
                                      label: Text(_categoryLabel(c)),
                                      selected: isSelected,
                                      selectedColor: const Color(0xFFFFF1D6),
                                      labelStyle: TextStyle(
                                        color: isSelected ? saffron : ink,
                                        fontWeight: isSelected
                                            ? FontWeight.w800
                                            : FontWeight.w500,
                                      ),
                                      onSelected: (_) =>
                                          setState(() => _category = c),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Menu Items List
                      if (_visibleMenu.isEmpty)
                        SliverToBoxAdapter(
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 18),
                            padding: const EdgeInsets.all(32),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Column(
                              children: [
                                const Icon(
                                  Icons.search_off,
                                  size: 44,
                                  color: saffron,
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  _preferHindi
                                      ? 'इन फ़िल्टर में कोई डिश नहीं मिली'
                                      : 'No dishes match your active filters',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(18, 0, 18, 32),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final item = _visibleMenu[index];
                                final id = '${item['_id']}';
                                final qty = _quantityForItem(id);
                                final availability = _availabilityFor(item);

                                return FadeSlideReveal(
                                  delay: Duration(milliseconds: (index * 40).clamp(0, 400)),
                                  child: FoodMenuCard(
                                    item: item,
                                    quantity: qty,
                                    preferHindi: _preferHindi,
                                    isAvailable: availability.available,
                                    availabilityLabel: availability.label,
                                    onAdd: () => _addMenuItem(item),
                                    onDecrease: () => _decreaseMenuItem(id),
                                    onTap: () => _addMenuItem(item),
                                  ),
                                );
                              },
                              childCount: _visibleMenu.length,
                            ),
                          ),
                        ),
                    ],
                  ],
                ),
              ),
      ),
    );
  }

  Widget _hero() => ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            Image.asset(
              'assets/images/indian_hospitality_hero.png',
              height: 180,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
            Container(
              height: 180,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xC0000000), Color(0x10000000)],
                ),
              ),
            ),
            Positioned(
              left: 20,
              bottom: 20,
              child: Text(
                'A seat made for\ngood food.',
                style: GoogleFonts.playfairDisplay(
                  color: Colors.white,
                  fontSize: 26,
                  height: 1.1,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      );

  Widget _scanCard() => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: ink,
          borderRadius: BorderRadius.circular(22),
          boxShadow: const [
            BoxShadow(
              color: Color(0x26071A31),
              blurRadius: 16,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: saffron.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.qr_code_scanner_rounded,
                color: Color(0xFFFFC46B),
                size: 32,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Scan Your Table QR',
                    style: GoogleFonts.dmSans(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Access live menu & order instantly',
                    style: TextStyle(color: Colors.white60, fontSize: 12),
                  ),
                ],
              ),
            ),
            BouncyTap(
              onTap: _openScanner,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                decoration: BoxDecoration(
                  color: saffron,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Scan',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      );

  Widget _customerEntryCard() => Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFF0EAE1)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0C000000),
              blurRadius: 14,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Welcome to $_restaurantName',
              style: GoogleFonts.playfairDisplay(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: ink,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '$_tableName • Verify your mobile number to view the live menu.',
              style: GoogleFonts.dmSans(color: const Color(0xFF7A6258)),
            ),
            const SizedBox(height: 18),
            TextField(
              controller: _name,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Your Name',
                prefixIcon: Icon(Icons.person_outline),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              maxLength: 10,
              decoration: const InputDecoration(
                labelText: '10-digit Mobile Number',
                prefixIcon: Icon(Icons.phone_outlined),
                border: OutlineInputBorder(),
                counterText: '',
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF2F8F4),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Row(
                children: [
                  Icon(Icons.location_on_outlined, color: leaf),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Location must be enabled to order at the restaurant table.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            BouncyTap(
              onTap: _loading ? null : _verifyCustomer,
              child: Container(
                height: 52,
                decoration: BoxDecoration(
                  color: saffron,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x33C99232),
                      blurRadius: 10,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Center(
                  child: _loading
                      ? const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: Colors.white,
                          ),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.restaurant_menu, color: Colors.white, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Verify & Open Menu',
                              style: TextStyle(
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
      );
}
