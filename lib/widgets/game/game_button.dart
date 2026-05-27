import 'package:flutter/material.dart';
import '../../theme/design_tokens.dart';
import '_animated_pressable.dart';

enum GameButtonVariant { primary, secondary, ghost, danger }
enum GameButtonSize { sm, md, lg }

class GameButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final GameButtonVariant variant;
  final GameButtonSize size;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool fullWidth;

  const GameButton({
    super.key,
    required this.label,
    this.icon,
    this.variant = GameButtonVariant.primary,
    this.size = GameButtonSize.md,
    this.onPressed,
    this.isLoading = false,
    this.fullWidth = false,
  });

  Color _backgroundColor() {
    if (onPressed == null) return DSColors.surface2;
    switch (variant) {
      case GameButtonVariant.primary: return DSColors.accent;
      case GameButtonVariant.secondary: return DSColors.surface4;
      case GameButtonVariant.ghost: return Colors.transparent;
      case GameButtonVariant.danger: return DSColors.error;
    }
  }

  Color _textColor() {
    if (onPressed == null) return DSColors.textDisabled;
    switch (variant) {
      case GameButtonVariant.primary: return DSColors.textOnAccent;
      case GameButtonVariant.secondary: return DSColors.textPrimary;
      case GameButtonVariant.ghost: return DSColors.textPrimary;
      case GameButtonVariant.danger: return Colors.white;
    }
  }

  Color? _borderColor() {
    if (onPressed == null) return null;
    if (variant == GameButtonVariant.secondary) return DSColors.borderDefault;
    return null;
  }

  double _height() {
    switch (size) {
      case GameButtonSize.sm: return 28;
      case GameButtonSize.md: return 36;
      case GameButtonSize.lg: return 44;
    }
  }

  double _fontSize() {
    switch (size) {
      case GameButtonSize.sm: return 11;
      case GameButtonSize.md: return 13;
      case GameButtonSize.lg: return 14;
    }
  }

  EdgeInsets _padding() {
    switch (size) {
      case GameButtonSize.sm: return const EdgeInsets.symmetric(horizontal: 12, vertical: 6);
      case GameButtonSize.md: return const EdgeInsets.symmetric(horizontal: 16, vertical: 8);
      case GameButtonSize.lg: return const EdgeInsets.symmetric(horizontal: 20, vertical: 12);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textStyle = DSText.button(context).copyWith(
      color: _textColor(),
      fontSize: _fontSize(),
    );

    final innerContent = isLoading
        ? SizedBox(
            width: _height() * 0.4,
            height: _height() * 0.4,
            child: CircularProgressIndicator(strokeWidth: 2, color: _textColor()),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, color: _textColor(), size: _fontSize() + 2),
                const SizedBox(width: 6),
              ],
              Text(label, style: textStyle),
            ],
          );

    final buttonDecorated = Container(
      height: _height(),
      padding: _padding(),
      decoration: BoxDecoration(
        color: _backgroundColor(),
        borderRadius: BorderRadius.circular(DSRadius.sm),
        border: _borderColor() != null ? Border.all(color: _borderColor()!, width: 1.5) : null,
        boxShadow: onPressed == null ? null : DSShadow.sm,
      ),
      child: Center(
        child: innerContent,
      ),
    );

    final childWidget = fullWidth
        ? SizedBox(width: double.infinity, child: buttonDecorated)
        : buttonDecorated;

    return AnimatedPressable(
      onTap: isLoading ? null : onPressed,
      child: childWidget,
    );
  }
}
