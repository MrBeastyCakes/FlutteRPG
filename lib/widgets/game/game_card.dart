import 'package:flutter/material.dart';
import '../../theme/design_tokens.dart';
import '_animated_pressable.dart';

class GameCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final int elevation;
  final Color? accentColor;
  final VoidCallback? onTap;
  final bool visible;

  const GameCard({
    super.key,
    required this.child,
    this.padding = DSSpace.card,
    this.elevation = 1,
    this.accentColor,
    this.onTap,
    this.visible = true,
  });

  Color _surfaceColor() {
    switch (elevation) {
      case 0: return DSColors.surface1;
      case 1: return DSColors.surface2;
      case 2: return DSColors.surface3;
      case 3: return DSColors.surface4;
      case 4: return DSColors.surface5;
      default: return DSColors.surface2;
    }
  }

  List<BoxShadow> _shadow() {
    switch (elevation) {
      case 0: return DSShadow.sm.map((s) => s.copyWith(color: Colors.transparent)).toList();
      case 1: return DSShadow.sm;
      case 2: return DSShadow.md;
      case 3: return DSShadow.lg;
      case 4: return DSShadow.glow;
      default: return DSShadow.md;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!visible) return const SizedBox.shrink();

    final cardBody = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: _surfaceColor(),
        borderRadius: BorderRadius.circular(DSRadius.md),
        border: accentColor != null 
            ? Border(left: BorderSide(color: accentColor!, width: 4))
            : Border.all(color: DSColors.borderSubtle, width: 1.5),
        boxShadow: _shadow(),
      ),
      child: child,
    );

    if (onTap != null) {
      return AnimatedPressable(
        onTap: onTap,
        child: cardBody,
      );
    }

    return cardBody;
  }
}
