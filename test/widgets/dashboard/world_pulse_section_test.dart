import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:flutter_text_based_rpg/engine/game_engine.dart';
import 'package:flutter_text_based_rpg/views/dashboard/world_pulse_section.dart';

void main() {
  testWidgets('renders the current zone name as a chip', (tester) async {
    final engine = GameEngine(); // starts in Town Square
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ChangeNotifierProvider<GameEngine>.value(
          value: engine,
          child: const WorldPulseSection(),
        ),
      ),
    ));
    await tester.pump();

    expect(find.textContaining('Town Square'), findsAtLeastNWidgets(1));
  });
}
