import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/restaurant_api.dart';
import '../../../../core/storage/local_storage.dart';
import '../../application/customer_auth_session.dart';
import '../widgets/auth_ui.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});
  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final name = TextEditingController();
  final phone = TextEditingController();
  final email = TextEditingController();
  final password = TextEditingController();
  final confirmPassword = TextEditingController();
  bool loading = false;
  bool obscure = true;
  bool acceptedTerms = true;
  String accountType = 'owner'; // 'owner' or 'customer'
  String? error;

  @override
  void dispose() {
    name.dispose();
    phone.dispose();
    email.dispose();
    password.dispose();
    confirmPassword.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (name.text.trim().length < 2) return showError('Enter your full name.');
    if (phone.text.length != 10) {
      return showError('Enter a valid 10-digit mobile number.');
    }
    if (email.text.isNotEmpty &&
        !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email.text.trim())) {
      return showError('Enter a valid email address.');
    }
    if (password.text.length < 6) {
      return showError('Password must be at least 6 characters.');
    }
    if (password.text != confirmPassword.text) {
      return showError('Passwords do not match.');
    }
    if (!acceptedTerms) {
      return showError('Please accept the Terms and Privacy Policy.');
    }
    setState(() {
      loading = true;
      error = null;
    });
    try {
      if (accountType == 'owner') {
        final mockToken = 'owner_token_${DateTime.now().millisecondsSinceEpoch}';
        await LocalStorage.clearToken();
        await LocalStorage.saveToken(mockToken);
        await LocalStorage.saveRole('Admin');
        await LocalStorage.saveSubscriptionStatus(isActive: false);
        await LocalStorage.saveCustomerProfile({
          'name': name.text.trim(),
          'phone': phone.text,
          'email': email.text,
          'role': 'Admin',
        });
        if (mounted) context.go('/subscription');
      } else {
        await CustomerAuthSession.registerWithPassword(
          name: name.text.trim(),
          phone: phone.text,
          password: password.text,
        );
        if (mounted) context.go('/customer');
      }
    } catch (exception) {
      if (mounted) showError(RestaurantApi.messageFor(exception));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> googleSignup() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      await CustomerAuthSession.loginWithGoogle();
      if (mounted) context.go('/customer');
    } catch (exception) {
      if (mounted) {
        showError(
          exception is StateError
              ? exception.message.toString()
              : RestaurantApi.messageFor(exception),
        );
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void showError(String message) => setState(() => error = message);

  @override
  Widget build(BuildContext context) => Scaffold(
    body: AuthBackground(
      child: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                24,
                26,
                24,
                MediaQuery.paddingOf(context).bottom + 38,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Column(
                    children: [
                      const SizedBox(height: 18),
                      const AuthBrand(),
                      const SizedBox(height: 38),
                      const Text(
                        'Create your account',
                        style: TextStyle(
                          color: authInk,
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "Let's get started with your details",
                        style: TextStyle(color: authMuted, fontSize: 16),
                      ),
                      const SizedBox(height: 24),
                      // Account Type Toggle
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() => accountType = 'owner'),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  decoration: BoxDecoration(
                                    color: accountType == 'owner' ? authOrange : Colors.transparent,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.storefront_rounded,
                                        size: 18,
                                        color: accountType == 'owner' ? Colors.white : authMuted,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Restaurant Owner',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                          color: accountType == 'owner' ? Colors.white : authMuted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() => accountType = 'customer'),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  decoration: BoxDecoration(
                                    color: accountType == 'customer' ? authOrange : Colors.transparent,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.person_rounded,
                                        size: 18,
                                        color: accountType == 'customer' ? Colors.white : authMuted,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Customer',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                          color: accountType == 'customer' ? Colors.white : authMuted,
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
                      const SizedBox(height: 20),
                      AuthField(
                        controller: name,
                        hint: 'Full Name',
                        icon: Icons.person_outline_rounded,
                        textCapitalization: TextCapitalization.words,
                      ),
                      const SizedBox(height: 14),
                      AuthField(
                        controller: phone,
                        hint: 'Phone Number',
                        icon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        maxLength: 10,
                      ),
                      const SizedBox(height: 14),
                      AuthField(
                        controller: email,
                        hint: 'Email Address (optional)',
                        icon: Icons.mail_outline_rounded,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 14),
                      AuthField(
                        controller: password,
                        hint: 'Password',
                        icon: Icons.lock_outline_rounded,
                        obscureText: obscure,
                        suffix: IconButton(
                          onPressed: () => setState(() => obscure = !obscure),
                          icon: Icon(
                            obscure
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: authMuted,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      AuthField(
                        controller: confirmPassword,
                        hint: 'Confirm Password',
                        icon: Icons.lock_outline_rounded,
                        obscureText: obscure,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) {
                          if (!loading) submit();
                        },
                      ),
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Checkbox(
                            value: acceptedTerms,
                            activeColor: authOrange,
                            visualDensity: VisualDensity.compact,
                            onChanged: (value) =>
                                setState(() => acceptedTerms = value ?? false),
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Wrap(
                                children: [
                                  const Text(
                                    'I agree to the ',
                                    style: TextStyle(color: authMuted),
                                  ),
                                  _PolicyText(
                                    label: 'Terms & Conditions',
                                    path: '/terms-of-service',
                                  ),
                                  const Text(
                                    ' and ',
                                    style: TextStyle(color: authMuted),
                                  ),
                                  _PolicyText(
                                    label: 'Privacy Policy',
                                    path: '/privacy-policy',
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (error != null) ...[
                        const SizedBox(height: 8),
                        AuthError(error!),
                      ],
                      const SizedBox(height: 18),
                      AuthPrimaryButton(
                        label: 'Sign Up',
                        loading: loading,
                        onPressed: submit,
                      ),
                      const SizedBox(height: 26),
                      const AuthDivider(),
                      const SizedBox(height: 22),
                      SocialAuthRow(loading: loading, onGoogle: googleSignup),
                      const SizedBox(height: 30),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Already have an account? ',
                            style: TextStyle(color: authMuted),
                          ),
                          GestureDetector(
                            onTap: loading ? null : () => context.pop(),
                            child: const Text(
                              'Login',
                              style: TextStyle(
                                color: authOrange,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 8,
              top: 4,
              child: IconButton(
                onPressed: () => context.pop(),
                icon: const Icon(Icons.arrow_back_rounded, size: 30),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _PolicyText extends StatelessWidget {
  const _PolicyText({required this.label, required this.path});
  final String label;
  final String path;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () => context.push(path),
    child: Text(
      label,
      style: const TextStyle(color: authOrange, fontWeight: FontWeight.w600),
    ),
  );
}
