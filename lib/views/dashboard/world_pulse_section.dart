import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../engine/game_engine.dart';
import '../../models/structure.dart';
import '../../theme/design_tokens.dart';
import '../../widgets/game/game_card.dart';
import '../../widgets/game/game_chip.dart';
import '../../widgets/pulsing_weather_chip.dart';

/// World Pulse section — current zone, weather, and station status chips.
/// Shown on the dashboard (non-combat).
///
/// Renders a compact [GameCard] holding a [Wrap] of chips: the current zone,
/// the live weather, and one status chip per station accessible in the current
/// zone. Stations that are not present/operational in the current zone are
/// never rendered (progressive discovery — no greyed-out placeholders).
class WorldPulseSection extends StatelessWidget {
  final VoidCallback? onZoneTap;

  const WorldPulseSection({super.key, this.onZoneTap});

  @override
  Widget build(BuildContext context) {
    final engine = context.watch<GameEngine>();
    final zone = engine.currentZone;

    return GameCard(
      elevation: 1,
      padding: DSSpace.dense,
      child: Wrap(
        spacing: DSSpace.sm,
        runSpacing: DSSpace.sm,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          GameChip(
            label: zone.name,
            icon: Icons.place,
            color: DSColors.info,
            size: GameChipSize.sm,
            onTap: onZoneTap,
          ),
          PulsingWeatherChip(weather: engine.coastWeather),
          ..._buildStationChips(context, engine),
        ],
      ),
    );
  }

  /// Builds a status chip for each station accessible in the current zone.
  ///
  /// Ported from the legacy `_buildStationStatusStrip` in `dashboard_view.dart`:
  /// only non-ruined stations in the current zone are shown, the tap focuses the
  /// station (which switches to the Workshop tab), and the name, tier, and
  /// status each render as a distinct [Text] widget. Returns an empty list when
  /// no station is accessible.
  List<Widget> _buildStationChips(BuildContext context, GameEngine engine) {
    final currentZone = engine.currentZone;
    final stations = engine.stationInstances.values
        .where((inst) => inst.zoneId == currentZone.id && !inst.isRuined)
        .toList();

    if (stations.isEmpty) return const [];

    final chips = <Widget>[];
    for (final inst in stations) {
      final station = Stations.findById(inst.stationId);
      if (station == null) continue;

      // Determine status + accent color, mirroring the legacy strip.
      bool isActive = false;
      String statusText = 'Idle';
      Color accentColor = DSColors.textMuted;

      if (inst.currentCraft != null) {
        isActive = true;
        statusText = inst.currentCraft!.recipe?.name ?? 'Crafting';
        accentColor = DSColors.skill(station.primarySkill);
      } else if (inst.tierUpgrade != null) {
        isActive = true;
        statusText = 'Upgrading to T${inst.tier + 1}';
        accentColor = DSColors.info;
      } else if (inst.restoration != null) {
        isActive = true;
        statusText = 'Restoring';
        accentColor = DSColors.error;
      }

      chips.add(_StationStatusChip(
        icon: station.icon,
        name: station.name,
        tier: 'T${inst.tier}',
        status: statusText,
        accentColor: accentColor,
        isActive: isActive,
        // Replicate the legacy navigation exactly: focusStation() sets the
        // Workshop tab (index 3) synchronously and stores the focused station;
        // BuildView consumes + clears it in a post-frame callback.
        onTap: () => engine.focusStation(inst.stationId),
      ));
    }

    return chips;
  }
}

/// Compact station status chip rendering the station name, tier, and status as
/// three separate [Text] widgets inside a tappable [GameCard].
class _StationStatusChip extends StatelessWidget {
  final String icon;
  final String name;
  final String tier;
  final String status;
  final Color accentColor;
  final bool isActive;
  final VoidCallback onTap;

  const _StationStatusChip({
    required this.icon,
    required this.name,
    required this.tier,
    required this.status,
    required this.accentColor,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GameCard(
      elevation: 0,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      accentColor: isActive ? accentColor : null,
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(icon, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 6),
          Text(
            name,
            style: DSText.label(context).copyWith(
              color: DSColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
              color: DSColors.surface0,
              borderRadius: BorderRadius.circular(DSRadius.sm),
              border: Border.all(color: accentColor.withOpacity(0.4)),
            ),
            child: Text(
              tier,
              style: DSText.bodySmall(context).copyWith(
                color: isActive ? DSColors.textPrimary : DSColors.textMuted,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            status,
            style: DSText.bodySmall(context).copyWith(
              color: isActive ? accentColor : DSColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
