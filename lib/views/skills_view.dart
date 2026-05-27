import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../engine/game_engine.dart';
import '../models/skill.dart';
import '../models/masterwork.dart';
import '../theme/design_tokens.dart';

import '../widgets/game/game_card.dart';
import '../widgets/game/game_progress_bar.dart';
import '../widgets/game/game_chip.dart';
import '../widgets/game/game_avatar.dart';
import '../widgets/game/game_sheet.dart';
import '../widgets/game/game_button.dart';
import '../widgets/game/game_toast.dart';

class SkillsView extends StatefulWidget {
  const SkillsView({Key? key}) : super(key: key);

  @override
  State<SkillsView> createState() => _SkillsViewState();
}

class _SkillsViewState extends State<SkillsView> {
  @override
  Widget build(BuildContext context) {
    final engine = Provider.of<GameEngine>(context);
    final skills = engine.skills.values.toList();

    return GridView.builder(
      padding: const EdgeInsets.all(DSSpace.md),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.15,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: skills.length,
      itemBuilder: (context, index) {
        final skill = skills[index];
        final skillColor = DSColors.skill(skill.type);
        final isGated = skill.isGated;

        return GameCard(
          elevation: 1,
          accentColor: isGated ? DSColors.error : skillColor,
          onTap: () => _showSkillDetails(context, engine, skill),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  GameAvatar(
                    emoji: skill.type.icon,
                    size: GameAvatarSize.sm,
                    backgroundColor: DSColors.surface3,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          skill.type.name,
                          style: DSText.headingSmall(context).copyWith(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (isGated)
                          Text(
                            'GATED',
                            style: DSText.label(context).copyWith(
                              color: DSColors.error,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Lvl ${skill.level}',
                    style: DSText.numeric(context).copyWith(
                      color: isGated ? DSColors.error : DSColors.accent,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (skill.levelCap >= 30)
                    const Text('👑', style: TextStyle(fontSize: 12))
                  else if (isGated)
                    const Icon(Icons.lock, color: DSColors.error, size: 12),
                ],
              ),
              GameProgressBar(
                progress: skill.progress,
                color: isGated ? DSColors.error : skillColor,
                height: 6,
              ),
            ],
          ),
        );
      },
    );
  }

  void _showSkillDetails(BuildContext context, GameEngine engine, SkillState skill) {
    final skillColor = DSColors.skill(skill.type);
    final nextLevelXpStart = SkillState.totalXpForLevel(skill.level + 1);
    final xpRemaining = nextLevelXpStart - skill.xp;
    
    // Find if there's an available Masterwork task for this gated skill
    final masterworkTask = skill.isGated 
        ? MasterworkTasks.findForSkill(skill.type, skill.levelCap, engine.specForSkill(skill.type))
        : null;

    final spec = engine.specForSkill(skill.type);
    final subSpec = engine.subSpecForSkill(skill.type);

    GameSheet.show(
      context: context,
      title: '${skill.type.icon} ${skill.type.name}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Basic Info Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: skill.isGated ? DSColors.errorSoft : DSColors.surface3,
                  borderRadius: BorderRadius.circular(DSRadius.pill),
                  border: Border.all(
                    color: skill.isGated ? DSColors.error : DSColors.borderDefault,
                  ),
                ),
                child: Text(
                  'LEVEL ${skill.level}',
                  style: DSText.label(context).copyWith(
                    color: skill.isGated ? DSColors.error : DSColors.accent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (spec != null || subSpec != null)
                Wrap(
                  spacing: 6,
                  children: [
                    if (spec != null)
                      GameChip(
                        label: engine.specDisplayName(spec).toUpperCase(),
                        color: DSColors.info,
                        size: GameChipSize.sm,
                      ),
                    if (subSpec != null)
                      GameChip(
                        label: engine.subSpecDisplayName(subSpec).toUpperCase(),
                        color: DSColors.accent,
                        size: GameChipSize.sm,
                      ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Progress
          GameProgressBar(
            progress: skill.progress,
            color: skill.isGated ? DSColors.error : skillColor,
            height: 12,
          ),
          const SizedBox(height: 8),

          // XP Stats
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total XP: ${skill.xp.toInt()}',
                style: DSText.bodySmall(context),
              ),
              Text(
                skill.isGated
                    ? '🔒 Cap: Lvl ${skill.levelCap} reached'
                    : 'Next Level: ${xpRemaining.toInt()} XP needed',
                style: DSText.bodySmall(context).copyWith(
                  color: skill.isGated ? DSColors.error : DSColors.textMuted,
                  fontWeight: skill.isGated ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: DSColors.borderSubtle),
          const SizedBox(height: 12),

          // Active Bonuses Section
          Text(
            '⚡ ACTIVE BONUSES',
            style: DSText.label(context).copyWith(color: DSColors.accent),
          ),
          const SizedBox(height: 8),
          _buildActiveBonuses(engine, skill),
          const SizedBox(height: 16),

          // Masterwork Perks Section
          Text(
            '🏆 MASTERWORK PERKS',
            style: DSText.label(context).copyWith(color: DSColors.accent),
          ),
          const SizedBox(height: 8),
          _buildPerkRow(context, skill, 10),
          const SizedBox(height: 6),
          _buildPerkRow(context, skill, 20),

          // Gated Challenge Section
          if (skill.isGated) ...[
            const SizedBox(height: 16),
            const Divider(color: DSColors.borderSubtle),
            const SizedBox(height: 12),
            GameCard(
              elevation: 0,
              accentColor: DSColors.error,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: DSColors.error, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'LEVEL LIMIT GATED',
                        style: DSText.label(context).copyWith(
                          color: DSColors.error,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    masterworkTask != null
                        ? 'You must complete the trial "${masterworkTask.title}" to continue progressing to level ${skill.levelCap + 10}.'
                        : 'Complete the Masterwork Challenge for this skill to unlock further progression.',
                    style: DSText.bodyMedium(context),
                  ),
                  const SizedBox(height: 12),
                  GameButton(
                    variant: GameButtonVariant.danger,
                    label: masterworkTask != null ? 'Start: ${masterworkTask.title}' : 'Trial Details Locked',
                    onPressed: masterworkTask != null
                        ? () {
                            engine.startMasterworkChallenge(masterworkTask);
                            Navigator.pop(context);
                            GameToast.show(
                              context,
                              'Trial "${masterworkTask.title}" started! Go to the Dashboard to begin.',
                            );
                          }
                        : null,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
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
        color: DSColors.surface2,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: DSColors.borderSubtle),
      ),
      child: Text(
        text,
        style: DSText.bodySmall(context).copyWith(
          color: DSColors.textPrimary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildPerkRow(BuildContext context, SkillState skill, int tier) {
    final isUnlocked = tier == 10 ? skill.isPerk10Unlocked : skill.isPerk20Unlocked;
    final perkName = tier == 10 ? skill.perk10Name : skill.perk20Name;
    final perkDesc = tier == 10 ? skill.perk10Desc : skill.perk20Desc;
    
    return Container(
      padding: const EdgeInsets.all(8),
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: isUnlocked ? DSColors.accent.withOpacity(0.04) : Colors.black.withOpacity(0.15),
        borderRadius: BorderRadius.circular(DSRadius.md),
        border: Border.all(
          color: isUnlocked ? DSColors.accent.withOpacity(0.3) : DSColors.borderSubtle,
          width: isUnlocked ? 1.0 : 0.8,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isUnlocked ? Icons.verified : Icons.lock_outline,
            color: isUnlocked ? DSColors.accent : DSColors.textDisabled,
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
                      style: DSText.bodyMedium(context).copyWith(
                        color: isUnlocked ? DSColors.textPrimary : DSColors.textDisabled,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                    Text(
                      isUnlocked ? 'UNLOCKED' : 'LOCKED',
                      style: DSText.label(context).copyWith(
                        color: isUnlocked ? DSColors.accent : DSColors.error,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  perkDesc,
                  style: DSText.bodySmall(context).copyWith(
                    color: isUnlocked ? DSColors.textSecondary : DSColors.textDisabled,
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
