import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:flutter_text_based_rpg/engine/game_engine.dart';
import 'package:flutter_text_based_rpg/main.dart';

void main() {
  testWidgets('Elaria RPG layout and tab switching smoke test', (WidgetTester tester) async {
    // Build our app under the provider and trigger a frame.
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => GameEngine(),
        child: const MyApp(),
      ),
    );

    // Verify that the title 'ELARIA RPG' is present.
    expect(find.text('ELARIA RPG'), findsOneWidget);

    // Verify default view is the Dashboard (e.g. shows 'Town Square' location)
    expect(find.text('Town Square'), findsAtLeastNWidgets(1));

    // Tap on the 'Skills' tab in bottom navigation.
    await tester.tap(find.text('Skills'));
    await tester.pumpAndSettle();

    // Verify we are now on the Skills tab and it displays 'Woodcutting'.
    expect(find.text('Woodcutting'), findsOneWidget);
  });
}
