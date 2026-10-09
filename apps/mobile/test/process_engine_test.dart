import 'package:flutter_test/flutter_test.dart';
import 'package:nurturio/game/engine/process_engine.dart';

class TestClock implements Clock {
  DateTime value = DateTime.utc(2026, 10, 9);
  @override
  DateTime now() => value;
  void advance(int seconds) => value = value.add(Duration(seconds: seconds));
}

void main() {
  test('wait expires to ready and completion is idempotent', () {
    final clock = TestClock(), engine = ProcessEngine(TestClock());
    final e = ProcessEngine(clock), p = ProcessInstance(questId: 'honey-1');
    e.start(p);
    e.finishInteraction(p, 10);
    expect(p.status, ProcessStatus.waiting);
    clock.advance(9);
    expect(e.complete(p), false);
    clock.advance(1);
    expect(e.complete(p), true);
    expect(e.complete(p), false);
    expect(engine.unlocked(['honey-1'], {}), false);
  });
  test(
    'serialized wait survives restart and a rollback does not finish it',
    () {
      final clock = TestClock(), p = ProcessInstance(questId: 'garden-5');
      final e = ProcessEngine(clock);
      e.start(p);
      e.finishInteraction(p, 10);
      final restored = ProcessInstance.fromJson(p.toJson());
      clock.advance(-20);
      e.refresh(restored);
      expect(restored.status, ProcessStatus.waiting);
      clock.advance(30);
      e.refresh(restored);
      expect(restored.status, ProcessStatus.ready);
      expect(restored.contentVersion, '1.0.0');
    },
  );
  test('illegal transitions do not award or skip the interactive stage', () {
    final clock = TestClock(), p = ProcessInstance(questId: 'olive-1');
    final e = ProcessEngine(clock);
    expect(e.complete(p), false);
    e.finishInteraction(p, 0);
    expect(p.status, ProcessStatus.available);
    e.start(p);
    e.finishInteraction(p, 0);
    expect(e.complete(p), true);
    expect(e.speedUp(p), false);
  });
}
