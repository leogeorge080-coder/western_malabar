import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

class ScanFeedback {
  ScanFeedback._();

  static final AudioPlayer _player = AudioPlayer();

  static Future<void> success() async {
    await HapticFeedback.mediumImpact();
    try {
      await _player.stop();
      await _player.play(AssetSource('sfx/success_beep.mp3'));
    } catch (_) {}
  }

  static Future<void> error() async {
    await HapticFeedback.heavyImpact();
    try {
      await _player.stop();
      await _player.play(AssetSource('sfx/error_beep.mp3'));
    } catch (_) {}
  }

  static Future<void> soft() async {
    await HapticFeedback.selectionClick();
  }
}


