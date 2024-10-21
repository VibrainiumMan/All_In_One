import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:all_in_one/pages/auth_pages/timer_screen.dart';

void main() {
  group('Study Timer Basic Test', () {
    testWidgets('Timer starts and counts down correctly', (WidgetTester tester) async {
      // Create a mock function to simulate points update
      int pointsUpdated = 0;
      void mockUpdatePoints(int points) {
        pointsUpdated = points;
      }

      // Build the TimerScreen widget
      await tester.pumpWidget(
        MaterialApp(
          home: TimerScreen(
            showNotification: (String title, String message) {},
            updatePoints: mockUpdatePoints,
          ),
        ),
      );

      // Verify that the initial state is "Set your timer"
      expect(find.text('Set your timer'), findsOneWidget);

      // Simulate tapping the +5 min button to set the timer to 5 minutes
      await tester.tap(find.text('+5 min'));
      await tester.pumpAndSettle();

      // Verify that the timer now shows 5:00
      expect(find.text('5:00'), findsOneWidget);

      // Simulate starting the timer
      await tester.tap(find.text('Start Timer'));
      await tester.pump(); // Trigger the first frame of the timer

      // Fast-forward the timer by 1 minute
      await tester.pump(const Duration(seconds: 60));

      // Verify that the timer has decremented to 4:00
      expect(find.text('4:00'), findsOneWidget);
    });
  });
}