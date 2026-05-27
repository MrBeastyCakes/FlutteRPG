import 'package:flutter/material.dart';
import '../../theme/design_tokens.dart';

class GameSkeleton extends StatefulWidget {
  final double? width;
  final double height;
  final double borderRadius;

  const GameSkeleton({
    super.key,
    this.width,
    required this.height,
    this.borderRadius = DSRadius.md,
  });

  @override
  State<GameSkeleton> createState() => _GameSkeletonState();
}

class _GameSkeletonState extends State<GameSkeleton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.25, end: 0.65).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: DSColors.surface3.withOpacity(_animation.value),
            borderRadius: BorderRadius.circular(widget.borderRadius),
          ),
        );
      },
    );
  }
}
