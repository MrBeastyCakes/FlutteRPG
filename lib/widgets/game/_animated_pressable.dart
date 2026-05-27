import 'package:flutter/material.dart';
import '../../theme/design_tokens.dart';

class AnimatedPressable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double pressedScale;
  final Duration pressDuration;
  final HitTestBehavior behavior;

  const AnimatedPressable({
    super.key,
    required this.child,
    this.onTap,
    this.pressedScale = 0.96,
    this.pressDuration = DSMotion.fast,
    this.behavior = HitTestBehavior.opaque,
  });

  @override
  State<AnimatedPressable> createState() => _AnimatedPressableState();
}

class _AnimatedPressableState extends State<AnimatedPressable>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.pressDuration,
      lowerBound: 0.0,
      upperBound: 1.0,
    );
    _scale = Tween<double>(begin: 1.0, end: widget.pressedScale).animate(
      CurvedAnimation(parent: _controller, curve: DSMotion.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(_) {
    if (widget.onTap == null) return;
    _controller.forward();
  }

  void _handleTapUp(_) {
    if (widget.onTap == null) return;
    _controller.reverse();
    widget.onTap?.call();
  }

  void _handleTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: widget.behavior,
      onTapDown: widget.onTap == null ? null : _handleTapDown,
      onTapUp: widget.onTap == null ? null : _handleTapUp,
      onTapCancel: widget.onTap == null ? null : _handleTapCancel,
      child: AnimatedBuilder(
        animation: _scale,
        builder: (context, child) => Transform.scale(scale: _scale.value, child: child),
        child: widget.child,
      ),
    );
  }
}
