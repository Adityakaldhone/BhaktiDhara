import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nitya_aarti/presentation/screens/panchang_app_dashboard_screen.dart';

void main() {
  group('Sampurna Panchang & Rashifal Standalone App Tests', () {
    testWidgets('Renders all 5 navigation destinations in PanchangAppDashboardScreen', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: PanchangAppDashboardScreen(),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      // Verify bottom navigation bar exists
      expect(find.byType(NavigationBar), findsOneWidget);

      // Verify the 5 navigation destinations exist
      expect(find.byType(NavigationDestination), findsNWidgets(5));

      // Tap on More (5th tab)
      await tester.tap(find.byIcon(Icons.more_horiz_rounded));
      await tester.pump(const Duration(milliseconds: 100));

      // Verify More screen items
      expect(find.textContaining('100% Authentic Vedic Astrology'), findsOneWidget);
    });
  });
}

