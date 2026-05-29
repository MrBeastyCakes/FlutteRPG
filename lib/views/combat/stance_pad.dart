import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../engine/game_engine.dart';
import '../../models/combat.dart';
import '../../theme/design_tokens.dart';
import '../../widgets/game/game_button.dart';

/// Stance Pad — 5 combat stances in a 3+2 grid (thumb-zone friendly).
class StancePad extends StatelessWidget {
  const StancePad({super.key});

  @override
  Widget build(BuildContext context) {
    final engine = context.watch<GameEngine>();
    final selected = engine.activeCombat?.pendingStance;

    Widget btn(PlayerStance stance, String emoji, String label) =>
        _StanceButton(
          stance: stance,
          emoji: emoji,
          label: label,
          selected: selected == stance,
          onTap: () => engine.setCombatStance(stance),
        );

    return Column(
      children: [
        Row(
          children: [
            Expanded(child: btn(PlayerStance.strike, '⚔️', 'Strike')),
            const SizedBox(width: DSSpace.sm),
            Expanded(child: btn(PlayerStance.heavyStrike, '💪', 'Heavy')),
            const SizedBox(width: DSSpace.sm),
            Expanded(child: btn(PlayerStance.defend, '🛡️', 'Defend')),
          ],
        ),
        const SizedBox(height: DSSpace.sm),
        Row(
          children: [
            const Spacer(),
            Expanded(
                flex: 2, child: btn(PlayerStance.readTells, '👁️', 'Read')),
            const SizedBox(width: DSSpace.sm),
            Expanded(flex: 2, child: btn(PlayerStance.item, '🎒', 'Item')),
            const Spacer(),
          ],
        ),
      ],
    );
  }
}

class _StanceButton extends StatelessWidget {
  final PlayerStance stance;
  final String emoji;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _StanceButton({
    required this.stance,
    required this.emoji,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isItem = stance == PlayerStance.item;
    return GameButton(
      label: isItem ? '$emoji $label ▾' : '$emoji $label',
      variant:
          selected ? GameButtonVariant.primary : GameButtonVariant.secondary,
      size: GameButtonSize.md,
      fullWidth: true,
      onPressed: onTap,
    );
  }
}
