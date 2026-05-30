import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../engine/game_engine.dart';
import '../../theme/design_tokens.dart';

/// Round Timer arc — 56×56 circular countdown for the current combat round.
class RoundTimerArc extends StatelessWidget {
  const RoundTimerArc({super.key});

  @override
  Widget build(BuildContext context) {
    final combat = context.watch<GameEngine>().activeCombat;
    if (combat == null) return const SizedBox.shrink();
    final remaining =
        combat.roundDeadline?.difference(DateTime.now()) ?? Duration.zero;
    final ms = remaining.inMilliseconds.clamp(0, 2000);
    final pct = ms / 2000.0;
    final Color stroke = pct < 0.2
        ? DSColors.error
        : pct < 0.5
            ? DSColors.warning
            : DSColors.goldAccent;

    return SizedBox(
      width: 56,
      height: 56,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: pct,
            strokeWidth: 4,
            valueColor: AlwaysStoppedAnimation(stroke),
            backgroundColor: DSColors.borderSubtle,
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('${combat.currentRoundNumber}',
                  style: DSText.numeric(context)),
              Text(
                ms < 1000 ? '0.${ms ~/ 100}s' : '${(ms / 1000).floor()}s',
                style: DSText.label(context),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
