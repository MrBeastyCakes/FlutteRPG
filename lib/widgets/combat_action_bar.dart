import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../engine/game_engine.dart';
import '../models/combat.dart';
import '../theme/design_tokens.dart';
import '../models/item.dart';
import 'game/_animated_pressable.dart';
import 'game/game_progress_bar.dart';
import 'game/game_sheet.dart';
import 'game/game_avatar.dart';
import 'game/game_card.dart';
import 'game/game_list_item.dart';

@Deprecated(
    'Use CombatHud and its sub-widgets (Spec 7b-1). Delete once no references remain.')
class CombatActionBar extends StatelessWidget {
  const CombatActionBar({super.key});

  @override
  Widget build(BuildContext context) {
    final engine = Provider.of<GameEngine>(context);
    final combat = engine.activeCombat;
    if (combat == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (combat.activeTelegraph != null) _buildTelegraphBanner(context, combat.activeTelegraph!),
        const SizedBox(height: 8),
        _buildRoundTimer(context, combat),
        const SizedBox(height: 8),
        Row(
          children: [
            _buildStanceButton(context, engine, PlayerStance.strike, '⚔️', 'Strike'),
            _buildStanceButton(context, engine, PlayerStance.heavyStrike, '💪', 'Heavy'),
            _buildStanceButton(context, engine, PlayerStance.defend, '🛡️', 'Defend'),
            _buildStanceButton(context, engine, PlayerStance.readTells, '👁️', 'Read'),
            _buildStanceButton(context, engine, PlayerStance.item, '🎒', 'Item'),
          ],
        ),
      ],
    );
  }

  Widget _buildTelegraphBanner(BuildContext context, BeastTelegraph tg) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: DSColors.errorSoft,
        borderRadius: BorderRadius.circular(DSRadius.md),
        border: Border.all(color: DSColors.error.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          const Text('⚠️', style: TextStyle(fontSize: 14)),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              tg.text + (tg.reveal ? ' [${tg.abilityId.toUpperCase()}]' : ''),
              style: DSText.bodyMedium(context).copyWith(color: DSColors.error, fontStyle: FontStyle.italic),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoundTimer(BuildContext context, CombatState combat) {
    final remaining = combat.roundDeadline?.difference(DateTime.now()) ?? Duration.zero;
    final pct = remaining.inMilliseconds.clamp(0, 2000) / 2000.0;
    return Row(
      children: [
        Text(
          'Round ${combat.currentRoundNumber}',
          style: DSText.label(context),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: GameProgressBar(
            progress: pct,
            color: DSColors.accent,
            height: 6,
          ),
        ),
      ],
    );
  }

  Widget _buildStanceButton(BuildContext context, GameEngine engine, PlayerStance stance, String emoji, String label) {
    final cost = engine.getStanceCost(stance);
    final canAfford = engine.playerStats.currentEnergy >= cost;
    final isItem = stance == PlayerStance.item;
    
    // Check if item stance is available (must have at least one consumable in quickslots)
    bool hasQuickslotItems = false;
    if (isItem) {
      hasQuickslotItems = engine.quickslots.any((id) => id != null);
    }

    final buttonEnabled = canAfford && (!isItem || hasQuickslotItems);

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: AnimatedPressable(
          onTap: !buttonEnabled ? null : () {
            if (isItem) {
              _showItemPopover(context, engine);
            } else {
              engine.setCombatStance(stance);
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: buttonEnabled ? DSColors.surface3 : DSColors.surface2.withOpacity(0.3),
              borderRadius: BorderRadius.circular(DSRadius.md),
              border: Border.all(
                color: buttonEnabled ? DSColors.borderEmphasis : Colors.transparent,
                width: 1.5,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(emoji, style: const TextStyle(fontSize: 18)),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: DSText.label(context).copyWith(
                    color: buttonEnabled ? DSColors.textPrimary : DSColors.textDisabled,
                    fontSize: 10,
                  ),
                ),
                if (cost > 0) ...[
                  const SizedBox(height: 2),
                  Text(
                    '-$cost E',
                    style: DSText.numeric(context).copyWith(
                      fontSize: 9,
                      color: canAfford ? DSColors.warning : DSColors.error,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ] else if (isItem) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Use',
                    style: DSText.label(context).copyWith(
                      fontSize: 9,
                      color: hasQuickslotItems ? DSColors.textMuted : DSColors.error,
                    ),
                  ),
                ] else ...[
                  const SizedBox(height: 2),
                  Text(
                    '0 E',
                    style: DSText.label(context).copyWith(
                      fontSize: 9,
                      color: DSColors.textDisabled,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showItemPopover(BuildContext context, GameEngine engine) {
    GameSheet.show(
      context: context,
      title: 'Select Quick-Slot Item to Use',
      child: Column(
        children: [
          for (int i = 0; i < 3; i++) _buildItemOption(context, engine, i),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildItemOption(BuildContext context, GameEngine engine, int index) {
    final itemId = engine.quickslots[index];
    final item = itemId != null ? Items.findById(itemId) : null;

    return GameCard(
      elevation: item != null ? 1 : 0,
      child: GameListItem(
        padding: EdgeInsets.zero,
        leading: GameAvatar(
          emoji: item != null ? item.icon : '${index + 1}',
          size: GameAvatarSize.sm,
          backgroundColor: DSColors.surface3,
        ),
        title: Text(
          item != null ? item.name : 'Slot ${index + 1} (Empty)',
          style: DSText.bodyMedium(context).copyWith(
            color: item != null ? DSColors.textPrimary : DSColors.textDisabled,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          item != null 
              ? '+${item.healAmount} HP, +${item.energyAmount} energy'
              : 'Assign food on Dashboard',
          style: DSText.bodySmall(context),
        ),
        onTap: item != null ? () {
          Navigator.pop(context); // Close sheet
          engine.setCombatStance(PlayerStance.item, quickslotIndex: index);
        } : null,
      ),
    );
  }
}
