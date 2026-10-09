import 'dart:async';
import 'dart:math' as math;

import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/app_controller.dart';
import '../../core/content.dart';
import '../../core/audio_service.dart';
import '../components/world_view.dart';
import '../components/choice_card.dart';
import '../engine/process_engine.dart';

class QuestScene extends FlameGame with TapCallbacks {
  final String topicWorld, template;
  final VoidCallback onTap;
  final bool reducedMotion;
  double elapsed = 0, progress = 0;
  QuestScene({
    required this.topicWorld,
    required this.template,
    required this.onTap,
    this.reducedMotion = false,
  });
  double get rhythm => (math.sin(elapsed * 2.5) + 1) / 2;
  @override
  Color backgroundColor() => const Color(0xFFEFF3DF);
  @override
  void update(double dt) {
    super.update(dt);
    if (!reducedMotion) elapsed += dt.clamp(0, .1);
  }

  @override
  void onTapDown(TapDownEvent event) {
    if (template == 'pour' || template == 'timing') onTap();
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    if (template == 'pour') {
      final r = Rect.fromLTWH(size.x * .08, size.y * .4, size.x * .84, 12);
      canvas.drawRRect(
        RRect.fromRectAndRadius(r, const Radius.circular(6)),
        Paint()..color = Colors.white,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            r.left,
            r.top,
            r.width * progress.clamp(0, 1),
            r.height,
          ),
          const Radius.circular(6),
        ),
        Paint()..color = const Color(0xFF456A43),
      );
    }
    if (template == 'timing') {
      final r = Rect.fromLTWH(size.x * .08, size.y * .4, size.x * .84, 14);
      canvas.drawRRect(
        RRect.fromRectAndRadius(r, const Radius.circular(7)),
        Paint()..color = Colors.white,
      );
      canvas.drawRect(
        Rect.fromLTWH(r.left + r.width * .25, r.top, r.width * .5, r.height),
        Paint()..color = const Color(0xFF91AF81),
      );
      canvas.drawCircle(
        Offset(r.left + r.width * rhythm, r.center.dy),
        10,
        Paint()..color = const Color(0xFF795548),
      );
    }
  }
}

class QuestPlay extends StatefulWidget {
  final Quest quest;
  final AppController controller;
  const QuestPlay({super.key, required this.quest, required this.controller});
  @override
  State<QuestPlay> createState() => _QuestPlayState();
}

class _QuestPlayState extends State<QuestPlay> {
  late final QuestScene scene;
  String feedback = '';
  String? selectedId, incorrectTarget;
  Timer? hold;
  @override
  void initState() {
    super.initState();
    scene = QuestScene(
      topicWorld: widget.quest.topicId,
      template: widget.quest.template,
      reducedMotion: widget.controller.settings['motion'] != true,
      onTap: _pourOrTime,
    );
  }

  @override
  void dispose() {
    hold?.cancel();
    scene.pauseEngine();
    super.dispose();
  }

  void _pourOrTime() {
    final q = widget.quest, c = widget.controller;
    if (!mounted || c.process(q).status != ProcessStatus.playing) {
      hold?.cancel();
      return;
    }
    if (q.template == 'timing' &&
        c.settings['motion'] == true &&
        (scene.rhythm < .25 || scene.rhythm > .75)) {
      setState(() => feedback = 'Try when the marker is in the green middle.');
      return;
    }
    c.recordAction(q, 'pulse-${c.doneActions(q)}');
    if (c.process(q).status != ProcessStatus.playing) hold?.cancel();
    audio.action(c.settings['sound'] == true);
    setState(
      () => feedback = q.template == 'pour' ? 'A little more…' : 'Steady work!',
    );
  }

  void accept(QuestItem item, String target) {
    final q = widget.quest, c = widget.controller;
    if (c.process(q).status != ProcessStatus.playing) return;
    if (c.actions[q.id]?.contains(item.id) == true) return;
    if (target != item.target) {
      setState(() {
        selectedId = item.id;
        incorrectTarget = target;
        feedback = 'Try another place for ${item.label}.';
      });
      return;
    }
    if (q.template == 'sequence' && q.items.indexOf(item) != c.doneActions(q)) {
      setState(
        () => feedback = 'Start with the first stage, then follow the process.',
      );
      return;
    }
    c.recordAction(q, item.id);
    HapticFeedback.selectionClick();
    audio.action(c.settings['sound'] == true);
    setState(() {
      selectedId = null;
      incorrectTarget = null;
      feedback = 'That’s it! ${item.label} → $target';
    });
  }

