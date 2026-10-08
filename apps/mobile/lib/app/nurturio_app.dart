import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/app_controller.dart';
import '../core/audio_service.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/village/village_screen.dart';
import '../features/village/garden_screen.dart';
import '../features/quests/quest_screen.dart';
import '../features/learn/learn_screen.dart';
import '../features/buzz/buzz_screen.dart';
import '../features/discover/discover_screen.dart';
import '../features/collection/collection_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/settings/account_screen.dart';
import '../l10n/app_localizations.dart';
import 'theme.dart';

class NurturioApp extends ConsumerStatefulWidget {
  const NurturioApp({super.key});
  @override
  ConsumerState<NurturioApp> createState() => _NurturioAppState();
}

class _NurturioAppState extends ConsumerState<NurturioApp>
    with WidgetsBindingObserver {
  late final AppController controller;
  late final GoRouter router;
  Timer? tick;
  bool active = true;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final c = ref.read(controllerProvider);
    controller = c;
    router = GoRouter(
      initialLocation: c.onboarded ? '/village' : '/onboarding',
      refreshListenable: c,
      redirect: (context, state) {
        if (!c.onboarded && state.uri.path != '/onboarding') {
          return '/onboarding';
        }
        if (c.breakRequired &&
            !['/parent', '/settings', '/break'].contains(state.uri.path)) {
          return '/break';
        }
        return null;
      },
      routes: [
        GoRoute(path: '/garden', builder: (_, s) => const GardenScreen()),
        GoRoute(
          path: '/onboarding',
          builder: (_, s) => const OnboardingScreen(),
        ),
        GoRoute(
          path: '/quest/:id',
          builder: (_, s) => QuestScreen(
            key: ValueKey(s.pathParameters['id']),
            questId: s.pathParameters['id']!,
          ),
        ),
        GoRoute(
          path: '/topic/:id',
          builder: (_, s) => TopicScreen(topicId: s.pathParameters['id']!),
        ),
        GoRoute(
          path: '/article/:kind/:id',
          builder: (_, s) => ArticleScreen(
            kind: s.pathParameters['kind']!,
            id: s.pathParameters['id']!,
          ),
        ),
        GoRoute(
          path: '/buzz',
          builder: (_, s) => BuzzScreen(topic: s.uri.queryParameters['topic']),
        ),
        GoRoute(path: '/settings', builder: (_, s) => const SettingsScreen()),
        GoRoute(path: '/parent', builder: (_, s) => const ParentScreen()),
        GoRoute(path: '/account', builder: (_, s) => const AccountScreen()),
        GoRoute(
          path: '/break',
          builder: (context, s) => Scaffold(
            body: SafeArea(
              child: PageBody(
                children: [
                  const SizedBox(height: 70),
                  const Icon(
                    Icons.local_florist_outlined,
                    size: 80,
                    color: olive,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'A little time to rest.',
                    style: Theme.of(context).textTheme.displaySmall,
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Your progress is saved. Ask an adult to open the parent area when it is time to return.',
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: () => context.push('/parent'),
                    child: const Text('Open parent area'),
                  ),
                ],
              ),
            ),
          ),
        ),
        ShellRoute(
          builder: (context, s, child) =>
              VillageShell(location: s.uri.path, child: child),
          routes: [
            GoRoute(path: '/village', builder: (_, s) => const VillageScreen()),
            GoRoute(path: '/learn', builder: (_, s) => const LearnScreen()),
            GoRoute(
              path: '/discover',
              builder: (_, s) => const DiscoverScreen(),
            ),
            GoRoute(
              path: '/collection',
              builder: (_, s) => const CollectionScreen(),
            ),
          ],
        ),
      ],
      errorBuilder: (context, s) => Scaffold(
        appBar: AppBar(title: const Text('A path back home')),
        body: Center(
          child: FilledButton(
            onPressed: () => context.go('/village'),
            child: const Text('Return to the village'),
          ),
        ),
      ),
    );
    tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (active) {
        c.tickSession();
        c.refresh();
      }
    });
    c.addListener(_updateReminders);
  }

  void _updateReminders() {
    reminders.rebuild(ref.read(controllerProvider)).catchError((Object e) {
      /* Reminders are best-effort and never block saves. */
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    active = state == AppLifecycleState.resumed;
    if (active) {
      ref.read(controllerProvider).refresh();
      audio.setMusic(ref.read(controllerProvider).settings['music'] == true);
    } else {
      ref.read(controllerProvider).flush();
      ref.read(controllerProvider).parentVerified = false;
      audio.pause();
    }
  }

  @override
  void dispose() {
    tick?.cancel();
    controller.removeListener(_updateReminders);
    WidgetsBinding.instance.removeObserver(this);
    router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp.router(
    title: 'Nurturio',
    debugShowCheckedModeBanner: false,
    theme: nurturioTheme(),
    darkTheme: nurturioTheme(brightness: Brightness.dark),
    themeMode: switch (ref.watch(controllerProvider).settings['theme']) {
      'dark' => ThemeMode.dark,
      'light' => ThemeMode.light,
      _ => ThemeMode.system,
    },
    routerConfig: router,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
  );
}

class VillageShell extends ConsumerWidget {
  final String location;
  final Widget child;
  const VillageShell({super.key, required this.location, required this.child});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = ref.watch(controllerProvider);
    const paths = ['/village', '/learn', '/discover', '/collection'];
    final index = paths.indexOf(location);
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            if (c.error != null)
              MaterialBanner(
                content: Text(c.error!),
                actions: [
                  TextButton(onPressed: c.persist, child: const Text('Retry')),
                ],
              ),
            Expanded(child: child),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index < 0 ? 0 : index,
        onDestinationSelected: (i) => context.go(paths[i]),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.cottage_outlined),
            selectedIcon: const Icon(Icons.cottage),
            label: l.village,
          ),
          NavigationDestination(
            icon: const Icon(Icons.menu_book_outlined),
            label: l.learn,
          ),
          NavigationDestination(
            icon: const Icon(Icons.center_focus_strong),
            label: l.discover,
          ),
          NavigationDestination(
            icon: const Icon(Icons.collections_bookmark_outlined),
            label: l.collection,
          ),
        ],
      ),
    );
  }
}
