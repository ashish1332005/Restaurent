import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../application/customer_auth_session.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});
  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final phone = TextEditingController();
  final password = TextEditingController();
  bool loading = false, obscure = true;
  String? error;
  @override
  void dispose() {
    phone.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    final digits = phone.text.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 10 || password.text.isEmpty) {
      setState(() => error = 'Enter a valid mobile number and password.');
      return;
    }
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final role = await CustomerAuthSession.loginWithPassword(
        phone: digits,
        password: password.text,
      );
      if (!mounted) return;
      const allowed = {
        'Admin',
        'Restaurant Admin',
        'Manager',
        'Super Admin',
        'Cashier',
        'Kitchen',
        'Waiter',
      };
      if (!allowed.contains(role)) {
        setState(() {
          loading = false;
          error = 'This account cannot access the admin panel.';
        });
        return;
      }
      context.go(role == 'Super Admin' ? '/super-admin' : '/admin');
    } catch (e) {
      if (mounted)
        setState(() {
          loading = false;
          error = e.toString().replaceFirst('Bad state: ', '');
        });
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFFFF8F1),
    body: Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(22),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x16000000),
                  blurRadius: 30,
                  offset: Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const CircleAvatar(
                  radius: 27,
                  backgroundColor: Color(0xFFD66A2C),
                  child: Icon(Icons.restaurant, color: Colors.white, size: 28),
                ),
                const SizedBox(height: 18),
                Text(
                  'Welcome back',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 30,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF241711),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Sign in to manage your restaurant.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.dmSans(color: const Color(0xFF806E64)),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: phone,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Mobile number',
                    prefixIcon: Icon(Icons.phone_outlined),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: password,
                  obscureText: obscure,
                  onSubmitted: (_) => submit(),
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
                  Text(
                    error!,
                    style: GoogleFonts.dmSans(color: Colors.red.shade700),
                  ),
                ],
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: loading ? null : submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFD66A2C),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: loading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Sign in'),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () => context.go('/admin/register'),
                  child: const Text('Create a restaurant account'),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
