import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../engine/game_engine.dart';
import '../models/skill.dart';
import '../models/masterwork.dart';
import '../theme/game_theme.dart';
import '../widgets/custom_progress_bar.dart';

class SkillsView extends StatelessWidget {
  const SkillsView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final engine = Provider.of<GameEngine>(context);
    final skills = engine.skills.values.toList();

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: skills.length,
      itemBuilder: (context, index) {
        final skill = skills[index];
        final skillColor = GameTheme.getSkillColor(skill.type);
        final nextLevelXpStart = SkillState.totalXpForLevel(skill.level + 1);
        final xpRemaining = nextLevelXpStart - skill.xp;
        
        // Find if there's an available Masterwork task for this gated skill
        final masterworkTask = skill.isGated 
            ? MasterworkTasks.findForSkill(skill.type, skill.levelCap)
            : null;

        return Card(
          color: GameTheme.cardBg,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: skill.isGated ? GameTheme.healthRed.withOpacity(0.5) : GameTheme.border.withOpacity(0.5),
              width: skill.isGated ? 1.5 : 1,
            ),
          ),
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Skill Title Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text(
                          skill.type.icon,
                          style: const TextStyle(fontSize: 22),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          skill.type.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: skill.isGated ? GameTheme.healthRed.withOpacity(0.15) : const Color(0xFF222C37),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: skill.isGated ? GameTheme.healthRed : GameTheme.border,
                          width: 1,
                        ),
                      ),
                      child: Text(
                        'Lvl ${skill.level}',
                        style: TextStyle(
                          color: skill.isGated ? GameTheme.healthRed : GameTheme.accentGold,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Progress Bar
                CustomProgressBar(
                  progress: skill.progress,
                  color: skill.isGated ? GameTheme.healthRed : skillColor,
                  height: 12,
                ),
                const SizedBox(height: 6),

                // XP stats
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total XP: ${skill.xp.toInt()}',
                      style: const TextStyle(color: GameTheme.textMuted, fontSize: 12),
                    ),
                    Text(
                      skill.isGated
                          ? '🔒 Cap: Lvl ${skill.levelCap} reached'
                          : 'Next Level: ${xpRemaining.toInt()} XP needed',
                      style: TextStyle(
                        color: skill.isGated ? GameTheme.healthRed : GameTheme.textMuted,
                        fontSize: 12,
                        fontWeight: skill.isGated ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                ),

                // Masterwork challenge trigger section
                if (skill.isGated) ...[
                  const SizedBox(height: 12),
                  const Divider(color: GameTheme.border, height: 1),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: GameTheme.healthRed.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: GameTheme.healthRed.withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.warning_amber_rounded, color: GameTheme.healthRed, size: 16),
                            SizedBox(width: 6),
                            Text(
                              'LEVEL LIMIT GATED',
                              style: TextStyle(
                                color: GameTheme.healthRed,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          masterworkTask != null
                              ? 'You must complete the trial "${masterworkTask.title}" to continue progressing to level ${skill.levelCap + 10}.'
                              : 'Complete the Masterwork Challenge for this skill to unlock further progression.',
                          style: const TextStyle(color: GameTheme.textLight, fontSize: 12),
                        ),
                        const SizedBox(height: 10),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: GameTheme.healthRed,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                          onPressed: masterworkTask != null
                              ? () {
                                  engine.startMasterworkChallenge(masterworkTask);
                                  // Auto navigate or show visual feedback
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      backgroundColor: GameTheme.cardBg,
                                      content: Text(
                                        'Trial "${masterworkTask.title}" started! Go to the Dashboard to begin.',
                                        style: const TextStyle(color: Colors.white),
                                      ),
                                      duration: const Duration(seconds: 3),
                                    ),
                                  );
                                }
                              : null,
                          icon: const Icon(Icons.psychology, size: 16),
                          label: Text(
                            masterworkTask != null 
                                ? 'Start: ${masterworkTask.title}'
                                : 'Trial Details Locked',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
