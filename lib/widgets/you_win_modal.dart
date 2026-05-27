import 'package:flutter/material.dart';
import '../theme/design_tokens.dart';
import 'game/game_card.dart';
import 'game/game_button.dart';

class YouWinModal extends StatelessWidget {
  final VoidCallback onContinue;
  const YouWinModal({super.key, required this.onContinue});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withOpacity(0.85),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          child: GameCard(
            elevation: 4,
            accentColor: DSColors.accent,
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('👁️', style: TextStyle(fontSize: 64)),
                const SizedBox(height: 24),
                Text(
                  'YOU WIN',
                  style: DSText.display(context).copyWith(
                    color: DSColors.accent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'The Source is quieted. The world breathes.',
                  style: DSText.bodyLarge(context).copyWith(
                    color: DSColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                GameButton(
                  variant: GameButtonVariant.primary,
                  label: 'Continue',
                  onPressed: onContinue,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
