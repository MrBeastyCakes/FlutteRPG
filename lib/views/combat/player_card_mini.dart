import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../engine/game_engine.dart';
import '../../theme/design_tokens.dart';
import '../../widgets/game/game_card.dart';
import '../../widgets/game/game_avatar.dart';
import '../../widgets/game/game_progress_bar.dart';

/// Player Card (mini) — condensed HP + energy mirror for the combat HUD.
class PlayerCardMini extends StatelessWidget {
  const PlayerCardMini({super.key});

  @override
  Widget build(BuildContext context) {
    final stats = context.watch<GameEngine>().playerStats;
    final hpRatio =
        stats.maxHealth > 0 ? stats.currentHealth / stats.maxHealth : 0.0;
    final enRatio =
        stats.maxEnergy > 0 ? stats.currentEnergy / stats.maxEnergy : 0.0;
    return GameCard(
      elevation: 1,
      padding: DSSpace.dense,
      child: Row(
        children: [
          const GameAvatar(emoji: '🧙', size: GameAvatarSize.sm),
          const SizedBox(width: DSSpace.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                GameProgressBar(
                  progress: hpRatio.clamp(0.0, 1.0),
                  color: DSColors.healthBar,
                  height: 6,
                  leadingLabel: '❤',
                  trailingLabel: '${stats.currentHealth}/${stats.maxHealth}',
                  animated: true,
                ),
                const SizedBox(height: DSSpace.xs),
                GameProgressBar(
                  progress: enRatio.clamp(0.0, 1.0),
                  color: DSColors.energyBar,
                  height: 6,
                  leadingLabel: '⚡',
                  trailingLabel: '${stats.currentEnergy}/${stats.maxEnergy}',
                  animated: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
