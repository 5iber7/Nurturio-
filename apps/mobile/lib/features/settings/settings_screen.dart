import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../app/theme.dart';
import '../../app/selection_field.dart';
import '../../core/app_controller.dart';
import '../../core/services.dart';
import '../../core/audio_service.dart';

final reminders = ReminderService();

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = ref.watch(controllerProvider);
    return Scaffold(
      appBar: AppBar(
        leading: const VillageBackButton(),
        title: const Text('Make yourself comfortable'),
      ),
      body: PageBody(
        children: [
          Text(
            'Your village, your pace.',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 20),
          SelectionField<String>(
            value: c.settings['theme'] ?? 'system',
            label: 'Appearance',
            options: const [
              ('system', 'Use device setting'),
              ('light', 'Light'),
              ('dark', 'Dark'),
            ],
            onChanged: (v) => c.setSetting('theme', v),
          ),
          const SizedBox(height: 16),
          SelectionField<String>(
            value: c.settings['reading'],
            label: 'Reading level',
            options: const [('Simple', 'Simple'), ('Explorer', 'Explorer')],
            onChanged: (v) => c.setSetting('reading', v),
          ),
          const SizedBox(height: 16),
          SelectionField<String>(
            value: c.settings['pace'],
            label: 'Game pace',
            options: const [
              ('guided', 'Guided · short waits'),
              ('garden', 'Garden pace · longer waits'),
            ],
            onChanged: (v) => c.setSetting('pace', v),
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Reduced motion'),
            subtitle: const Text(
              'Gentler scenes and relaxed timing challenges',
            ),
            value: c.settings['motion'] != true,
            onChanged: (v) => c.setSetting('motion', !v),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Interactive 3D scenes'),
            subtitle: const Text(
              'Switch off for lighter visuals on older devices',
            ),
            value: c.settings['scene3d'] != false,
            onChanged: (v) => c.setSetting('scene3d', v),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Nature music'),
            value: c.settings['music'] == true,
            onChanged: (v) {
              c.setSetting('music', v);
              audio.setMusic(v);
            },
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Action sounds'),
            value: c.settings['sound'] == true,
            onChanged: (v) => c.setSetting('sound', v),
          ),
          const SizedBox(height: 12),
          SoftCard(
            child: const Text(
              'English is available now. Arabic and Spanish are planned. Text follows your device’s accessibility size. Lessons offer read-aloud where your device supports it.',
            ),
          ),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: () => context.push('/parent'),
            icon: const Icon(Icons.family_restroom),
            label: const Text('Parent & privacy area'),
          ),
        ],
      ),
    );
  }
}

class ParentScreen extends ConsumerStatefulWidget {
  const ParentScreen({super.key});
  @override
  ConsumerState<ParentScreen> createState() => _ParentScreenState();
}

class _ParentScreenState extends ConsumerState<ParentScreen> {
  final storage = const FlutterSecureStorage();
  final pin = TextEditingController();
  bool unlocked = false, hasPin = false, loading = true;
  String message = '';
  @override
  void initState() {
    super.initState();
    check();
  }

