import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:flutter_text_based_rpg/engine/game_engine.dart';
import 'package:flutter_text_based_rpg/views/dashboard/recent_log_section.dart';

void main() {
  testWidgets('shows at most 3 entries collapsed, expands on Show more', (tester) async {
    final engine = GameEngine();
    for (var i = 0; i < 6; i++) {
      engine.log('Test log entry $i');
    }
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ChangeNotifierProvider<GameEngine>.value(
          value: engine,
          child: const SingleChildScrollView(child: RecentLogSection()),
        ),
      ),
    ));
    await tester.pump();

    expect(find.textContaining('Test log entry 5'), findsOneWidget);
    expect(find.textContaining('Test log entry 0'), findsNothing);

    await tester.tap(find.text('Show more'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Test log entry 0'), findsOneWidget);
  });
}
