import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nurturio/app/nurturio_app.dart';
import 'package:nurturio/core/app_controller.dart';
import 'package:nurturio/core/content.dart';
import 'package:nurturio/core/database.dart';

void main() {
  testWidgets(
    'appearance changes immediately, persists and follows the device',
    (tester) async {
      final db = SaveDatabase.forTesting(NativeDatabase.memory());
      final library = await ContentLibrary.load();
      final c = AppController(library, db)..settings['onboarded'] = true;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [controllerProvider.overrideWith((ref) => c)],
          child: const NurturioApp(),
        ),
      );
      await tester.pump();
      await tester.tap(find.byTooltip('Settings'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Use device setting'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Dark').last);
      await tester.pumpAndSettle();
      expect(
        tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
        ThemeMode.dark,
      );
      expect(
        Theme.of(tester.element(find.byType(Scaffold).last)).brightness,
        Brightness.dark,
      );
      await c.flush();
      final restored = await AppController.load(library, db);
      expect(restored.settings['theme'], 'dark');
      c.setSetting('theme', 'light');
      await tester.pumpAndSettle();
      expect(
        Theme.of(tester.element(find.byType(Scaffold).last)).brightness,
        Brightness.light,
      );
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
      c.setSetting('theme', 'system');
      await tester.pumpAndSettle();
      expect(
        Theme.of(tester.element(find.byType(Scaffold).last)).brightness,
        Brightness.dark,
      );
      tester.platformDispatcher.clearPlatformBrightnessTestValue();
      await tester.pumpWidget(const SizedBox());
      await c.flush();
      await db.close();
    },
  );
}