  Future<void> check() async {
    try {
      final value = await storage.read(key: 'parent.hash');
      if (mounted) {
        setState(() {
          hasPin = value != null;
          loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          message = 'Secure parent controls are unavailable on this device.';
          loading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    pin.dispose();
    super.dispose();
  }

  Future<void> unlock() async {
    try {
      final lock = DateTime.tryParse(
        await storage.read(key: 'parent.lock') ?? '',
      );
      if (lock != null && DateTime.now().isBefore(lock)) {
        setState(() => message = 'Please wait a minute before trying again.');
        return;
      }
      if (!RegExp(r'^\d{6}$').hasMatch(pin.text)) {
        setState(() => message = 'Use a six-digit PIN.');
        return;
      }
      final salt = await storage.read(key: 'parent.salt') ?? const Uuid().v4();
      final hash = sha256.convert(utf8.encode('$salt:${pin.text}')).toString();
      if (hasPin && hash != await storage.read(key: 'parent.hash')) {
        final attempts =
            int.tryParse(await storage.read(key: 'parent.attempts') ?? '0') ??
            0;
        await storage.write(key: 'parent.attempts', value: '${attempts + 1}');
        if (attempts >= 4) {
          await storage.write(
            key: 'parent.lock',
            value: DateTime.now()
                .add(const Duration(minutes: 1))
                .toIso8601String(),
          );
          await storage.write(key: 'parent.attempts', value: '0');
        }
        if (mounted) setState(() => message = 'That PIN did not match.');
        return;
      }
      if (!hasPin) {
        await storage.write(key: 'parent.salt', value: salt);
        await storage.write(key: 'parent.hash', value: hash);
      }
      await storage.write(key: 'parent.attempts', value: '0');
      if (mounted) {
        final c = ref.read(controllerProvider);
        c.parentVerified = true;
        c.sessionSeconds = 0;
        c.refresh();
        setState(() => unlocked = true);
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => message = 'Parent controls could not open. Please try again.',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = ref.watch(controllerProvider);
    return Scaffold(
      appBar: AppBar(
        leading: const VillageBackButton(),
        title: const Text('Parent & privacy area'),
      ),
      body: PageBody(
        children: [
          if (loading) const Center(child: CircularProgressIndicator()),
          if (!loading && !unlocked) ...[
            Text(
              hasPin ? 'Enter your parent PIN' : 'An adult should set this up',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 12),
            const Text(
              'This local PIN protects settings. It does not verify parental consent for cloud or AI services.',
            ),
            const SizedBox(height: 18),
            TextField(
              controller: pin,
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: 6,
              decoration: const InputDecoration(
                labelText: 'Six-digit parent PIN',
              ),
            ),
            FilledButton(
              onPressed: unlock,
              child: Text(hasPin ? 'Unlock' : 'Set parent PIN'),
            ),
          ],
          if (unlocked) ...[
            SoftCard(
              child: Text(
                '${c.completed.length} lessons explored · level ${c.level}\nAll four worlds are available offline.',
              ),
            ),
            const SizedBox(height: 20),
            SelectionField<int>(
              value: c.settings['timeLimit'],
              label: 'Session reminder',
              options: const [
                (0, 'No limit'),
                (15, '15 minutes'),
                (30, '30 minutes'),
              ],
              onChanged: (v) => c.setSetting('timeLimit', v),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Readiness reminders'),
              subtitle: const Text(
                'Optional notifications on supported phones',
              ),
              value: c.settings['notifications'] == true,
              onChanged: (v) async {
                if (!v) {
                  c.setSetting('notifications', false);
                  await reminders.clear();
                  return;
                }
                final granted = await reminders.request();
                c.setSetting('notifications', granted);
                if (!granted && mounted) {
                  setState(
                    () => message = 'Reminders are unavailable or permission was not granted.',
                  );
                }
              },
            ),
            const SizedBox(height: 14),
            SoftCard(
              child: const Text(
                'Privacy defaults: local progress, no advertising, no public chat, no location tracking. Camera previews stay on this device. Live AI is disabled. Cloud access for minors awaits a verified consent process.',
              ),
            ),
            const SizedBox(height: 18),
            OutlinedButton(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: prettyExport(c)));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Save data copied. Keep it somewhere private.',
                    ),
                  ),
                );
              },
              child: const Text('Export local save'),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: CloudService.configured && c.settings['age'] == 'adult'
                  ? () => context.push('/account')
                  : null,
              child: const Text('Adult cloud account'),
            ),
            if (!CloudService.configured)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text('Cloud accounts are not available in this build.'),
              ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Delete local progress?'),
                    content: const Text(
                      'This removes quests, coins, saved discoveries, and reminders from this device. It does not delete a cloud account.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Keep it'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Delete'),
                      ),
                    ],
                  ),
                );
                if (confirmed == true) {
                  await reminders.clear();
                  await c.reset();
                  if (context.mounted) context.go('/onboarding');
                }
              },
              child: const Text('Delete local progress'),
            ),
          ],
          if (message.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Text(message),
            ),
        ],
      ),
    );
  }
}
