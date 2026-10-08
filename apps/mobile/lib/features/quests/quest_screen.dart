import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../../app/theme.dart';
import '../../core/app_controller.dart';
import '../../game/engine/process_engine.dart';
import '../../game/templates/quest_play.dart';
import '../../game/components/world_art.dart';
import 'lesson_video.dart';

class QuestScreen extends ConsumerStatefulWidget {
  final String questId;
  const QuestScreen({super.key, required this.questId});
  @override
  ConsumerState<QuestScreen> createState() => _QuestScreenState();
}

class _QuestScreenState extends ConsumerState<QuestScreen>
    with WidgetsBindingObserver {
  Timer? timer;
  bool showCheck = false;
  String message = '';
  final tts = FlutterTts();
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) ref.read(controllerProvider).refresh();
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    tts.stop();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(controllerProvider).refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = ref.watch(controllerProvider),
        q = c.library.quest(widget.questId),
        p = c.process(q);
    final topic = c.library.topic(q.topicId);
    if (!c.available(q)) {
      return Scaffold(
        appBar: AppBar(
          leading: const VillageBackButton(),
          title: const Text('Not quite yet'),
        ),
        body: const Center(child: Text('Finish the previous lesson first.')),
      );
    }
    return Scaffold(
      appBar: AppBar(
        leading: const VillageBackButton(),
        title: Text(topic.name),
        actions: [
          IconButton(
            tooltip: 'Ask Buzz',
            onPressed: () => context.push('/buzz?topic=${topic.id}'),
            icon: const Icon(Icons.chat_bubble_outline),
          ),
        ],
      ),
      body: PageBody(
        children: [
          if (q.videoUrl != null && q.videoTranscript != null)
            LessonVideo(url: q.videoUrl!, transcript: q.videoTranscript!),
          Text(
            'LESSON ${q.order + 1} OF ${topic.quests.length}',
            style: const TextStyle(
              letterSpacing: 2,
              fontWeight: FontWeight.bold,
              color: olive,
            ),
          ),
          const SizedBox(height: 10),
          Text(q.title, style: Theme.of(context).textTheme.displaySmall),
          const SizedBox(height: 16),
          SoftCard(
            color: const Color(0xFFFFEDC5),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.schedule, color: olive),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Real life: ${q.realDuration}\nGame wait: ${c.settings['pace'] == 'garden' ? q.gardenSeconds : q.waitSeconds} seconds',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          if (p.status == ProcessStatus.available) ...[
            WorldArt(world: topic.id, height: 230),
            const SizedBox(height: 16),
            Text(q.intro, style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 16),
            SoftCard(child: Text(q.safety)),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () => c.start(q),
              child: const Text('Let’s try it'),
            ),
          ],
          if (p.status == ProcessStatus.playing)
            QuestPlay(key: ValueKey(q.id), quest: q, controller: c),
          if (p.status == ProcessStatus.waiting) ...[
            WorldArt(world: topic.id, height: 250, progress: 1),
            const SizedBox(height: 16),
            Text(
              'Nature takes its time.',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Your simulated process is growing. ${c.engine.remaining(p)} seconds remain. You can explore another world while you wait.',
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => context.go('/village'),
              child: const Text('Explore the village'),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => setState(() => showCheck = !showCheck),
              child: const Text('Speed up with a learning check'),
            ),
            if (showCheck) ...[
              const SizedBox(height: 14),
              Text(q.question),
              for (var i = 0; i < q.answers.length; i++)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: OutlinedButton(
                    onPressed: () {
                      if (c.speedUp(q, i)) {
                        setState(() => showCheck = false);
                      } else {
                        setState(() => message = 'Try again. ${q.fact}');
                      }
                    },
                    child: Text(q.answers[i]),
                  ),
                ),
            ],
          ],
          if (p.status == ProcessStatus.ready) ...[
            SoftCard(
              color: const Color(0xFFE7EDD7),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'DID YOU KNOW?',
                    style: TextStyle(
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.bold,
                      color: olive,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    c.settings['reading'] == 'Explorer' ? q.explorer : q.fact,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: () async {
                      try {
                        await tts.speak(q.fact);
                      } catch (_) {
                        if (mounted) {
                          setState(
                            () => message =
                                'Read-aloud is unavailable on this device.',
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.volume_up_outlined),
                    label: const Text('Read aloud'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'One little discovery',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Text(q.question, style: Theme.of(context).textTheme.bodyLarge),
            for (var i = 0; i < q.answers.length; i++)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: OutlinedButton(
                  onPressed: () {
                    if (c.claim(q, i)) {
                      setState(() => message = '');
                    } else {
                      setState(() => message = 'Not quite. ${q.fact}');
                    }
                  },
                  child: Text(q.answers[i]),
                ),
              ),
          ],
          if (p.status == ProcessStatus.completed) ...[
            const Icon(Icons.verified_rounded, size: 84, color: olive),
            const SizedBox(height: 18),
            Text(
              'A new discovery!',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 10),
            Text(
              '+${q.xp} XP  ·  +${q.coins} coins',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 22),
            SoftCard(child: Text(q.fact)),
            const SizedBox(height: 22),
            FilledButton(
              onPressed: () => context.go(
                q.order + 1 < topic.quests.length
                    ? '/quest/${topic.quests[q.order + 1].id}'
                    : '/topic/${topic.id}',
              ),
              child: Text(
                q.order + 1 < topic.quests.length
                    ? 'Next discovery'
                    : 'Back to your path',
              ),
            ),
          ],
          if (message.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Semantics(
                liveRegion: true,
                child: Text(
                  message,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
