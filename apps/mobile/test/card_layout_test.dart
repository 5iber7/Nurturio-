import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nurturio/app/nurturio_app.dart';
import 'package:nurturio/core/app_controller.dart';
import 'package:nurturio/core/content.dart';
import 'package:nurturio/core/database.dart';

void main() {
  testWidgets('all main cards and controls fit 320px with doubled text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 760);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      tester.platformDispatcher.clearTextScaleFactorTestValue();
    });
    final db = SaveDatabase.forTesting(NativeDatabase.memory());
    final c = AppController(await ContentLibrary.load(), db);
    c.settings['onboarded'] = true;
    c.settings['motion'] = false;
    c.settings['sound'] = false;
    c.start(c.library.quest('honey-1'));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [controllerProvider.overrideWith((ref) => c)],
        child: const NurturioApp(),
      ),
    );
    await tester.pump();
    for (final route in [
      '/village',
      '/collection',
      '/learn',
      '/settings',
      '/garden',
      '/buzz',
      '/quest/honey-1',
    ]) {
      debugPrint('Checking large-text layout: $route');
      GoRouter.of(tester.element(find.byType(Scaffold).first)).go(route);
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.takeException(), null, reason: route);
      for (var i = 0; i < 100; i++) {
        final scrollable = tester.state<ScrollableState>(
          find.byType(Scrollable).first,
        );
        if (scrollable.position.pixels >= scrollable.position.maxScrollExtent) {
          break;
        }
        scrollable.position.jumpTo(
          (scrollable.position.pixels + 250).clamp(
            0,
            scrollable.position.maxScrollExtent,
          ),
        );
        await tester.pump(const Duration(milliseconds: 200));
        expect(tester.takeException(), null, reason: '$route, scroll $i');
      }
    }
    final q = c.library.quest('honey-1');
    for (final item in q.items) {
      c.recordAction(q, item.id);
    }
    await tester.pump(const Duration(milliseconds: 300));
    final position = tester
        .state<ScrollableState>(find.byType(Scrollable).first)
        .position;
    position.jumpTo(position.maxScrollExtent);
    await tester.pump();
    expect(tester.takeException(), null, reason: 'large-text learning check');
    await tester.pumpWidget(const SizedBox());
    await c.flush();
    await db.close();
  });
}
