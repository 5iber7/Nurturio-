import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../core/app_controller.dart';
import '../../game/engine/process_engine.dart';
import '../../game/components/plant_art.dart';

class GardenScreen extends ConsumerStatefulWidget {
  const GardenScreen({super.key});
  @override
  ConsumerState<GardenScreen> createState() => _GardenScreenState();
}

class _GardenScreenState extends ConsumerState<GardenScreen> {
  final selected = {0: 'tomato', 1: 'sunflower', 2: 'basil'};
  @override
  Widget build(BuildContext context) {
    final c = ref.watch(controllerProvider);
    return Scaffold(
      appBar: AppBar(
        leading: const VillageBackButton(),
        title: const Text('Your growing beds'),
      ),
      body: PageBody(
        children: [
          Text(
            'Give a little care.\nWatch a little wonder.',
            style: Theme.of(context).textTheme.displaySmall,
          ),
          const SizedBox(height: 12),
          const Text(
            'Choose from eight plants. Their game waits differ; real growing times depend on variety and conditions.',
          ),
          const SizedBox(height: 22),
          for (var slot = 0; slot < 3; slot++)
            Padding(
              padding: const EdgeInsets.only(bottom: 18),
              child: SoftCard(
                child: Builder(
                  builder: (context) {
                    final bed = c.beds[slot],
                        plant = bed == null
                            ? null
                            : c.library.plants.firstWhere(
                                (p) => p['id'] == bed.plantId,
                              );
                    final p = bed?.process;
                    final duration =
                        p?.readyAt?.difference(p.startedAt!).inSeconds ?? 1;
                    final remaining = p == null ? 0 : c.engine.remaining(p);
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'BED ${slot + 1}',
                          style: TextStyle(
                            letterSpacing: 1.5,
                            fontWeight: FontWeight.bold,
                            color: accent(context),
                          ),
                        ),
                        if (bed == null ||
                            p!.status == ProcessStatus.completed) ...[
                          if (bed != null) ...[
                            const SizedBox(height: 12),
                            Text(
                              '${plant!['name']} discovered!',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const Text(
                              'Your plant card is in the collection. Plant again whenever you like.',
                            ),
                            const SizedBox(height: 12),
                          ],
                          DropdownButtonFormField<String>(
                            initialValue: selected[slot],
                            decoration: const InputDecoration(
                              labelText: 'Choose a plant',
                            ),
                            items: [
                              for (final option in c.library.plants)
                                DropdownMenuItem(
                                  value: option['id'] as String,
                                  child: Text(option['name']),
                                ),
                            ],
                            onChanged: (v) =>
                                setState(() => selected[slot] = v!),
                          ),
                          const SizedBox(height: 12),
                          FilledButton.icon(
                            onPressed: () => c.plant(slot, selected[slot]!),
                            icon: const Icon(Icons.spa_outlined),
                            label: const Text('Plant in this bed'),
                          ),
                        ] else ...[
                          Text(
                            plant!['name'],
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          PlantArt(
                            plant: bed.plantId,
                            progress: (1 - remaining / duration).clamp(0, 1),
                          ),
                          Text('Stages: ${plant['timeline']}'),
                          const SizedBox(height: 8),
                          Text('Real life: ${plant['duration']}'),
                          Text(
                            'Game: ${p.status == ProcessStatus.ready ? 'Ready to enjoy' : '$remaining seconds remaining'}',
                          ),
                          const SizedBox(height: 12),
                          if (bed.needsCare(c.engine.clock.now()))
                            const Padding(
                              padding: EdgeInsets.only(bottom: 8),
                              child: Text(
                                'Your simulated bed could use care. Water it to continue; your plant is safe.',
                              ),
                            ),
                          OutlinedButton.icon(
                            onPressed: () => c.waterBed(slot),
                            icon: const Icon(Icons.water_drop_outlined),
                            label: Text(
                              bed.needsCare(c.engine.clock.now())
                                  ? 'Water gently'
                                  : 'Water checked',
                            ),
                          ),
                          if (p.status == ProcessStatus.ready) ...[
                            const SizedBox(height: 10),
                            FilledButton(
                              onPressed: bed.needsCare(c.engine.clock.now())
                                  ? null
                                  : () => c.harvestBed(slot),
                              child: const Text('Enjoy & collect plant card'),
                            ),
                          ],
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: () =>
                                context.push('/article/plant/${bed.plantId}'),
                            child: const Text('Read this plant’s field notes'),
                          ),
                        ],
                      ],
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }
}
