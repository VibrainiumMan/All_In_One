import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:all_in_one/pages/auth_pages/quiz_result_page.dart';

void main() {
  testWidgets('QuizResultPage displays correct scores and functions', (WidgetTester tester) async {
    // Create a MaterialApp around QuizResultPage for correct theme and navigation loading
    await tester.pumpWidget(MaterialApp(
      home: QuizResultPage(
        correctAnswers: 5,
        totalQuestions: 10,
        deckName: 'Test Deck',
      ),
    ));

    // Verify that the correct score information is displayed
    expect(find.text('You got 5 out of 10 correct!'), findsOneWidget);

    // Verify that the button exists and its text is correct
    expect(find.widgetWithText(ElevatedButton, 'Back to Deck'), findsOneWidget);

    // Simulate button press and check if Navigator.popUntil is called
    await tester.tap(find.widgetWithText(ElevatedButton, 'Back to Deck'));
    await tester.pumpAndSettle(); // Complete all animations and frames

    // In theory, we should check the Navigator's state here, but since we don't have an actual Navigator stack,
    // this part is usually left to integration testing.
    // If you want to test Navigator functionality in unit tests, you might need to use mock navigator observers.
  });
}
