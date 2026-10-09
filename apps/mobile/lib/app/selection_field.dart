import 'package:flutter/material.dart';

import '../game/components/choice_card.dart';

/// A wrapping selected value and a scrollable panel, including at large text sizes.
class SelectionField<T extends Object> extends StatelessWidget {
  final String label;
  final T value;
  final List<(T, String)> options;
  final ValueChanged<T> onChanged;
  const SelectionField({
    super.key,
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final text = options.firstWhere((option) => option.$1 == value).$2;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 6),
        OutlinedButton(
          style: OutlinedButton.styleFrom(
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.all(16),
          ),
          onPressed: () async {
            final selected = await showModalBottomSheet<T>(
              context: context,
              useSafeArea: true,
              isScrollControlled: true,
              builder: (sheetContext) => SafeArea(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.sizeOf(sheetContext).height * .8,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                label,
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                            ),
                            IconButton(
                              tooltip: 'Close choices',
                              onPressed: () => Navigator.pop(sheetContext),
                              icon: const Icon(Icons.close),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Flexible(
                          child: ListView(
                            shrinkWrap: true,
                            children: [
                              for (final option in options)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: ChoiceCard(
                                    label: option.$2,
                                    selected: option.$1 == value,
                                    onPressed: () =>
                                        Navigator.pop(sheetContext, option.$1),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
            if (context.mounted && selected != null) onChanged(selected);
          },
          child: Row(
            children: [
              Expanded(child: Text(text, softWrap: true)),
              const SizedBox(width: 12),
              const Icon(Icons.expand_more),
            ],
          ),
        ),
      ],
    );
  }
}
