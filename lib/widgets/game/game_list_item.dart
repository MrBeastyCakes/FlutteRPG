import 'package:flutter/material.dart';
import '../../theme/design_tokens.dart';
import '_animated_pressable.dart';

class GameListItem extends StatelessWidget {
  final Widget? leading;
  final Widget title;
  final Widget? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool selected;
  final bool disabled;
  final EdgeInsets padding;
  final Color? accentColor;

  const GameListItem({
    super.key,
    this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.selected = false,
    this.disabled = false,
    this.padding = const EdgeInsets.symmetric(horizontal: DSSpace.md, vertical: DSSpace.sm),
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    Widget itemContent = Opacity(
      opacity: disabled ? 0.4 : 1.0,
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          color: selected ? DSColors.surface3 : DSColors.surface2,
          borderRadius: BorderRadius.circular(DSRadius.md),
          border: Border.all(
            color: selected 
                ? DSColors.accent.withOpacity(0.5) 
                : (accentColor != null ? accentColor!.withOpacity(0.3) : DSColors.borderSubtle),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            if (leading != null) ...[
              leading!,
              const SizedBox(width: DSSpace.md),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  title,
                  if (subtitle != null) ...[
                    const SizedBox(width: DSSpace.xs),
                    subtitle!,
                  ],
                ],
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: DSSpace.md),
              trailing!,
            ],
          ],
        ),
      ),
    );

    if (onTap != null && !disabled) {
      return AnimatedPressable(
        onTap: onTap,
        child: itemContent,
      );
    }

    return itemContent;
  }
}
