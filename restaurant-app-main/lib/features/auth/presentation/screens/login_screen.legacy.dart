import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../application/customer_auth_session.dart';
import '../../../../core/network/restaurant_api.dart';
import '../../../../core/theme/app_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _loginError;
  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _cardSlideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );
    _cardSlideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );
    _animationController.forward();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final phone = _phoneController.text.replaceAll(RegExp(r'\D'), '');
    final password = _passwordController.text;
    if (phone.length != 10) {
      setState(() => _loginError = 'Enter a valid 10-digit mobile number.');
      return;
    }
    if (password.isEmpty) {
      setState(() => _loginError = 'Password is required.');
      return;
    }
    if (password.length < 6) {
      setState(() => _loginError = 'Password must be at least 6 characters.');
      return;
    }

    setState(() {
      _isLoading = true;
      _loginError = null;
    });
    try {
      final role = await CustomerAuthSession.loginWithPassword(
        phone: phone,
        password: password,
      );
      if (!mounted) return;
      _goToRole(role);
    } catch (error) {
      if (mounted) {
        setState(() => _loginError = RestaurantApi.messageFor(error));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleGoogleLogin() async {
    setState(() {
      _isLoading = true;
      _loginError = null;
    });

    try {
      final role = await CustomerAuthSession.loginWithGoogle();
      if (!mounted) return;
      _goToRole(role);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loginError = error is StateError
            ? error.message.toString()
            : RestaurantApi.messageFor(error);
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _goToRole(String role) {
    final value = role.toLowerCase();
    if (value.contains('admin') || value == 'manager') {
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
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isCompact = size.width < 600;
    if (isCompact) {
      final heroHeight = (size.height * 0.60).clamp(340.0, 440.0);
      return Scaffold(
        backgroundColor: const Color(0xFFF7F7FB),
        body: FadeTransition(
          opacity: _fadeAnimation,
          child: SingleChildScrollView(
            child: Column(
              children: [
                SizedBox(
                  height: heroHeight,
                  width: double.infinity,
                  child: const _HeroPanel(isCompact: true),
                ),
                Transform.translate(
                  offset: const Offset(0, -16),
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      0,
                      0,
                      0,
                      MediaQuery.paddingOf(context).bottom + 4,
                    ),
                    child: SlideTransition(
                      position: _cardSlideAnimation,
                      child: _buildLoginCard(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final topAreaHeight = size.height * 0.54;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7FB),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Stack(
          children: [
            Column(
              children: [
                SizedBox(
                  height: topAreaHeight,
                  child: _HeroPanel(isCompact: isCompact),
                ),
                Expanded(child: Container(color: const Color(0xFFF7F7FB))),
              ],
            ),
            SafeArea(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: SlideTransition(
                  position: _cardSlideAnimation,
                  child: SingleChildScrollView(
                    padding: EdgeInsets.only(
                      left: 16,
                      right: 16,
                      top: topAreaHeight * 0.64,
                      bottom: 12 + MediaQuery.of(context).padding.bottom,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 430),
                        child: _buildLoginCard(),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.09),
            blurRadius: 30,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 54,
              height: 5,
              decoration: BoxDecoration(
                color: const Color(0xFFD8DDE6),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Login to your account',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF344054),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Enter your mobile number and password',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF98A2B3),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildCountrySelector(),
                const SizedBox(width: 10),
                Expanded(child: _buildPhoneInput()),
              ],
            ),
            const SizedBox(height: 10),
            _buildPasswordInput(),
            if (_loginError != null) ...[
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  _loginError!,
                  style: const TextStyle(
                    color: Color(0xFFD92D20),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleLogin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Login',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 12),
            _GoogleAuthButton(
              loading: _isLoading,
              onPressed: _handleGoogleLogin,
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: _isLoading ? null : () => context.push('/signup'),
              style: TextButton.styleFrom(
                minimumSize: const Size(0, 38),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                visualDensity: VisualDensity.compact,
              ),
              child: const Text("Don't have an account? Create account"),
            ),
            const SizedBox(height: 12),
            Text(
              'By continuing, you agree to our',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
            ),
            const SizedBox(height: 6),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 10,
              runSpacing: 4,
              children: [
                _PolicyLink(
                  label: 'Terms of Service',
                  routePath: '/terms-of-service',
                ),
                _PolicyLink(
                  label: 'Privacy Policy',
                  routePath: '/privacy-policy',
                ),
                _PolicyLink(
                  label: 'Content Policy',
                  routePath: '/content-policy',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCountrySelector() {
    return Container(
      width: 88,
      height: 56,
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD8DEE8)),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'IN',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimaryLight,
            ),
          ),
          SizedBox(width: 6),
          Icon(
            Icons.keyboard_arrow_down_rounded,
            color: Color(0xFF667085),
            size: 18,
          ),
        ],
      ),
    );
  }

  Widget _buildPhoneInput() {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD8DEE8)),
      ),
      child: Row(
        children: [
          const SizedBox(width: 14),
          const Text(
            '+91',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimaryLight,
            ),
          ),
          const SizedBox(width: 10),
          Container(width: 1, height: 24, color: const Color(0xFFD8DEE8)),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              maxLength: 10,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimaryLight,
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                isCollapsed: true,
                filled: false,
                counterText: '',
                hintText: 'Enter Phone Number',
                hintStyle: TextStyle(
                  color: Color(0xFF98A2B3),
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
        ],
      ),
    );
  }

  Widget _buildPasswordInput() {
    return TextField(
      controller: _passwordController,
      obscureText: _obscurePassword,
      enableSuggestions: false,
      autocorrect: false,
      textInputAction: TextInputAction.done,
      onSubmitted: (_) {
        if (!_isLoading) _handleLogin();
      },
      decoration: InputDecoration(
        hintText: 'Enter Password',
        prefixIcon: const Icon(Icons.lock_outline_rounded),
        suffixIcon: IconButton(
          onPressed: () {
            setState(() => _obscurePassword = !_obscurePassword);
          },
          icon: Icon(
            _obscurePassword
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
          ),
        ),
      ),
    );
  }
}

class _HeroPanel extends StatelessWidget {
  const _HeroPanel({required this.isCompact});

  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          'assets/images/login_bg_optimized.jpg',
          fit: BoxFit.cover,
          cacheWidth: isCompact ? 720 : 1024,
          gaplessPlayback: true,
          alignment: isCompact
              ? const Alignment(0, 0.62)
              : const Alignment(0, 0.46),
        ),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.white.withValues(alpha: 0.04),
                Colors.transparent,
                Colors.black.withValues(alpha: 0.06),
              ],
              stops: const [0.0, 0.54, 1.0],
            ),
          ),
        ),
        SafeArea(
          bottom: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(22, isCompact ? 18 : 26, 22, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Align(
                  alignment: Alignment.topCenter,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.32),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: const Text(
                      'Fast delivery • Fresh meals • Best offers',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const Spacer(),
                const Text(
                  'ALL-IN-ONE RESTAURANT\nOPERATING SYSTEM',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    height: 1.14,
                    shadows: [
                      Shadow(
                        color: Colors.black38,
                        blurRadius: 14,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Freshly prepared dishes, fast doorstep delivery, and a smooth ordering experience.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    height: 1.45,
                    shadows: [
                      Shadow(
                        color: Colors.black26,
                        blurRadius: 10,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Transform.rotate(
                  angle: -0.07,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 30,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryColor.withValues(alpha: 0.34),
                          blurRadius: 18,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: const Text(
                      'TasteHub',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        fontStyle: FontStyle.italic,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 26),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _PolicyLink extends StatelessWidget {
  const _PolicyLink({required this.label, required this.routePath});

  final String label;
  final String routePath;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.push(routePath),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
        child: Text(
          label,
          style: const TextStyle(
            color: Color(0xFF475467),
            fontSize: 11,
            decoration: TextDecoration.underline,
          ),
        ),
      ),
    );
  }
}

class _GoogleAuthButton extends StatelessWidget {
  const _GoogleAuthButton({required this.loading, required this.onPressed});

  final bool loading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: OutlinedButton(
        onPressed: loading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color(0xFFD8DEE8)),
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: const Color(0xFFFCE8E6),
                borderRadius: BorderRadius.circular(999),
              ),
              alignment: Alignment.center,
              child: const Text(
                'G',
                style: TextStyle(
                  color: Color(0xFFEA4335),
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Continue with Google',
              style: TextStyle(
                color: AppTheme.textPrimaryLight,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
