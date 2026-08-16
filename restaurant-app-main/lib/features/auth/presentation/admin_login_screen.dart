import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../application/customer_auth_session.dart';
import 'widgets/owner_auth_shell.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});
  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  static const navy = Color(0xFF071A31),
      gold = Color(0xFFC99B4C),
      cream = Color(0xFFFFFBF7);
  final phone = TextEditingController(), password = TextEditingController();
  bool loading = false, obscure = true, remember = true;
  String? error;

  @override
  void dispose() {
    phone.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    FocusManager.instance.primaryFocus?.unfocus();
    final digits = phone.text.replaceAll(RegExp(r'\D'), '');
    if (digits.length != 10 || password.text.isEmpty) {
      setState(
        () => error = 'Enter a valid 10-digit mobile number and password.',
      );
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
          error = 'This account cannot access the restaurant workspace.';
        });
        return;
      }
      context.go(role == 'Super Admin' ? '/super-admin' : '/admin');
    } catch (exception) {
      if (mounted)
        setState(() {
          loading = false;
          error = exception.toString().replaceFirst('Bad state: ', '');
        });
    }
  }

  void message(String text) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(text), behavior: SnackBarBehavior.floating),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: navy,
    body: LayoutBuilder(
      builder: (context, box) {
        final desktop = box.maxWidth >= 820;
        return Row(
          children: [
            if (desktop) const Expanded(child: _RoyalArtwork()),
            Expanded(
              child: ColoredBox(
                color: desktop ? const Color(0xFFF4EFE9) : navy,
                child: SafeArea(
                  child: SingleChildScrollView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    child: Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: desktop ? 520 : box.maxWidth,
                        ),
                        child: desktop
                            ? Padding(
                                padding: const EdgeInsets.all(36),
                                child: _formCard(false),
                              )
                            : Container(
                                decoration: const BoxDecoration(
                                  image: DecorationImage(
                                    image: AssetImage(
                                      'assets/images/auth_ornamental_v2.png',
                                    ),
                                    fit: BoxFit.cover,
                                    alignment: Alignment.topCenter,
                                  ),
                                ),
                                padding: EdgeInsets.fromLTRB(
                                  18,
                                  box.maxHeight < 760 ? 54 : 72,
                                  18,
                                  64,
                                ),
                                child: _formCard(true),
                              ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    ),
  );

  Widget _formCard(bool mobile) => Container(
    width: double.infinity,
    padding: EdgeInsets.fromLTRB(
      mobile ? 12 : 34,
      mobile ? 12 : 28,
      mobile ? 12 : 34,
      mobile ? 12 : 24,
    ),
    decoration: BoxDecoration(
      color: mobile ? Colors.transparent : cream,
      borderRadius: BorderRadius.only(
        topLeft: const Radius.circular(38),
        topRight: const Radius.circular(38),
        bottomLeft: Radius.circular(mobile ? 0 : 38),
        bottomRight: Radius.circular(mobile ? 0 : 38),
      ),
      boxShadow: mobile
          ? const []
          : const [BoxShadow(color: Color(0x30000000), blurRadius: 24)],
    ),
    child: AutofillGroup(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _LoginBrand(),
          const SizedBox(height: 14),
          Text(
            'Welcome Back',
            textAlign: TextAlign.center,
            style: GoogleFonts.playfairDisplay(
              color: navy,
              fontSize: mobile ? 32 : 38,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'Login to manage your restaurant',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF6D6B6B), fontSize: 15),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: phone,
            autofocus: !mobile,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.telephoneNumber],
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(10),
            ],
            decoration: field('Phone number', Icons.person_outline_rounded),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: password,
            obscureText: obscure,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.password],
            onSubmitted: (_) => loading ? null : submit(),
            decoration: field('Password', Icons.lock_outline_rounded).copyWith(
              suffixIcon: IconButton(
                tooltip: obscure ? 'Show password' : 'Hide password',
                onPressed: () => setState(() => obscure = !obscure),
                icon: Icon(
                  obscure
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Checkbox(
                    value: remember,
                    activeColor: navy,
                    visualDensity: VisualDensity.compact,
                    onChanged: (value) =>
                        setState(() => remember = value ?? true),
                  ),
                  const Text('Remember me'),
                ],
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed: () => message(
                    'Password recovery will be available after support email setup.',
                  ),
                  child: const Text(
                    'Forgot Password?',
                    style: TextStyle(color: Color(0xFFA9761D), fontSize: 13),
                  ),
                ),
              ),
            ],
          ),
          if (error != null) ...[
            const SizedBox(height: 4),
            AuthErrorBanner(message: error!),
          ],
          const SizedBox(height: 12),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: navy,
              foregroundColor: const Color(0xFFF4CA78),
              minimumSize: const Size.fromHeight(58),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(13),
              ),
            ),
            onPressed: loading ? null : submit,
            icon: loading
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.room_service_outlined),
            label: Text(
              'Login',
              style: GoogleFonts.playfairDisplay(
                fontSize: 21,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 18),
          const Row(
            children: [
              Expanded(child: Divider()),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 14),
                child: Text('OR', style: TextStyle(color: Color(0xFFA9761D))),
              ),
              Expanded(child: Divider()),
            ],
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(54),
              side: const BorderSide(color: gold),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(13),
              ),
            ),
            onPressed: () => message(
              'Google sign-in is not enabled for restaurant owner accounts.',
            ),
            icon: const Text(
              'G',
              style: TextStyle(
                color: Color(0xFF4285F4),
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            label: const Text('Continue with Google'),
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Flexible(child: Text("Don't have an account?")),
              TextButton(
                onPressed: loading ? null : () => context.go('/admin/register'),
                child: const Text(
                  'Sign Up',
                  style: TextStyle(
                    color: Color(0xFFA9761D),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );

  InputDecoration field(String hint, IconData icon) => InputDecoration(
    hintText: hint,
    isDense: true,
    contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 14),
    prefixIcon: Icon(icon, color: gold),
    filled: true,
    fillColor: Colors.white,
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(13),
      borderSide: const BorderSide(color: Color(0xFFE2D7C9)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(13),
      borderSide: const BorderSide(color: gold, width: 1.5),
    ),
  );
}

class _RoyalArtwork extends StatelessWidget {
  const _RoyalArtwork();
  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      Image.asset(
        'assets/images/owner_login_royal.png',
        fit: BoxFit.cover,
        alignment: Alignment.bottomCenter,
      ),
      const DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0x33000000), Colors.transparent, Color(0x22000000)],
          ),
        ),
      ),
      SafeArea(
        child: Align(
          alignment: const Alignment(0, -0.57),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 66,
                height: 66,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _AdminLoginScreenState.gold,
                    width: 1.5,
                  ),
                  color: const Color(0x9907192D),
                ),
                child: const Icon(
                  Icons.restaurant_rounded,
                  color: Color(0xFFF3C96F),
                  size: 34,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'MEHMAAN',
                style: GoogleFonts.playfairDisplay(
                  color: const Color(0xFFF3C96F),
                  fontSize: 31,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 4,
                ),
              ),
              const Text(
                'R E S T A U R A N T',
                style: TextStyle(
                  color: Color(0xFFF3C96F),
                  letterSpacing: 3,
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 9),
              const Text(
                'Atithi Devo Bhava',
                style: TextStyle(color: Color(0xFFF3C96F), fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    ],
  );
}

class _LoginBrand extends StatelessWidget {
  const _LoginBrand();
  @override
  Widget build(BuildContext context) => Column(
    children: [
      Container(
        width: 58,
        height: 58,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFF071A31),
          border: Border.all(color: const Color(0xFFC99B4C), width: 2),
        ),
        child: const Icon(
          Icons.room_service_rounded,
          color: Color(0xFFF3C96F),
          size: 30,
        ),
      ),
      const SizedBox(height: 7),
      Text(
        'MEHMAAN',
        style: GoogleFonts.playfairDisplay(
          color: const Color(0xFF071A31),
          fontSize: 30,
          fontWeight: FontWeight.w700,
          letterSpacing: 2,
        ),
      ),
      const Text(
        'RESTAURANT MANAGEMENT APP',
        style: TextStyle(
          color: Color(0xFFA9761D),
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 1,
        ),
      ),
    ],
  );
}
