import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:nurturio/core/app_controller.dart';
import 'package:nurturio/core/content.dart';
import 'package:nurturio/core/database.dart';

import 'process_engine_test.dart' show TestClock;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'plant growth requires care, persists, and grants one plant card',
    () async {
      final clock = TestClock(),
          library = await ContentLibrary.load(),
          db = SaveDatabase.forTesting(NativeDatabase.memory());
      final c = AppController(library, db, clock: clock);
      c.plant(0, 'basil');
      clock.advance(100);
      c.refresh();
      expect(c.harvestBed(0), false);
      c.waterBed(0);
      expect(c.harvestBed(0), true);
      expect(c.harvestBed(0), false);
      await c.flush();
      final restored = await AppController.load(library, db);
      expect(restored.plantCards, {'basil'});
      expect(restored.beds[0]!.plantId, 'basil');
      await db.close();
    },
  );
  test('all 32 quests complete, saves reload, rewards cannot repeat', () async {
    final library = await ContentLibrary.load(),
        clock = TestClock(),
        db = SaveDatabase.forTesting(NativeDatabase.memory());
    final c = AppController(library, db, clock: clock);
    for (final t in library.topics) {
      for (final q in t.quests) {
        expect(c.available(q), true);
        c.start(q);
        for (var i = 0; i < c.targetActions(q); i++) {
          c.recordAction(q, 'action-$i');
        }
        clock.advance(20);
        expect(c.claim(q, q.correct), true);
        expect(c.claim(q, q.correct), false);
      }
    }
    expect(c.completed.length, 32);
    expect(c.xp, 960);
    expect(c.coins, 320);
    expect(c.buy('flower-path', 30), true);
    expect(c.buy('flower-path', 30), false);
    expect(c.buy('unknown', 10000), false);
    await c.flush();
    final restored = await AppController.load(library, db);
    expect(restored.completed, c.completed);
    expect(restored.coins, 290);
    expect(restored.decorations, {'flower-path'});
    await db.close();
  });
  test('locked quest and wrong answer cannot award progress', () async {
    final library = await ContentLibrary.load(),
        db = SaveDatabase.forTesting(NativeDatabase.memory());
    final c = AppController(library, db);
    final locked = library.quest('honey-2');
    c.start(locked);
    expect(c.doneActions(locked), 0);
    expect(c.claim(locked, locked.correct), false);
    expect(c.coins, 0);
    await c.flush();
    await db.close();
  });
  test('same interaction is saved once and interrupted play resumes', () async {
    final library = await ContentLibrary.load(),
        db = SaveDatabase.forTesting(NativeDatabase.memory());
    final c = AppController(library, db), q = library.quest('honey-1');
    c.start(q);
    c.recordAction(q, 'item-0');
    c.recordAction(q, 'item-0');
    await c.flush();
    final restored = await AppController.load(library, db);
    expect(restored.doneActions(q), 1);
    expect(restored.process(q).actions, 1);
    await db.close();
  });
}
