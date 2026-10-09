import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nurturio/core/app_controller.dart';
import 'package:nurturio/core/content.dart';
import 'package:nurturio/core/database.dart';
import 'package:nurturio/game/templates/quest_play.dart';

void main() {
  testWidgets('choices require an item, reject mistakes and cannot act twice', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final db = SaveDatabase.forTesting(NativeDatabase.memory());
    final c = AppController(await ContentLibrary.load(), db);
    c.settings['motion'] = false;
    c.settings['sound'] = false;
    final q = c.library.quest('honey-1');
    c.start(q);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [controllerProvider.overrideWith((ref) => c)],
        child: MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: QuestPlay(quest: q, controller: c),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(
      tester
          .getSemantics(
            find.descendant(
              of: find.byKey(ValueKey('quest-item-${q.items.first.id}')),
              matching: find.byType(OutlinedButton),
            ),
          )
          .getSemanticsData()
          .label,
      q.items.first.label,
    );
    Future<void> tap(String key) async {
      final finder = find.byKey(ValueKey(key));
      await tester.ensureVisible(finder);
      await tester.pump();
      await tester.tap(finder);
      await tester.pump();
    }

    final first = q.items.first;
    await tap('quest-target-${q.id}-${first.target}');
    expect(c.doneActions(q), 0);
    await tap('quest-item-${first.id}');
    await tap('quest-target-${q.id}-${q.items[1].target}');
    expect(c.doneActions(q), 0);
    expect(find.text('Try another place for ${first.label}.'), findsOneWidget);
    await tap('quest-target-${q.id}-${first.target}');
    expect(c.doneActions(q), 1);
    await tap('quest-target-${q.id}-${first.target}');
    expect(c.doneActions(q), 1);
    expect(find.byKey(ValueKey('quest-item-${first.id}')), findsOneWidget);
    expect(tester.takeException(), null);
    await tester.pumpWidget(const SizedBox());
    semantics.dispose();
    await c.flush();
    await db.close();
  });
}
