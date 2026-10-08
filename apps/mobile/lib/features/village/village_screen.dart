import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../core/app_controller.dart';
import '../../game/components/world_art.dart';

class VillageScreen extends ConsumerWidget {
  const VillageScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = ref.watch(controllerProvider);
    final next = c.nextQuest;
    return PageBody(
      children: [
        Row(
          children: [
            const Icon(Icons.spa_rounded, color: olive, size: 30),
            const SizedBox(width: 8),
            Expanded(
              child: Align(
                alignment: Alignment.centerLeft,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    'nurturio',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ),
              ),
            ),
            IconButton(
              tooltip: 'Settings',
              onPressed: () => context.push('/settings'),
              icon: const Icon(Icons.tune),
            ),
          ],
        ),
        const SizedBox(height: 24),
        if (c.settings['demo'] == true)
          const Padding(
            padding: EdgeInsets.only(bottom: 16),
            child: SoftCard(
              child: Text(
                'Demo village · example progress. Reset it in the parent area.',
              ),
            ),
          ),
        if (c.decorations.isNotEmpty)
          SoftCard(
            color: const Color(0xFFFFEDC5),
            child: Row(
              children: [
                Icon(
                  c.decorations.contains('garden-bench')
                      ? Icons.weekend_outlined
                      : Icons.local_florist,
                  color: olive,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Your village touches: ${c.decorations.map((id) => {'flower-path': 'Flower path', 'sunny-sign': 'Sunny welcome sign', 'garden-bench': 'Garden bench'}[id]).join(' · ')}',
                  ),
                ),
              ],
            ),
          ),
        Text(
          'A little care.\nA world of discovery.',
          style: Theme.of(context).textTheme.displaySmall,
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Chip(
              avatar: const Icon(Icons.auto_awesome, size: 18),
              label: Text('Level ${c.level}'),
            ),
            Text('${c.coins} coins · ${c.xp} XP'),
          ],
        ),
        const SizedBox(height: 12),
        const Text('Welcome to your village. What will you nurture today?'),
        const SizedBox(height: 22),
        if (next != null)
          SoftCard(
            color: const Color(0xFFE7EDD7),
            child: Row(
              children: [
                const Icon(Icons.play_circle_outline, size: 40, color: olive),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'YOUR NEXT DISCOVERY',
                        style: TextStyle(
                          fontSize: 11,
                          letterSpacing: 1.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        next.title,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Continue learning',
                  onPressed: () => context.push('/quest/${next.id}'),
                  icon: const Icon(Icons.arrow_forward),
                ),
              ],
            ),
          ),
        const SizedBox(height: 28),
        Text(
          'Explore your worlds',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 14),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth > 650 ? 2 : 1;
            return Wrap(
              spacing: 18,
              runSpacing: 18,
              children: [
                for (final topic in c.library.topics)
                  SizedBox(
                    width:
                        (constraints.maxWidth - (columns - 1) * 18) / columns,
                    child: Material(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () => context.push('/topic/${topic.id}'),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Container(
                              color: Color(topic.color).withValues(alpha: .14),
                              child: WorldArt(
                                world: topic.id,
                                height: 175,
                                progress:
                                    c.topicCount(topic) / topic.quests.length,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          topic.name,
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleLarge,
                                        ),
                                      ),
                                      const Icon(
                                        Icons.arrow_outward,
                                        color: olive,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(topic.subtitle),
                                  const SizedBox(height: 14),
                                  LinearProgressIndicator(
                                    value:
                                        c.topicCount(topic) /
                                        topic.quests.length,
                                    minHeight: 6,
                                    borderRadius: BorderRadius.circular(6),
                                    color: Color(topic.color),
                                    backgroundColor: cream,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '${c.topicCount(topic)} of ${topic.quests.length} discoveries',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: 24),
        SoftCard(
          child: Row(
            children: [
              const Icon(Icons.emoji_nature, size: 38, color: olive),
              const SizedBox(width: 16),
              const Expanded(
                child: Text(
                  'Curious about something? Buzz has a little wisdom to share.',
                ),
              ),
              TextButton(
                onPressed: () => context.push('/buzz'),
                child: const Text('Ask Buzz'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class TopicScreen extends ConsumerWidget {
  final String topicId;
  const TopicScreen({super.key, required this.topicId});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = ref.watch(controllerProvider), t = c.library.topic(topicId);
    return Scaffold(
      appBar: AppBar(leading: const VillageBackButton(), title: Text(t.name)),
      body: PageBody(
        children: [
          WorldArt(world: t.id, height: 220),
          Text(t.subject, style: Theme.of(context).textTheme.displaySmall),
          const SizedBox(height: 10),
          Text(t.goal),
          if (t.id == 'garden')
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: FilledButton.icon(
                onPressed: () => context.push('/garden'),
                icon: const Icon(Icons.spa_outlined),
                label: const Text('Open your growing beds'),
              ),
            ),
          const SizedBox(height: 24),
          for (final q in t.quests)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: SoftCard(
                padding: const EdgeInsets.all(12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Color(t.color).withValues(alpha: .2),
                    child: c.completed.contains(q.id)
                        ? const Icon(Icons.check, color: olive)
                        : Text('${q.order + 1}'),
                  ),
                  title: Text(
                    q.title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    c.completed.contains(q.id)
                        ? 'Discovered'
                        : c.available(q)
                        ? 'Ready to explore'
                        : 'Complete the previous lesson',
                  ),
                  trailing: Icon(
                    c.available(q) ? Icons.chevron_right : Icons.lock_outline,
                  ),
                  onTap: c.available(q)
                      ? () => context.push('/quest/${q.id}')
                      : null,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
