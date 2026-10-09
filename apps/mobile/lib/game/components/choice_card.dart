import 'package:flutter/material.dart';

/// A choice that grows with its text instead of squeezing it beside an icon.
class ChoiceCard extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool selected, completed, incorrect;
  const ChoiceCard({
    super.key,
    required this.label,
    required this.onPressed,
    this.selected = false,
    this.completed = false,
    this.incorrect = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final highlight = incorrect ? colors.error : colors.primary;
    return Semantics(
      container: true,
      selected: selected,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.all(16),
          foregroundColor: completed ? colors.primary : colors.onSurface,
          disabledForegroundColor: completed ? colors.primary : null,
          backgroundColor: selected || completed || incorrect
              ? highlight.withValues(alpha: .09)
              : colors.surfaceContainer,
          side: BorderSide(
            color: selected || completed || incorrect
                ? highlight
                : colors.outline.withValues(alpha: .45),
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                label,
                softWrap: true,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(width: 12),
            Icon(
              completed
                  ? Icons.check_circle_rounded
                  : incorrect
                  ? Icons.refresh_rounded
                  : selected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}

class LearningCheck extends StatefulWidget {
  final List<String> answers;
  final bool Function(int answer) onAnswer;
  final String explanation;
  const LearningCheck({
    super.key,
    required this.answers,
    required this.onAnswer,
    required this.explanation,
  });
  @override
  State<LearningCheck> createState() => _LearningCheckState();
}

class _LearningCheckState extends State<LearningCheck> {
  int? incorrect;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      for (var i = 0; i < widget.answers.length; i++)
        Padding(
          padding: const EdgeInsets.only(top: 10),
          child: ChoiceCard(
            label: widget.answers[i],
            incorrect: incorrect == i,
            onPressed: () {
              final correct = widget.onAnswer(i);
              if (mounted) setState(() => incorrect = correct ? null : i);
            },
          ),
        ),
      if (incorrect != null)
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Semantics(
            liveRegion: true,
            child: Text('Try another choice. ${widget.explanation}'),
          ),
        ),
    ],
  );
}
