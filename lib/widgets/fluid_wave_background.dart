import 'dart:math' as math;
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class FluidWaveBackground extends StatefulWidget {
  final Color color;

  const FluidWaveBackground({
    super.key,
    required this.color,
  });

  @override
  State<FluidWaveBackground> createState() => _FluidWaveBackgroundState();
}

class _FluidWaveBackgroundState extends State<FluidWaveBackground> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    );

    final isTest = !kIsWeb && Platform.environment.containsKey('FLUTTER_TEST');
    if (!isTest) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: _WavePainter(
            color: widget.color,
            animationValue: _controller.value,
          ),
          child: Container(),
        );
      },
    );
  }
}

class _WavePainter extends CustomPainter {
  final Color color;
  final double animationValue;

  _WavePainter({
    required this.color,
    required this.animationValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint1 = Paint()
      ..color = color.withOpacity(0.09)
      ..style = PaintingStyle.fill;

    final paint2 = Paint()
      ..color = color.withOpacity(0.05)
      ..style = PaintingStyle.fill;

    final double baseHeight = size.height * 0.45;
    final double amplitude = size.height * 0.15;

    // Draw first wave (moving forward)
    final path1 = Path();
    path1.moveTo(0, size.height);
    for (double x = 0; x <= size.width; x++) {
      final double radians = (x / size.width) * 2 * math.pi + (animationValue * 2 * math.pi);
      final double y = baseHeight + math.sin(radians) * amplitude;
      path1.lineTo(x, y);
    }
    path1.lineTo(size.width, size.height);
    path1.close();
    canvas.drawPath(path1, paint1);

    // Draw second wave (moving backward, higher frequency)
    final path2 = Path();
    path2.moveTo(0, size.height);
    for (double x = 0; x <= size.width; x++) {
      final double radians = (x / size.width) * 3 * math.pi - (animationValue * 2 * math.pi * 1.2);
      final double y = (baseHeight + size.height * 0.1) + math.cos(radians) * (amplitude * 0.7);
      path2.lineTo(x, y);
    }
    path2.lineTo(size.width, size.height);
    path2.close();
    canvas.drawPath(path2, paint2);
  }

  @override
  bool shouldRepaint(covariant _WavePainter oldDelegate) {
    return oldDelegate.animationValue != animationValue || oldDelegate.color != color;
  }
}
