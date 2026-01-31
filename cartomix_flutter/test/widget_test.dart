import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cartomix_flutter/main.dart';
import 'package:cartomix_flutter/core/providers/app_state.dart';
import 'package:cartomix_flutter/ui/screens/onboarding_screen.dart';
import 'package:cartomix_flutter/ui/screens/main_screen.dart';
import 'package:cartomix_flutter/ui/screens/library_screen.dart';
import 'package:cartomix_flutter/ui/screens/set_builder_screen.dart';
import 'package:cartomix_flutter/ui/screens/graph_screen.dart';
import 'package:cartomix_flutter/ui/screens/settings_screen.dart';

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

    testWidgets('Onboarding welcome step shows feature list', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: const CartoMixApp(),
        ),
      );
      await tester.pumpAndSettle();

      // Check all three feature items are present
      expect(find.text('Analyze Your Tracks'), findsOneWidget);
      expect(find.text('Smart Transitions'), findsOneWidget);
      expect(find.text('Build Perfect Sets'), findsOneWidget);

      // Check descriptions
      expect(find.text('AI-powered BPM, key, and energy detection'), findsOneWidget);
      expect(find.text('Find harmonically compatible tracks instantly'), findsOneWidget);
      expect(find.text('Plan your DJ sets with energy flow visualization'), findsOneWidget);
    });

    testWidgets('Onboarding shows step indicator', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: const CartoMixApp(),
        ),
      );
      await tester.pumpAndSettle();

      // Step indicator should have 4 dots (AnimatedContainers)
      // First one should be active (wider)
      final stepIndicators = find.byType(AnimatedContainer);
      expect(stepIndicators, findsWidgets);
    });

    testWidgets('Add library step has skip option', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: const CartoMixApp(),
        ),
      );
      await tester.pumpAndSettle();

      // Navigate to add library step
      final getStartedButton = find.byKey(const Key('onboarding.getStarted'));
      await tester.ensureVisible(getStartedButton);
      await tester.pumpAndSettle();
      await tester.tap(getStartedButton);
      await tester.pumpAndSettle();

      // Should show skip option
      expect(find.text('Skip for now'), findsOneWidget);
    });

    testWidgets('Add library step has back button', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: const CartoMixApp(),
        ),
      );
      await tester.pumpAndSettle();

      // Navigate to add library step
      final getStartedButton = find.byKey(const Key('onboarding.getStarted'));
      await tester.ensureVisible(getStartedButton);
      await tester.pumpAndSettle();
      await tester.tap(getStartedButton);
      await tester.pumpAndSettle();

      // Should show back button
      expect(find.text('Back'), findsOneWidget);

      // Tap back to return to welcome
      await tester.tap(find.text('Back'));
      await tester.pumpAndSettle();

      // Should be back on welcome screen
      expect(find.text('Welcome to CartoMix'), findsOneWidget);
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

    testWidgets('Search field accepts input', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: const CartoMixApp(),
        ),
      );
      await tester.pumpAndSettle();

      // Find search field and enter text
      final searchField = find.byKey(const Key('library.search'));
      await tester.enterText(searchField, 'test query');
      await tester.pumpAndSettle();

      // Verify text is entered
      expect(find.text('test query'), findsOneWidget);
    });

    testWidgets('Library empty state shows actionable button', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: const CartoMixApp(),
        ),
      );
      await tester.pumpAndSettle();

      // Should show empty state with action
      expect(find.text('Add your music folders in Settings to get started'), findsOneWidget);
      expect(find.byKey(const Key('library.openSettings')), findsOneWidget);
    });
  });

  group('Main Screen Navigation Tests', () {
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({
        'onboarding_complete': true,
      });
      prefs = await SharedPreferences.getInstance();
    });

    testWidgets('Main screen shows title bar and footer', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: const CartoMixApp(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('main.screen')), findsOneWidget);
      expect(find.byKey(const Key('main.titleBar')), findsOneWidget);
      expect(find.byKey(const Key('main.footer')), findsOneWidget);
    });

    testWidgets('Footer shows version and connection status', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: const CartoMixApp(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('v0.13.0'), findsOneWidget);
      expect(find.text('Native Backend Connected'), findsOneWidget);
    });

    testWidgets('Navigation rail shows CartoMix logo', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: const CartoMixApp(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('CartoMix'), findsWidgets);
    });

    testWidgets('Tapping Set Builder shows Set Builder screen', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: const CartoMixApp(),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Set Builder nav item
      await tester.tap(find.text('Set Builder'));
      await tester.pumpAndSettle();

      // Should show Set Builder screen content
      expect(find.byType(SetBuilderScreen), findsOneWidget);
    });

    testWidgets('Tapping Graph shows Graph screen', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: const CartoMixApp(),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Graph nav item
      await tester.tap(find.text('Graph'));
      await tester.pumpAndSettle();

      // Should show Graph screen content
      expect(find.byType(GraphScreen), findsOneWidget);
    });

    testWidgets('Tapping Settings shows Settings screen', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: const CartoMixApp(),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Settings nav item
      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();

      // Should show Settings screen content
      expect(find.byType(SettingsScreen), findsOneWidget);
    });

    testWidgets('Navigating back to Library works', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: const CartoMixApp(),
        ),
      );
      await tester.pumpAndSettle();

      // Navigate to Settings
      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();
      expect(find.byType(SettingsScreen), findsOneWidget);

      // Navigate back to Library
      await tester.tap(find.text('Library'));
      await tester.pumpAndSettle();
      expect(find.byType(LibraryScreen), findsOneWidget);
    });
  });

  group('Theme Tests', () {
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({
        'onboarding_complete': true,
      });
      prefs = await SharedPreferences.getInstance();
    });

    testWidgets('App uses dark theme', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: const CartoMixApp(),
        ),
      );
      await tester.pumpAndSettle();

      // Check theme brightness
      final MaterialApp app = tester.widget(find.byType(MaterialApp));
      expect(app.theme?.brightness, Brightness.dark);
    });

    testWidgets('App title is CartoMix', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: const CartoMixApp(),
        ),
      );
      await tester.pumpAndSettle();

      final MaterialApp app = tester.widget(find.byType(MaterialApp));
      expect(app.title, 'CartoMix');
    });
  });

  group('Graph Screen Tests', () {
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({
        'onboarding_complete': true,
      });
      prefs = await SharedPreferences.getInstance();
    });

    testWidgets('Graph screen shows empty state when no tracks', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: const CartoMixApp(),
        ),
      );
      await tester.pumpAndSettle();

      // Navigate to Graph
      await tester.tap(find.text('Graph'));
      await tester.pumpAndSettle();

      // Should show empty state
      expect(find.byType(GraphScreen), findsOneWidget);
      expect(find.text('No Tracks to Visualize'), findsOneWidget);
    });

    testWidgets('Graph screen has toolbar with controls', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: const CartoMixApp(),
        ),
      );
      await tester.pumpAndSettle();

      // Navigate to Graph
      await tester.tap(find.text('Graph'));
      await tester.pumpAndSettle();

      // Should show toolbar elements
      expect(find.text('Min Score:'), findsOneWidget);
      expect(find.text('Set Only'), findsOneWidget);
      expect(find.byType(Slider), findsOneWidget);
      expect(find.byType(Checkbox), findsOneWidget);
    });

    testWidgets('Graph screen has sidebar with stats and legend', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: const CartoMixApp(),
        ),
      );
      await tester.pumpAndSettle();

      // Navigate to Graph
      await tester.tap(find.text('Graph'));
      await tester.pumpAndSettle();

      // Should show sidebar elements
      expect(find.text('Graph Stats'), findsOneWidget);
      expect(find.text('Legend'), findsOneWidget);
      expect(find.text('Nodes'), findsOneWidget);
      expect(find.text('Visible Edges'), findsOneWidget);
    });

    testWidgets('Graph screen shows instruction when no node selected', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: const CartoMixApp(),
        ),
      );
      await tester.pumpAndSettle();

      // Navigate to Graph
      await tester.tap(find.text('Graph'));
      await tester.pumpAndSettle();

      // Should show instruction text
      expect(find.text('Click a node to view details'), findsOneWidget);
    });

    testWidgets('Graph screen has zoom controls', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: const CartoMixApp(),
        ),
      );
      await tester.pumpAndSettle();

      // Navigate to Graph
      await tester.tap(find.text('Graph'));
      await tester.pumpAndSettle();

      // Should show zoom controls
      expect(find.byIcon(Icons.zoom_in), findsOneWidget);
      expect(find.byIcon(Icons.zoom_out), findsOneWidget);
      expect(find.byIcon(Icons.center_focus_strong), findsOneWidget);
      expect(find.text('100%'), findsOneWidget);
    });
  });

  group('State Persistence Tests', () {
    testWidgets('Onboarding state persists across restarts', (WidgetTester tester) async {
      // First launch - complete onboarding
      SharedPreferences.setMockInitialValues({});
      var prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: const CartoMixApp(),
        ),
      );
      await tester.pumpAndSettle();

      // Should show onboarding
      expect(find.byType(OnboardingScreen), findsOneWidget);

      // Simulate completing onboarding by setting the preference
      await prefs.setBool('onboarding_complete', true);

      // Simulate app restart with persisted data
      SharedPreferences.setMockInitialValues({
        'onboarding_complete': true,
      });
      prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: const CartoMixApp(),
        ),
      );
      await tester.pumpAndSettle();

      // Should now show main screen
      expect(find.byType(MainScreen), findsOneWidget);
    });
  });
}
