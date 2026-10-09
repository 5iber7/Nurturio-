import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../app/theme.dart';
import '../../core/app_controller.dart';
import '../../core/services.dart';
import '../../core/account_auth.dart';

class AccountScreen extends ConsumerStatefulWidget {
  const AccountScreen({super.key});
  @override
  ConsumerState<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends ConsumerState<AccountScreen> {
  final email = TextEditingController(), password = TextEditingController();
  final form = GlobalKey<FormState>();
  final cloud = CloudService();
  StreamSubscription<AuthState>? subscription;
  bool busy = false, creating = false, reveal = false;
  String message = '';
  @override
  void initState() {
    super.initState();
    if (CloudService.available) {
      subscription = cloud.client.auth.onAuthStateChange.listen((state) {
        if (mounted) setState(() {});
      });
    }
  }

  @override
  void dispose() {
    subscription?.cancel();
    email.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (!(form.currentState?.validate() ?? false)) return;
    setState(() {
      busy = true;
      message = '';
    });
    try {
      final auth = AccountAuth(cloud.client);
      if (creating) {
        final response = await auth.signUp(email.text, password.text);
        if (mounted) {
          setState(() {
            message = response.session == null
                ? 'Check your email to confirm your address, then return here and sign in. Your guest village is safe.'
                : 'Your account is ready. Your village remains on this device.';
            creating = false;
          });
        }
      } else {
        await auth.signIn(email.text, password.text);
        if (mounted) setState(() => message = 'Signed in. Welcome back.');
      }
      password.clear();
    } on AuthException catch (e) {
      if (mounted) {
        setState(
          () => message = switch (e.code) {
            'invalid_credentials' => 'The email or password is incorrect.',
            'email_not_confirmed' =>
              'Confirm your email address before signing in.',
            'over_email_send_rate_limit' =>
              'Email delivery is temporarily limited. Please try again later.',
            'email_address_not_authorized' => 'Email delivery is not available for this address yet. You can keep playing as a guest.',
            'weak_password' =>
              'Choose a stronger password with at least 8 characters.',
            'user_already_exists' => 'Try signing in with this email instead.',
            _ => 'Your account request could not finish. Check the email and try again.',
          },
        );
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => message =
              'Could not connect. Your guest village is still available.',
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = ref.watch(controllerProvider);
    final adult = c.settings['age'] == 'adult';
    final available = CloudService.available && adult;
    final signedIn = available && cloud.client.auth.currentSession != null;
    return Scaffold(
      appBar: AppBar(
        leading: const VillageBackButton(),
        title: const Text('Your Nurturio account'),
      ),
      body: PageBody(
        children: [
          Text(
            'A village for everyone.',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 14),
          const SoftCard(
            child: Text(
              'An account is optional. You can always play as a guest. Game progress stays on this device; photos and chat are not uploaded.',
            ),
          ),
          const SizedBox(height: 20),
          if (!adult)
            const SoftCard(
              child: Text(
                'Accounts are currently available for adults. Younger players can enjoy all four worlds as guests.',
              ),
            )
          else if (!CloudService.available)
            const SoftCard(
              child: Text(
                'Accounts cannot connect right now. Please try again later, or continue playing as a guest.',
              ),
            )
          else if (!signedIn) ...[
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: false, label: Text('Sign in')),
                ButtonSegment(value: true, label: Text('Sign up')),
              ],
              selected: {creating},
              onSelectionChanged: busy
                  ? null
                  : (v) => setState(() {
                      creating = v.first;
                      message = '';
                      password.clear();
                    }),
            ),
            const SizedBox(height: 20),
            Form(
              key: form,
              child: Column(
                children: [
                  TextFormField(
                    controller: email,
                    enabled: !busy,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    decoration: const InputDecoration(
                      labelText: 'Email address',
                    ),
                    validator: (v) =>
                        RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
                            .hasMatch(v?.trim() ?? '')
                        ? null
                        : 'Enter a valid email address.',
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: password,
                    enabled: !busy,
                    obscureText: !reveal,
                    autocorrect: false,
                    enableSuggestions: false,
                    autofillHints: [
                      creating
                          ? AutofillHints.newPassword
                          : AutofillHints.password,
                    ],
                    decoration: InputDecoration(
                      labelText: 'Password',
                      helperText: creating ? 'At least 8 characters' : null,
                      suffixIcon: IconButton(
                        tooltip: reveal ? 'Hide password' : 'Show password',
                        onPressed: () => setState(() => reveal = !reveal),
                        icon: Icon(
                          reveal ? Icons.visibility_off : Icons.visibility,
                        ),
                      ),
                    ),
                    onFieldSubmitted: (_) {
                      if (!busy) submit();
                    },
                    validator: (v) => (v ?? '').isEmpty
                        ? 'Enter your password.'
                        : creating && v!.length < 8
                        ? 'Use at least 8 characters.'
                        : null,
                  ),
                  const SizedBox(height: 18),
                  FilledButton(
                    onPressed: busy ? null : submit,
                    child: Text(
                      creating ? 'Create account' : 'Sign in to Nurturio',
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            SoftCard(
              child: Text(
                'Signed in as ${cloud.client.auth.currentUser?.email ?? 'your account'}',
              ),
            ),
            const SizedBox(height: 14),
            OutlinedButton(
              onPressed: busy
                  ? null
                  : () async {
                      setState(() => busy = true);
                      try {
                        await AccountAuth(cloud.client).signOut();
                        c.setSetting('cloud', false);
                        if (mounted) {
                          setState(
                            () => message =
                                'Signed out. Your guest progress remains.',
                          );
                        }
                      } catch (_) {
                        if (mounted) {
                          setState(
                            () => message =
                                'Could not sign out. Please try again.',
                          );
                        }
                      } finally {
                        if (mounted) setState(() => busy = false);
                      }
                    },
              child: const Text('Sign out'),
            ),
            if (CloudService.syncEnabled) ...[
              const SizedBox(height: 14),
              FilledButton(
                onPressed: busy
                    ? null
                    : () async {
                        setState(() => busy = true);
                        try {
                          await cloud.sync(c);
                          if (mounted) {
                            setState(() => message = 'Progress synchronized.');
                          }
                        } catch (_) {
                          if (mounted) {
                            setState(
                              () => message =
                                  'Could not sync. Your local save is safe.',
                            );
                          }
                        } finally {
                          if (mounted) setState(() => busy = false);
                        }
                      },
                child: const Text('Sync this device'),
              ),
            ],
          ],
          if (busy)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),
          if (message.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 18),
              child: Semantics(liveRegion: true, child: Text(message)),
            ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () => context.go('/village'),
            icon: const Icon(Icons.eco_outlined),
            label: const Text('Continue playing'),
          ),
        ],
      ),
    );
  }
}
