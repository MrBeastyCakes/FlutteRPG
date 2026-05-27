import 'package:flutter/material.dart';
import '../../theme/design_tokens.dart';

class GameSlider extends StatelessWidget {
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;
  final int? divisions;
  final String? label;

  const GameSlider({
    super.key,
    required this.value,
    this.min = 0.0,
    this.max = 1.0,
    required this.onChanged,
    this.divisions,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    return SliderTheme(
      data: SliderThemeData(
        activeTrackColor: DSColors.accent,
        inactiveTrackColor: DSColors.surface3,
        trackHeight: 4.0,
        thumbColor: DSColors.accent,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8.0),
        overlayColor: DSColors.accent.withOpacity(0.2),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 16.0),
        tickMarkShape: const RoundSliderTickMarkShape(),
        activeTickMarkColor: DSColors.accent,
        inactiveTickMarkColor: DSColors.borderDefault,
        valueIndicatorShape: const PaddleSliderValueIndicatorShape(),
        valueIndicatorColor: DSColors.surface4,
        valueIndicatorTextStyle: DSText.numeric(context).copyWith(color: DSColors.textPrimary),
      ),
      child: Slider(
        value: value,
        min: min,
        max: max,
        divisions: divisions,
        label: label,
        onChanged: onChanged,
      ),
    );
  }
}
