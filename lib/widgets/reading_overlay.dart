import 'package:flutter/material.dart';
import '../models/codex.dart';
import '../theme/game_theme.dart';

class ReadingOverlay extends StatelessWidget {
  final CodexReading reading;
  final VoidCallback onDismiss;

  const ReadingOverlay({
    super.key,
    required this.reading,
    required this.onDismiss,
  });

  Color _tagColor(CodexTag tag) {
    switch (tag) {
      case CodexTag.wilds: return const Color(0xFF5BAA6F);
      case CodexTag.stone: return const Color(0xFFAAAAAA);
      case CodexTag.tide: return const Color(0xFF5B8FAA);
      case CodexTag.source: return const Color(0xFF7B5BAA);
      case CodexTag.oldEmpire: return GameTheme.accentGold;
      case CodexTag.misc: return Colors.white;
    }
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = _tagColor(reading.tag);
    return Container(
      color: Colors.black.withOpacity(0.95),
      child: Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500),
            margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: GameTheme.cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: accentColor.withOpacity(0.5), width: 2),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    reading.tag.name.toUpperCase(),
                    style: TextStyle(
                      color: accentColor,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2.0,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    reading.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    reading.body,
                    style: const TextStyle(
                      color: GameTheme.textLight,
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (reading.rewards.isNotEmpty) ...[
                    const Divider(color: GameTheme.border),
                    const SizedBox(height: 12),
                    const Text(
                      'REWARDS',
                      style: TextStyle(
                        color: GameTheme.accentGold,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...reading.rewards.map((r) => Text(
                          '+ ${r.amount} ${r.kind.name}${r.targetId != null ? " (${r.targetId})" : ""}',
                          style: const TextStyle(
                            color: GameTheme.textMuted,
                            fontSize: 12,
                          ),
                        )),
                    const SizedBox(height: 16),
                  ],
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: onDismiss,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accentColor,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Continue',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
