import 'package:flutter/material.dart';

import 'dart:io';
import 'package:flutter/foundation.dart';

class CustomProgressBar extends StatelessWidget {
  final double progress; // 0.0 to 1.0
  final Color color;
  final Color backgroundColor;
  final double height;
  final String? label;
  final TextStyle? labelStyle;

  const CustomProgressBar({
    Key? key,
    required this.progress,
    required this.color,
    this.backgroundColor = const Color(0xFF1E2833),
    this.height = 16,
    this.label,
    this.labelStyle,
  }) : super(key: key);

  @override
  Widget build(BuildContext buildContext) {
    final double clampedProgress = progress.clamp(0.0, 1.0);

    return ClipRRect(
      borderRadius: BorderRadius.circular(height / 2),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background
          Container(
            height: height,
            color: backgroundColor,
          ),
          // Filled Bar
          Align(
            alignment: Alignment.centerLeft,
            child: AnimatedFractionallySizedBox(
              duration: const Duration(milliseconds: 150),
              curve: Curves.easeOut,
              widthFactor: clampedProgress,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(height / 2),
                child: Stack(
                  children: [
                    Container(
                      height: height,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(height / 2),
                        boxShadow: [
                          BoxShadow(
                            color: color.withOpacity(0.4),
                            blurRadius: 4,
                            offset: const Offset(0, 0),
                          ),
                        ],
                      ),
                    ),
                    Positioned.fill(
                      child: ShimmerProgressOverlay(color: color),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Label Overlay
          if (label != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                label!,
                style: labelStyle ??
                    const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
        ],
      ),
    );
  }
}

class ShimmerProgressOverlay extends StatefulWidget {
  final Color color;
  const ShimmerProgressOverlay({super.key, required this.color});

  @override
  State<ShimmerProgressOverlay> createState() => _ShimmerProgressOverlayState();
}

class _ShimmerProgressOverlayState extends State<ShimmerProgressOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
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
        return FractionalTranslation(
          translation: Offset(_controller.value * 2.0 - 1.0, 0.0),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white.withOpacity(0.0),
                  Colors.white.withOpacity(0.12),
                  Colors.white.withOpacity(0.28),
                  Colors.white.withOpacity(0.12),
                  Colors.white.withOpacity(0.0),
                ],
                stops: const [0.0, 0.35, 0.5, 0.65, 1.0],
              ),
            ),
          ),
        );
      },
    );
  }
}

