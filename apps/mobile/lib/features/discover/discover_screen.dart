import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';

import '../../app/theme.dart';
import '../../core/app_controller.dart';
import '../../core/ai_service.dart';

Uint8List preparePhoto(Uint8List bytes) {
  if (bytes.length < 16) throw StateError('Unsupported image.');
  if (bytes.length > 20 * 1024 * 1024) throw StateError('Photo is too large.');
  final decoded = img.decodeImage(bytes);
  if (decoded == null) throw StateError('Unsupported image.');
  if (decoded.width * decoded.height > 40 * 1000 * 1000) {
    throw StateError('Photo dimensions are too large.');
  }
  final baked = img.bakeOrientation(decoded);
  final resized = img.copyResize(
    baked,
    width: baked.width >= baked.height ? 1536 : null,
    height: baked.height > baked.width ? 1536 : null,
  );
  // Copy pixels into a new image to discard EXIF/GPS and other source metadata.
  final clean = img.Image(
    width: resized.width,
    height: resized.height,
    numChannels: 3,
  );
  for (final pixel in resized) {
    clean.setPixelRgb(pixel.x, pixel.y, pixel.r, pixel.g, pixel.b);
  }
  return Uint8List.fromList(img.encodeJpg(clean, quality: 80));
}

class DiscoverScreen extends ConsumerStatefulWidget {
  const DiscoverScreen({super.key});
  @override
  ConsumerState<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends ConsumerState<DiscoverScreen> {
  final ai = AIService();
  ScanResult? result;
  Uint8List? photo;
  bool busy = false;
  String? message;
  Future<void> choose(ImageSource source) async {
    try {
      final selected = await ImagePicker().pickImage(
        source: source,
        maxWidth: 1536,
        maxHeight: 1536,
        imageQuality: 85,
      );
      if (selected == null) return;
      setState(() => busy = true);
      final bytes = await selected.readAsBytes();
      final clean = await compute(preparePhoto, bytes);
      if (mounted) {
        setState(() {
          photo = clean;
          result = null;
          message = null;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => message = 'We could not open that photo. Check permission or try a smaller image.',
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> analyze() async {
    if (photo == null || !ai.available) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          ai.mock ? 'Preview a sample result?' : 'Analyze this photo?',
        ),
        content: Text(
          ai.mock
              ? 'This development fixture does not analyze or upload your image.'
              : 'This sends the prepared image to the configured identification provider. A photo cannot establish health, edibility, or handling safety.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    setState(() => busy = true);
    try {
      final value = await ai.identify(photo!, ref.read(controllerProvider));
      if (mounted) setState(() => result = value);
    } catch (_) {
      if (mounted) {
        setState(
          () => message = 'Identification could not finish. The service may be unavailable or not enabled for this profile. Try the field guide below.',
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = ref.watch(controllerProvider);
    return PageBody(
      children: [
        Text(
          'What caught\nyour curiosity?',
          style: Theme.of(context).textTheme.displaySmall,
        ),
        const SizedBox(height: 12),
        const Text(
          'Plants, pollinators, everyday wonders. Start with a closer look.',
        ),
        const SizedBox(height: 22),
        SoftCard(
          color: const Color(0xFFE7EDD7),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.center_focus_strong, size: 48, color: accent(context)),
              const SizedBox(height: 12),
              Text(
                ai.mock
                    ? 'Development sample mode'
                    : ai.available
                    ? 'Look closely, learn cautiously'
                    : 'Photo identification is not enabled yet',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 10),
              Text(
                ai.available
                    ? 'Review your photo before choosing analysis. Identification cannot guarantee that an object is safe.'
                    : 'You can preview a photo on this device. No image is uploaded. Explore a plant manually below while identification is unavailable.',
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        if (photo != null) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Image.memory(photo!, height: 240, fit: BoxFit.contain),
          ),
          const SizedBox(height: 10),
          const Text(
            'Local preview only · never use a photo to decide whether something is safe to eat or touch.',
          ),
          const SizedBox(height: 16),
        ],
        if (busy) const Center(child: CircularProgressIndicator()),
        if (photo != null && ai.available)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: FilledButton(
              onPressed: busy ? null : analyze,
              child: Text(ai.mock ? 'Preview sample result' : 'Analyze photo'),
            ),
          ),
        if (result != null) ...[
          SoftCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  result!.name,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text('${result!.status} · ${result!.confidence}'),
                const SizedBox(height: 8),
                Text(result!.description),
                for (final warning in result!.warnings)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Text(
                      warning,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                for (final tip in result!.retakeTips) Text(tip),
                TextButton.icon(
                  onPressed: () {
                    c.addScan({
                      'name': result!.name,
                      'description': result!.description,
                      'date': DateTime.now().toIso8601String(),
                      'type': ai.mock ? 'development-fixture' : 'ai-result',
                    });
                    setState(() => message = 'Saved to your local journal.');
                  },
                  icon: const Icon(Icons.bookmark_add_outlined),
                  label: const Text('Save result locally'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
        ],
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            FilledButton.icon(
              onPressed: busy ? null : () => choose(ImageSource.camera),
              icon: const Icon(Icons.camera_alt_outlined),
              label: Text(photo == null ? 'Take a photo' : 'Retake'),
            ),
            OutlinedButton.icon(
              onPressed: busy ? null : () => choose(ImageSource.gallery),
              icon: const Icon(Icons.photo_library_outlined),
              label: const Text('Choose a photo'),
            ),
          ],
        ),
        if (message != null)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(message!),
          ),
        const SizedBox(height: 28),
        Text(
          'Explore from the field guide',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        for (final plant in c.library.plants)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: SoftCard(
              padding: const EdgeInsets.all(10),
              child: ListTile(
                leading: Icon(Icons.eco_outlined, color: accent(context)),
                title: Text(plant['name']),
                subtitle: const Text(
                  'Manually selected · no photo identification',
                ),
                onTap: () => context.push('/article/plant/${plant['id']}'),
                trailing: IconButton(
                  tooltip: 'Save field guide entry',
                  icon: const Icon(Icons.bookmark_add_outlined),
                  onPressed: () {
                    c.addScan({
                      'name': plant['name'],
                      'description': plant['note'],
                      'date': DateTime.now().toIso8601String(),
                      'type': 'manual-library-entry',
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Field guide entry saved to your journal.',
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
      ],
    );
  }
}
