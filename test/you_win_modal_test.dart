import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_text_based_rpg/widgets/you_win_modal.dart';
import 'package:flutter_text_based_rpg/widgets/game/game_button.dart';
import 'package:flutter_text_based_rpg/theme/game_theme.dart';

void main() {
  group('YouWinModal Widget Tests', () {
    testWidgets('Renders modal with correct title, description, and button', (WidgetTester tester) async {
      bool continueTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: GameTheme.themeData,
          home: Scaffold(
            body: YouWinModal(
              onContinue: () {
                continueTapped = true;
              },
            ),
          ),
        ),
      );

      // Verify "YOU WIN" title and description are present
      expect(find.text('YOU WIN'), findsOneWidget);
      expect(find.text('The Source is quieted. The world breathes.'), findsOneWidget);
      expect(find.text('👁️'), findsOneWidget);

      // Verify "Continue" button is present and tappable
      final buttonFinder = find.widgetWithText(GameButton, 'Continue');
      expect(buttonFinder, findsOneWidget);

      // Tap button and verify callback
      await tester.tap(buttonFinder);
      await tester.pumpAndSettle();

      expect(continueTapped, true);
    });
  });
}
