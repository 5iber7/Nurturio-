import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../core/app_controller.dart';

class LearnScreen extends ConsumerStatefulWidget {
  const LearnScreen({super.key});
  @override
  ConsumerState<LearnScreen> createState() => _LearnScreenState();
}

class _LearnScreenState extends ConsumerState<LearnScreen> {
  String search = '';
  @override
  Widget build(BuildContext context) {
    final c = ref.watch(controllerProvider);
    bool matches(String v) => v.toLowerCase().contains(search.toLowerCase());
    return PageBody(
      children: [
        Text(
          'A growing library',
          style: Theme.of(context).textTheme.displaySmall,
        ),
        const SizedBox(height: 10),
        const Text(
          'Real knowledge for curious minds. Always available offline.',
        ),
        const SizedBox(height: 22),
        TextField(
          decoration: const InputDecoration(
            hintText: 'Find a plant, process, or word',
            prefixIcon: Icon(Icons.search),
          ),
          onChanged: (v) => setState(() => search = v),
        ),
        const SizedBox(height: 24),
        for (final topic in c.library.topics) ...[
          if (matches(topic.name) || matches(topic.subject))
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: SoftCard(
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    Icons.menu_book_outlined,
                    color: accent(context),
                  ),
                  title: Text(
                    topic.subject,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  subtitle: Text(topic.goal),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/topic/${topic.id}'),
                ),
              ),
            ),
          for (final q in topic.quests)
            if (matches('${q.title} ${q.fact}') && (search.isNotEmpty))
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: SoftCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        q.title,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        c.settings['reading'] == 'Explorer'
                            ? q.explorer
                            : q.fact,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Source: ${q.sourceIds.map((id) => c.library.sources.firstWhere((s) => s['id'] == id)['publisher']).toSet().join(', ')}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      TextButton(
                        onPressed: () => context.push('/article/quest/${q.id}'),
                        child: const Text('Read lesson & sources'),
                      ),
                    ],
                  ),
                ),
              ),
          for (final term in topic.glossary)
            if (matches(term.join(' ')))
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: SoftCard(
                  padding: const EdgeInsets.all(16),
                  color: const Color(0xFFEFF3DF),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.bookmark_outline, color: accent(context)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: '${term[0]}\n',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              TextSpan(text: term[1]),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
        ],
        const SizedBox(height: 14),
        Text('Meet the plants', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        for (final plant in c.library.plants)
          if (matches(plant.values.join(' ')))
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: SoftCard(
                padding: const EdgeInsets.all(12),
                child: ListTile(
                  leading: Icon(Icons.eco_outlined, color: accent(context)),
                  title: Text(
                    plant['name'],
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(plant['season']),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/article/plant/${plant['id']}'),
                ),
              ),
            ),
        if (search.isNotEmpty &&
            !c.library.plants.any((p) => matches(p.values.join(' '))) &&
            !c.library.topics.any(
              (t) =>
                  matches(t.name) ||
                  t.quests.any((q) => matches('${q.title} ${q.fact}')) ||
                  t.glossary.any((g) => matches(g.join(' '))),
            ))
          const Text('No matches yet. Try “water”, “honey”, or a plant name.'),
      ],
    );
  }
}

class ArticleScreen extends ConsumerWidget {
  final String kind, id;
  const ArticleScreen({super.key, required this.kind, required this.id});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = ref.watch(controllerProvider);
    final isPlant = kind == 'plant';
    final p = isPlant
        ? c.library.plants.firstWhere((p) => p['id'] == id)
        : null;
    final q = isPlant ? null : c.library.quest(id);
    final sourceIds = isPlant
        ? List<String>.from(p!['sourceIds'])
        : q!.sourceIds;
    return Scaffold(
      appBar: AppBar(
        leading: const VillageBackButton(),
        title: const Text('Field notes'),
      ),
      body: PageBody(
        children: [
          Text(
            isPlant ? p!['name'] : q!.title,
            style: Theme.of(context).textTheme.displaySmall,
          ),
          const SizedBox(height: 20),
          if (isPlant)
            for (final key in [
              'sun',
              'water',
              'season',
              'timeline',
              'duration',
              'harvest',
              'note',
            ])
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: SoftCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        key.toUpperCase(),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: accent(context),
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(p![key]),
                    ],
                  ),
                ),
              ),
          if (!isPlant) ...[
            Text(q!.fact, style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 16),
            SoftCard(child: Text(q.safety)),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: c.available(q)
                  ? () => context.push('/quest/${q.id}')
                  : null,
              child: const Text('Try the lesson'),
            ),
          ],
          const SizedBox(height: 22),
          Text(
            'Reference notes',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 10),
          for (final source in c.library.sources.where(
            (s) => sourceIds.contains(s['id']),
          ))
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: SoftCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      source['publisher'],
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(source['title']),
                    const SizedBox(height: 6),
                    SelectableText(
                      source['url'],
                      style: const TextStyle(fontSize: 12),
                    ),
                    Text(
                      'Reviewed ${source['accessedAt']} · expert review pending',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
