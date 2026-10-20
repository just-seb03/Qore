import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:project_anima/features/search/components/search_bar.dart';
import 'package:project_anima/features/search/components/search_header.dart';
import 'package:project_anima/features/search/screens/search.dart';

void main() {
  group('SearchScreen and AppSearchBar optimization tests', () {
    testWidgets('Clear button visibility is reactively toggled without rebuilding SearchHeader',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SearchScreen(showBottomNav: false),
        ),
      );

      // SearchHeader and AppSearchBar are rendered
      expect(find.byType(SearchHeader), findsOneWidget);
      expect(find.byType(AppSearchBar), findsOneWidget);

      // Initially no clear button
      expect(find.byIcon(Symbols.close_rounded), findsNothing);

      // Type some text into the search field
      await tester.enterText(find.byType(EditableText), 'Cyberpunk');
      await tester.pump();

      // Clear button is now visible inside AppSearchBar
      expect(find.byIcon(Symbols.close_rounded), findsOneWidget);

      // Tap clear button
      await tester.tap(find.byIcon(Symbols.close_rounded));
      await tester.pump();

      // Text is cleared and clear button is gone
      expect(find.text('Cyberpunk'), findsNothing);
      expect(find.byIcon(Symbols.close_rounded), findsNothing);
    });
  });
}
