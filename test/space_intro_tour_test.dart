/// File: space_intro_tour_test.dart
/// Description: Widget test suite validating Space first-time onboarding tour overlay,
/// moon_stars icon badge, 3-step text transitions, downward arrow bounce cue, and exit persistence.
library;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:project_anima/controls/navigation_controller.dart';
import 'package:project_anima/core/database/dao/app_metadata_dao.dart';
import 'package:project_anima/core/localization/app_localizations.dart';
import 'package:project_anima/core/theme/controllers/theme_controller.dart';
import 'package:project_anima/core/theme/theme.dart';
import 'package:project_anima/features/home/components/space_intro_overlay.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  setUp(() {
    NavigationController.instance.reset();
    AppMetadataDao.instance.setMockSpaceIntroSeen(null);
  });

  tearDown(() {
    ThemeController.instance.setDarkMode(true);
  });

  Widget buildTestHost({
    bool forceShow = true,
    VoidCallback? onDismissed,
  }) {
    return MaterialApp(
      locale: const Locale('es'),
      supportedLocales: const [
        Locale('es'),
        Locale('en'),
      ],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: Scaffold(
        body: Stack(
          children: [
            const Center(child: Text('Space Screen Underneath')),
            SpaceIntroOverlay(
              forceShow: forceShow,
              onDismissed: onDismissed,
            ),
          ],
        ),
      ),
    );
  }

  group('SpaceIntroOverlay Staged Steps and Iconography Tests', () {
    testWidgets('renders moon_stars badge, welcome text, and down arrow on step 0', (tester) async {
      NavigationController.instance.setIndex(NavigationTab.home.index);

      await tester.pumpWidget(buildTestHost(forceShow: true));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // 1. Native Moon Stars icon badge
      expect(find.byIcon(Symbols.moon_stars_rounded), findsOneWidget);

      // 2. Initial Step 0 text
      expect(
        find.text('Bienvenido a Space, el lugar para tu contenido favorito'),
        findsOneWidget,
      );

      // 3. Downward pointing chevron arrow
      expect(find.byIcon(Icons.keyboard_arrow_down_rounded), findsOneWidget);
    });

    testWidgets('transitions through step 1 and step 2 on tap, then dismisses on step 3', (tester) async {
      NavigationController.instance.setIndex(NavigationTab.home.index);
      bool dismissed = false;

      await tester.pumpWidget(
        buildTestHost(
          forceShow: true,
          onDismissed: () => dismissed = true,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(
        find.text('Bienvenido a Space, el lugar para tu contenido favorito'),
        findsOneWidget,
      );

      // --- Tap 1: Advance to Step 1 ---
      await tester.tap(find.byKey(const ValueKey('space_intro_tap_target')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(
        find.textContaining('Aquí todo el contenido que tengas guardado con un'),
        findsOneWidget,
      );
      expect(
        find.textContaining('aparecerá anclado'),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.favorite_rounded), findsOneWidget);
      final heartIcon = tester.widget<Icon>(find.byIcon(Icons.favorite_rounded));
      expect(heartIcon.color, AppColors.accent);
      expect(find.byIcon(Symbols.moon_stars_rounded), findsOneWidget);
      expect(find.byIcon(Icons.keyboard_arrow_down_rounded), findsOneWidget);

      // --- Tap 2: Advance to Step 2 ---
      await tester.tap(find.byKey(const ValueKey('space_intro_tap_target')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(
        find.text('Así tendrás acceso directo a la música que más amas'),
        findsOneWidget,
      );
      expect(find.byIcon(Symbols.moon_stars_rounded), findsOneWidget);
      expect(find.byIcon(Icons.keyboard_arrow_down_rounded), findsOneWidget);

      // --- Tap 3: Transformation exit and dismissal ---
      await tester.tap(find.byKey(const ValueKey('space_intro_tap_target')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(dismissed, isTrue);
      expect(AppMetadataDao.instance.hasSeenSpaceIntroSync, isTrue);
      expect(
        find.text('Así tendrás acceso directo a la música que más amas'),
        findsNothing,
      );
    });

    testWidgets('does not render when hasSeenSpaceIntroSync is true', (tester) async {
      NavigationController.instance.setIndex(NavigationTab.home.index);
      AppMetadataDao.instance.setMockSpaceIntroSeen(true);

      await tester.pumpWidget(buildTestHost(forceShow: false));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byIcon(Symbols.moon_stars_rounded), findsNothing);
      expect(find.byKey(const ValueKey('space_intro_tap_target')), findsNothing);
    });

    testWidgets('triggers smoothly when switching navigation tab to Space', (tester) async {
      // Start on tab 1 (Search)
      NavigationController.instance.setIndex(1);

      await tester.pumpWidget(buildTestHost(forceShow: true));
      await tester.pump();

      // Not active yet because user is on Search tab
      expect(find.byIcon(Symbols.moon_stars_rounded), findsNothing);

      // User switches to Space tab (0)
      NavigationController.instance.setIndex(NavigationTab.home.index);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Now active on Space
      expect(find.byIcon(Symbols.moon_stars_rounded), findsOneWidget);
      expect(
        find.text('Bienvenido a Space, el lugar para tu contenido favorito'),
        findsOneWidget,
      );
    });

    testWidgets('uses white background scrim in light mode and black in dark mode', (tester) async {
      NavigationController.instance.setIndex(NavigationTab.home.index);

      // Light mode test
      ThemeController.instance.setDarkMode(false);
      await tester.pumpWidget(buildTestHost(forceShow: true));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final lightContainer = tester.widget<Container>(
        find.descendant(
          of: find.byKey(const ValueKey('space_intro_tap_target')),
          matching: find.byType(Container),
        ).first,
      );
      final lightColor = lightContainer.color!;
      expect(lightColor.r, greaterThan(0.9)); // White-based scrim

      // Dark mode test
      ThemeController.instance.setDarkMode(true);
      await tester.pumpWidget(buildTestHost(forceShow: true));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final darkContainer = tester.widget<Container>(
        find.descendant(
          of: find.byKey(const ValueKey('space_intro_tap_target')),
          matching: find.byType(Container),
        ).first,
      );
      final darkColor = darkContainer.color!;
      expect(darkColor.r, lessThan(0.1)); // Black-based scrim
    });
  });
}
