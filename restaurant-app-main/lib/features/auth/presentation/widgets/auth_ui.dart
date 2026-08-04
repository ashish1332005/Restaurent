import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const authOrange = Color(0xFFFF4D0A);
const authInk = Color(0xFF171717);
const authMuted = Color(0xFF707070);

class AuthBackground extends StatelessWidget {
  const AuthBackground({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: const BoxDecoration(color: Color(0xFFFFFCF9)),
    child: Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          'assets/images/auth_food_background.png',
          fit: BoxFit.cover,
        ),
        Container(color: Colors.white.withValues(alpha: 0.10)),
        child,
      ],
    ),
  );
}

class AuthBrand extends StatelessWidget {
  const AuthBrand({super.key});

  @override
  Widget build(BuildContext context) => Column(
    children: [
      const Icon(Icons.room_service_outlined, color: authOrange, size: 47),
      RichText(
        text: const TextSpan(
          style: TextStyle(
            fontSize: 38,
            height: 1,
            fontWeight: FontWeight.w800,
            letterSpacing: -1.5,
            color: authInk,
          ),
          children: [
            TextSpan(text: 'Taste'),
            TextSpan(
              text: 'Hub',
              style: TextStyle(color: authOrange),
            ),
          ],
        ),
      ),
      const SizedBox(height: 10),
      const Text(
        'Good Food, Good Mood',
        style: TextStyle(
          color: authMuted,
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
      ),
    ],
  );
}

class AuthField extends StatelessWidget {
  const AuthField({
    super.key,
    required this.controller,
    required this.hint,
    required this.icon,
    this.keyboardType,
    this.inputFormatters,
    this.maxLength,
    this.obscureText = false,
    this.suffix,
    this.textInputAction,
    this.onSubmitted,
    this.textCapitalization = TextCapitalization.none,
  });
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final int? maxLength;
  final bool obscureText;
  final Widget? suffix;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final TextCapitalization textCapitalization;

  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    keyboardType: keyboardType,
    inputFormatters: inputFormatters,
    maxLength: maxLength,
    obscureText: obscureText,
    enableSuggestions: !obscureText,
    autocorrect: !obscureText,
    textInputAction: textInputAction,
    onSubmitted: onSubmitted,
    textCapitalization: textCapitalization,
    style: const TextStyle(fontSize: 16, color: authInk),
    decoration: InputDecoration(
      counterText: '',
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF8B8B91), fontSize: 16),
      prefixIcon: Icon(icon, color: const Color(0xFF303035), size: 23),
      suffixIcon: suffix,
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.90),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 19),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFD8D5D2)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: authOrange, width: 1.5),
      ),
    ),
  );
}

class AuthPrimaryButton extends StatelessWidget {
  const AuthPrimaryButton({
    super.key,
    required this.label,
    required this.loading,
    required this.onPressed,
  });
  final String label;
  final bool loading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    height: 58,
    child: DecoratedBox(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF5B0A), Color(0xFFFF3D00)],
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: authOrange.withValues(alpha: 0.22),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: loading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          disabledBackgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: loading
            ? const SizedBox(
                width: 23,
                height: 23,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  color: Colors.white,
                ),
              )
            : Text(
                label,
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                ),
              ),
      ),
    ),
  );
}

class AuthDivider extends StatelessWidget {
  const AuthDivider({super.key});
  @override
  Widget build(BuildContext context) => const Row(
    children: [
      Expanded(child: Divider(color: Color(0xFFD8D5D2))),
      Padding(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: Text('or continue with', style: TextStyle(color: authMuted)),
      ),
      Expanded(child: Divider(color: Color(0xFFD8D5D2))),
    ],
  );
}

class SocialAuthRow extends StatelessWidget {
  const SocialAuthRow({
    super.key,
    required this.loading,
    required this.onGoogle,
  });
  final bool loading;
  final VoidCallback onGoogle;

  @override
  Widget build(BuildContext context) {
    void unavailable(String provider) =>
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$provider sign-in is coming soon.')),
        );
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _SocialButton(
          label: 'G',
          color: const Color(0xFF4285F4),
          onTap: loading ? null : onGoogle,
        ),
        const SizedBox(width: 22),
        _SocialButton(
          icon: Icons.apple,
          color: Colors.black,
          onTap: loading ? null : () => unavailable('Apple'),
        ),
        const SizedBox(width: 22),
        _SocialButton(
          label: 'f',
          color: const Color(0xFF1877F2),
          onTap: loading ? null : () => unavailable('Facebook'),
        ),
      ],
    );
  }
}

class _SocialButton extends StatelessWidget {
  const _SocialButton({this.label, this.icon, required this.color, this.onTap});
  final String? label;
  final IconData? icon;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(14),
    child: Container(
      width: 58,
      height: 58,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE0DDDA)),
      ),
      child: icon != null
          ? Icon(icon, color: color, size: 31)
          : Text(
              label!,
              style: TextStyle(
                color: color,
                fontSize: 29,
                fontWeight: FontWeight.w900,
                height: 1,
              ),
            ),
    ),
  );
}

class AuthError extends StatelessWidget {
  const AuthError(this.message, {super.key});
  final String message;
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: BoxDecoration(
      color: const Color(0xFFFFEFEA),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Text(
      message,
      style: const TextStyle(
        color: Color(0xFFB42318),
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}
