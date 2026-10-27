import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hershield_app/data/app_database.dart';
import 'package:hershield_app/screens/safevoice_screens.dart';
import 'package:hershield_app/state.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AppDatabase.instance.init();
  });

  testWidgets('PrivacyScreen renders cleanly without errors', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final container = ProviderContainer();
    container.read(draftProvider.notifier).patch((x) => x.copyWith(
          category: 'Harassment',
          description: 'This is a test description that has more than 20 characters.',
          location: 'Addis Ababa Area (9.020° N, 38.740° E)',
          date: DateTime(2026, 10, 1),
        ));

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: PrivacyScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Your privacy, your choice'), findsOneWidget);
    expect(find.text('Review your report'), findsOneWidget);
    expect(find.text('Anonymous report'), findsOneWidget);
    expect(find.text('Confidential report'), findsOneWidget);
  });
}
