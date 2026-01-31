import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cartomix_flutter/main.dart';
import 'package:cartomix_flutter/core/providers/app_state.dart';
import 'package:cartomix_flutter/ui/screens/onboarding_screen.dart';
import 'package:cartomix_flutter/ui/screens/main_screen.dart';
import 'package:cartomix_flutter/ui/screens/library_screen.dart';

void main() {
  group('CartoMix App Tests', () {
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
    });

    testWidgets('Shows onboarding on first launch', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: const CartoMixApp(),
        ),
      );
      await tester.pumpAndSettle();

      // Should show onboarding screen on first launch
      expect(find.byType(OnboardingScreen), findsOneWidget);
      expect(find.text('Welcome to CartoMix'), findsOneWidget);
    });

    testWidgets('Shows main screen after onboarding complete', (WidgetTester tester) async {
      // Set onboarding as complete
      await prefs.setBool('onboarding_complete', true);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: const CartoMixApp(),
        ),
      );
      await tester.pumpAndSettle();

      // Should show main screen
      expect(find.byType(MainScreen), findsOneWidget);
      expect(find.byType(LibraryScreen), findsOneWidget);
    });

    testWidgets('Onboarding has Get Started button', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: const CartoMixApp(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('onboarding.getStarted')), findsOneWidget);
      expect(find.text('Get Started'), findsOneWidget);
    });

    testWidgets('Get Started navigates to add library step', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: const CartoMixApp(),
        ),
      );
      await tester.pumpAndSettle();

      // Scroll to and tap Get Started button
      final getStartedButton = find.byKey(const Key('onboarding.getStarted'));
      await tester.ensureVisible(getStartedButton);
      await tester.pumpAndSettle();
      await tester.tap(getStartedButton);
      await tester.pumpAndSettle();

      // Should now show add library step
      expect(find.text('Add Your Music Library'), findsOneWidget);
      expect(find.byKey(const Key('onboarding.addFolder')), findsOneWidget);
    });
  });

  group('Library Screen Tests', () {
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({
        'onboarding_complete': true,
      });
      prefs = await SharedPreferences.getInstance();
    });

    testWidgets('Library shows empty state when no folders configured', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: const CartoMixApp(),
        ),
      );
      await tester.pumpAndSettle();

      // Should show library screen with empty state
      expect(find.byKey(const Key('library.screen')), findsOneWidget);
      expect(find.text('No Music Folders Added'), findsOneWidget);
    });

    testWidgets('Library toolbar is present', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: const CartoMixApp(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('library.toolbar')), findsOneWidget);
      expect(find.byKey(const Key('library.search')), findsOneWidget);
    });

    testWidgets('Navigation rail shows all destinations', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: const CartoMixApp(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Library'), findsOneWidget);
      expect(find.text('Set Builder'), findsOneWidget);
      expect(find.text('Graph'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);
    });
  });
}
