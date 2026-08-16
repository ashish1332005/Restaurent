import 'package:flutter/material.dart';

import '../../../../core/theme/hospitality_theme.dart';

class OwnerAuthShell extends StatelessWidget {
  const OwnerAuthShell({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    this.leading,
    this.maxFormWidth = 460,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final Widget? leading;
  final double maxFormWidth;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 880;
          final content = ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxFormWidth),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (leading != null) ...[
                  Align(alignment: Alignment.centerLeft, child: leading!),
                  const SizedBox(height: 12),
                ],
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: HospitalityColors.softSaffron,
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: const Icon(
                        Icons.restaurant_rounded,
                        color: HospitalityColors.saffron,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Mehmaan',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          Text(
                            'Restaurant OS',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(title, style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 7),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: HospitalityColors.mutedInk,
                  ),
                ),
                const SizedBox(height: 22),
                child,
              ],
            ),
          );
          return Row(
            children: [
              if (wide)
                Expanded(
                  flex: 5,
                  child: Container(
                    height: double.infinity,
                    color: HospitalityColors.ink,
                    padding: const EdgeInsets.all(48),
                    child: Align(
                      alignment: Alignment.bottomLeft,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 440),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 7,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: .1),
                                borderRadius: BorderRadius.circular(99),
                              ),
                              child: const Text(
                                'ATITHI DEVO BHAVA',
                                style: TextStyle(
                                  color: HospitalityColors.turmeric,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'Warm service.\nSmarter operations.',
                              style: Theme.of(context).textTheme.displaySmall
                                  ?.copyWith(color: Colors.white, fontSize: 42),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              'Manage your menu, tables, kitchen and guests from one calm workspace.',
                              style: Theme.of(context).textTheme.bodyLarge
                                  ?.copyWith(color: Colors.white70),
                            ),
                            const SizedBox(height: 28),
                            const Row(
                              children: [
                                _Feature(
                                  icon: Icons.qr_code_rounded,
                                  label: 'QR ordering',
                                ),
                                SizedBox(width: 22),
                                _Feature(
                                  icon: Icons.insights_rounded,
                                  label: 'Live insights',
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              Expanded(
                flex: wide ? 6 : 1,
                child: SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: EdgeInsets.symmetric(
                    horizontal: wide ? 48 : 20,
                    vertical: wide ? 36 : 20,
                  ),
                  child: Align(alignment: Alignment.topCenter, child: content),
                ),
              ),
            ],
          );
        },
      ),
    ),
  );
}

class _Feature extends StatelessWidget {
  const _Feature({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, color: HospitalityColors.turmeric, size: 19),
      const SizedBox(width: 7),
      Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    ],
  );
}

class AuthErrorBanner extends StatelessWidget {
  const AuthErrorBanner({super.key, required this.message});
  final String message;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: const Color(0xFFFFECEA),
      borderRadius: BorderRadius.circular(HospitalityRadius.small),
      border: Border.all(color: const Color(0xFFF7C5C0)),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.error_outline_rounded,
          size: 19,
          color: HospitalityColors.danger,
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            message,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: HospitalityColors.danger,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );
}
