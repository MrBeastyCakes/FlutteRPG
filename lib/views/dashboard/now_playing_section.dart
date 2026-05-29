import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../engine/game_engine.dart';
import '../../models/skill.dart';
import '../../models/zone.dart';
import '../../theme/design_tokens.dart';
import '../../widgets/game/game_card.dart';
import '../../widgets/game/game_button.dart';
import '../../widgets/game/game_progress_bar.dart';

/// Which content the "Now Playing" card shows. Precedence (highest first):
/// [activeAction] when an action/craft is running; else [townFixtures] when the
/// current zone is the town hub; else [zoneActions].
enum _NowPlayingState { activeAction, zoneActions, townFixtures }

/// Now Playing section — context-sensitive: active action OR zone actions OR
/// town fixtures. Shown beneath the player hand on the dashboard (non-combat).
///
/// This is a layout-only port of the old dashboard rendering. It invents no
/// engine APIs and adds no game logic — it reuses [GameEngine.activeAction],
/// [GameEngine.startAction], [GameEngine.cancelAction], [GameEngine.isActionVisible]
/// and the existing travel flow (surfaced via [onTravel]).
class NowPlayingSection extends StatelessWidget {
  /// Opens the travel destination flow (the dashboard's zone-travel sheet).
  final VoidCallback? onTravel;

  const NowPlayingSection({super.key, this.onTravel});

  /// The town hub is identified by its zone id (there is no `isHub` flag on
  /// [Zone]; Town Square is the only tier-0 hub zone in the registry).
  static bool _isTownHub(Zone zone) => zone.id == 'town_square';

  _NowPlayingState _select(GameEngine engine) {
    if (engine.activeAction != null) return _NowPlayingState.activeAction;
    if (_isTownHub(engine.currentZone)) return _NowPlayingState.townFixtures;
    return _NowPlayingState.zoneActions;
  }

