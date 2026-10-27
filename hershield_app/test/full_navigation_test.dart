import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hershield_app/data/app_database.dart';
import 'package:hershield_app/router.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AppDatabase.instance.init();
  });

  testWidgets('Full report navigation from /report to /report/privacy', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp.router(
          routerConfig: appRouter,
        ),
      ),
    );
    await tester.pumpAndSettle();

    appRouter.go('/report');
    await tester.pumpAndSettle();

    expect(find.text('Your voice matters.'), findsOneWidget);

    // Tap "Start a report"
    final startBtn = find.text('Start a report');
    expect(startBtn, findsOneWidget);
    await tester.tap(startBtn);
    await tester.pumpAndSettle();

    // Now on Incident screen
    expect(find.text('Harassment'), findsOneWidget);
    await tester.tap(find.text('Harassment'));
    await tester.pumpAndSettle();

    // Tap "Continue to details"
    final continueBtn = find.text('Continue to details');
    expect(continueBtn, findsOneWidget);
    await tester.tap(continueBtn);
    await tester.pumpAndSettle();

    // Now on Details screen
    expect(find.text('Share at your own pace'), findsOneWidget);
    final field = find.byType(TextField);
    expect(field, findsOneWidget);
    await tester.enterText(field, 'This is a long test incident description with more than 20 characters to satisfy validation.');
    await tester.pumpAndSettle();

    // Tap "Continue to privacy & review"
    final privacyBtn = find.text('Continue to privacy & review');
    expect(privacyBtn, findsOneWidget);
    await tester.tap(privacyBtn);
    await tester.pumpAndSettle();

    // Verify PrivacyScreen loaded cleanly
    expect(find.text('Your privacy, your choice'), findsOneWidget);
    expect(find.text('Review your report'), findsOneWidget);
    expect(find.text('Anonymous report'), findsOneWidget);
    expect(find.text('Confidential report'), findsOneWidget);
  });
}
