import 'package:flutter/material.dart';

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
              child: Container(
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
