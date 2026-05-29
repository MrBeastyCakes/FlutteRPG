import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../engine/game_engine.dart';
import '../../theme/design_tokens.dart';

/// Telegraph Strip — full-width danger banner that briefly shakes on a new
/// telegraph. Hidden when no telegraph is active.
class TelegraphStrip extends StatelessWidget {
  const TelegraphStrip({super.key});

  @override
  Widget build(BuildContext context) {
    final tg = context.watch<GameEngine>().activeCombat?.activeTelegraph;
    if (tg == null) return const SizedBox.shrink();

    return TweenAnimationBuilder<double>(
      key: ValueKey(tg.text),
      tween: Tween<double>(begin: -8, end: 0),
      duration: DSMotion.fast,
      curve: DSMotion.spring,
      builder: (_, shake, child) =>
          Transform.translate(offset: Offset(shake, 0), child: child),
      child: Container(
        padding: DSSpace.dense,
        decoration: BoxDecoration(
          color: DSColors.error.withValues(alpha: 0.25),
          border: Border.all(color: DSColors.error),
          borderRadius: BorderRadius.circular(DSRadius.sm),
        ),
        child: Row(
          children: [
            const Text('⚠', style: TextStyle(fontSize: 18)),
            const SizedBox(width: DSSpace.sm),
            Expanded(
              child: Text(
                tg.reveal
                    ? '${tg.text}  [${tg.abilityId.toUpperCase()}]'
                    : tg.text,
                style: DSText.bodyMedium(context).copyWith(
                  color: DSColors.error,
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
