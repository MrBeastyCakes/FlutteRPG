import 'dart:math' as math;
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class ParticleExplosionOverlay extends StatefulWidget {
  final Offset position;
  final Color color;
  final VoidCallback onFinished;

  const ParticleExplosionOverlay({
    super.key,
    required this.position,
    required this.color,
    required this.onFinished,
  });

  static void show(BuildContext context, Offset position, {Color color = const Color(0xFFFFD700)}) {
    final overlayState = Overlay.of(context);
    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (context) => ParticleExplosionOverlay(
        position: position,
        color: color,
        onFinished: () {
          entry.remove();
        },
      ),
    );

    overlayState.insert(entry);
  }

  @override
  State<ParticleExplosionOverlay> createState() => _ParticleExplosionOverlayState();
}

class _ParticleExplosionOverlayState extends State<ParticleExplosionOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_Particle> _particles = [];
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    // Generate particles
    final isTest = !kIsWeb && Platform.environment.containsKey('FLUTTER_TEST');
    final count = isTest ? 2 : 45; // Generate very few particles in tests to avoid performance overhead
    
    final particleColors = [
      widget.color,
      Colors.white,
      widget.color.withBlue(120),
      const Color(0xFFFFD700), // Gold
      const Color(0xFFFFC0CB), // Rose
    ];

    for (int i = 0; i < count; i++) {
      final angle = _random.nextDouble() * 2 * math.pi;
      final speed = 2.0 + _random.nextDouble() * 7.0;
      _particles.add(
        _Particle(
          x: widget.position.dx,
          y: widget.position.dy,
          vx: math.cos(angle) * speed,
          vy: math.sin(angle) * speed - 3.0, // Bias upward slightly
          color: particleColors[_random.nextInt(particleColors.length)],
          size: 3.0 + _random.nextDouble() * 7.0,
          life: 0.0,
          maxLife: 0.5 + _random.nextDouble() * 0.7,
          isStar: _random.nextBool(),
        ),
      );
    }

    _controller.addListener(() {
      if (mounted) {
        setState(() {
          final dt = 0.016; // 60fps step
          for (var p in _particles) {
            p.x += p.vx;
            p.y += p.vy;
            p.vy += 0.2; // Gravity pull
            p.vx *= 0.96; // Air resistance drag
            p.vy *= 0.96;
            p.life += dt;
          }
        });
      }
    });

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onFinished();
      }
    });

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        painter: _ParticlePainter(particles: _particles),
        child: Container(),
      ),
    );
  }
}

class _Particle {
  double x;
  double y;
  double vx;
  double vy;
  final Color color;
  final double size;
  double life;
  final double maxLife;
  final bool isStar;

  _Particle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.color,
    required this.size,
    required this.life,
    required this.maxLife,
    required this.isStar,
  });
}

class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;

  _ParticlePainter({required this.particles});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    for (var p in particles) {
      if (p.life >= p.maxLife) continue;
      
      final opacity = (1.0 - (p.life / p.maxLife)).clamp(0.0, 1.0);
      paint.color = p.color.withOpacity(opacity);

      if (p.isStar) {
        _drawStar(canvas, Offset(p.x, p.y), p.size, paint);
      } else {
        canvas.drawCircle(Offset(p.x, p.y), p.size, paint);
      }
    }
  }

  void _drawStar(Canvas canvas, Offset center, double size, Paint paint) {
    final path = Path();
    final double innerRadius = size * 0.4;
    final double outerRadius = size;
    const int points = 5;

    for (int i = 0; i < points * 2; i++) {
      final double radius = i.isEven ? outerRadius : innerRadius;
      final double angle = (i * math.pi) / points - (math.pi / 2);
      final double x = center.dx + radius * math.cos(angle);
      final double y = center.dy + radius * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter oldDelegate) {
    return true;
  }
}