  @override
  Widget build(BuildContext context) {
    final engine = context.watch<GameEngine>();
    final state = _select(engine);

    return GameCard(
      elevation: 1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Now Playing',
            style: DSText.label(context).copyWith(color: DSColors.textSecondary),
          ),
          const SizedBox(height: DSSpace.md),
          switch (state) {
            _NowPlayingState.activeAction => _buildActiveAction(context, engine),
            _NowPlayingState.zoneActions =>
              _buildZoneActions(context, engine, engine.currentZone),
            _NowPlayingState.townFixtures =>
              _buildTownFixtures(context, engine, engine.currentZone),
          },
          if (state != _NowPlayingState.activeAction) ...[
            const SizedBox(height: DSSpace.md),
            GameButton(
              label: 'Travel',
              icon: Icons.map,
              variant: GameButtonVariant.secondary,
              fullWidth: true,
              onPressed: onTravel,
            ),
          ],
        ],
      ),
    );
  }

  // ── State A: an action / craft / build is in progress ──────────────────────
  Widget _buildActiveAction(BuildContext context, GameEngine engine) {
    final activeState = engine.activeAction;
    if (activeState == null) return const SizedBox.shrink();

    final String name;
    final String icon;
    final String subtitle;
    final Color progressColor;
    final SkillType? skill;

    if (activeState.recipe != null) {
      final recipe = activeState.recipe!;
      name = 'Crafting: ${recipe.name}';
      icon = recipe.icon;
      subtitle = 'Restores or creates valuable items';
      progressColor = DSColors.goldAccent;
      skill = null;
    } else if (activeState.structure != null) {
      final structure = activeState.structure!;
      name = 'Building: ${structure.name}';
      icon = structure.icon;
      subtitle = 'Constructing permanent structure';
      progressColor = DSColors.info;
      skill = null;
    } else {
      final action = activeState.action;
      name = action?.name ?? 'Working...';
      icon = action?.requiredSkill?.icon ?? '⚡';
      skill = action?.requiredSkill;
      subtitle = skill != null ? skill.name : 'In progress';
      progressColor = skill != null ? DSColors.skill(skill) : DSColors.goldAccent;
    }

    final progress = activeState.progress;
    final percent = (progress * 100).toInt();

    // Approximate remaining time from duration + progress (no new engine API).
    final totalSeconds = activeState.durationSeconds;
    final remainingSeconds = (totalSeconds * (1.0 - progress)).clamp(0.0, totalSeconds);
    final remainingLabel = '${remainingSeconds.ceil()}s left';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: DSSpace.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: DSText.bodyMedium(context)
                        .copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: DSSpace.xs),
                  Text(
                    '$subtitle  •  $remainingLabel',
                    style: DSText.bodySmall(context)
                        .copyWith(color: DSColors.textMuted),
                  ),
                ],
              ),
            ),
            GameButton(
              label: 'Cancel',
              variant: GameButtonVariant.danger,
              size: GameButtonSize.sm,
              onPressed: () => engine.cancelAction(),
            ),
          ],
        ),
        const SizedBox(height: DSSpace.md),
        GameProgressBar(
          progress: progress,
          color: progressColor,
          height: 8,
          trailingLabel: '$percent%',
        ),
      ],
    );
  }

  // ── State B: idle in an action zone — list this zone's available actions ────
  Widget _buildZoneActions(BuildContext context, GameEngine engine, Zone zone) {
    final actions = zone.actions
        .where((action) => engine.isActionVisible(action))
        .toList();

    if (actions.isEmpty) {
      return _emptyHint(context, 'No actions available here right now.');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final action in actions)
          Padding(
            padding: const EdgeInsets.only(bottom: DSSpace.sm),
            child: _actionRow(context, engine, action),
          ),
      ],
    );
  }

  // ── State C: idle in the town hub — list the town fixtures (visible only) ───
  Widget _buildTownFixtures(BuildContext context, GameEngine engine, Zone zone) {
    // Town fixtures ARE the town zone's actions (Inn / Tavern / lore stall /
    // travel scouts). Only render the ones currently visible (progressive
    // discovery — gated by engine.isActionVisible).
    final fixtures = zone.actions
        .where((action) => engine.isActionVisible(action))
        .toList();

    if (fixtures.isEmpty) {
      return _emptyHint(context, 'Nothing to do in town right now.');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final fixture in fixtures)
          Padding(
            padding: const EdgeInsets.only(bottom: DSSpace.sm),
            child: _actionRow(context, engine, fixture),
          ),
      ],
    );
  }

  /// A single tappable action/fixture row. Tapping starts the action via the
  /// existing [GameEngine.startAction] (the same call the old dashboard made).
  Widget _actionRow(BuildContext context, GameEngine engine, ZoneAction action) {
    final skill = action.requiredSkill;
    final hasLevelReq = skill == null ||
        (engine.skills[skill]?.level ?? 0) >= action.requiredLevel;
    final isGated = skill != null && (engine.skills[skill]?.isGated ?? false);

    final accent = skill != null ? DSColors.skill(skill) : DSColors.goldAccent;

    final String reqLabel;
    final Color reqColor;
    if (isGated) {
      reqLabel = '🔒 Level Capped';
      reqColor = DSColors.error;
    } else if (skill != null) {
      reqLabel = 'Req: ${skill.name} Lvl ${action.requiredLevel}+';
      reqColor = hasLevelReq ? DSColors.textMuted : DSColors.error;
    } else {
      reqLabel = 'No requirements';
      reqColor = DSColors.textMuted;
    }

    return GameCard(
      elevation: 0,
      accentColor: accent,
      padding: DSSpace.dense,
      onTap: () => engine.startAction(action),
      child: Row(
        children: [
          Text(skill?.icon ?? '⚡', style: const TextStyle(fontSize: 20)),
          const SizedBox(width: DSSpace.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  action.name,
                  style: DSText.bodyMedium(context)
                      .copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: DSSpace.xs),
                Text(
                  reqLabel,
                  style: DSText.bodySmall(context).copyWith(
                    color: reqColor,
                    fontWeight: isGated ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: DSColors.textMuted, size: 18),
        ],
      ),
    );
  }

  Widget _emptyHint(BuildContext context, String message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: DSSpace.md),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: DSText.bodySmall(context).copyWith(
          color: DSColors.textMuted,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }
}
