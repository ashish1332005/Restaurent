import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/restaurant_api.dart';
import '../../application/customer_auth_session.dart';
import '../widgets/auth_ui.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final phone = TextEditingController();
  final password = TextEditingController();
  bool loading = false;
  bool obscure = true;
  bool rememberMe = true;
  String? error;

  @override
  void dispose() {
    phone.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> login() async {
    final mobile = phone.text.replaceAll(RegExp(r'\D'), '');
    if (mobile.length != 10) {
      return showError('Enter a valid 10-digit mobile number.');
    }
    if (password.text.length < 6) {
      return showError('Password must be at least 6 characters.');
    }
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final role = await CustomerAuthSession.loginWithPassword(
        phone: mobile,
        password: password.text,
      );
      if (mounted) goToRole(role);
    } catch (exception) {
      if (mounted) showError(RestaurantApi.messageFor(exception));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> googleLogin() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final role = await CustomerAuthSession.loginWithGoogle();
      if (mounted) goToRole(role);
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

  void goToRole(String role) {
    final value = role.toLowerCase();
    if (value.contains('super')) {
      context.goNamed('super-admin');
    } else if (value.contains('admin') || value == 'manager') {
      context.goNamed('admin');
    } else if (value == 'waiter') {
      context.goNamed('waiter');
    } else if (value.contains('kitchen') || value == 'chef') {
      context.goNamed('kitchen');
    } else if (value == 'cashier') {
      context.goNamed('cashier');
    } else {
      context.goNamed('customer');
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: AuthBackground(
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              24,
              24,
              24,
              MediaQuery.paddingOf(context).bottom + 42,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Container(
                  constraints: BoxConstraints(
                    minHeight: (constraints.maxHeight - 70).clamp(0, 900),
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 34),
                      const AuthBrand(),
                      const SizedBox(height: 50),
                      const Text(
                        'Welcome back!',
                        style: TextStyle(
                          color: authInk,
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Login to continue your food journey',
                        style: TextStyle(color: authMuted, fontSize: 16),
                      ),
                      const SizedBox(height: 36),
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
                      const SizedBox(height: 16),
                      AuthField(
                        controller: password,
                        hint: 'Password',
                        icon: Icons.lock_outline_rounded,
                        obscureText: obscure,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) {
                          if (!loading) login();
                        },
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
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Checkbox(
                            value: rememberMe,
                            activeColor: authOrange,
                            visualDensity: VisualDensity.compact,
                            onChanged: (value) =>
                                setState(() => rememberMe = value ?? false),
                          ),
                          const Text(
                            'Remember me',
                            style: TextStyle(color: authMuted),
                          ),
                          const Spacer(),
                          TextButton(
                            onPressed: () =>
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Password recovery will be available soon.',
                                    ),
                                  ),
                                ),
                            child: const Text(
                              'Forgot Password?',
                              style: TextStyle(color: authOrange),
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
                        label: 'Login',
                        loading: loading,
                        onPressed: login,
                      ),
                      const SizedBox(height: 28),
                      const AuthDivider(),
                      const SizedBox(height: 24),
                      SocialAuthRow(loading: loading, onGoogle: googleLogin),
                      const SizedBox(height: 34),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            "Don't have an account? ",
                            style: TextStyle(color: authMuted),
                          ),
                          GestureDetector(
                            onTap: loading
                                ? null
                                : () => context.push('/signup'),
                            child: const Text(
                              'Sign up',
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
          ),
        ),
      ),
    ),
  );
}
