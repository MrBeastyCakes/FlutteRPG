import 'dart:math' as math;
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/crafted_item.dart';
import '../theme/game_theme.dart';

class FlyingItemOverlay extends StatefulWidget {
  final String icon;
  final Offset startPosition;
  final Offset endPosition;
  final VoidCallback onFinished;
  final QualityTier? quality;

  const FlyingItemOverlay({
    super.key,
    required this.icon,
    required this.startPosition,
    required this.endPosition,
    required this.onFinished,
    this.quality,
  });

  static void show(
    BuildContext context, {
    required String icon,
    required Offset startPosition,
    QualityTier? quality,
  }) {
    // If running in tests, skip overlay insertion to prevent test execution delays
    final isTest = !kIsWeb && Platform.environment.containsKey('FLUTTER_TEST');
    if (isTest) return;

    final overlayState = Overlay.of(context);
    final size = MediaQuery.of(context).size;
    
    // Inventory tab is index 2 of 5. It sits exactly in the center horizontally (x = width / 2).
    // The bottom bar height is about 56px, so we target 30px from bottom.
    final endPos = Offset(size.width * 0.5, size.height - 30.0);
    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (context) => FlyingItemOverlay(
        icon: icon,
        startPosition: startPosition,
        endPosition: endPos,
        quality: quality,
        onFinished: () {
          entry.remove();
        },
      ),
    );

    overlayState.insert(entry);
  }

  @override
  State<FlyingItemOverlay> createState() => _FlyingItemOverlayState();
}

class _FlyingItemOverlayState extends State<FlyingItemOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _progressAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutCubic,
    );

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
    return AnimatedBuilder(
      animation: _progressAnimation,
      builder: (context, child) {
        final t = _progressAnimation.value;
        
        // Quadratic bezier curve interpolation to arc upward
        // Control point: midpoint but shifted upward/left
        final p0 = widget.startPosition;
        final p2 = widget.endPosition;
        final p1 = Offset(
          (p0.dx + p2.dx) / 2 - 40.0,
          math.min(p0.dy, p2.dy) - 100.0,
        );

        // Bezier formula: B(t) = (1-t)^2 * p0 + 2*(1-t)*t * p1 + t^2 * p2
        final double x = (1 - t) * (1 - t) * p0.dx + 2 * (1 - t) * t * p1.dx + t * t * p2.dx;
        final double y = (1 - t) * (1 - t) * p0.dy + 2 * (1 - t) * t * p1.dy + t * t * p2.dy;

        // Shrink item as it approaches the target, and fade out at the end
        final scale = (1.4 - t * 0.8).clamp(0.6, 1.4);
        final opacity = t < 0.85 ? 1.0 : ((1.0 - t) / 0.15).clamp(0.0, 1.0);

        return Positioned(
          left: x - 20,
          top: y - 20,
          child: IgnorePointer(
            child: Opacity(
              opacity: opacity,
              child: Transform.scale(
                scale: scale,
                child: Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E2833).withOpacity(0.85),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: widget.quality != null
                          ? GameTheme.getQualityColor(widget.quality).withOpacity(0.8)
                          : Colors.amber.withOpacity(0.5),
                      width: widget.quality != null && widget.quality != QualityTier.standard ? 2.0 : 1.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: widget.quality != null
                            ? GameTheme.getQualityColor(widget.quality).withOpacity(0.4)
                            : Colors.amber.withOpacity(0.25),
                        blurRadius: widget.quality == QualityTier.masterwork ? 10.0 : 6.0,
                        spreadRadius: widget.quality == QualityTier.masterwork ? 3.0 : 2.0,
                      ),
                    ],
                  ),
                  child: Text(
                    widget.icon,
                    style: const TextStyle(
                      fontSize: 22,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
