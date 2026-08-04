import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'app_theme.dart';

class AppScrollBehavior extends MaterialScrollBehavior {
  const AppScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.trackpad,
    PointerDeviceKind.stylus,
  };
}

class DesktopAppFrame extends StatelessWidget {
  const DesktopAppFrame({super.key, required this.child});

  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final width = media.size.width;
    final isDesktop = width >= 1100;
    final clampedTextScale = media.textScaler.clamp(
      minScaleFactor: 0.9,
      maxScaleFactor: 1.12,
    );

    return MediaQuery(
      data: media.copyWith(textScaler: clampedTextScale),
      child: ScrollConfiguration(
        behavior: const AppScrollBehavior(),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppTheme.scaffoldBackgroundLight,
            gradient: isDesktop
                ? const LinearGradient(
                    colors: [
                      Color(0xFFFFF7F2),
                      Color(0xFFF7F8FB),
                      Color(0xFFF4F7FB),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
          ),
          child: Stack(
            children: [
              if (isDesktop) ...[
                Positioned(
                  top: -160,
                  right: -120,
                  child: _GlowOrb(
                    size: 360,
                    color: AppTheme.primaryColor.withValues(alpha: 0.10),
                  ),
                ),
                Positioned(
                  bottom: -180,
                  left: -120,
                  child: _GlowOrb(
                    size: 340,
                    color: const Color(0xFFFFB020).withValues(alpha: 0.11),
                  ),
                ),
              ],
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1640),
                  child: child ?? const SizedBox.shrink(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          boxShadow: [
            BoxShadow(color: color, blurRadius: 100, spreadRadius: 80),
          ],
        ),
      ),
    );
  }
}
