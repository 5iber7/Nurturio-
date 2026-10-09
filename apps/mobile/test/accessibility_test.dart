import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/native.dart';
import 'package:nurturio/app/nurturio_app.dart';
import 'package:nurturio/core/app_controller.dart';
import 'package:nurturio/core/content.dart';
import 'package:nurturio/core/database.dart';

void main() {
  testWidgets('village supports a narrow phone and large device text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 1.8;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      tester.platformDispatcher.clearTextScaleFactorTestValue();
    });
    final db = SaveDatabase.forTesting(NativeDatabase.memory());
    final c = AppController(await ContentLibrary.load(), db);
    c.settings['onboarded'] = true;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [controllerProvider.overrideWith((ref) => c)],
        child: const NurturioApp(),
      ),
    );
    await tester.pump();
    expect(tester.takeException(), null);
    await tester.pumpWidget(const SizedBox());
    await c.flush();
    await db.close();
  });
}
