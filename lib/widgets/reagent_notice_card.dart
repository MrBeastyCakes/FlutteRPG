import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/reagent_spawn.dart';
import '../models/item.dart';
import '../models/skill.dart';
import '../engine/game_engine.dart';
import '../theme/game_theme.dart';
import 'bounce_tap.dart';

class ReagentNoticeCard extends StatefulWidget {
  final ReagentSpawn spawn;
  final GameEngine engine;

  const ReagentNoticeCard({
    super.key,
    required this.spawn,
    required this.engine,
  });

  @override
  State<ReagentNoticeCard> createState() => _ReagentNoticeCardState();
}

class _ReagentNoticeCardState extends State<ReagentNoticeCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _glowAnimation = Tween<double>(begin: 0.15, end: 0.6).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    final isTest = !kIsWeb && Platform.environment.containsKey('FLUTTER_TEST');
    if (!isTest) {
      _controller.repeat(reverse: true);
    } else {
      _controller.value = 1.0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final item = Items.findById(widget.spawn.itemId)!;
    final hasEnoughEnergy = widget.engine.playerStats.currentEnergy >= widget.spawn.energyCost;
    final skillState = widget.engine.skills[widget.spawn.requiredSkill];
    final hasLevel = skillState != null && skillState.level >= widget.spawn.requiredLevel;
    final isFull = widget.engine.inventory.isFull;
    final canGather = hasEnoughEnergy && hasLevel && !isFull;

    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, child) {
        return Container(
          margin: const EdgeInsets.only(bottom: 8.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: GameTheme.accentGold.withOpacity(_glowAnimation.value),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: GameTheme.accentGold.withOpacity(_glowAnimation.value * 0.3),
                blurRadius: 8,
                spreadRadius: 1,
              ),
            ],
            gradient: LinearGradient(
              colors: [
                GameTheme.accentGold.withOpacity(0.08),
                const Color(0xFF1E2833).withOpacity(0.9),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: child,
        );
      },
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Text(item.icon, style: const TextStyle(fontSize: 28)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '⭐ UNCOMMON SIGHTING',
                        style: TextStyle(
                          color: GameTheme.accentGold,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.name,
                        style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                BounceTap(
                  onTap: canGather ? () => widget.engine.collectReagentSpawn(widget.spawn) : null,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: canGather ? GameTheme.accentGold : Colors.white10,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Collect',
                      style: TextStyle(
                        color: canGather ? Colors.black : Colors.white24,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              widget.spawn.noticeText,
              style: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.3),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.flash_on,
                  size: 14,
                  color: hasEnoughEnergy ? Colors.amber : Colors.redAccent,
                ),
                const SizedBox(width: 4),
                Text(
                  '${widget.spawn.energyCost} Energy',
                  style: TextStyle(
                    color: hasEnoughEnergy ? Colors.white70 : Colors.redAccent,
                    fontSize: 10,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  '${widget.spawn.requiredSkill.icon} level ${widget.spawn.requiredLevel}',
                  style: TextStyle(
                    color: hasLevel ? Colors.white70 : Colors.redAccent,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
