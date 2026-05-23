import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../engine/game_engine.dart';
import '../models/skill.dart';
import '../models/zone.dart';
import '../theme/game_theme.dart';
import '../models/structure.dart';
import '../widgets/custom_progress_bar.dart';

class ZonesView extends StatelessWidget {
  const ZonesView({Key? key}) : super(key: key);

  String _getZoneEmoji(String zoneId) {
    if (zoneId.contains('woods')) return '🌲';
    if (zoneId.contains('mine')) return '⛰️';
    return '🏡';
  }

  @override
  Widget build(BuildContext context) {
    final engine = Provider.of<GameEngine>(context);
    final activeZone = engine.currentZone;
    final allZones = Zones.all;

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: allZones.length,
      itemBuilder: (context, index) {
        final zone = allZones[index];
        final isCurrent = activeZone.id == zone.id;
        final isUnlocked = engine.unlockedZoneIds.contains(zone.id);

        String? unlockActionId;
        if (zone.id == 'whispering_woods_1') {
          unlockActionId = 'explore_forest_paths';
        } else if (zone.id == 'darkstone_mine_1') {
          unlockActionId = 'explore_rocky_trails';
        } else if (zone.id == 'whispering_woods_2') {
          unlockActionId = 'explore_deep_woods';
        } else if (zone.id == 'darkstone_mine_2') {
          unlockActionId = 'explore_lower_shafts';
        }

        final double progress = unlockActionId != null
            ? (engine.explorationProgress[unlockActionId] ?? 0.0)
            : 0.0;

        final cardWidget = Card(
          color: GameTheme.cardBg,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: isCurrent
                  ? GameTheme.accentGold
                  : isUnlocked
                      ? GameTheme.border.withOpacity(0.5)
                      : GameTheme.border.withOpacity(0.2),
              width: isCurrent ? 1.5 : 1,
            ),
          ),
          elevation: isUnlocked ? 3 : 1,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Zone Title Header
                Row(
                  children: [
                    Text(
                      isUnlocked ? _getZoneEmoji(zone.id) : '🔒',
                      style: const TextStyle(fontSize: 24),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            zone.name,
                            style: TextStyle(
                              color: isUnlocked ? Colors.white : GameTheme.textMuted,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Zone Tier ${zone.tier}',
                            style: const TextStyle(
                              color: GameTheme.textMuted,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Current location indicator, Travel button, or Locked indicator
                    if (isCurrent)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.green.withOpacity(0.5)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.location_on, color: Colors.greenAccent, size: 12),
                            SizedBox(width: 4),
                            Text(
                              'Current',
                              style: TextStyle(
                                color: Colors.greenAccent,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      )
                    else if (isUnlocked)
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: GameTheme.accentGold,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        onPressed: () {
                          engine.travelTo(zone);
                        },
                        icon: const Icon(Icons.directions_run, size: 14),
                        label: const Text(
                          'Travel',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.red.withOpacity(0.3)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.lock, color: Colors.redAccent, size: 12),
                            SizedBox(width: 4),
                            Text(
                              'Locked',
                              style: TextStyle(
                                color: Colors.redAccent,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),

                // Description / Unlock Hint
                Text(
                  isUnlocked ? zone.description : 'Unlock Hint: ${zone.unlockHint}',
                  style: TextStyle(
                    color: isUnlocked ? GameTheme.textLight : GameTheme.textMuted,
                    fontSize: 13,
                    fontStyle: isUnlocked ? FontStyle.normal : FontStyle.italic,
                  ),
                ),
                if (!isUnlocked && progress > 0.0) ...[
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Discovery Progress',
                        style: TextStyle(
                          color: GameTheme.accentGold,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${(progress * 100).toInt()}%',
                        style: const TextStyle(
                          color: GameTheme.accentGold,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  CustomProgressBar(
                    progress: progress,
                    color: GameTheme.accentGold,
                    height: 8,
                  ),
                ],
                const SizedBox(height: 8),

                if (isUnlocked) ...[
                  // Modifiers & Weather
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF151D26),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: GameTheme.border.withOpacity(0.6)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.cloudy_snowing, color: GameTheme.accentGold, size: 14),
                        const SizedBox(width: 6),
                        Text(
                          'Weather Effect: ',
                          style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 11),
                        ),
                        Expanded(
                          child: Text(
                            zone.weatherBonusDescription,
                            style: const TextStyle(
                              color: GameTheme.accentGold,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Built Structures list in this zone
                  Builder(
                    builder: (context) {
                      final builtStructures = engine.getBuiltStructuresForZone(zone.id);
                      if (builtStructures.isEmpty) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Structures: ',
                              style: TextStyle(
                                color: GameTheme.textMuted,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Wrap(
                                spacing: 6,
                                runSpacing: 4,
                                children: builtStructures.map((sId) {
                                  final struct = Structures.findById(sId);
                                  if (struct == null) return const SizedBox.shrink();
                                  return Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: GameTheme.craftingCyan.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: GameTheme.craftingCyan.withOpacity(0.3)),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(struct.icon, style: const TextStyle(fontSize: 10)),
                                        const SizedBox(width: 4),
                                        Text(
                                          struct.name,
                                          style: const TextStyle(
                                            color: GameTheme.craftingCyan,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                  // Preview Actions list
                  Theme(
                    data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      title: const Text(
                        'Preview Zone Activities',
                        style: TextStyle(color: GameTheme.textMuted, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                      dense: true,
                      tilePadding: EdgeInsets.zero,
                      children: zone.actions.map((act) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Row(
                            children: [
                              Text(
                                act.requiredSkill?.icon ?? '⚡',
                                style: const TextStyle(fontSize: 14),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  act.name,
                                  style: const TextStyle(color: Colors.white, fontSize: 12),
                                ),
                              ),
                              if (act.requiredSkill != null)
                                Text(
                                  'Lvl ${act.requiredLevel} ${act.requiredSkill!.name}',
                                  style: const TextStyle(color: GameTheme.textMuted, fontSize: 10),
                                )
                              else
                                const Text(
                                  'No Requirements',
                                  style: const TextStyle(color: GameTheme.textMuted, fontSize: 10),
                                ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );

        if (!isUnlocked) {
          return Opacity(
            opacity: 0.65,
            child: cardWidget,
          );
        }
        return cardWidget;
      },
    );
  }}
