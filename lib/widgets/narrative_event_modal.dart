import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../engine/game_engine.dart';
import '../models/random_event.dart';
import '../models/masterwork.dart';
import '../models/item.dart';
import '../theme/design_tokens.dart';
import 'game/game_card.dart';
import 'game/game_avatar.dart';
import 'game/game_button.dart';

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
    if (variant == NarrativeEventVariant.masterwork) return DSColors.accent;
    switch (eventCategory) {
      case EventCategory.interruption:
        return DSColors.warning;
      case EventCategory.discovery:
        return DSColors.success;
      case EventCategory.traveler:
        return DSColors.info;
      case EventCategory.omen:
        return DSColors.error;
      default:
        return DSColors.accent;
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = _borderColor();
    return Container(
      color: Colors.black.withOpacity(0.85),
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
          child: Material(
            color: Colors.transparent,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 480),
              child: GameCard(
                elevation: 3,
                accentColor: themeColor,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      variant == NarrativeEventVariant.masterwork ? '⚔ TRIAL' : 'EVENT',
                      style: DSText.label(context).copyWith(
                        color: themeColor,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2.0,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      title,
                      style: DSText.headingMedium(context).copyWith(fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      prompt,
                      style: DSText.narrativeBody(context).copyWith(color: DSColors.textPrimary),
                    ),
                    const SizedBox(height: 20),
                    for (final c in choices)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Opacity(
                          opacity: c.isLocked ? 0.5 : 1.0,
                          child: InkWell(
                            onTap: c.isLocked ? null : c.onTap,
                            borderRadius: BorderRadius.circular(DSRadius.md),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: DSColors.surface3,
                                borderRadius: BorderRadius.circular(DSRadius.md),
                                border: Border.all(
                                  color: c.isLocked
                                      ? DSColors.borderSubtle
                                      : themeColor.withOpacity(0.4),
                                  width: 1.5,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        c.isLocked ? Icons.lock : Icons.play_arrow_rounded,
                                        size: 16,
                                        color: c.isLocked ? DSColors.textDisabled : themeColor,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          c.label,
                                          style: DSText.bodyMedium(context).copyWith(
                                            color: c.isLocked ? DSColors.textDisabled : DSColors.textPrimary,
                                            fontWeight: FontWeight.bold,
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
                                        style: DSText.bodySmall(context).copyWith(
                                          color: DSColors.textMuted,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    if (onAbandon != null) ...[
                      const SizedBox(height: 16),
                      GameButton(
                        variant: GameButtonVariant.danger,
                        label: 'Abandon Trial',
                        onPressed: onAbandon,
                      ),
                    ],
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
