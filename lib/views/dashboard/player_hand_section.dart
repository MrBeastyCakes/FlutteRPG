import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../engine/game_engine.dart';
import '../../models/player_progression.dart';
import '../../models/skill.dart';
import '../../theme/design_tokens.dart';
import '../../widgets/game/game_card.dart';
import '../../widgets/game/game_avatar.dart';
import '../../widgets/game/game_progress_bar.dart';

/// Player Hand section — HP, energy, player XP, name, title, level.
/// Shown at the top of the dashboard (non-combat).
class PlayerHandSection extends StatelessWidget {
  const PlayerHandSection({super.key});

  SkillType _highestSkill(GameEngine engine) {
    SkillType best = SkillType.values.first;
    int bestLevel = -1;
    engine.skills.forEach((type, state) {
      if (state.level > bestLevel) {
        bestLevel = state.level;
        best = type;
      }
    });
    return best;
  }

  @override
  Widget build(BuildContext context) {
    final engine = context.watch<GameEngine>();
    final stats = engine.playerStats;
    final xpToNext = PlayerProgression.xpToNextLevel(stats.playerLevel);
    final xpRatio = xpToNext > 0 ? (stats.playerXp / xpToNext).clamp(0.0, 1.0) : 0.0;
    final hpRatio = stats.maxHealth > 0 ? stats.currentHealth / stats.maxHealth : 0.0;
    final enRatio = stats.maxEnergy > 0 ? stats.currentEnergy / stats.maxEnergy : 0.0;
    final ringColor = DSColors.skill(_highestSkill(engine));

    return GameCard(
      elevation: 1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              GameAvatar(emoji: '🧙', size: GameAvatarSize.md, ringColor: ringColor),
              const SizedBox(width: DSSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(stats.name, style: DSText.headingSmall(context)),
                    Text(
                      stats.title,
                      style: DSText.label(context).copyWith(color: DSColors.goldAccent),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Lvl ${stats.playerLevel}',
                      style: DSText.numeric(context).copyWith(color: DSColors.goldAccent)),
                  const SizedBox(height: DSSpace.xs),
                  SizedBox(
                    width: 120,
                    child: GameProgressBar(
                      progress: xpRatio,
                      color: DSColors.xpBar,
                      height: 4,
                      trailingLabel: '${stats.playerXp}/$xpToNext XP',
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: DSSpace.md),
          GameProgressBar(
            progress: hpRatio,
            color: DSColors.healthBar,
            height: 10,
            leadingLabel: '❤',
            trailingLabel: '${stats.currentHealth}/${stats.maxHealth}',
            animated: true,
          ),
          const SizedBox(height: DSSpace.sm),
          GameProgressBar(
            progress: enRatio,
            color: DSColors.energyBar,
            height: 10,
            leadingLabel: '⚡',
            trailingLabel: '${stats.currentEnergy}/${stats.maxEnergy}',
            animated: true,
          ),
        ],
      ),
    );
  }
}
