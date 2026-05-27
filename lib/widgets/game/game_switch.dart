import 'package:flutter/material.dart';
import '../../theme/design_tokens.dart';

class GameSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const GameSwitch({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: DSMotion.fast,
        width: 44,
        height: 24,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(DSRadius.pill),
          color: value ? DSColors.accent.withOpacity(0.2) : DSColors.surface3,
          border: Border.all(
            color: value ? DSColors.accent : DSColors.borderDefault,
            width: 1.5,
          ),
        ),
        padding: const EdgeInsets.all(2),
        alignment: value ? Alignment.centerRight : Alignment.centerLeft,
        child: AnimatedContainer(
          duration: DSMotion.fast,
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: value ? DSColors.accent : DSColors.textSecondary,
            boxShadow: value ? DSShadow.sm : null,
          ),
        ),
      ),
    );
  }
}
