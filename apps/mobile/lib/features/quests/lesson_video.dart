import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class LessonVideo extends StatefulWidget {
  final String url, transcript;
  const LessonVideo({super.key, required this.url, required this.transcript});
  @override
  State<LessonVideo> createState() => _LessonVideoState();
}

class _LessonVideoState extends State<LessonVideo> {
  VideoPlayerController? player;
  String? error;
  @override
  void initState() {
    super.initState();
    initialize();
  }

  Future<void> initialize() async {
    final uri = Uri.tryParse(widget.url);
    final hosts = const String.fromEnvironment('NURTURIO_VIDEO_HOSTS')
        .split(',')
        .where((s) => s.isNotEmpty);
    if (uri == null || uri.scheme != 'https' || !hosts.contains(uri.host)) {
      setState(
        () =>
            error = 'This video is not available. Read the lesson text below.',
      );
      return;
    }
    final p = VideoPlayerController.networkUrl(uri);
    player = p;
    try {
      await p.initialize();
      if (mounted) setState(() {});
    } catch (_) {
      if (mounted) {
        setState(
          () => error =
              'The video could not load. The lesson still works offline.',
        );
      }
    }
  }

  @override
  void dispose() {
    player?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      if (error != null)
        Text(error!)
      else if (player?.value.isInitialized != true)
        const Center(child: CircularProgressIndicator())
      else ...[
        AspectRatio(
          aspectRatio: player!.value.aspectRatio,
          child: VideoPlayer(player!),
        ),
        TextButton.icon(
          onPressed: () {
            setState(() {
              player!.value.isPlaying ? player!.pause() : player!.play();
            });
          },
          icon: Icon(player!.value.isPlaying ? Icons.pause : Icons.play_arrow),
          label: Text(player!.value.isPlaying ? 'Pause video' : 'Play video'),
        ),
      ],
      ExpansionTile(
        title: const Text('Video transcript'),
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(widget.transcript),
          ),
        ],
      ),
    ],
  );
}
