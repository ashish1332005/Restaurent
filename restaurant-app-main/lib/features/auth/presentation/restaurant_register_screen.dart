import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/network/restaurant_api.dart';
import '../application/customer_auth_session.dart';

class RestaurantRegisterScreen extends StatefulWidget {
  const RestaurantRegisterScreen({super.key});

  @override
  State<RestaurantRegisterScreen> createState() =>
      _RestaurantRegisterScreenState();
}

class _RestaurantRegisterScreenState extends State<RestaurantRegisterScreen> {
  final owner = TextEditingController();
  final restaurant = TextEditingController();
  final phone = TextEditingController();
  final email = TextEditingController();
  final address = TextEditingController();
  final password = TextEditingController();
  bool loading = false;
  bool obscure = true;
  String? error;

  @override
  void dispose() {
    for (final controller in [
      owner,
      restaurant,
      phone,
      email,
      address,
      password,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> submit() async {
    final digits = phone.text.replaceAll(RegExp(r'\D'), '');
    if (owner.text.trim().length < 2 ||
        restaurant.text.trim().length < 2 ||
        digits.length != 10 ||
        password.text.length < 6 ||
        address.text.trim().length < 4) {
      setState(
        () => error =
            'Complete all required fields. Password must have at least 6 characters.',
      );
      return;
    }
    setState(() {
      loading = true;
      error = null;
    });
    try {
      await CustomerAuthSession.registerRestaurantOwner(
        ownerName: owner.text.trim(),
        restaurantName: restaurant.text.trim(),
        phone: digits,
        email: email.text.trim(),
        password: password.text,
        address: address.text.trim(),
      );
      if (mounted) context.go('/subscription');
    } catch (exception) {
      if (mounted) {
        setState(() {
          loading = false;
          error = RestaurantApi.messageFor(exception);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFFFF8F1),
    appBar: AppBar(
      backgroundColor: Colors.transparent,
      title: const Text('Restaurant registration'),
      leading: IconButton(
        onPressed: () => context.go('/admin/login'),
        icon: const Icon(Icons.arrow_back),
      ),
    ),
    body: Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Card(
            elevation: 0,
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
              side: const BorderSide(color: Color(0xFFFFE1CC)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(
                    Icons.storefront_rounded,
                    size: 46,
                    color: Color(0xFFD66A2C),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Start your restaurant',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Create your owner account and main branch.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 22),
                  _field(owner, 'Owner name', Icons.person_outline),
                  _field(restaurant, 'Restaurant name', Icons.restaurant),
                  _field(
                    phone,
                    'Mobile number',
                    Icons.phone_outlined,
                    keyboard: TextInputType.phone,
                  ),
                  _field(
                    email,
                    'Email (optional)',
                    Icons.email_outlined,
                    keyboard: TextInputType.emailAddress,
                  ),
                  _field(
                    address,
                    'Main branch address',
                    Icons.location_on_outlined,
                    lines: 2,
                  ),
                  TextField(
                    controller: password,
                    obscureText: obscure,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        onPressed: () => setState(() => obscure = !obscure),
                        icon: Icon(
                          obscure
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                      ),
                    ),
                  ),
                  if (error != null) ...[
                    const SizedBox(height: 12),
                    Text(error!, style: TextStyle(color: Colors.red.shade700)),
                  ],
                  const SizedBox(height: 18),
                  FilledButton(
                    onPressed: loading ? null : submit,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFD66A2C),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: loading
                        ? const SizedBox.square(
                            dimension: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Create restaurant account'),
                  ),
                  TextButton(
                    onPressed: () => context.go('/admin/login'),
                    child: const Text('Already registered? Sign in'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );

  Widget _field(
    TextEditingController controller,
    String label,
    IconData icon, {
    TextInputType? keyboard,
    int lines = 1,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 13),
    child: TextField(
      controller: controller,
      keyboardType: keyboard,
      maxLines: lines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
      ),
    ),
  );
}
