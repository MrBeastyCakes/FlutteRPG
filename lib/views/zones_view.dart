import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../engine/game_engine.dart';
import '../models/skill.dart';
import '../models/zone.dart';
import '../theme/game_theme.dart';

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

        return Card(
          color: GameTheme.cardBg,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: isCurrent ? GameTheme.accentGold : GameTheme.border.withOpacity(0.5),
              width: isCurrent ? 1.5 : 1,
            ),
          ),
          elevation: 3,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Zone Title Header
                Row(
                  children: [
                    Text(
                      _getZoneEmoji(zone.id),
                      style: const TextStyle(fontSize: 24),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            zone.name,
                            style: const TextStyle(
                              color: Colors.white,
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
                    // Current location indicator or Travel button
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
                    else
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
                      ),
                  ],
                ),
                const SizedBox(height: 8),

                // Description
                Text(
                  zone.description,
                  style: const TextStyle(color: GameTheme.textLight, fontSize: 13),
                ),
                const SizedBox(height: 8),

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

                // Preview Actions list (small expansion tile or bullet list)
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
            ),
          ),
        );
      },
    );
  }
}
