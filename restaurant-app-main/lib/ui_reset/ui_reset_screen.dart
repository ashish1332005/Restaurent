import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/network/restaurant_api.dart';
import '../core/services/location_service.dart';
import '../core/storage/local_storage.dart';

class UiResetScreen extends StatefulWidget {
  const UiResetScreen({super.key, this.initialTableCode});
  final String? initialTableCode;

  @override
  State<UiResetScreen> createState() => _UiResetScreenState();
}

class _UiResetScreenState extends State<UiResetScreen> {
  static const saffron = Color(0xFFC95B20);
  static const ink = Color(0xFF2A1A14);
  static const green = Color(0xFF236B4E);
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _code = TextEditingController();
  final _search = TextEditingController();
  final Map<String, int> _cart = {};
  final Map<String, Map<String, dynamic>> _cartChoices = {};
  Map<String, dynamic>? _venue;
  Map<String, dynamic>? _order;
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
  String get _menuHeader {
    final branding = (_venue?['restaurant'] as Map?)?['menuBranding'] as Map?;
    final value = branding?['menuHeaderText']?.toString().trim() ?? '';
    return value.isEmpty ? 'Explore the menu' : value;
  }

  String get _tableName =>
      ((_venue?['table'] as Map?)?['name'] ??
              (_venue?['table'] as Map?)?['tableNumber'] ??
              'Table')
          .toString();
  List<String> get _categories => [
    'All',
    ..._menu
        .map((e) => ((e['categoryId'] as Map?)?['name'] ?? 'Other').toString())
        .toSet(),
  ];
  List<Map<String, dynamic>> get _visibleMenu {
    final query = _search.text.trim().toLowerCase();
    return _menu.where((item) {
      final category = ((item['categoryId'] as Map?)?['name'] ?? 'Other')
          .toString();
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

  int get _cartCount => _cart.values.fold(0, (a, b) => a + b);

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
    final variants = ((item['variants'] as List?) ?? const []).whereType<Map>();
    final variant = variants
        .where((entry) => '${entry['name']}' == variantName)
        .firstOrNull;
    var price =
        (variant?['price'] as num?)?.toDouble() ??
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

  @override
  void initState() {
    super.initState();
    final saved = LocalStorage.getCustomerTableSession();
    final code = widget.initialTableCode ?? saved?['tableCode']?.toString();
    _sessionToken = saved?['sessionToken']?.toString();
    _customerReady = _sessionToken != null && _sessionToken!.isNotEmpty;
    _name.text = saved?['customerName']?.toString() ?? '';
    _phone.text = saved?['customerPhone']?.toString() ?? '';
    if (code != null && code.isNotEmpty)
      Future.microtask(() => _loadTable(code, restore: true));
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
      if (restore && _sessionToken != null) await _refreshOrder();
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        _message(RestaurantApi.messageFor(e));
      }
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
                      'Scan table QR',
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
        title: const Text('Enter table code'),
        content: TextField(
          controller: _code,
          autofocus: true,
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.table_restaurant),
            hintText: 'QR or table code',
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
      backgroundColor: const Color(0xFFFFFBF7),
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
                    Text(
                      _localized(item['name'], item['nameHi']),
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 25,
                        fontWeight: FontWeight.w700,
                        color: ink,
                      ),
                    ),
                    if (variants.isNotEmpty) ...[
                      const SizedBox(height: 18),
                      Text(
                        _preferHindi
                            ? 'साइज़ / विकल्प चुनें'
                            : 'Choose a variant',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 7),
                      RadioGroup<String>(
                        groupValue: selectedVariant,
                        onChanged: (value) {
                          if (value != null) {
                            setSheetState(() => selectedVariant = value);
                          }
                        },
                        child: Column(
                          children: variants
                              .map(
                                (variant) => RadioListTile<String>(
                                  contentPadding: EdgeInsets.zero,
                                  value: '${variant['name']}',
                                  title: Text(
                                    _localized(
                                      variant['name'],
                                      variant['nameHi'],
                                    ),
                                  ),
                                  secondary: Text(
                                    '₹${((variant['price'] as num?) ?? 0).toStringAsFixed(0)}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ),
                    ],
                    if (modifiers.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(
                        _preferHindi ? 'ऐड-ऑन चुनें' : 'Choose add-ons',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 7),
                      ...modifiers.map((modifier) {
                        final name = '${modifier['name']}';
                        return CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          value: selectedAddOns.contains(name),
                          onChanged: (selected) => setSheetState(() {
                            selected == true
                                ? selectedAddOns.add(name)
                                : selectedAddOns.remove(name);
                          }),
                          title: Text(
                            _localized(modifier['name'], modifier['nameHi']),
                          ),
                          secondary: Text(
                            '+₹${((modifier['price'] as num?) ?? 0).toStringAsFixed(0)}',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        );
                      }),
                    ],
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () => Navigator.pop(sheetContext, true),
                        style: FilledButton.styleFrom(
                          backgroundColor: saffron,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                        ),
                        icon: const Icon(Icons.add_shopping_cart),
                        label: Text(
                          '${_preferHindi ? 'कार्ट में जोड़ें' : 'Add to cart'} · ₹${unitPrice.toStringAsFixed(0)}',
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

  Future<void> _checkout() async {
    if (_cart.isEmpty || _tableCode == null) return;
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFFFFF9F3),
      builder: (c) => Padding(
        padding: EdgeInsets.fromLTRB(
          22,
          22,
          22,
          MediaQuery.viewInsetsOf(c).bottom + 22,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Who are we serving?',
              style: GoogleFonts.playfairDisplay(
                fontSize: 25,
                fontWeight: FontWeight.w700,
                color: ink,
              ),
            ),
            const SizedBox(height: 12),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 190),
              child: ListView(
                shrinkWrap: true,
                children: _cart.entries.map((entry) {
                  final item = _menuItemForCartKey(entry.key);
                  if (item == null) return const SizedBox.shrink();
                  final choice = _choiceFor(entry.key);
                  final unitPrice = _configuredUnitPrice(item, choice);
                  final amount = unitPrice * entry.value;
                  final variant = '${choice['selectedVariant'] ?? ''}';
                  final addOns =
                      ((choice['selectedAddOns'] as List?) ?? const [])
                          .map((value) => '$value')
                          .toList();
                  final details = <String>[
                    if (item['itemType'] == 'Thali')
                      '${item['thaliConfig']?['serviceType'] ?? 'Limited'} Thali',
                    if (variant.isNotEmpty) variant,
                    if (addOns.isNotEmpty) addOns.join(', '),
                  ];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    title: Text(
                      _localized(item['name'], item['nameHi']),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: details.isEmpty
                        ? null
                        : Text(details.join(' · ')),
                    trailing: Text(
                      '${entry.value} × ₹${unitPrice.toStringAsFixed(0)} = ₹${amount.toStringAsFixed(0)}',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  );
                }).toList(),
              ),
            ),
            const Divider(),
            TextField(
              controller: _name,
              decoration: const InputDecoration(
                labelText: 'Name',
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              maxLength: 10,
              decoration: const InputDecoration(
                labelText: 'Mobile number',
                prefixIcon: Icon(Icons.phone_outlined),
                counterText: '',
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  final digits = _phone.text.replaceAll(RegExp(r'\D'), '');
                  if (_name.text.trim().length < 2 || digits.length != 10) {
                    _message(
                      'Valid name aur 10-digit mobile number enter karein.',
                    );
                    return;
                  }
                  Navigator.pop(c, true);
                },
                child: Text('Place order • ₹${_subtotal.toStringAsFixed(0)}'),
              ),
            ),
          ],
        ),
      ),
    );
    if (ok != true) return;
    setState(() => _loading = true);
    try {
      final restaurant = _venue?['restaurant'] as Map?;
      final geo = restaurant?['geoLocation'] as Map?;
      double? latitude, longitude;
      if (geo?['latitude'] is num && geo?['longitude'] is num) {
        final pos = await LocationService.getCurrentLocation();
        if (pos == null)
          throw Exception(
            'Location permission is required to order at this restaurant.',
          );
        latitude = pos.latitude;
        longitude = pos.longitude;
      }
      final data = await RestaurantApi.placeQrOrder(_tableCode!, {
        'customerName': _name.text.trim(),
        'customerPhone': _phone.text.replaceAll(RegExp(r'\D'), ''),
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
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
      });
      _startPolling();
      _message('Order kitchen ko bhej diya gaya hai.');
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        _message(
          e is Exception && e.toString().contains('Location permission')
              ? e.toString().replaceFirst('Exception: ', '')
              : RestaurantApi.messageFor(e),
        );
      }
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
        () => _order = Map<String, dynamic>.from(
          data['order'] as Map? ?? const {},
        ),
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
          !paymentUrl.isScheme('https'))
        throw Exception('Invalid secure payment link.');
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
      _paymentTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
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
            _message('Payment verified. Dhanyavaad!');
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
        } catch (_) {
          // Temporary network errors are retried within the verification window.
        }
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
                            'Your final bill',
                            style: GoogleFonts.playfairDisplay(
                              fontSize: 26,
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
                    const SizedBox(height: 18),
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
                      final itemType = matchingItem is Map
                          ? '${matchingItem['itemType'] ?? ''}'
                          : '';
                      final selections = <String>[
                        if ('${raw['selectedVariant'] ?? ''}'.isNotEmpty)
                          '${raw['selectedVariant']}',
                        ...((raw['selectedAddOns'] as List?) ?? const []).map(
                          (value) => '$value',
                        ),
                      ];
                      final quantity = (raw['quantity'] as num?)?.toInt() ?? 1;
                      final price = (raw['price'] as num?)?.toDouble() ?? 0;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 9),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                '$name × $quantity${itemType == 'Thali' ? ' · Thali' : ''}${selections.isEmpty ? '' : ' · ${selections.join(', ')}'}',
                              ),
                            ),
                            Text(
                              '₹${(price * quantity).toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    const Divider(height: 26),
                    _billRow('Subtotal', subTotal),
                    _billRow('Tax', tax),
                    if (discount > 0) _billRow('Discount', -discount),
                    const SizedBox(height: 6),
                    _billRow('Total', total, strong: true),
                    const SizedBox(height: 20),
                    Text(
                      'How would you like to pay?',
                      style: GoogleFonts.dmSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
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
                            onSelected: (_) =>
                                setSheetState(() => method = option.$1),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      method == 'Online'
                          ? 'Staff aapke table par verified UPI QR layega.'
                          : method == 'Card'
                          ? 'Card machine aapke table par laayi jayegi.'
                          : 'Staff cash collect karke payment confirm karega.',
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: saffron,
                          minimumSize: const Size.fromHeight(52),
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
                          'Request $method payment • ₹${total.toStringAsFixed(2)}',
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
                  fontSize: strong ? 17 : 14,
                  fontWeight: strong ? FontWeight.w700 : FontWeight.w400,
                ),
              ),
            ),
            Text(
              '${amount < 0 ? '-' : ''}₹${amount.abs().toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: strong ? 19 : 14,
                fontWeight: strong ? FontWeight.w800 : FontWeight.w500,
                color: strong ? green : ink,
              ),
            ),
          ],
        ),
      );
  Future<void> _requestRefill(
    Map<String, dynamic> item,
    Map<String, dynamic> dish,
  ) async {
    if (_sessionToken == null || _tableCode == null) {
      _message('Place an order before requesting a refill.');
      return;
    }
    if (_order?['status'] != 'Served') {
      _message('Refill can be requested after the thali is served.');
      return;
    }
    try {
      await RestaurantApi.sendQrServiceRequest(
        _tableCode!,
        _sessionToken!,
        'Refill',
        menuItemId: '${item['_id']}',
        dishName: '${dish['name']}',
      );
      _message(
        '${_localized(dish['name'], dish['nameHi'])} refill request staff ko bhej di gayi.',
      );
    } catch (error) {
      _message(RestaurantApi.messageFor(error));
    }
  }

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
                    _preferHindi ? 'मेन्यू फ़िल्टर' : 'Menu filters',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 25,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: vegOnly,
                    onChanged: (value) => setSheetState(() => vegOnly = value),
                    title: Text(
                      _preferHindi ? 'केवल शाकाहारी' : 'Vegetarian only',
                    ),
                  ),
                  const Text(
                    'Dietary preferences',
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
                            onSelected: (selected) => setSheetState(() {
                              selected ? dietary.add(tag) : dietary.remove(tag);
                            }),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Spice level',
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
                            onSelected: (selected) => setSheetState(() {
                              selected ? spice.add(level) : spice.remove(level);
                            }),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Exclude allergens',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'We will hide dishes marked with these allergens. Always confirm severe allergies with restaurant staff.',
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
                        style: FilledButton.styleFrom(backgroundColor: saffron),
                        child: const Text('Apply filters'),
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
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFFFF9F3),
    bottomNavigationBar: _cart.isEmpty
        ? null
        : SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: ink,
                  minimumSize: const Size.fromHeight(56),
                ),
                onPressed: _checkout,
                icon: const Icon(Icons.shopping_bag_outlined),
                label: Text(
                  'View cart • $_cartCount items • ₹${_subtotal.toStringAsFixed(0)}',
                ),
              ),
            ),
          ),
    body: SafeArea(
      child: _loading && _venue == null
          ? const Center(child: CircularProgressIndicator(color: saffron))
          : RefreshIndicator(
              onRefresh: () => _tableCode == null
                  ? Future.value()
                  : _loadTable(_tableCode!, restore: true),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 28),
                children: [
                  Row(
                    children: [
                      if (_venue != null && _restaurantLogo.isNotEmpty) ...[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            _restaurantLogo,
                            width: 46,
                            height: 46,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                const SizedBox.shrink(),
                          ),
                        ),
                        const SizedBox(width: 10),
                      ],
                      Text(
                        'Namaste',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 30,
                          fontWeight: FontWeight.w700,
                          color: ink,
                        ),
                      ),
                      const Spacer(),
                      if (_venue != null)
                        IconButton.filledTonal(
                          onPressed: _openScanner,
                          icon: const Icon(Icons.qr_code_scanner),
                        ),
                    ],
                  ),
                  Text(
                    _venue == null
                        ? 'Your table, your pace.'
                        : 'Welcome to $_restaurantName',
                    style: GoogleFonts.dmSans(color: const Color(0xFF7A6258)),
                  ),
                  const SizedBox(height: 18),
                  _hero(),
                  const SizedBox(height: 18),
                  if (_venue == null)
                    _scanCard()
                  else if (!_customerReady)
                    _customerEntryCard()
                  else ...[
                    _tableCard(),
                    const SizedBox(height: 18),
                    if (_order != null) _orderCard(),
                    if (_order != null) const SizedBox(height: 18),
                    _actions(),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _menuHeader,
                            style: GoogleFonts.playfairDisplay(
                              fontSize: 23,
                              fontWeight: FontWeight.w700,
                              color: ink,
                            ),
                          ),
                        ),
                        SegmentedButton<bool>(
                          showSelectedIcon: false,
                          segments: const [
                            ButtonSegment(value: false, label: Text('EN')),
                            ButtonSegment(value: true, label: Text('हिं')),
                          ],
                          selected: {_preferHindi},
                          onSelectionChanged: (value) => setState(() {
                            _preferHindi = value.first;
                          }),
                          style: const ButtonStyle(
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _search,
                      onChanged: (_) => setState(() {}),
                      textInputAction: TextInputAction.search,
                      decoration: InputDecoration(
                        hintText: _preferHindi
                            ? 'डिश या श्रेणी खोजें'
                            : 'Search dishes or categories',
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
                    SizedBox(
                      height: 42,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _categories.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (_, i) {
                          final c = _categories[i];
                          return ChoiceChip(
                            label: Text(_categoryLabel(c)),
                            selected: c == _category,
                            selectedColor: const Color(0xFFFFD9B7),
                            onSelected: (_) => setState(() => _category = c),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 14),
                    if (_visibleMenu.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.search_off,
                              size: 38,
                              color: saffron,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _preferHindi
                                  ? 'इन फ़िल्टर में कोई डिश नहीं मिली'
                                  : 'No dishes match these filters',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      ..._visibleMenu.map(_menuCard),
                  ],
                ],
              ),
            ),
    ),
  );

  Widget _hero() {
    final hasTable = _venue != null;
    final height = hasTable ? 132.0 : 190.0;
    return ClipRRect(
      borderRadius: BorderRadius.circular(hasTable ? 20 : 26),
      child: Stack(
        children: [
          Image.asset(
            'assets/images/indian_hospitality_hero.png',
            height: height,
            width: double.infinity,
            fit: BoxFit.cover,
          ),
          Container(
            height: height,
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
              !hasTable ? 'A seat made for\ngood food.' : _restaurantName,
              style: GoogleFonts.playfairDisplay(
                color: Colors.white,
                fontSize: hasTable ? 23 : 27,
                height: 1.08,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _scanCard() => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: ink,
      borderRadius: BorderRadius.circular(22),
    ),
    child: Row(
      children: [
        const Icon(
          Icons.table_restaurant_rounded,
          color: Color(0xFFFFC46B),
          size: 34,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            'Scan the QR on your table to view its live menu.',
            style: GoogleFonts.dmSans(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        FilledButton(
          onPressed: _openScanner,
          style: FilledButton.styleFrom(backgroundColor: saffron),
          child: const Text('Scan'),
        ),
      ],
    ),
  );
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
    } catch (exception) {
      if (!mounted) return;
      setState(() => _loading = false);
      _message(exception.toString().replaceFirst('Exception: ', ''));
    }
  }

  Widget _customerEntryCard() => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: const Color(0xFFFFD7BC)),
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
        const SizedBox(height: 5),
        Text(
          '$_tableName • Apni details verify karke live menu dekhein.',
          style: GoogleFonts.dmSans(color: const Color(0xFF7A6258)),
        ),
        const SizedBox(height: 18),
        TextField(
          controller: _name,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
            labelText: 'Your name',
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
            labelText: '10-digit mobile number',
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
              Icon(Icons.location_on_outlined, color: green),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Location on aur permission allow honi chahiye. Ordering sirf restaurant ke andar available hai.',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: _loading ? null : _verifyCustomer,
          style: FilledButton.styleFrom(
            backgroundColor: saffron,
            padding: const EdgeInsets.symmetric(vertical: 15),
          ),
          icon: _loading
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.restaurant_menu),
          label: const Text('Verify location & view menu'),
        ),
      ],
    ),
  );
  Widget _tableCard() => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: ink,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      children: [
        const Icon(Icons.table_restaurant, color: Color(0xFFFFC46B), size: 32),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _restaurantName,
                style: const TextStyle(color: Colors.white70),
              ),
              Text(
                _tableName,
                style: GoogleFonts.dmSans(
                  color: Colors.white,
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        const Icon(Icons.verified_rounded, color: Color(0xFF75D6AE)),
      ],
    ),
  );
  Widget _actions() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'Quick service',
        style: TextStyle(fontWeight: FontWeight.w800, color: ink),
      ),
      const SizedBox(height: 9),
      Row(
        children: [
          _action(Icons.water_drop_outlined, 'Water'),
          const SizedBox(width: 8),
          _action(Icons.room_service_outlined, 'Waiter'),
          const SizedBox(width: 8),
          _action(Icons.receipt_long_outlined, 'Bill'),
        ],
      ),
    ],
  );
  Widget _action(IconData icon, String title) => Expanded(
    child: InkWell(
      onTap: () => title == 'Bill' ? _openBill() : _service(title),
      borderRadius: BorderRadius.circular(16),
      child: Ink(
        height: 72,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFF0E3D7)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: saffron),
            const SizedBox(height: 5),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    ),
  );
  ({bool available, String label}) _availabilityFor(Map<String, dynamic> item) {
    if (item['isAvailable'] == false) {
      return (
        available: false,
        label: _preferHindi ? 'उपलब्ध नहीं' : 'Unavailable',
      );
    }
    final raw = item['availabilitySchedule'];
    if (raw is! Map) return (available: true, label: '');
    final days = ((raw['days'] as List?) ?? const [])
        .map((day) => '$day')
        .toSet();
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

  Future<void> _showMenuItemDetails(Map<String, dynamic> item) async {
    final config = item['thaliConfig'] is Map
        ? Map<String, dynamic>.from(item['thaliConfig'] as Map)
        : <String, dynamic>{};
    final dishes = ((config['includedItems'] as List?) ?? const [])
        .whereType<Map>()
        .map((dish) => Map<String, dynamic>.from(dish))
        .toList();
    final availability = _availabilityFor(item);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFFFFFBF7),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            14,
            20,
            20 + MediaQuery.viewInsetsOf(sheetContext).bottom,
          ),
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
                  _localized(item['name'], item['nameHi']),
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: ink,
                  ),
                ),
                finalSecondaryName(item),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _mealBadge('${config['serviceType'] ?? 'Limited'}'),
                    if (config['dineInOnly'] == true)
                      _mealBadge(
                        _preferHindi ? 'केवल रेस्टोरेंट में' : 'Dine-in only',
                      ),
                    if (config['servingDurationMinutes'] != null)
                      _mealBadge('${config['servingDurationMinutes']} min'),
                  ],
                ),
                if (_localized(
                  item['description'],
                  item['descriptionHi'],
                ).isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    _localized(item['description'], item['descriptionHi']),
                    style: const TextStyle(color: Colors.black87, height: 1.4),
                  ),
                ],
                const SizedBox(height: 18),
                Text(
                  _preferHindi ? 'थाली में शामिल' : 'Included in this thali',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                ...dishes.map((dish) {
                  final refill = '${dish['refillPolicy'] ?? 'None'}';
                  final refillText = switch (refill) {
                    'Unlimited' =>
                      _preferHindi ? 'अनलिमिटेड रीफिल' : 'Unlimited refill',
                    'Limited' =>
                      _preferHindi
                          ? '${dish['refillLimit']} बार रीफिल'
                          : '${dish['refillLimit']} refills',
                    _ => _preferHindi ? 'रीफिल नहीं' : 'No refill',
                  };
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const CircleAvatar(
                      backgroundColor: Color(0xFFFFF1D6),
                      child: Icon(Icons.restaurant, color: saffron),
                    ),
                    title: Text(
                      _localized(dish['name'], dish['nameHi']),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text(
                      '${dish['quantity']} ${dish['unit']} · $refillText',
                    ),
                    trailing: refill == 'None'
                        ? (dish['replacementAllowed'] == true
                              ? const Tooltip(
                                  message: 'Replacement available',
                                  child: Icon(Icons.swap_horiz, color: green),
                                )
                              : null)
                        : OutlinedButton.icon(
                            onPressed: _order?['status'] == 'Served'
                                ? () => _requestRefill(item, dish)
                                : null,
                            icon: const Icon(Icons.refresh, size: 17),
                            label: Text(_preferHindi ? 'रीफिल' : 'Refill'),
                          ),
                  );
                }),
                if (!availability.available) ...[
                  const SizedBox(height: 8),
                  Text(
                    availability.label,
                    style: const TextStyle(
                      color: Color(0xFFB54708),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: availability.available
                        ? () {
                            Navigator.pop(sheetContext);
                            Future.microtask(() => _addMenuItem(item));
                          }
                        : null,
                    style: FilledButton.styleFrom(
                      backgroundColor: saffron,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                    icon: const Icon(Icons.add_shopping_cart),
                    label: Text(
                      '${_preferHindi ? 'जोड़ें' : 'Add'} · ₹${((item['basePrice'] as num?) ?? 0).toStringAsFixed(0)}',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget finalSecondaryName(Map<String, dynamic> item) {
    final english = item['name']?.toString().trim() ?? '';
    final hindi = item['nameHi']?.toString().trim() ?? '';
    final secondary = _preferHindi ? english : hindi;
    if (secondary.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 3),
      child: Text(secondary, style: const TextStyle(color: Colors.black54)),
    );
  }

  Widget _mealBadge(String label) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
    decoration: BoxDecoration(
      color: const Color(0xFFFFF1D6),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      label,
      style: const TextStyle(
        color: Color(0xFF9D4317),
        fontSize: 11,
        fontWeight: FontWeight.w700,
      ),
    ),
  );

  Widget _menuCard(Map<String, dynamic> item) {
    final id = '${item['_id']}';
    final qty = _quantityForItem(id);
    final image = RestaurantApi.mediaUrl(item['imageUrl'] ?? item['image']);
    final isThali = item['itemType'] == 'Thali';
    final variants = ((item['variants'] as List?) ?? const []).whereType<Map>();
    final modifiers = ((item['modifiers'] as List?) ?? const [])
        .whereType<Map>();
    final hasChoices = variants.isNotEmpty || modifiers.isNotEmpty;
    final spiceLevel = '${item['spiceLevel'] ?? 'None'}';
    final dietaryTags = ((item['dietaryTags'] as List?) ?? const [])
        .map((value) => '$value')
        .toList();
    final allergens = ((item['allergens'] as List?) ?? const [])
        .map((value) => '$value')
        .toList();
    final variantPrices = variants
        .map((entry) => (entry['price'] as num?)?.toDouble())
        .whereType<double>()
        .toList();
    final displayPrice = variantPrices.isEmpty
        ? (item['basePrice'] as num?)?.toDouble() ?? 0
        : variantPrices.reduce((a, b) => a < b ? a : b);
    final config = item['thaliConfig'] is Map
        ? item['thaliConfig'] as Map
        : const {};
    final availability = _availabilityFor(item);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D2A1A14),
            blurRadius: 14,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: InkWell(
        onTap: isThali ? () => _showMenuItemDetails(item) : null,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(13),
                child: image.isNotEmpty
                    ? Image.network(
                        image,
                        width: 82,
                        height: 92,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _foodPlaceholder(),
                      )
                    : _foodPlaceholder(),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _localized(item['name'], item['nameHi']),
                      style: GoogleFonts.dmSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: ink,
                      ),
                    ),
                    finalSecondaryName(item),
                    if (isThali) ...[
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 5,
                        runSpacing: 5,
                        children: [
                          _mealBadge('${config['serviceType'] ?? 'Limited'}'),
                          if (config['dineInOnly'] == true)
                            _mealBadge(_preferHindi ? 'Dine-in' : 'Dine-in'),
                        ],
                      ),
                    ],
                    if (hasChoices) ...[
                      const SizedBox(height: 5),
                      _mealBadge(
                        _preferHindi ? 'विकल्प उपलब्ध' : 'Customizable',
                      ),
                    ],
                    if (spiceLevel != 'None' || dietaryTags.isNotEmpty) ...[
                      const SizedBox(height: 5),
                      Wrap(
                        spacing: 5,
                        runSpacing: 5,
                        children: [
                          if (spiceLevel != 'None')
                            _mealBadge('🌶 $spiceLevel'),
                          ...dietaryTags.take(2).map(_mealBadge),
                        ],
                      ),
                    ],
                    if (allergens.isNotEmpty) ...[
                      const SizedBox(height: 5),
                      Text(
                        '${_preferHindi ? 'एलर्जी:' : 'Contains:'} ${allergens.join(', ')}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFFB42318),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                    const SizedBox(height: 5),
                    Text(
                      '${variantPrices.isEmpty ? '' : 'From '}₹${displayPrice.toStringAsFixed(0)}',
                      style: const TextStyle(
                        color: green,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (!isThali &&
                        _localized(
                          item['description'],
                          item['descriptionHi'],
                        ).isNotEmpty)
                      Text(
                        _localized(item['description'], item['descriptionHi']),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                      ),
                    if (isThali)
                      Text(
                        _preferHindi
                            ? 'पूरी जानकारी देखें'
                            : 'View thali details',
                        style: const TextStyle(
                          color: saffron,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    if (!availability.available)
                      Text(
                        availability.label,
                        style: const TextStyle(
                          color: Color(0xFFB54708),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              qty == 0
                  ? IconButton.filled(
                      onPressed: availability.available
                          ? () => _addMenuItem(item)
                          : null,
                      style: IconButton.styleFrom(backgroundColor: saffron),
                      icon: const Icon(Icons.add),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          onPressed: () => _decreaseMenuItem(id),
                          icon: const Icon(Icons.remove_circle_outline),
                        ),
                        Text(
                          '$qty',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        IconButton(
                          onPressed: availability.available
                              ? () => _addMenuItem(item)
                              : null,
                          icon: const Icon(Icons.add_circle, color: saffron),
                        ),
                      ],
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _foodPlaceholder() => Container(
    width: 82,
    height: 82,
    color: const Color(0xFFFFF1D6),
    child: const Icon(Icons.restaurant_menu, color: saffron, size: 34),
  );
  String _orderItemName(dynamic menuItem) {
    if (menuItem is Map) {
      return _localized(menuItem['name'], menuItem['nameHi']);
    }
    final item = _menu
        .where((value) => '${value['_id']}' == '$menuItem')
        .firstOrNull;
    return item == null
        ? 'Menu item'
        : _localized(item['name'], item['nameHi']);
  }

  Widget _orderCard() {
    final status = '${_order?['status'] ?? 'Pending'}';
    const stages = [
      'Pending',
      'Accepted',
      'Preparing',
      'Ready',
      'Served',
      'Bill Requested',
      'Paid',
    ];
    final index = stages.indexOf(status);
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF6F0),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFB8DDCA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.local_fire_department_outlined, color: green),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Order status',
                  style: GoogleFonts.dmSans(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              IconButton(
                onPressed: _refreshOrder,
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          Text(
            status,
            style: GoogleFonts.playfairDisplay(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: green,
            ),
          ),
          if ((_order?['items'] as List?)?.isNotEmpty == true) ...[
            const SizedBox(height: 7),
            ...((_order?['items'] as List?) ?? const [])
                .whereType<Map>()
                .take(3)
                .map((raw) {
                  final choices = <String>[
                    if ('${raw['selectedVariant'] ?? ''}'.isNotEmpty)
                      '${raw['selectedVariant']}',
                    ...((raw['selectedAddOns'] as List?) ?? const []).map(
                      (value) => '$value',
                    ),
                  ];
                  return Text(
                    '${_orderItemName(raw['menuItem'])} × ${raw['quantity'] ?? 1}${choices.isEmpty ? '' : ' · ${choices.join(', ')}'}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.black54),
                  );
                }),
          ],
          const SizedBox(height: 10),
          LinearProgressIndicator(
            value: ((index < 0 ? 0 : index) + 1) / stages.length,
            minHeight: 7,
            borderRadius: BorderRadius.circular(8),
            color: green,
            backgroundColor: Colors.white,
          ),
        ],
      ),
    );
  }
}
