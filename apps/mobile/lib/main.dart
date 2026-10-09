import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/nurturio_app.dart';
import 'app/theme.dart';
import 'core/app_controller.dart';
import 'core/content.dart';
import 'core/database.dart';
import 'core/services.dart';
import 'features/settings/settings_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MaterialApp(
      theme: nurturioTheme(),
      home: const Scaffold(body: Center(child: CircularProgressIndicator())),
    ),
  );
  try {
    final library = await ContentLibrary.load();
    final controller = await AppController.load(library, SaveDatabase());
    if (kDebugMode && const bool.fromEnvironment('DEMO_MODE')) {
      controller.seedDemo();
    }
    try {
      await CloudService.initialize();
    } catch (_) {
      controller.error = 'Cloud is unavailable. Your local village is ready.';
    }
    try {
      await reminders.initialize();
    } catch (_) {
      /* Permission and notification availability are optional. */
    }
    runApp(
      ProviderScope(
        overrides: [controllerProvider.overrideWith((ref) => controller)],
        child: const NurturioApp(),
      ),
    );
  } catch (_) {
    runApp(
      MaterialApp(
        theme: nurturioTheme(),
        home: Scaffold(
          body: SafeArea(
            child: PageBody(
              children: [
                const SizedBox(height: 60),
                const Text('Your village could not open.'),
                const SizedBox(height: 12),
                const Text(
                  'Your existing save has not been erased. Close and reopen the app to retry. If this continues, export your device backup before reinstalling.',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
