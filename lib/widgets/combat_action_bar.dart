import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../engine/game_engine.dart';
import '../models/combat.dart';
import '../theme/game_theme.dart';
import '../models/item.dart';

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
        if (combat.activeTelegraph != null) _buildTelegraphBanner(combat.activeTelegraph!),
        const SizedBox(height: 8),
        _buildRoundTimer(combat),
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

  Widget _buildTelegraphBanner(BeastTelegraph tg) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          const Text('⚠️', style: TextStyle(fontSize: 14)),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              tg.text + (tg.reveal ? ' [${tg.abilityId.toUpperCase()}]' : ''),
              style: const TextStyle(color: Colors.red, fontSize: 12, fontStyle: FontStyle.italic),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoundTimer(CombatState combat) {
    final remaining = combat.roundDeadline?.difference(DateTime.now()) ?? Duration.zero;
    final pct = remaining.inMilliseconds.clamp(0, 2000) / 2000.0;
    return Row(
      children: [
        Text('Round ${combat.currentRoundNumber}', style: const TextStyle(color: GameTheme.textMuted, fontSize: 11)),
        const SizedBox(width: 8),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              backgroundColor: GameTheme.border,
              valueColor: const AlwaysStoppedAnimation<Color>(GameTheme.accentGold),
              minHeight: 6,
            ),
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
        child: ElevatedButton(
          onPressed: !buttonEnabled ? null : () {
            if (isItem) {
              _showItemPopover(context, engine);
            } else {
              engine.setCombatStance(stance);
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: buttonEnabled ? GameTheme.cardBg : GameTheme.border.withOpacity(0.3),
            padding: const EdgeInsets.symmetric(vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
              side: BorderSide(
                color: buttonEnabled ? GameTheme.border : Colors.transparent,
                width: 1,
              ),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 18)),
              const SizedBox(height: 2),
              Text(label, style: const TextStyle(fontSize: 10, color: Colors.white)),
              if (cost > 0) ...[
                const SizedBox(height: 2),
                Text('-$cost E', style: TextStyle(fontSize: 9, color: canAfford ? GameTheme.energyYellow : GameTheme.healthRed, fontWeight: FontWeight.bold)),
              ] else if (isItem) ...[
                const SizedBox(height: 2),
                Text('Use', style: TextStyle(fontSize: 9, color: hasQuickslotItems ? GameTheme.textMuted : GameTheme.healthRed)),
              ] else ...[
                const SizedBox(height: 2),
                const Text('0 E', style: TextStyle(fontSize: 9, color: GameTheme.textMuted)),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showItemPopover(BuildContext context, GameEngine engine) {
    showModalBottomSheet(
      context: context,
      backgroundColor: GameTheme.cardBg,
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const ListTile(
            title: Text('Select Quick-Slot Item to Use', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
          const Divider(color: GameTheme.border),
          for (int i = 0; i < 3; i++) _buildItemOption(context, engine, i),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildItemOption(BuildContext context, GameEngine engine, int index) {
    final itemId = engine.quickslots[index];
    final item = itemId != null ? Items.findById(itemId) : null;
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Colors.black.withOpacity(0.3),
        child: Text(item != null ? item.icon : '${index + 1}', style: const TextStyle(fontSize: 18)),
      ),
      title: Text(
        item != null ? item.name : 'Slot ${index + 1} (Empty)',
        style: TextStyle(color: item != null ? Colors.white : GameTheme.textMuted),
      ),
      subtitle: item != null 
          ? Text('+${item.healAmount} HP, +${item.energyAmount} energy', style: const TextStyle(color: GameTheme.textMuted, fontSize: 11))
          : const Text('Assign food on Dashboard', style: TextStyle(color: GameTheme.textMuted, fontSize: 11)),
      onTap: item != null ? () {
        Navigator.pop(context);
        engine.setCombatStance(PlayerStance.item, quickslotIndex: index);
      } : null,
    );
  }
}
