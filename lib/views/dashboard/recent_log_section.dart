import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../engine/game_engine.dart';
import '../../engine/activity_log.dart';
import '../../theme/design_tokens.dart';
import '../../widgets/game/game_card.dart';

/// Recent Log section — newest 3 log entries with expand to newest 12.
/// Shown at the bottom of the dashboard (non-combat).
class RecentLogSection extends StatefulWidget {
  const RecentLogSection({super.key});

  @override
  State<RecentLogSection> createState() => _RecentLogSectionState();
}

class _RecentLogSectionState extends State<RecentLogSection> {
  bool _expanded = false;

  ({String glyph, Color color}) _severity(LogType type) {
    switch (type) {
      case LogType.success:
      case LogType.levelUp:
        return (glyph: '✓', color: DSColors.success);
      case LogType.warning:
        return (glyph: '⚠', color: DSColors.warning);
      case LogType.error:
        return (glyph: '✗', color: DSColors.error);
      case LogType.worldEvent:
        return (glyph: '◆', color: DSColors.info);
      case LogType.info:
        return (glyph: '▸', color: DSColors.textMuted);
    }
  }

  @override
  Widget build(BuildContext context) {
    final engine = context.watch<GameEngine>();
    // engine.logs is newest-first (log() inserts at index 0), so no reversal.
    final all = engine.logs;
    final limit = _expanded ? 12 : 3;
    final visible = all.take(limit).toList();

    return GameCard(
      elevation: 1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Recent Activity',
                  style: DSText.label(context)
                      .copyWith(color: DSColors.textSecondary)),
              if (all.length > 3)
                GestureDetector(
                  onTap: () => setState(() => _expanded = !_expanded),
                  child: Text(_expanded ? 'Show less' : 'Show more',
                      style: DSText.label(context)
                          .copyWith(color: DSColors.goldAccent)),
                ),
            ],
          ),
          const SizedBox(height: DSSpace.sm),
          if (visible.isEmpty)
            Text('No recent activity.',
                style: DSText.bodySmall(context)
                    .copyWith(color: DSColors.textMuted))
          else
            ...visible.map((e) {
              final sev = _severity(e.type);
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(sev.glyph,
                        style: TextStyle(color: sev.color, fontSize: 12)),
                    const SizedBox(width: DSSpace.sm),
                    Expanded(
                        child: Text(e.message,
                            style: DSText.bodySmall(context))),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}
