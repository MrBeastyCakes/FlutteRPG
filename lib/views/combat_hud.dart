import 'package:flutter/material.dart';
import '../theme/design_tokens.dart';
import 'combat/beast_card.dart';
import 'combat/telegraph_strip.dart';
import 'combat/round_timer_arc.dart';
import 'combat/player_card_mini.dart';
import 'combat/stance_pad.dart';
import 'combat/quickslot_bar.dart';

/// Combat HUD — full-screen takeover shown while a combat is active.
class CombatHud extends StatelessWidget {
  const CombatHud({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO(7a PhaseBannerOverlay): wrap body in a Stack and add the overlay
    // once the 7a PhaseBannerOverlay widget exists.
    return Container(
      color: DSColors.surface0,
      padding: DSSpace.section,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: const [
            BeastCard(),
            SizedBox(height: DSSpace.md),
            TelegraphStrip(),
            SizedBox(height: DSSpace.md),
            Center(child: RoundTimerArc()),
            SizedBox(height: DSSpace.md),
            PlayerCardMini(),
            Spacer(),
            StancePad(),
            SizedBox(height: DSSpace.sm),
            QuickslotBar(),
          ],
        ),
      ),
    );
  }
}
