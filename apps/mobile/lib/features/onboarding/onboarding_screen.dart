import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../core/app_controller.dart';
import '../../game/components/world_art.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});
  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  int step = 0;
  String age = 'under13', reading = 'Simple';
  @override
  Widget build(BuildContext context) {
    final c = ref.watch(controllerProvider);
    const titles = [
      'Learn by growing.',
      'Discover by doing.',
      'Your own little village.',
    ];
    const texts = [
      'Follow a flower all the way to a jar of honey. Learn real processes through small, meaningful actions.',
      'Build a coop, care for plants, and make olive oil. Mistakes are simply another chance to learn.',
      'Play offline, without an account. Your progress stays on this device. Choose a comfortable reading level.',
    ];
    return Scaffold(
      body: SafeArea(
        child: PageBody(
          children: [
            const SizedBox(height: 24),
            const Text(
              'NURTURIO',
              style: TextStyle(
                letterSpacing: 4,
                fontWeight: FontWeight.w800,
                color: olive,
              ),
            ),
            WorldArt(
              world: step == 0
                  ? 'honey'
                  : step == 1
                  ? 'garden'
                  : 'chicken',
              height: 280,
            ),
            Text(titles[step], style: Theme.of(context).textTheme.displaySmall),
            const SizedBox(height: 16),
            Text(texts[step], style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 24),
            if (step == 2) ...[
              DropdownButtonFormField<String>(
                initialValue: age,
                decoration: const InputDecoration(labelText: 'Age group'),
                items: const [
                  DropdownMenuItem(value: 'under13', child: Text('Under 13')),
                  DropdownMenuItem(value: 'teen', child: Text('13–17')),
                  DropdownMenuItem(value: 'adult', child: Text('18 or older')),
                ],
                onChanged: (v) => setState(() => age = v!),
              ),
              const SizedBox(height: 16),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'Simple', label: Text('Simple')),
                  ButtonSegment(value: 'Explorer', label: Text('Explorer')),
                ],
                selected: {reading},
                onSelectionChanged: (v) => setState(() => reading = v.first),
              ),
              const SizedBox(height: 20),
              const Text(
                'Photo identification is not enabled. Buzz offers curated offline lessons. Real-world animal care and tools need appropriate supervision.',
              ),
              const SizedBox(height: 20),
            ],
            FilledButton(
              onPressed: () {
                if (step < 2) {
                  setState(() => step++);
                } else {
                  c.settings.addAll({
                    'age': age,
                    'reading': reading,
                    'onboarded': true,
                  });
                  c.persist();
                  context.go('/village');
                }
              },
              child: Text(step < 2 ? 'Next' : 'Start my village'),
            ),
            const SizedBox(height: 18),
            Text('${step + 1} / 3', textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
