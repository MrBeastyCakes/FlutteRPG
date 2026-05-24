import 'dart:io' show Platform;
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../theme/game_theme.dart';

class CoinParticle {
  final double id;
  final Offset start;
  final Offset end;
  final Offset control;
  final double delay; // delay in milliseconds

  CoinParticle({
    required this.id,
    required this.start,
    required this.end,
    required this.control,
    required this.delay,
  });
}

class CoinBurstOverlay {
  static void show({
    required OverlayState overlayState,
    required Offset source,
    required Offset target,
    bool isBuy = true,
  }) {
    if (kIsWeb || (const bool.fromEnvironment('dart.vm.product') == false &&
        RegExp(r'FLUTTER_TEST').hasMatch(Platform.environment['FLUTTER_TEST'] ?? ''))) {
      // Avoid starting animation timers during testing to prevent tests hanging
      return;
    }

    late OverlayEntry entry;

    final random = Random();
    final particles = List.generate(8, (index) {
      // Calculate a midpoint control point for Bezier curve
      final double midX = (source.dx + target.dx) / 2;
      
      // Arc height and offset variation
      final double controlX = midX + (random.nextDouble() * 160 - 80);
      final double controlY = min(source.dy, target.dy) - (60 + random.nextDouble() * 120);

      return CoinParticle(
        id: random.nextDouble(),
        start: source,
        end: target,
        control: Offset(controlX, controlY),
        delay: index * 60.0, // Staggered entry
      );
    });

    entry = OverlayEntry(
      builder: (context) => _CoinBurstAnimator(
        particles: particles,
        onComplete: () {
          entry.remove();
        },
      ),
    );

    overlayState.insert(entry);
  }
}

class _CoinBurstAnimator extends StatefulWidget {
  final List<CoinParticle> particles;
  final VoidCallback onComplete;

  const _CoinBurstAnimator({
    required this.particles,
    required this.onComplete,
  });

  @override
  State<_CoinBurstAnimator> createState() => _CoinBurstAnimatorState();
}

class _CoinBurstAnimatorState extends State<_CoinBurstAnimator> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          widget.onComplete();
        }
      });
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Offset _getBezierPath(Offset p0, Offset p1, Offset p2, double t) {
    // Quadratic Bezier: B(t) = (1-t)^2*P0 + 2*(1-t)*t*P1 + t^2*P2
    final double u = 1 - t;
    final double tt = t * t;
    final double uu = u * u;

    final double x = uu * p0.dx + 2 * u * t * p1.dx + tt * p2.dx;
    final double y = uu * p0.dy + 2 * u * t * p1.dy + tt * p2.dy;
    return Offset(x, y);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final progress = _controller.value;
        return Stack(
          children: widget.particles.map((p) {
            // Adjust local time value based on delay
            final double startT = p.delay / 1100.0;
            if (progress < startT) return const SizedBox.shrink();

            // Rescale progress from startT to 1.0
            final double t = min(1.0, (progress - startT) / (1.0 - startT));
            if (t >= 1.0) return const SizedBox.shrink();

            final position = _getBezierPath(p.start, p.control, p.end, t);

            // Compute scaling and rotation
            final double scale = t < 0.2 ? t / 0.2 : (t > 0.8 ? (1.0 - t) / 0.2 : 1.0);
            final double rotation = t * pi * 4;

            return Positioned(
              left: position.dx - 12,
              top: position.dy - 12,
              child: Opacity(
                opacity: (1.0 - t).clamp(0.0, 1.0),
                child: Transform.rotate(
                  angle: rotation,
                  child: Transform.scale(
                    scale: scale,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: GameTheme.accentGold,
                        border: Border.all(color: Colors.white, width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: GameTheme.accentGold.withOpacity(0.6),
                            blurRadius: 6,
                            spreadRadius: 1,
                          )
                        ],
                      ),
                      child: const Center(
                        child: Text(
                          'G',
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class GoldCounter extends StatefulWidget {
  final int gold;
  final double fontSize;
  final bool showIcon;

  const GoldCounter({
    super.key,
    required this.gold,
    this.fontSize = 18,
    this.showIcon = true,
  });

  @override
  State<GoldCounter> createState() => _GoldCounterState();
}

class _GoldCounterState extends State<GoldCounter> with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _numberController;
  late Animation<double> _numberAnimation;
  int _oldGold = 0;
  int _targetGold = 0;
  Color _flashColor = Colors.transparent;

  @override
  void initState() {
    super.initState();
    _oldGold = widget.gold;
    _targetGold = widget.gold;

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _numberController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _numberAnimation = Tween<double>(begin: _oldGold.toDouble(), end: _targetGold.toDouble())
        .animate(CurvedAnimation(parent: _numberController, curve: Curves.easeOutCubic));
  }

  @override
  void didUpdateWidget(GoldCounter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.gold != widget.gold) {
      setState(() {
        _oldGold = _targetGold;
        _targetGold = widget.gold;
        
        // Pick flash color based on direction
        if (_targetGold > _oldGold) {
          _flashColor = Colors.greenAccent;
        } else {
          _flashColor = Colors.redAccent;
        }
      });

      _pulseController.forward(from: 0.0);
      
      _numberAnimation = Tween<double>(begin: _oldGold.toDouble(), end: _targetGold.toDouble())
          .animate(CurvedAnimation(parent: _numberController, curve: Curves.easeOutCubic));
      _numberController.forward(from: 0.0).then((_) {
        setState(() {
          _flashColor = Colors.transparent;
        });
      });
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _numberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scaleAnimation = Tween<double>(begin: 1.0, end: 1.25)
        .animate(CurvedAnimation(parent: _pulseController, curve: Curves.elasticOut));

    return AnimatedBuilder(
      animation: Listenable.merge([_numberController, _pulseController]),
      builder: (context, child) {
        final currentVal = _numberAnimation.value.round();
        
        // Color transition logic
        Color textColor = GameTheme.accentGold;
        if (_flashColor != Colors.transparent) {
          textColor = Color.lerp(
            textColor,
            _flashColor,
            1.0 - _numberController.value,
          )!;
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.3),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: GameTheme.accentGold.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.showIcon) ...[
                Transform.scale(
                  scale: scaleAnimation.value,
                  child: const Text(
                    '🪙',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
                const SizedBox(width: 6),
              ],
              Text(
                '$currentVal',
                style: TextStyle(
                  color: textColor,
                  fontSize: widget.fontSize,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                  shadows: [
                    BoxShadow(
                      color: textColor.withOpacity(0.3),
                      blurRadius: 4,
                    )
                  ],
                ),
              ),
              const SizedBox(width: 2),
              Text(
                'g',
                style: TextStyle(
                  color: textColor.withOpacity(0.7),
                  fontSize: widget.fontSize * 0.8,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
