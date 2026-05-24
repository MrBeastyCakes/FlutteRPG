import 'package:flutter/material.dart';
import '../engine/activity_log.dart';
import '../theme/game_theme.dart';

class FloatingNotificationOverlay extends StatelessWidget {
  final List<LogEntry> notifications;

  const FloatingNotificationOverlay({
    super.key,
    required this.notifications,
  });

  @override
  Widget build(BuildContext context) {
    if (notifications.isEmpty) return const SizedBox.shrink();

    return Positioned(
      bottom: 16,
      left: 16,
      right: 16,
      child: IgnorePointer(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          verticalDirection: VerticalDirection.up, // Stack new notifications on top of old ones
          children: notifications.map((entry) {
            return FloatingNotificationItem(entry: entry, key: ValueKey(entry.timestamp.millisecondsSinceEpoch ^ entry.message.hashCode));
          }).toList(),
        ),
      ),
    );
  }
}

class FloatingNotificationItem extends StatefulWidget {
  final LogEntry entry;

  const FloatingNotificationItem({
    super.key,
    required this.entry,
  });

  @override
  State<FloatingNotificationItem> createState() => _FloatingNotificationItemState();
}

class _FloatingNotificationItemState extends State<FloatingNotificationItem> {
  double _opacity = 0.0;
  double _yOffset = 20.0; // Start below (slide up on enter)

  @override
  void initState() {
    super.initState();
    // Schedule animation in next frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _opacity = 1.0;
          _yOffset = 0.0;
        });
      }
    });

    // Schedule fade out slightly before removal
    Future.delayed(const Duration(milliseconds: 2400), () {
      if (mounted) {
        setState(() {
          _opacity = 0.0;
          _yOffset = -10.0; // Continue sliding up on exit
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    Color borderColor;
    IconData icon;
    Color iconColor;

    switch (widget.entry.type) {
      case LogType.success:
        borderColor = Colors.greenAccent;
        icon = Icons.check_circle_outline;
        iconColor = Colors.greenAccent;
        break;
      case LogType.levelUp:
        borderColor = GameTheme.accentGold;
        icon = Icons.workspace_premium;
        iconColor = GameTheme.accentGold;
        break;
      case LogType.warning:
        borderColor = GameTheme.energyYellow;
        icon = Icons.warning_amber_rounded;
        iconColor = GameTheme.energyYellow;
        break;
      case LogType.error:
        borderColor = GameTheme.healthRed;
        icon = Icons.error_outline_rounded;
        iconColor = GameTheme.healthRed;
        break;
      case LogType.info:
      default:
        borderColor = GameTheme.border;
        icon = Icons.info_outline;
        iconColor = GameTheme.textMuted;
        break;
    }

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 250),
      opacity: _opacity,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        transform: Matrix4.translationValues(0, _yOffset, 0),
        margin: const EdgeInsets.only(bottom: 8.0),
        decoration: BoxDecoration(
          color: GameTheme.cardBg.withOpacity(0.95),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor.withOpacity(0.8), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                widget.entry.message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
