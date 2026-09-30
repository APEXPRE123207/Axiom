import 'package:flutter_test/flutter_test.dart';
import 'package:axiom_tablet/audio/sound_engine.dart';
import 'package:axiom_tablet/keyboard/rgb_effects.dart';
import 'package:axiom_tablet/themes/theme_model.dart';

void main() {
  test('SoundEngine profiles and volume test', () {
    final sound = SoundEngine.instance;
    expect(sound.currentProfile, SoundProfile.clicky);

    sound.setProfile(SoundProfile.tactile);
    expect(sound.currentProfile, SoundProfile.tactile);

    sound.setVolume(0.5);
    expect(sound.volume, 0.5);
  });

  test('RgbEngine modes and theme calculation test', () {
    final rgb = RgbEngine.instance;
    expect(rgb.currentTheme.id, "cyber_blue");

    // Switch theme to Matrix Green
    rgb.setTheme(AxiomTheme.matrixGreen);
    expect(rgb.currentTheme.id, "matrix_green");

    // Switch to Reactive mode
    rgb.setMode(RgbEffectMode.reactive);
    expect(rgb.currentMode, RgbEffectMode.reactive);

    // Verify key color for idle and pressed states
    final idleColor = rgb.getKeyColor(row: 2, col: 2, isPressed: false, isModifier: false);
    final pressedColor = rgb.getKeyColor(row: 2, col: 2, isPressed: true, isModifier: false);
    expect(idleColor, AxiomTheme.matrixGreen.keyBase);
    expect(pressedColor, AxiomTheme.matrixGreen.accentPressed);

    // Switch to Wave mode
    rgb.setMode(RgbEffectMode.wave);
    final waveColor = rgb.getKeyColor(row: 1, col: 5, isPressed: false, isModifier: false);
    expect(waveColor, isNotNull);
  });
}
