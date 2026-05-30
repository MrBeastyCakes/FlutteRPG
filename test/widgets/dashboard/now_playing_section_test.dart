import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:flutter_text_based_rpg/engine/game_engine.dart';
import 'package:flutter_text_based_rpg/views/dashboard/now_playing_section.dart';

void main() {
  testWidgets('idle in Town Square renders the Now Playing header and a town action',
      (tester) async {
    final engine = GameEngine(); // idle, in town
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ChangeNotifierProvider<GameEngine>.value(
          value: engine,
          child: const SingleChildScrollView(child: NowPlayingSection()),
        ),
      ),
    ));
    await tester.pump();

    // Header is always present.
    expect(find.text('Now Playing'), findsOneWidget);

    // State-specific: idle in Town Square shows the visible town fixtures/actions.
    // 'Rest at the Inn' is an always-visible town_square ZoneAction.
    expect(find.text('Rest at the Inn'), findsOneWidget);

    // Idle states (non-active-action) expose the Travel button.
    expect(find.text('Travel'), findsOneWidget);
  });
}
