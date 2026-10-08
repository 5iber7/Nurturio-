import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../core/app_controller.dart';
import '../../core/services.dart';

class AccountScreen extends ConsumerStatefulWidget {
  const AccountScreen({super.key});
  @override
  ConsumerState<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends ConsumerState<AccountScreen> {
  final email = TextEditingController(), code = TextEditingController();
  final cloud = CloudService();
  bool busy = false, sent = false;
  String message = '';
  @override
  void dispose() {
    email.dispose();
    code.dispose();
    super.dispose();
  }

  Future<void> perform(Future<void> Function() action, String success) async {
    setState(() => busy = true);
    try {
      await action();
      if (mounted) setState(() => message = success);
    } catch (_) {
      if (mounted) {
        setState(
          () => message =
              'That could not finish. Check your connection and try again.',
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = ref.watch(controllerProvider);
    if (!CloudService.configured || c.settings['age'] != 'adult') {
      return Scaffold(
        appBar: AppBar(
          leading: const VillageBackButton(),
          title: const Text('Cloud account'),
        ),
        body: const Center(
          child: Text('Cloud access is unavailable for this profile.'),
        ),
      );
    }
    final signedIn = cloud.client.auth.currentSession != null;
    return Scaffold(
      appBar: AppBar(
        leading: const VillageBackButton(),
        title: const Text('Adult cloud account'),
      ),
      body: PageBody(
        children: [
          const SoftCard(
            child: Text(
              'Cloud sync sends progress to your private account. Photos and chat are not included. Under-18 cloud access remains disabled until a consent process is configured.',
            ),
          ),
          const SizedBox(height: 20),
          if (!signedIn) ...[
            TextField(
              controller: email,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Adult email'),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: busy
                  ? null
                  : () => perform(() async {
                      await cloud.requestCode(email.text.trim());
                      sent = true;
                    }, 'Check your email for a sign-in code.'),
              child: const Text('Send sign-in code'),
            ),
            if (sent) ...[
              const SizedBox(height: 12),
              TextField(
                controller: code,
                decoration: const InputDecoration(labelText: 'Email code'),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: busy
                    ? null
                    : () => perform(
                        () => cloud.verifyCode(
                          email.text.trim(),
                          code.text.trim(),
                        ),
                        'Signed in. You can now sync your progress.',
                      ),
                child: const Text('Verify code'),
              ),
            ],
          ],
          if (signedIn) ...[
            FilledButton(
              onPressed: busy
                  ? null
                  : () => perform(() async {
                      c.setSetting('cloud', true);
                      await c.flush();
                      await cloud.sync(c);
                    }, 'Your progress was synchronized.'),
              child: const Text('Sync this device'),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: busy
                  ? null
                  : () => perform(() async {
                      await cloud.signOut();
                      c.setSetting('cloud', false);
                    }, 'Signed out. Local progress remains.'),
              child: const Text('Sign out'),
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: busy
                  ? null
                  : () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Delete cloud account?'),
                          content: const Text(
                            'This permanently removes this account and its cloud progress. Your local save remains.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              child: const Text('Delete'),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        await perform(() async {
                          await cloud.deleteAccount();
                          c.setSetting('cloud', false);
                        }, 'Cloud account deleted.');
                      }
                    },
              child: const Text('Delete cloud account'),
            ),
          ],
          if (busy)
            const Padding(
              padding: EdgeInsets.all(20),
              child: Center(child: CircularProgressIndicator()),
            ),
          if (message.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 18),
              child: Text(message),
            ),
        ],
      ),
    );
  }
}
