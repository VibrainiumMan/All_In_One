import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:all_in_one/pages/main_pages/progress_indicator_widget.dart';

void main() {
  group('ProgressIndicatorWidget', () {
    testWidgets('displays the correct progress and type', (WidgetTester tester) async {
      const double progress = 0.75; // 75%
      const String type = "Daily";

      await tester.pumpWidget(
        MaterialApp(
          home: ProgressIndicatorWidget(type: type, progress: progress),
        ),
      );

      // Expect to find "75%" text
      expect(find.text('75%'), findsOneWidget);

      // Expect to find "Daily" text
      expect(find.text('Daily'), findsOneWidget);

      // Check if the CircularProgressIndicator shows the correct value
      final CircularProgressIndicator indicator = tester.widget(find.byType(CircularProgressIndicator));
      expect(indicator.value, progress);
    });
  });
}
