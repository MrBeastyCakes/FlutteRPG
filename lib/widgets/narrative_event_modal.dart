import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../engine/game_engine.dart';
import '../models/random_event.dart';
import '../models/masterwork.dart';
import '../models/item.dart';
import '../theme/game_theme.dart';

enum NarrativeEventVariant { masterwork, randomEvent }

class NarrativeEventModal extends StatelessWidget {
  final String title;
  final String prompt;
  final List<NarrativeEventChoice> choices;
  final NarrativeEventVariant variant;
  final EventCategory? eventCategory;

  final VoidCallback? onAbandon;

  const NarrativeEventModal({
    super.key,
    required this.title,
    required this.prompt,
    required this.choices,
    this.variant = NarrativeEventVariant.randomEvent,
    this.eventCategory,
    this.onAbandon,
  });

  Color _borderColor() {
    if (variant == NarrativeEventVariant.masterwork) return GameTheme.accentGold;
    switch (eventCategory) {
      case EventCategory.interruption:
        return Colors.orange;
      case EventCategory.discovery:
        return Colors.greenAccent;
      case EventCategory.traveler:
        return Colors.cyanAccent;
      case EventCategory.omen:
        return Colors.redAccent;
      default:
        return GameTheme.accentGold;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withOpacity(0.85),
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
          child: Material(
            color: Colors.transparent,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 480),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: GameTheme.cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _borderColor(), width: 2),
                boxShadow: [
                  BoxShadow(
                    color: _borderColor().withOpacity(0.15),
                    blurRadius: 16,
                    spreadRadius: 2,
                  )
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    variant == NarrativeEventVariant.masterwork ? '⚔ TRIAL' : 'EVENT',
                    style: TextStyle(
                      color: _borderColor(),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2.0,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    prompt,
                    style: const TextStyle(
                      color: GameTheme.textLight,
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 20),
                  for (final c in choices)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Opacity(
                        opacity: c.isLocked ? 0.5 : 1.0,
                        child: ElevatedButton(
                          onPressed: c.isLocked ? null : c.onTap,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: GameTheme.cardBg,
                            foregroundColor: Colors.white,
                            side: BorderSide(
                              color: c.isLocked
                                  ? GameTheme.border.withOpacity(0.3)
                                  : _borderColor().withOpacity(0.5),
                            ),
                            padding: const EdgeInsets.all(12),
                            alignment: Alignment.centerLeft,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    c.isLocked ? Icons.lock : Icons.play_arrow_rounded,
                                    size: 16,
                                    color: c.isLocked ? GameTheme.textMuted : _borderColor(),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      c.label,
                                      style: TextStyle(
                                        color: c.isLocked ? GameTheme.textMuted : Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              if (c.preview != null)
                                Padding(
                                  padding: const EdgeInsets.only(left: 24, top: 4),
                                  child: Text(
                                    c.preview!,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: GameTheme.textMuted,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  if (onAbandon != null) ...[
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: GameTheme.textMuted,
                        side: const BorderSide(color: GameTheme.border, width: 1.5),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: onAbandon,
                      icon: const Icon(Icons.logout),
                      label: const Text('Abandon Trial', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class NarrativeEventChoice {
  final String label;
  final String? preview;
  final VoidCallback onTap;
  final bool isLocked;

  const NarrativeEventChoice({
    required this.label,
    this.preview,
    required this.onTap,
    this.isLocked = false,
  });
}

class NarrativeEventListener extends StatefulWidget {
  final Widget child;
  const NarrativeEventListener({super.key, required this.child});

  @override
  State<NarrativeEventListener> createState() => _NarrativeEventListenerState();
}

class _NarrativeEventListenerState extends State<NarrativeEventListener> {
  StreamSubscription? _sub;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sub?.cancel();
    final engine = Provider.of<GameEngine>(context, listen: false);
    _sub = engine.randomEvents.listen((event) {
      _showEventModal(context, engine, event);
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  void _showEventModal(BuildContext ctx, GameEngine engine, RandomEvent event) {
    showGeneralDialog(
      context: ctx,
      barrierDismissible: false,
      barrierLabel: 'Event',
      barrierColor: Colors.transparent,
      pageBuilder: (_, __, ___) => NarrativeEventModal(
        title: event.title,
        prompt: event.prompt,
        variant: NarrativeEventVariant.randomEvent,
        eventCategory: event.category,
        choices: [
          for (int i = 0; i < event.options.length; i++)
            _buildChoice(ctx, engine, event.options[i], i),
        ],
      ),
    );
  }

  NarrativeEventChoice _buildChoice(BuildContext ctx, GameEngine engine, RandomEventOption opt, int index) {
    final hasSkill = opt.requiredSkill == null ||
        (engine.skills[opt.requiredSkill!]?.level ?? 0) >= opt.requiredLevel;
    final hasItems = opt.requiredItemId == null ||
        engine.inventory.hasItem(opt.requiredItemId!, opt.requiredItemCount);
    final hasEnergy = engine.playerStats.currentEnergy >= opt.energyCost;
    final hasGold = engine.playerStats.gold >= opt.goldCost;

    final isLocked = !hasSkill || !hasItems || !hasEnergy || !hasGold;

    return NarrativeEventChoice(
      label: opt.text,
      preview: _buildPreview(opt),
      isLocked: isLocked,
      onTap: () {
        Navigator.pop(ctx);
        engine.resolveRandomEvent(index);
      },
    );
  }

  String? _buildPreview(RandomEventOption opt) {
    final parts = <String>[];
    if (opt.requiredSkill != null) {
      parts.add('Requires ${opt.requiredSkill!.name} Lvl ${opt.requiredLevel}+');
    }
    if (opt.requiredItemId != null) {
      final item = Items.findById(opt.requiredItemId!);
      final name = item != null ? item.name : opt.requiredItemId;
      parts.add('Needs $name x${opt.requiredItemCount}');
    }
    if (opt.energyCost != 0) parts.add('Costs ${opt.energyCost} Energy');
    if (opt.healthCost != 0) parts.add('Costs ${opt.healthCost} HP');
    if (opt.goldCost != 0) parts.add('Costs ${opt.goldCost} Gold');
    return parts.isEmpty ? null : parts.join(', ');
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
