import 'package:audioplayers/audioplayers.dart';

class AudioService {
  final ambience = AudioPlayer(), effect = AudioPlayer();
  bool playing = false;
  Future<void> setMusic(bool value) async {
    if (value == playing) return;
    playing = value;
    try {
      if (value) {
        await ambience.setReleaseMode(ReleaseMode.loop);
        await ambience.play(AssetSource('audio/village.wav'), volume: .22);
      } else {
        await ambience.stop();
      }
    } catch (_) {
      playing = false;
    }
  }

  Future<void> action(bool enabled) async {
    if (enabled) {
      try {
        await effect.play(AssetSource('audio/discovery.wav'), volume: .25);
      } catch (_) {
        /* Optional sound must not interrupt gameplay. */
      }
    }
  }

  Future<void> pause() => setMusic(false);
}

final audio = AudioService();
