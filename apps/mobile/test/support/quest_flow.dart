import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/native.dart';
import 'package:nurturio/app/nurturio_app.dart';
import 'package:nurturio/core/app_controller.dart';
import 'package:nurturio/core/content.dart';
import 'package:nurturio/core/database.dart';
import 'package:nurturio/game/engine/process_engine.dart';

class FlowClock implements Clock {
  DateTime value = DateTime.utc(2026, 10, 9);
  @override
  DateTime now() => value;
}

Future<void> fullQuestFlow(WidgetTester tester) async {
  final db = SaveDatabase.forTesting(NativeDatabase.memory()),
      clock = FlowClock();
  final c = AppController(await ContentLibrary.load(), db, clock: clock);
  c.settings['onboarded'] = true;
  c.settings['motion'] = false;
  c.settings['sound'] = false;
  await tester.pumpWidget(
    ProviderScope(
      overrides: [controllerProvider.overrideWith((ref) => c)],
      child: const NurturioApp(),
    ),
  );
  await tester.pump(const Duration(milliseconds: 300));
  Future<void> tap(Finder finder) async {
    await tester.scrollUntilVisible(
      finder,
      150,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(finder);
    await tester.pump();
    await tester.tap(finder);
    await tester.pump(const Duration(milliseconds: 300));
  }

  for (var index = 0; index < 32; index++) {
    final q = c.nextQuest!;
    await tap(find.byTooltip('Continue learning'));
    await tap(find.text('Let’s try it'));
    if (q.template == 'pour' || q.template == 'timing') {
      for (var i = 0; i < 5; i++) {
        await tap(
          find.widgetWithText(
            FilledButton,
            q.template == 'pour' ? 'Pour a little' : 'Turn steadily',
          ),
        );
      }
    } else {
      for (final item in q.items) {
        await tap(find.byKey(ValueKey('quest-item-${item.id}')));
        await tap(find.byKey(ValueKey('quest-target-${q.id}-${item.target}')));
      }
    }
    if (q.waitSeconds > 0) {
      expect(c.process(q).status, ProcessStatus.waiting);
      clock.value = clock.value.add(const Duration(seconds: 100));
      c.refresh();
      await tester.pump();
    }
    await tap(find.widgetWithText(OutlinedButton, q.answers[q.correct]));
    expect(c.completed.contains(q.id), true, reason: q.id);
    expect(find.text('A new discovery!'), findsOneWidget);
    expect(tester.takeException(), null);
    await tester.tap(find.byTooltip('Back'));
    await tester.pump(const Duration(milliseconds: 300));
  }
  expect(c.completed.length, 32);
  expect(c.coins, 320);
  await c.flush();
  final restored = await AppController.load(c.library, db);
  expect(restored.completed.length, 32);
  await tester.pumpWidget(const SizedBox());
  await db.close();
}
