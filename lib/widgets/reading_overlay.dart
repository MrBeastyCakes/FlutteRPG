import 'package:flutter/material.dart';
import '../models/codex.dart';
import '../theme/design_tokens.dart';
import 'game/game_card.dart';
import 'game/game_button.dart';

class ReadingOverlay extends StatelessWidget {
  final CodexReading reading;
  final VoidCallback onDismiss;

  const ReadingOverlay({
    super.key,
    required this.reading,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final accentColor = DSColors.tag(reading.tag);
    return Container(
      color: Colors.black.withOpacity(0.95),
      child: Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500),
            margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
            child: GameCard(
              elevation: 3,
              accentColor: accentColor,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      reading.tag.name.toUpperCase(),
                      style: DSText.label(context).copyWith(
                        color: accentColor,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2.0,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      reading.title,
                      style: DSText.headingMedium(context).copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      reading.body,
                      style: DSText.narrativeBody(context).copyWith(
                        color: DSColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (reading.rewards.isNotEmpty) ...[
                      const Divider(color: DSColors.borderSubtle),
                      const SizedBox(height: 12),
                      Text(
                        'REWARDS',
                        style: DSText.label(context).copyWith(
                          color: DSColors.accent,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...reading.rewards.map((r) => Text(
                            '+ ${r.amount} ${r.kind.name}${r.targetId != null ? " (${r.targetId})" : ""}',
                            style: DSText.bodyMedium(context).copyWith(
                              color: DSColors.textMuted,
                            ),
                          )),
                      const SizedBox(height: 16),
                    ],
                    GameButton(
                      variant: GameButtonVariant.primary,
                      label: 'Continue',
                      onPressed: onDismiss,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
