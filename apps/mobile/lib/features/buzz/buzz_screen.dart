import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../core/app_controller.dart';

class BuzzScreen extends ConsumerStatefulWidget {
  final String? topic;
  const BuzzScreen({super.key, this.topic});
  @override
  ConsumerState<BuzzScreen> createState() => _BuzzScreenState();
}

class _BuzzScreenState extends ConsumerState<BuzzScreen> {
  final input = TextEditingController();
  final List<({String question, String answer})> messages = [];
  @override
  void dispose() {
    input.dispose();
    super.dispose();
  }

  void ask(String text) {
    if (text.trim().isEmpty) return;
    final c = ref.read(controllerProvider);
    final words = text
        .toLowerCase()
        .split(RegExp(r'\W+'))
        .where((w) => w.length > 3)
        .toSet();
    final quests = c.library.topics
        .where((t) => widget.topic == null || t.id == widget.topic)
        .expand((t) => t.quests)
        .toList();
    var best = 0;
    dynamic selected;
    for (final q in quests) {
      final searchable = '${q.title} ${q.fact} ${q.question}'.toLowerCase();
      final score = words.where(searchable.contains).length;
      if (score > best) {
        best = score;
        selected = q;
      }
    }
    final answer = selected != null
        ? '${selected.fact}\n\nTry “${selected.title}” in the ${c.library.topic(selected.topicId).name}.'
        : 'I’m not sure that is covered in my field notes yet. Try asking about nectar, chicken water, olive paste, seeds, or a plant in the library.';
    setState(() {
      messages.add((question: text.trim(), answer: answer));
      if (messages.length > 20) messages.removeAt(0);
      input.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const VillageBackButton(),
        title: const Text('Ask Buzz'),
      ),
      body: PageBody(
        children: [
          SoftCard(
            color: const Color(0xFFFFEDC5),
            child: Row(
              children: [
                Icon(Icons.emoji_nature, size: 48, color: accent(context)),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hello, curious explorer!',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const Text(
                        'I share curated field notes. No messages leave this device.',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final question in [
                'Where does nectar come from?',
                'What do chickens drink?',
                'What is olive paste?',
                'How do seeds grow?',
              ])
                ActionChip(
                  label: Text(question),
                  onPressed: () => ask(question),
                ),
            ],
          ),
          const SizedBox(height: 20),
          for (final m in messages) ...[
            Align(
              alignment: Alignment.centerRight,
              child: SoftCard(
                color: const Color(0xFFE7EDD7),
                child: Text(m.question),
              ),
            ),
            const SizedBox(height: 10),
            SoftCard(child: Text(m.answer)),
            const SizedBox(height: 16),
          ],
          TextField(
            controller: input,
            maxLength: 500,
            decoration: const InputDecoration(
              hintText: 'Ask about your world…',
            ),
            onSubmitted: ask,
          ),
          const SizedBox(height: 10),
          FilledButton.icon(
            onPressed: () => ask(input.text),
            icon: const Icon(Icons.send_outlined),
            label: const Text('Ask Buzz'),
          ),
        ],
      ),
    );
  }
}
