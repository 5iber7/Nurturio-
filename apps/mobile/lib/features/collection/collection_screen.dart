import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../core/app_controller.dart';

class CollectionScreen extends ConsumerWidget {
  const CollectionScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = ref.watch(controllerProvider);
    return PageBody(
      children: [
        Text(
          'Little things,\nbig discoveries.',
          style: Theme.of(context).textTheme.displaySmall,
        ),
        const SizedBox(height: 10),
        Text('${c.completed.length} discoveries · ${c.coins} coins'),
        const SizedBox(height: 24),
        Text(
          'Tools you have explored',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final tool in [
              ('honey-3', 'Protective veil'),
              ('honey-7', 'Honey extractor'),
              ('olive-4', 'Olive crusher'),
              ('olive-6', 'Decanter'),
              ('chicken-2', 'Coop & perch'),
              ('chicken-4', 'Drinking station'),
              ('garden-4', 'Watering can'),
            ])
              Chip(
                avatar: Icon(
                  c.completed.contains(tool.$1)
                      ? Icons.handyman_outlined
                      : Icons.lock_outline,
                  size: 18,
                  color: accent(context),
                ),
                label: Text(tool.$2),
              ),
          ],
        ),
        const SizedBox(height: 24),
        Text(
          'Your world badges',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        for (final t in c.library.topics)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: SoftCard(
              child: Row(
                children: [
                  Icon(
                    c.topicCount(t) == t.quests.length
                        ? Icons.workspace_premium
                        : Icons.lock_outline,
                    size: 42,
                    color: c.topicCount(t) == t.quests.length
                        ? accent(context)
                        : Colors.grey,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t.name,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        Text(
                          '${c.topicCount(t)} / ${t.quests.length} discoveries',
                        ),
                      ],
                    ),
                  ),
                  if (c.topicCount(t) == t.quests.length) const Text('Earned!'),
                ],
              ),
            ),
          ),
        const SizedBox(height: 18),
        Text('Plant cards', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final p in c.library.plants)
              Chip(
                avatar: Icon(
                  c.plantCards.contains(p['id'])
                      ? Icons.eco
                      : Icons.lock_outline,
                  size: 18,
                  color: accent(context),
                ),
                label: Text(p['name']),
              ),
          ],
        ),
        const SizedBox(height: 18),
        Text(
          'Decorate your village',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 10),
        for (final d in [
          ('flower-path', 'Flower path', 30),
          ('sunny-sign', 'Sunny welcome sign', 50),
          ('garden-bench', 'Garden bench', 80),
        ])
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: SoftCard(
              child: Row(
                children: [
                  Icon(Icons.local_florist_outlined, color: accent(context)),
                  const SizedBox(width: 12),
                  Expanded(child: Text(d.$2)),
                  FilledButton(
                    onPressed: c.decorations.contains(d.$1) || c.coins < d.$3
                        ? null
                        : () => c.buy(d.$1, d.$3),
                    child: Text(
                      c.decorations.contains(d.$1) ? 'Owned' : '${d.$3} coins',
                    ),
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 20),
        Text(
          'Discovery journal',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 10),
        if (c.scans.isEmpty)
          const SoftCard(
            child: Text(
              'Your saved discoveries will appear here. Explore the offline plant library to get started.',
            ),
          ),
        for (final scan in c.scans)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: SoftCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    scan['name'] ?? 'Discovery',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  Text(scan['description'] ?? ''),
                  Text(
                    scan['date'] ?? '',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
