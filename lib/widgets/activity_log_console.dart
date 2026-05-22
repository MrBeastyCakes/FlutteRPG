import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../engine/activity_log.dart';
import '../engine/game_engine.dart';
import '../theme/game_theme.dart';

class ActivityLogConsole extends StatelessWidget {
  const ActivityLogConsole({super.key});

  Color _getLogColor(LogType type) {
    switch (type) {
      case LogType.success:
        return const Color(0xFF81C784); // light green
      case LogType.warning:
        return const Color(0xFFFFB74D); // amber/orange
      case LogType.error:
        return const Color(0xFFE57373); // red
      case LogType.levelUp:
        return GameTheme.accentGold;
      case LogType.info:
        return GameTheme.textMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    final engine = Provider.of<GameEngine>(context);
    final logs = engine.logs;

    return Container(
      height: 140,
      decoration: GameTheme.glassCardDecoration(
        customBg: const Color(0xFF0C1014).withOpacity(0.95),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Console Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'RECENT ACTIVITY',
                style: TextStyle(
                  color: GameTheme.accentGold,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              Icon(
                Icons.terminal,
                color: GameTheme.accentGold.withOpacity(0.6),
                size: 14,
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Scrollable log lines
          Expanded(
            child: logs.isEmpty
                ? const Center(
                    child: Text(
                      'No recent actions.',
                      style: TextStyle(color: GameTheme.textMuted, fontSize: 12),
                    ),
                  )
                : ListView.builder(
                    reverse: true, // index 0 (newest) at bottom, pushes up
                    itemCount: logs.length,
                    itemBuilder: (context, index) {
                      final entry = logs[index];
                      final logColor = _getLogColor(entry.type);

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2.0),
                        child: RichText(
                          text: TextSpan(
                            style: const TextStyle(
                              fontFamily: 'monospace', // Monospaced font for console style
                              fontSize: 12,
                            ),
                            children: [
                              TextSpan(
                                text: '${entry.formattedTime} ',
                                style: const TextStyle(color: GameTheme.textMuted),
                              ),
                              TextSpan(
                                text: entry.message,
                                style: TextStyle(color: logColor),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