  @override
  Widget build(BuildContext context) {
    final q = widget.quest, c = widget.controller;
    final count = c.doneActions(q);
    scene.progress = count / c.targetActions(q);
    final isPulse = q.template == 'pour' || q.template == 'timing';
    final targets = q.items.map((i) => i.target).toSet().toList();
    final selected = q.items.where((i) => i.id == selectedId).firstOrNull;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        WorldView(world: q.topicId, height: 260),
        const SizedBox(height: 8),
        if (isPulse)
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: SizedBox(
              height: 58,
              child: ExcludeSemantics(child: GameWidget(game: scene)),
            ),
          ),
        const SizedBox(height: 16),
        Text(q.instruction, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Text(
          '$count of ${c.targetActions(q)} actions',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 8),
        Semantics(
          container: true,
          child: LinearProgressIndicator(
            value: count / c.targetActions(q),
            minHeight: 7,
            borderRadius: BorderRadius.circular(7),
            semanticsLabel:
                'Activity progress: $count of ${c.targetActions(q)} actions complete',
          ),
        ),
        const SizedBox(height: 12),
        if (isPulse)
          GestureDetector(
            onLongPressStart: q.template == 'pour'
                ? (_) {
                    hold = Timer.periodic(
                      const Duration(milliseconds: 650),
                      (_) => _pourOrTime(),
                    );
                  }
                : null,
            onLongPressEnd: (_) => hold?.cancel(),
            onLongPressCancel: () => hold?.cancel(),
            child: FilledButton.icon(
              onPressed: _pourOrTime,
              icon: Icon(
                q.template == 'pour' ? Icons.water_drop_outlined : Icons.sync,
              ),
              label: Text(
                q.template == 'pour' ? 'Pour a little' : 'Turn steadily',
              ),
            ),
          ),
        if (isPulse)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              q.template == 'pour'
                  ? 'Tap to pour, or hold for a gentle continuous pour.'
                  : 'Tap when the marker is in the middle. Reduced motion removes the timing requirement.',
            ),
          ),
        if (!isPulse) ...[
          const Text('1. Select an item'),
          const SizedBox(height: 8),
          for (final item in q.items)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: LongPressDraggable<QuestItem>(
                data: item,
                maxSimultaneousDrags: c.actions[q.id]?.contains(item.id) == true
                    ? 0
                    : 1,
                feedback: Material(
                  color: Theme.of(context).colorScheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(16),
                  elevation: 6,
                  child: SizedBox(
                    width: 200,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(item.label, softWrap: true),
                    ),
                  ),
                ),
                child: ChoiceCard(
                  key: ValueKey('quest-item-${item.id}'),
                  label: item.label,
                  selected: selectedId == item.id,
                  completed: c.actions[q.id]?.contains(item.id) == true,
                  onPressed: c.actions[q.id]?.contains(item.id) == true
                      ? null
                      : () => setState(() {
                          selectedId = item.id;
                          incorrectTarget = null;
                          feedback = '';
                        }),
                ),
              ),
            ),
          const SizedBox(height: 12),
          Text(
            selected == null
                ? '2. Choose a destination after selecting an item'
                : '2. Where does ${selected.label} belong?',
          ),
          const SizedBox(height: 8),
          for (final target in targets)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: DragTarget<QuestItem>(
                onAcceptWithDetails: (d) => accept(d.data, target),
                builder: (context, candidates, rejected) => ChoiceCard(
                  key: ValueKey('quest-target-${q.id}-$target'),
                  label: target,
                  selected: candidates.isNotEmpty,
                  incorrect: incorrectTarget == target,
                  onPressed: selected == null
                      ? null
                      : () => accept(selected, target),
                ),
              ),
            ),
          const Text(
            'You can also hold an item and drag it to its destination.',
          ),
        ],
        if (feedback.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Semantics(
              liveRegion: true,
              child: Text(
                feedback,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
      ],
    );
  }
}
