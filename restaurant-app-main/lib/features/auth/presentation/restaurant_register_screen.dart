import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/network/restaurant_api.dart';
import '../application/customer_auth_session.dart';
import 'widgets/owner_auth_shell.dart';

class RestaurantRegisterScreen extends StatefulWidget {
  const RestaurantRegisterScreen({super.key});
  @override
  State<RestaurantRegisterScreen> createState() =>
      _RestaurantRegisterScreenState();
}

class _RestaurantRegisterScreenState extends State<RestaurantRegisterScreen> {
  static const navy = Color(0xFF071A31),
      gold = Color(0xFFC99B4C),
      cream = Color(0xFFFFFBF7);
  final owner = TextEditingController(), restaurant = TextEditingController();
  final phone = TextEditingController(), email = TextEditingController();
  final address = TextEditingController(), city = TextEditingController();
  final password = TextEditingController(), confirm = TextEditingController();
  bool loading = false, obscure = true, obscureConfirm = true, agreed = false;
  int currentStep = 0;
  String type = 'Fine Dining';
  String? error;

  @override
  void dispose() {
    for (final c in [
      owner,
      restaurant,
      phone,
      email,
      address,
      city,
      password,
      confirm,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> submit() async {
    FocusManager.instance.primaryFocus?.unfocus();
    final digits = phone.text.replaceAll(RegExp(r'\D'), '');
    final mail = email.text.trim();
    if (restaurant.text.trim().length < 2)
      return showError('Enter your restaurant name.');
    if (owner.text.trim().length < 2)
      return showError('Enter the owner’s full name.');
    if (digits.length != 10)
      return showError('Enter a valid 10-digit mobile number.');
    if (mail.isNotEmpty &&
        !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(mail))
      return showError('Enter a valid email address or leave it empty.');
    if (address.text.trim().length < 4)
      return showError('Enter the restaurant address.');
    if (city.text.trim().length < 2) return showError('Enter the city.');
    if (password.text.length < 6)
      return showError('Password must have at least 6 characters.');
    if (password.text != confirm.text)
      return showError('Passwords do not match.');
    if (!agreed)
      return showError('Accept the Terms & Conditions and Privacy Policy.');
    setState(() {
      loading = true;
      error = null;
    });
    try {
      await CustomerAuthSession.registerRestaurantOwner(
        ownerName: owner.text.trim(),
        restaurantName: restaurant.text.trim(),
        phone: digits,
        email: mail,
        password: password.text,
        address: '${address.text.trim()}, ${city.text.trim()}',
      );
      if (mounted) context.go('/subscription');
    } catch (exception) {
      if (mounted)
        setState(() {
          loading = false;
          error = RestaurantApi.messageFor(exception);
        });
    }
  }

  void showError(String value) => setState(() => error = value);
  bool validateCurrentStep() {
    final digits = phone.text.replaceAll(RegExp(r'\D'), '');
    final mail = email.text.trim();
    String? message;
    if (currentStep == 0) {
      if (restaurant.text.trim().length < 2) {
        message = 'Enter your restaurant name.';
      } else if (owner.text.trim().length < 2) {
        message = "Enter the owner's full name.";
      }
    } else if (currentStep == 1) {
      if (digits.length != 10) {
        message = 'Enter a valid 10-digit mobile number.';
      } else if (mail.isNotEmpty && !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(mail)) {
        message = 'Enter a valid email address or leave it empty.';
      } else if (address.text.trim().length < 4) {
        message = 'Enter the restaurant address.';
      } else if (city.text.trim().length < 2) {
        message = 'Enter the city.';
      }
    } else if (password.text.length < 6) {
      message = 'Password must have at least 6 characters.';
    } else if (password.text != confirm.text) {
      message = 'Passwords do not match.';
    } else if (!agreed) {
      message = 'Accept the Terms & Conditions and Privacy Policy.';
    }
    if (message != null) { showError(message); return false; }
    return true;
  }

  void continueStep() {
    FocusManager.instance.primaryFocus?.unfocus();
    if (!validateCurrentStep()) return;
    setState(() { error = null; currentStep++; });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: navy,
    body: LayoutBuilder(
      builder: (context, box) {
        final desktop = box.maxWidth >= 900;
        return Row(
          children: [
            if (desktop) const Expanded(child: _RegisterArtwork()),
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
                          maxWidth: desktop ? 650 : box.maxWidth,
                        ),
                        child: desktop
                            ? Padding(
                                padding: const EdgeInsets.all(34),
                                child: formCard(false),
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
                                  72,
                                ),
                                child: formCard(true),
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

  Widget formCard(bool mobile) => Container(
    width: double.infinity,
    padding: EdgeInsets.fromLTRB(
      mobile ? 12 : 30,
      mobile ? 12 : 26,
      mobile ? 12 : 30,
      mobile ? 12 : 22,
    ),
    decoration: BoxDecoration(
      color: mobile ? Colors.transparent : cream,
      borderRadius: BorderRadius.only(
        topLeft: const Radius.circular(36),
        topRight: const Radius.circular(36),
        bottomLeft: Radius.circular(mobile ? 0 : 36),
        bottomRight: Radius.circular(mobile ? 0 : 36),
      ),
      boxShadow: mobile
          ? const []
          : const [BoxShadow(color: Color(0x30000000), blurRadius: 24)],
    ),
    child: AutofillGroup(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _RegisterBrand(),
          const SizedBox(height: 14),
          Column(
            children: [
              const Icon(Icons.storefront_outlined, color: gold, size: 34),
              const SizedBox(height: 6),
              Text(
                'Create Owner Account',
                textAlign: TextAlign.center,
                style: GoogleFonts.playfairDisplay(
                  color: navy,
                  fontSize: mobile ? 26 : 32,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          const Text(
            'Register your restaurant & start managing with ease',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF6D6B6B), fontSize: 14),
          ),
          const SizedBox(height: 22),
          _StepHeader(step: currentStep),
          const SizedBox(height: 18),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: KeyedSubtree(key: ValueKey(currentStep), child: stepContent()),
          ),
          if (error != null) ...[
            const SizedBox(height: 6),
            AuthErrorBanner(message: error!),
          ],
          const SizedBox(height: 14),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: navy,
              foregroundColor: const Color(0xFFF4CA78),
              minimumSize: const Size.fromHeight(58),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(13),
              ),
            ),
            onPressed: loading ? null : (currentStep == 2 ? submit : continueStep),
            icon: loading
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.cloud_done_outlined),
            label: Text(
              loading ? 'Creating Account...'
                : (currentStep == 2 ? 'Create Account' : 'Continue'),
              style: GoogleFonts.playfairDisplay(
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (currentStep > 0) ...[
            const SizedBox(height: 4),
            TextButton.icon(
              onPressed: loading ? null : () => setState(() { error = null; currentStep--; }),
              icon: const Icon(Icons.arrow_back_rounded),
              label: const Text('Back to previous step'),
            ),
          ],          const SizedBox(height: 14),
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Text('Already have an account?'),
              TextButton(
                onPressed: loading ? null : () => context.go('/admin/login'),
                child: const Text(
                  'Login',
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

  Widget stepContent() {
    switch (currentStep) {
      case 0:
        return Column(children: [
          field(restaurant, 'Restaurant Name', Icons.storefront_outlined),
          const SizedBox(height: 12), typeField(), const SizedBox(height: 12),
          field(owner, 'Owner Name', Icons.person_outline_rounded, hints: const [AutofillHints.name]),
        ]);
      case 1:
        return Column(children: [
          field(phone, 'Phone Number', Icons.phone_outlined, keyboard: TextInputType.phone, formatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)]),
          const SizedBox(height: 12),
          field(email, 'Email Address (optional)', Icons.email_outlined, keyboard: TextInputType.emailAddress),
          const SizedBox(height: 12),
          field(address, 'Restaurant Address', Icons.location_on_outlined, hints: const [AutofillHints.fullStreetAddress]),
          const SizedBox(height: 12), field(city, 'City', Icons.location_city_outlined),
        ]);
      default:
        return Column(children: [
          passwordField(password, 'Password', false), const SizedBox(height: 12), passwordField(confirm, 'Confirm Password', true), const SizedBox(height: 8),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Checkbox(value: agreed, activeColor: navy, onChanged: (value) => setState(() => agreed = value ?? false)),
            Expanded(child: Padding(padding: const EdgeInsets.only(top: 12), child: Wrap(children: [
              const Text('I agree to the '), InkWell(onTap: () => context.push('/legal/terms'), child: const Text('Terms & Conditions', style: TextStyle(color: Color(0xFFA9761D)))),
              const Text(' and '), InkWell(onTap: () => context.push('/legal/privacy'), child: const Text('Privacy Policy', style: TextStyle(color: Color(0xFFA9761D)))),
            ]))),
          ]),
        ]);
    }
  }
  Widget field(
    TextEditingController controller,
    String hint,
    IconData icon, {
    TextInputType? keyboard,
    List<String>? hints,
    List<TextInputFormatter>? formatters,
  }) => TextField(
    controller: controller,
    keyboardType: keyboard,
    autofillHints: hints,
    inputFormatters: formatters,
    textInputAction: TextInputAction.next,
    decoration: decoration(hint, icon),
  );

  Widget passwordField(
    TextEditingController controller,
    String hint,
    bool confirmation,
  ) => TextField(
    controller: controller,
    obscureText: confirmation ? obscureConfirm : obscure,
    textInputAction: confirmation ? TextInputAction.done : TextInputAction.next,
    onSubmitted: confirmation ? (_) => loading ? null : submit() : null,
    decoration: decoration(hint, Icons.lock_outline_rounded).copyWith(
      suffixIcon: IconButton(
        tooltip: (confirmation ? obscureConfirm : obscure)
            ? 'Show password'
            : 'Hide password',
        onPressed: () => setState(() {
          if (confirmation) {
            obscureConfirm = !obscureConfirm;
          } else {
            obscure = !obscure;
          }
        }),
        icon: Icon(
          (confirmation ? obscureConfirm : obscure)
              ? Icons.visibility_outlined
              : Icons.visibility_off_outlined,
        ),
      ),
    ),
  );

  Widget typeField() => DropdownButtonFormField<String>(
    isExpanded: true,
    initialValue: type,
    decoration: decoration('Restaurant Type', Icons.local_cafe_outlined),
    items:
        const [
              'Fine Dining',
              'Casual Dining',
              'Cafe',
              'Quick Service',
              'Cloud Kitchen',
            ]
            .map(
              (v) => DropdownMenuItem(
                value: v,
                child: Text(v, overflow: TextOverflow.ellipsis),
              ),
            )
            .toList(),
    onChanged: (v) => setState(() => type = v ?? type),
  );

  InputDecoration decoration(String hint, IconData icon) => InputDecoration(
    hintText: hint,
    isDense: true,
    contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 13),
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

class _StepHeader extends StatelessWidget {
  const _StepHeader({required this.step});

  final int step;

  static const _titles = ['Restaurant details', 'Contact & location', 'Secure your account'];
  static const _subtitles = ['Tell us about your restaurant', 'Where can we reach you?', 'Set your login details'];

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(children: [
        Text('STEP ${step + 1} OF 3', style: const TextStyle(color: Color(0xFFA9761D), fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.1)),
        const Spacer(),
        Text('${((step + 1) / 3 * 100).round()}%', style: const TextStyle(color: Color(0xFF6D6B6B), fontSize: 12, fontWeight: FontWeight.w600)),
      ]),
      const SizedBox(height: 8),
      ClipRRect(
        borderRadius: BorderRadius.circular(99),
        child: LinearProgressIndicator(value: (step + 1) / 3, minHeight: 6, color: const Color(0xFFC99B4C), backgroundColor: const Color(0xFFE9DED0)),
      ),
      const SizedBox(height: 16),
      Text(_titles[step], style: GoogleFonts.playfairDisplay(color: const Color(0xFF071A31), fontSize: 22, fontWeight: FontWeight.w700)),
      const SizedBox(height: 3),
      Text(_subtitles[step], style: const TextStyle(color: Color(0xFF6D6B6B), fontSize: 14)),
    ],
  );
}
class _RegisterArtwork extends StatelessWidget {
  const _RegisterArtwork();
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
            colors: [Color(0x22000000), Colors.transparent, Color(0x22000000)],
          ),
        ),
      ),
      SafeArea(
        child: Align(
          alignment: const Alignment(0, -0.56),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 62,
                height: 62,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _RestaurantRegisterScreenState.gold,
                    width: 1.5,
                  ),
                  color: const Color(0x9907192D),
                ),
                child: const Icon(
                  Icons.restaurant_rounded,
                  color: Color(0xFFF3C96F),
                  size: 32,
                ),
              ),
              const SizedBox(height: 9),
              Text(
                'MEHMAAN',
                style: GoogleFonts.playfairDisplay(
                  color: const Color(0xFFF3C96F),
                  fontSize: 29,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 4,
                ),
              ),
              const Text(
                'R E S T A U R A N T',
                style: TextStyle(
                  color: Color(0xFFF3C96F),
                  letterSpacing: 3,
                  fontSize: 10,
                ),
              ),
              const SizedBox(height: 9),
              const Text(
                'Manage. Grow. Delight.',
                style: TextStyle(color: Color(0xFFF3C96F), fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    ],
  );
}

class _RegisterBrand extends StatelessWidget {
  const _RegisterBrand();
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
