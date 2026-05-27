import 'package:flutter/material.dart';
import '../../theme/design_tokens.dart';

class GameProgressBar extends StatelessWidget {
  final double progress;
  final Color color;
  final Color? backgroundColor;
  final double height;
  final bool animated;
  final String? leadingLabel;
  final String? trailingLabel;

  const GameProgressBar({
    super.key,
    required this.progress,
    required this.color,
    this.backgroundColor,
    this.height = 6.0,
    this.animated = true,
    this.leadingLabel,
    this.trailingLabel,
  });

  @override
  Widget build(BuildContext context) {
    final double clampedValue = progress.clamp(0.0, 1.0);
    final Color barBg = backgroundColor ?? color.withOpacity(0.15);

    Widget progressIndicator;
    if (animated) {
      progressIndicator = TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: clampedValue),
        duration: DSMotion.standard,
        curve: DSMotion.easeOut,
        builder: (context, val, child) {
          return FractionalTranslation(
            translation: Offset(val - 1.0, 0.0),
            child: Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(DSRadius.pill),
              ),
            ),
          );
        },
      );
    } else {
      progressIndicator = FractionallySizedBox(
        widthFactor: clampedValue,
        alignment: Alignment.centerLeft,
        child: Container(
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(DSRadius.pill),
          ),
        ),
      );
    }

    final barWidget = Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: barBg,
        borderRadius: BorderRadius.circular(DSRadius.pill),
      ),
      clipBehavior: Clip.antiAlias,
      child: progressIndicator,
    );

    if (leadingLabel == null && trailingLabel == null) {
      return barWidget;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (leadingLabel != null)
              Text(
                leadingLabel!,
                style: DSText.label(context).copyWith(
                  fontSize: 10,
                  color: DSColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              )
            else
              const SizedBox.shrink(),
            if (trailingLabel != null)
              Text(
                trailingLabel!,
                style: DSText.numeric(context).copyWith(
                  fontSize: 10,
                  color: DSColors.textSecondary,
                ),
              )
            else
              const SizedBox.shrink(),
          ],
        ),
        const SizedBox(height: 4),
        barWidget,
      ],
    );
  }
}
