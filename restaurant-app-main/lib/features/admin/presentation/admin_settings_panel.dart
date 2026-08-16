import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/network/restaurant_api.dart';
import '../../../core/storage/local_storage.dart';

class AdminSettingsPanel extends StatefulWidget {
  const AdminSettingsPanel({super.key, required this.branchId});
  final String? branchId;
  @override
  State<AdminSettingsPanel> createState() => _AdminSettingsPanelState();
}

class _AdminSettingsPanelState extends State<AdminSettingsPanel> {
  final formKey = GlobalKey<FormState>();
  bool loading = true, saving = false;
  Map<String, dynamic> restaurant = {}, branch = {};
  PlatformFile? logoFile;
  Uint8List? logoBytes;
  String logoUrl = '';
  late final String role;
  final name = TextEditingController(),
      header = TextEditingController(),
      radius = TextEditingController(),
      latitude = TextEditingController(),
      longitude = TextEditingController(),
      currency = TextEditingController(),
      tax = TextEditingController(),
      primary = TextEditingController(),
      secondary = TextEditingController(),
      accent = TextEditingController(),
      branchName = TextEditingController(),
      address = TextEditingController(),
      city = TextEditingController(),
      state = TextEditingController(),
      zipcode = TextEditingController(),
      country = TextEditingController(),
      phone = TextEditingController(),
      email = TextEditingController(),
      timezone = TextEditingController();
  bool get canEditRestaurant =>
      ['Admin', 'Restaurant Admin', 'Super Admin'].contains(role);
  @override
  void initState() {
    super.initState();
    role = LocalStorage.getRole() ?? '';
    _load();
  }

