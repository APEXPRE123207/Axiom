import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

enum SoundProfile {
  clicky, // Razer Green / Cherry Blue (Crisp tactile snap)
  tactile, // Razer Orange / Cherry Brown (Deep mechanical thock)
  linear, // Razer Yellow / Cherry Red (Smooth acoustic clack)
  off,
}

class SoundEngine {
  static final SoundEngine instance = SoundEngine._internal();
  SoundEngine._internal();

  SoundProfile currentProfile = SoundProfile.clicky;
  double volume = 0.8;
  bool hapticsEnabled = true;

  static const int _poolSize = 4;
  final List<AudioPlayer> _players = [];
  int _playerIndex = 0;
  bool _initialized = false;

  final Map<SoundProfile, Source> _sources = {
    SoundProfile.clicky: AssetSource('sounds/clicky.wav'),
    SoundProfile.tactile: AssetSource('sounds/tactile.wav'),
    SoundProfile.linear: AssetSource('sounds/linear.wav'),
  };

  Future<void> init() async {
    if (_initialized) return;
    try {
      await AudioPlayer.global.setAudioContext(
        AudioContext(
          android: const AudioContextAndroid(
            isSpeakerphoneOn: false,
            audioMode: AndroidAudioMode.normal,
            stayAwake: false,
            contentType: AndroidContentType.sonification,
            usageType: AndroidUsageType.assistanceSonification,
            audioFocus: AndroidAudioFocus.none,
          ),
          iOS: AudioContextIOS(
            category: AVAudioSessionCategory.ambient,
            options: const {},
          ),
        ),
      );

      for (int i = 0; i < _poolSize; i++) {
        final player = AudioPlayer();
        await player.setPlayerMode(PlayerMode.mediaPlayer);
        await player.setVolume(volume);
        _players.add(player);
      }
      _initialized = true;
      _checkHardwareVibrator();
    } catch (_) {}
  }

  static const MethodChannel _hapticChannel = MethodChannel('axiom/haptics');
  bool hasHardwareVibrator = true;

  Future<void> _checkHardwareVibrator() async {
    try {
      final res = await _hapticChannel.invokeMethod<bool>('hasVibrator');
      if (res != null) {
        hasHardwareVibrator = res;
      }
    } catch (_) {}
  }

  void _triggerHaptic() {
    try {
      _hapticChannel.invokeMethod('vibrate', {'duration': 50, 'amplitude': 255});
    } catch (_) {}
    HapticFeedback.vibrate();
    HapticFeedback.lightImpact();
    HapticFeedback.selectionClick();
  }

  void playKeySound() {
    if (hapticsEnabled) {
      _triggerHaptic();
    }

    if (currentProfile == SoundProfile.off) {
      return;
    }

    final source = _sources[currentProfile];

    if (_players.isNotEmpty && source != null) {
      try {
        final player = _players[_playerIndex];
        _playerIndex = (_playerIndex + 1) % _players.length;
        player.play(source, volume: volume).catchError((_) {
          SystemSound.play(SystemSoundType.click);
        });
      } catch (_) {
        SystemSound.play(SystemSoundType.click);
      }
    } else {
      SystemSound.play(SystemSoundType.click);
    }
  }

  void setProfile(SoundProfile profile) {
    currentProfile = profile;
  }

  void setVolume(double vol) {
    volume = vol.clamp(0.0, 1.0);
    for (final player in _players) {
      player.setVolume(volume).catchError((_) {});
    }
  }

  void dispose() {
    for (final player in _players) {
      player.dispose().catchError((_) {});
    }
    _players.clear();
    _initialized = false;
  }
}
