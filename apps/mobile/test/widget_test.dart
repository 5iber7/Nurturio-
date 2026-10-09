// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/native.dart';
import 'package:nurturio/core/content.dart';
import 'package:nurturio/core/database.dart';
import 'package:nurturio/core/app_controller.dart';
import 'package:nurturio/app/nurturio_app.dart';

void main() {
  testWidgets('onboarding opens village with all four worlds', (
    WidgetTester tester,
  ) async {
    final db = SaveDatabase.forTesting(NativeDatabase.memory());
    final c = AppController(await ContentLibrary.load(), db);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [controllerProvider.overrideWith((ref) => c)],
        child: const NurturioApp(),
      ),
    );
    await tester.pump();
    expect(find.text('Learn by growing.'), findsOneWidget);
    await tester.ensureVisible(find.text('Next'));
    await tester.tap(find.text('Next'));
    await tester.pump();
    await tester.ensureVisible(find.text('Next'));
    await tester.tap(find.text('Next'));
    await tester.pump();
    await tester.scrollUntilVisible(
      find.text('Start my village'),
      150,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(find.text('Start my village'));
    await tester.pump();
    await tester.tap(find.text('Start my village'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('A little care.\nA world of discovery.'), findsOneWidget);
    expect(c.library.topics.length, 4);
    await tester.pumpWidget(const SizedBox());
    await c.flush();
    await db.close();
  });
}