  @override
  void didUpdateWidget(covariant AdminSettingsPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.branchId != widget.branchId) _load();
  }

  @override
  void dispose() {
    for (final c in [
      name,
      header,
      radius,
      latitude,
      longitude,
      currency,
      tax,
      primary,
      secondary,
      accent,
      branchName,
      address,
      city,
      state,
      zipcode,
      country,
      phone,
      email,
      timezone,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    if (widget.branchId == null) {
      if (mounted) setState(() => loading = false);
      return;
    }
    setState(() => loading = true);
    try {
      final restaurants = await RestaurantApi.getRestaurants();
      final profile = LocalStorage.getCustomerProfile() ?? const {};
      final restaurantId = '${profile['restaurantId'] ?? ''}';
      restaurant =
          restaurants.where((r) => '${r['_id']}' == restaurantId).isNotEmpty
          ? restaurants.firstWhere((r) => '${r['_id']}' == restaurantId)
          : (restaurants.isEmpty ? <String, dynamic>{} : restaurants.first);
      final branches = restaurant.isEmpty
          ? const <Map<String, dynamic>>[]
          : await RestaurantApi.getBranches('${restaurant['_id']}');
      branch =
          branches.where((b) => '${b['_id']}' == widget.branchId).isNotEmpty
          ? branches.firstWhere((b) => '${b['_id']}' == widget.branchId)
          : (branches.isEmpty ? <String, dynamic>{} : branches.first);
      _fill();
      if (mounted) setState(() => loading = false);
    } catch (e) {
      if (mounted) {
        setState(() => loading = false);
        _message(RestaurantApi.messageFor(e));
      }
    }
  }

  void _fill() {
    final branding = restaurant['menuBranding'] is Map
            ? restaurant['menuBranding'] as Map
            : const {},
        settings = restaurant['settings'] is Map
            ? restaurant['settings'] as Map
            : const {},
        geo = restaurant['geoLocation'] is Map
            ? restaurant['geoLocation'] as Map
            : const {},
        location = branch['location'] is Map
            ? branch['location'] as Map
            : const {},
        contact = branch['contact'] is Map
            ? branch['contact'] as Map
            : const {};
    name.text = '${restaurant['name'] ?? ''}';
    header.text = '${branding['menuHeaderText'] ?? ''}';
    primary.text = '${branding['primaryColor'] ?? '#FF4D0A'}';
    secondary.text = '${branding['secondaryColor'] ?? '#16A34A'}';
    accent.text = '${branding['accentColor'] ?? '#F59E0B'}';
    radius.text = '${restaurant['orderRadiusMeters'] ?? 100}';
    latitude.text = '${geo['latitude'] ?? ''}';
    longitude.text = '${geo['longitude'] ?? ''}';
    currency.text = '${settings['currency'] ?? 'INR'}';
    tax.text = '${settings['taxRate'] ?? 0}';
    branchName.text = '${branch['name'] ?? ''}';
    address.text = '${location['address'] ?? ''}';
    city.text = '${location['city'] ?? ''}';
    state.text = '${location['state'] ?? ''}';
    zipcode.text = '${location['zipcode'] ?? ''}';
    country.text = '${location['country'] ?? 'India'}';
    phone.text = '${contact['phone'] ?? ''}';
    email.text = '${contact['email'] ?? ''}';
    timezone.text = '${branch['timezone'] ?? 'Asia/Kolkata'}';
  }

  @override
  Widget build(BuildContext context) => Form(
    key: formKey,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 10,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              'Restaurant settings',
              style: GoogleFonts.playfairDisplay(
                fontSize: 27,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (restaurant.isNotEmpty)
              _tag('${restaurant['subscriptionPlan'] ?? 'Basic'} plan'),
            if (restaurant.isNotEmpty)
              _tag('${restaurant['subscriptionStatus'] ?? 'Unknown'}'),
            IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
          ],
        ),
        const SizedBox(height: 14),
        if (loading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(45),
              child: CircularProgressIndicator(),
            ),
          )
        else
          LayoutBuilder(
            builder: (_, box) {
              final wide = box.maxWidth >= 900;
              final restaurantCard = _restaurantCard();
              final branchCard = _branchCard();
              return Column(
                children: [
                  wide
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: restaurantCard),
                            const SizedBox(width: 14),
                            Expanded(child: branchCard),
                          ],
                        )
                      : Column(
                          children: [
                            restaurantCard,
                            const SizedBox(height: 14),
                            branchCard,
                          ],
                        ),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton.icon(
                      onPressed: saving ? null : _save,
                      icon: saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.save_outlined),
                      label: const Text('Save settings'),
                    ),
                  ),
                ],
              );
            },
          ),
      ],
    ),
  );
  Widget _restaurantCard() => _card('Restaurant & ordering', [
    TextFormField(
      controller: name,
      enabled: canEditRestaurant,
      decoration: const InputDecoration(labelText: 'Restaurant name'),
    ),
    const SizedBox(height: 10),
    TextFormField(
      controller: header,
      enabled: canEditRestaurant,
      decoration: const InputDecoration(labelText: 'Customer menu header'),
    ),
    const SizedBox(height: 12),
    Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8F1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: logoBytes != null
                ? Image.memory(
                    logoBytes!,
                    width: 68,
                    height: 68,
                    fit: BoxFit.cover,
                  )
                : logoUrl.isNotEmpty && logoUrl != 'no-logo.png'
                ? Image.network(
                    RestaurantApi.mediaUrl(logoUrl),
                    width: 68,
                    height: 68,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const SizedBox(
                      width: 68,
                      height: 68,
                      child: Icon(Icons.storefront_rounded),
                    ),
                  )
                : const SizedBox(
                    width: 68,
                    height: 68,
                    child: Icon(Icons.storefront_rounded, size: 34),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Restaurant logo',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                Text(
                  logoFile?.name ?? 'JPEG, PNG or WebP • max 3 MB',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: !canEditRestaurant
                ? null
                : () async {
                    final file = await FilePicker.pickFile(
                      type: FileType.custom,
                      allowedExtensions: const ['jpg', 'jpeg', 'png', 'webp'],
                    );
                    if (file == null) return;
                    final length = await file.length();
                    if (length > 3 * 1024 * 1024) {
                      _message('Choose an image smaller than 3 MB.');
                      return;
                    }
                    final bytes = await file.readAsBytes();
                    setState(() {
                      logoFile = file;
                      logoBytes = bytes;
                    });
                  },
            child: Text(logoUrl.isEmpty ? 'Choose' : 'Replace'),
          ),
        ],
      ),
    ),
    const SizedBox(height: 10),
    Row(
      children: [
        Expanded(
          child: TextFormField(
            controller: currency,
            enabled: canEditRestaurant,
            decoration: const InputDecoration(labelText: 'Currency'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: TextFormField(
            controller: tax,
            enabled: canEditRestaurant,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Default tax %'),
          ),
        ),
      ],
    ),
    const SizedBox(height: 10),
    TextFormField(
      controller: radius,
      enabled: canEditRestaurant,
      keyboardType: TextInputType.number,
      decoration: const InputDecoration(
        labelText: 'Allowed ordering radius (metres)',
        helperText: 'Customer must be inside this radius.',
      ),
    ),
    const SizedBox(height: 10),
    Row(
      children: [
        Expanded(
          child: TextFormField(
            controller: latitude,
            enabled: canEditRestaurant,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Latitude'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: TextFormField(
            controller: longitude,
            enabled: canEditRestaurant,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Longitude'),
          ),
        ),
      ],
    ),
    const SizedBox(height: 10),
    Row(
      children: [
        Expanded(
          child: TextFormField(
            controller: primary,
            enabled: canEditRestaurant,
            decoration: const InputDecoration(labelText: 'Primary color'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: TextFormField(
            controller: secondary,
            enabled: canEditRestaurant,
            decoration: const InputDecoration(labelText: 'Secondary color'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: TextFormField(
            controller: accent,
            enabled: canEditRestaurant,
            decoration: const InputDecoration(labelText: 'Accent color'),
          ),
        ),
      ],
    ),
  ]);
  Widget _branchCard() => _card('Selected branch', [
    TextFormField(
      controller: branchName,
      decoration: const InputDecoration(labelText: 'Branch name'),
    ),
    const SizedBox(height: 10),
    TextFormField(
      controller: address,
      decoration: const InputDecoration(labelText: 'Address'),
    ),
    const SizedBox(height: 10),
    Row(
      children: [
        Expanded(
          child: TextFormField(
            controller: city,
            decoration: const InputDecoration(labelText: 'City'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: TextFormField(
            controller: state,
            decoration: const InputDecoration(labelText: 'State'),
          ),
        ),
      ],
    ),
    const SizedBox(height: 10),
    Row(
      children: [
        Expanded(
          child: TextFormField(
            controller: zipcode,
            decoration: const InputDecoration(labelText: 'PIN code'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: TextFormField(
            controller: country,
            decoration: const InputDecoration(labelText: 'Country'),
          ),
        ),
      ],
    ),
    const SizedBox(height: 10),
    TextFormField(
      controller: phone,
      keyboardType: TextInputType.phone,
      decoration: const InputDecoration(labelText: 'Branch phone'),
    ),
    const SizedBox(height: 10),
    TextFormField(
      controller: email,
      keyboardType: TextInputType.emailAddress,
      decoration: const InputDecoration(labelText: 'Branch email'),
    ),
    const SizedBox(height: 10),
    TextFormField(
      controller: timezone,
      decoration: const InputDecoration(
        labelText: 'Timezone',
        helperText:
            'IANA timezone used for menu schedules · Example: Asia/Kolkata',
      ),
    ),
  ]);
  Widget _card(String title, List<Widget> children) => Container(
    padding: const EdgeInsets.all(18),
    decoration: _box(),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 16),
        ...children,
      ],
    ),
  );
  Future<void> _save() async {
    if (branch.isEmpty || restaurant.isEmpty) return;
    setState(() => saving = true);
    try {
      if (canEditRestaurant && logoFile != null) {
        logoUrl = await RestaurantApi.uploadImage(logoBytes!, logoFile!.name);
      }
      if (canEditRestaurant) {
        await RestaurantApi.updateRestaurantSettings('${restaurant['_id']}', {
          'logo': logoUrl,
          'name': name.text.trim(),
          'orderRadiusMeters': double.tryParse(radius.text),
          'geoLocation': {
            'latitude': double.tryParse(latitude.text),
            'longitude': double.tryParse(longitude.text),
          },
          'settings': {
            'currency': currency.text.trim(),
            'taxRate': double.tryParse(tax.text),
          },
          'menuBranding': {
            'primaryColor': primary.text.trim(),
            'secondaryColor': secondary.text.trim(),
            'accentColor': accent.text.trim(),
            'menuHeaderText': header.text.trim(),
          },
        });
      }
      await RestaurantApi.updateBranchSettings('${branch['_id']}', {
        'name': branchName.text.trim(),
        'location': {
          'address': address.text.trim(),
          'city': city.text.trim(),
          'state': state.text.trim(),
          'zipcode': zipcode.text.trim(),
          'country': country.text.trim(),
        },
        'contact': {'phone': phone.text.trim(), 'email': email.text.trim()},
        'timezone': timezone.text.trim(),
      });
      await _load();
      if (mounted) _message('Settings saved.');
    } catch (e) {
      if (mounted) _message(RestaurantApi.messageFor(e));
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Widget _tag(String text) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
    decoration: BoxDecoration(
      color: const Color(0xFFFFF1D6),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      text,
      style: const TextStyle(
        color: Color(0xFFD66A2C),
        fontWeight: FontWeight.w700,
      ),
    ),
  );
  BoxDecoration _box() => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(18),
    border: Border.all(color: const Color(0xFFE6DED2)),
  );
  void _message(String text) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(text), behavior: SnackBarBehavior.floating),
  );
}
