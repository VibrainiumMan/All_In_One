import 'package:all_in_one/components/theme_notifer.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late ThemeNotifer themeNotifier;

  setUp(() async {
    // Set up SharedPreferences mock with initial values (empty initially)
    SharedPreferences.setMockInitialValues({});
    themeNotifier = ThemeNotifer();
    // Wait for loadPreference to complete in the constructor
    await themeNotifier.loadPreference();
  });

  test('should have default theme as light', () {
    expect(themeNotifier.isDark, false);
  });

  test('should load theme preference from SharedPreferences', () async {
    // Simulate a saved preference in SharedPreferences
    SharedPreferences.setMockInitialValues({'isDark': true});

    // Reinitialize themeNotifier to trigger loadPreference again
    themeNotifier = ThemeNotifer();
    await themeNotifier.loadPreference();

    // Assert: Check if the theme was loaded as dark
    expect(themeNotifier.isDark, true);
  });
}