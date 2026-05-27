import 'package:flutter/material.dart';
import '../../theme/design_tokens.dart';

class GameTooltip extends StatelessWidget {
  final String message;
  final Widget child;
  final bool preferBelow;

  const GameTooltip({
    super.key,
    required this.message,
    required this.child,
    this.preferBelow = false,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: message,
      preferBelow: preferBelow,
      decoration: BoxDecoration(
        color: DSColors.surface4,
        borderRadius: BorderRadius.circular(DSRadius.sm),
        border: Border.all(color: DSColors.borderEmphasis, width: 1),
        boxShadow: DSShadow.md,
      ),
      padding: const EdgeInsets.symmetric(horizontal: DSSpace.sm, vertical: DSSpace.xs),
      textStyle: DSText.bodySmall(context).copyWith(color: DSColors.textPrimary),
      waitDuration: const Duration(milliseconds: 400),
      triggerMode: TooltipTriggerMode.longPress,
      child: child,
    );
  }
}
