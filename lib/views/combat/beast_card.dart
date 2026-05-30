import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../engine/game_engine.dart';
import '../../models/beast.dart';
import '../../theme/design_tokens.dart';
import '../../widgets/game/game_card.dart';
import '../../widgets/game/game_avatar.dart';
import '../../widgets/game/game_chip.dart';
import '../../widgets/game/game_progress_bar.dart';

/// Beast Card — combat target: icon, name, HP bar, phase indicator,
/// and (during Source phases) a Sediment Stacks row.
class BeastCard extends StatelessWidget {
  const BeastCard({super.key});

  @override
  Widget build(BuildContext context) {
    final combat = context.watch<GameEngine>().activeCombat;
    if (combat == null) return const SizedBox.shrink();
    final beast = combat.beast;
    final hpRatio =
        beast.maxHealth > 0 ? combat.beastCurrentHealth / beast.maxHealth : 0.0;
    final phase = combat.activePhaseIndex;
    final totalPhases = beast.phases?.length ?? 1;
    const accent = DSColors.error; // Beast has no themed color field

    return GameCard(
      elevation: 2,
      accentColor: accent,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GameAvatar(
              emoji: beast.icon, size: GameAvatarSize.lg, ringColor: accent),
          const SizedBox(width: DSSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                        child: Text(beast.name,
                            style: DSText.headingSmall(context))),
                    if (totalPhases > 1 && phase >= 0)
                      GameChip(
                          label: 'Phase ${phase + 1}/$totalPhases',
                          size: GameChipSize.sm,
                          color: accent),
                  ],
                ),
                if (beast.phases != null &&
                    phase >= 0 &&
                    phase < beast.phases!.length)
                  Text(beast.phases![phase].ability.name,
                      style: DSText.label(context)),
                const SizedBox(height: DSSpace.sm),
                GameProgressBar(
                  progress: hpRatio.clamp(0.0, 1.0),
                  color: DSColors.healthBar,
                  height: 10,
                  leadingLabel: '❤',
                  trailingLabel:
                      '${combat.beastCurrentHealth}/${beast.maxHealth}',
                  animated: true,
                ),
                if (combat.activePhasePassive ==
                        BeastPassive.sourceSedimentStack &&
                    combat.sourceSedimentStacks > 0)
                  _sedimentRow(context, combat.sourceSedimentStacks),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sedimentRow(BuildContext context, int stacks) {
    return Padding(
      padding: const EdgeInsets.only(top: DSSpace.xs),
      child: Row(
        children: [
          Text('⚠ Sediment: ',
              style: DSText.label(context).copyWith(color: DSColors.warning)),
          for (int i = 0; i < 3; i++)
            Icon(i < stacks ? Icons.circle : Icons.circle_outlined,
                size: 12, color: DSColors.warning),
        ],
      ),
    );
  }
}
