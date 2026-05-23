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

                const SizedBox(height: 12),
                const Divider(color: GameTheme.border, height: 1),
                const SizedBox(height: 8),

                // Active Skill Bonuses Panel
                const Text(
                  '⚡ ACTIVE BONUSES',
                  style: TextStyle(
                    color: GameTheme.accentGold,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 6),
                _buildActiveBonuses(engine, skill),
                const SizedBox(height: 12),
                
                // Masterwork Perks Panel
                const Text(
                  '🏆 MASTERWORK PERKS',
                  style: TextStyle(
                    color: GameTheme.accentGold,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 6),
                _buildPerkRow(skill, 10),
                const SizedBox(height: 6),
                _buildPerkRow(skill, 20),

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

  Widget _buildActiveBonuses(GameEngine engine, SkillState skill) {
    final speed = (engine.getSkillSpeedBonus(skill.type) * 100).toInt();
    final success = (engine.getSkillSuccessBonus(skill.type) * 100).toInt();
    final energySaving = (skill.level - 1); // 1% per level
    
    final bonusItems = <Widget>[];

    // Speed bonus is common to all
    bonusItems.add(_buildBonusChip('🏎️ Speed: +$speed%'));

    // Success chance for Woodcutting, Mining, Herbalism
    if (skill.type == SkillType.woodcutting ||
        skill.type == SkillType.mining ||
        skill.type == SkillType.herbalism) {
      bonusItems.add(_buildBonusChip('🎯 Success: +$success%'));
      
      // Double Yield Chance (Level 20 perk)
      if (skill.levelCap > 20) {
        bonusItems.add(_buildBonusChip('✨ Double Yield: 15%'));
      }
      
      // Bare-handed status
      if (skill.levelCap > 10) {
        bonusItems.add(_buildBonusChip('🧤 Bare-hand: Immune'));
      } else {
        bonusItems.add(_buildBonusChip('🧤 Bare-hand: Normal'));
      }
    }

    // Energy Saving
    if (skill.type != SkillType.lore) {
      // Add Tier 10 flat savings description if active
      String energyText = '⚡ Energy: -$energySaving%';
      if (skill.levelCap > 10) {
        int flat = 0;
        if (skill.type == SkillType.woodcutting) flat = 2;
        if (skill.type == SkillType.mining) flat = 3;
        if (skill.type == SkillType.herbalism) flat = 1;
        if (skill.type == SkillType.wayfinding) flat = 2;
        if (skill.type == SkillType.crafting || skill.type == SkillType.cooking) flat = 1;
        
        energyText += ' & -$flat flat';
      }
      bonusItems.add(_buildBonusChip(energyText));
    }

    // Lore XP boost
    if (skill.type == SkillType.lore) {
      double xpBonusPercent = ((engine.getXpMultiplier() - 1.0) * 100).roundToDouble();
      bonusItems.add(_buildBonusChip('📜 Global XP: +${xpBonusPercent.toInt()}%'));
    }

    // Cooking restoration boost & double output
    if (skill.type == SkillType.cooking) {
      double recoveryBonus = (skill.level - 1) * 1.5;
      if (skill.levelCap > 10) recoveryBonus += 15.0;
      if (skill.levelCap > 20) recoveryBonus += 30.0;
      bonusItems.add(_buildBonusChip('🍳 Food Boost: +${recoveryBonus.toInt()}%'));
      
      if (skill.levelCap > 20) {
        bonusItems.add(_buildBonusChip('🥞 Double Dish: 20%'));
      }
    }

    // Crafting save ingredients & double output
    if (skill.type == SkillType.crafting) {
      if (skill.levelCap > 20) {
        bonusItems.add(_buildBonusChip('♻️ Save Materials: 15%'));
      }
    }

    // Wayfinding double exploration chance
    if (skill.type == SkillType.wayfinding) {
      if (skill.levelCap > 20) {
        bonusItems.add(_buildBonusChip('🗺️ Void Wanderer: 15%'));
      }
    }

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: bonusItems,
    );
  }

  Widget _buildBonusChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2833),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: GameTheme.border.withOpacity(0.5)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildPerkRow(SkillState skill, int tier) {
    final isUnlocked = tier == 10 ? skill.isPerk10Unlocked : skill.isPerk20Unlocked;
    final perkName = tier == 10 ? skill.perk10Name : skill.perk20Name;
    final perkDesc = tier == 10 ? skill.perk10Desc : skill.perk20Desc;
    
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isUnlocked ? GameTheme.accentGold.withOpacity(0.04) : Colors.black.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isUnlocked ? GameTheme.accentGold.withOpacity(0.3) : GameTheme.border.withOpacity(0.3),
          width: isUnlocked ? 1.0 : 0.8,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isUnlocked ? Icons.verified : Icons.lock_outline,
            color: isUnlocked ? GameTheme.accentGold : GameTheme.textMuted,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Lvl $tier Perk: $perkName',
                      style: TextStyle(
                        color: isUnlocked ? Colors.white : GameTheme.textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      isUnlocked ? 'UNLOCKED' : 'LOCKED',
                      style: TextStyle(
                        color: isUnlocked ? GameTheme.accentGold : GameTheme.healthRed,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  perkDesc,
                  style: TextStyle(
                    color: isUnlocked ? Colors.white.withOpacity(0.7) : GameTheme.textMuted.withOpacity(0.7),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
