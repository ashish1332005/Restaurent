import 'dart:math' as math;
import 'package:flutter/material.dart';

class CelebrateParticles extends StatefulWidget {
  const CelebrateParticles({
    super.key,
    required this.child,
    this.particleCount = 35,
    this.colors = const [
      Color(0xFFC99232),
      Color(0xFF237A59),
      Color(0xFFE6B84E),
      Color(0xFFFF5722),
      Color(0xFF4CAF50),
    ],
  });

  final Widget child;
  final int particleCount;
  final List<Color> colors;

  @override
  State<CelebrateParticles> createState() => CelebrateParticlesState();
}

class CelebrateParticlesState extends State<CelebrateParticles>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  final List<_Particle> _particles = [];
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void blast() {
    _particles.clear();
    for (int i = 0; i < widget.particleCount; i++) {
      final angle = _random.nextDouble() * 2 * math.pi;
      final speed = 120.0 + _random.nextDouble() * 280.0;
      final color = widget.colors[_random.nextInt(widget.colors.length)];
      final size = 4.0 + _random.nextDouble() * 6.0;
      final rotation = _random.nextDouble() * math.pi;
      final isCircle = _random.nextBool();

      _particles.add(
        _Particle(
          vx: math.cos(angle) * speed,
          vy: math.sin(angle) * speed - 150.0,
          color: color,
          size: size,
          rotation: rotation,
          isCircle: isCircle,
        ),
      );
    }
    _controller.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      foregroundPainter: _controller.isAnimating
          ? _ParticlesPainter(
              particles: _particles,
              progress: _controller.value,
            )
          : null,
      child: widget.child,
    );
  }
}

class _Particle {
  _Particle({
    required this.vx,
    required this.vy,
    required this.color,
    required this.size,
    required this.rotation,
    required this.isCircle,
  });

  final double vx;
  final double vy;
  final Color color;
  final double size;
  final double rotation;
  final bool isCircle;
}

class _ParticlesPainter extends CustomPainter {
  _ParticlesPainter({
    required this.particles,
    required this.progress,
  });

  final List<_Particle> particles;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final gravity = 400.0 * progress * progress;
    final alpha = (1.0 - progress).clamp(0.0, 1.0);

    for (final p in particles) {
      final dx = center.dx + p.vx * progress * 0.8;
      final dy = center.dy + p.vy * progress * 0.8 + gravity;

      final paint = Paint()
        ..color = p.color.withValues(alpha: alpha)
        ..style = PaintingStyle.fill;

      canvas.save();
      canvas.translate(dx, dy);
      canvas.rotate(p.rotation + progress * 5.0);

      if (p.isCircle) {
        canvas.drawCircle(Offset.zero, p.size / 2, paint);
      } else {
        canvas.drawRect(
          Rect.fromCenter(
            center: Offset.zero,
            width: p.size,
            height: p.size * 0.6,
          ),
          paint,
        );
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlesPainter oldDelegate) => true;
}
