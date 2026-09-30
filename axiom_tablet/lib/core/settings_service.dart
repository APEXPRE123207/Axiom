import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../audio/sound_engine.dart';
import '../keyboard/rgb_effects.dart';
import '../themes/theme_model.dart';
import '../ui/connection_bar.dart';

class SettingsService {
  static final SettingsService instance = SettingsService._internal();
  SettingsService._internal();

  SharedPreferences? _prefs;

  Future<void> init() async {
    try {
      _prefs = await SharedPreferences.getInstance().timeout(const Duration(milliseconds: 500));
      _loadSettings();
    } catch (e) {
      debugPrint("Settings init fallback: $e");
    }
  }

  void _loadSettings() {
    if (_prefs == null) return;

    // 1. Sound & Haptics
    final profileIndex = _prefs!.getInt('sound_profile');
    if (profileIndex != null && profileIndex < SoundProfile.values.length) {
      SoundEngine.instance.setProfile(SoundProfile.values[profileIndex]);
    }
    final volume = _prefs!.getDouble('sound_volume');
    if (volume != null) {
      SoundEngine.instance.setVolume(volume);
    }
    final haptics = _prefs!.getBool('haptics_enabled');
    if (haptics != null) {
      SoundEngine.instance.hapticsEnabled = haptics;
    }

    // 2. RGB Lighting & Theme
    final rgbIndex = _prefs!.getInt('rgb_mode');
    if (rgbIndex != null && rgbIndex < RgbEffectMode.values.length) {
      RgbEngine.instance.setMode(RgbEffectMode.values[rgbIndex]);
    }
    final themeName = _prefs!.getString('theme_name');
    if (themeName != null) {
      try {
        final theme = AxiomTheme.allThemes.firstWhere((t) => t.name == themeName);
        RgbEngine.instance.setTheme(theme);
      } catch (_) {}
    }
  }

  // --- Mode (Standard, Ergonomic, Touchpad) ---
  AxiomMode loadMode() {
    final idx = _prefs?.getInt('app_mode');
    if (idx != null && idx < AxiomMode.values.length) {
      return AxiomMode.values[idx];
    }
    return AxiomMode.standard;
  }

  Future<void> saveMode(AxiomMode mode) async {
    await _prefs?.setInt('app_mode', mode.index);
  }

  // --- Sound & Haptics ---
  Future<void> saveSoundProfile(SoundProfile profile) async {
    await _prefs?.setInt('sound_profile', profile.index);
  }

  Future<void> saveVolume(double vol) async {
    await _prefs?.setDouble('sound_volume', vol);
  }

  Future<void> saveHaptics(bool enabled) async {
    await _prefs?.setBool('haptics_enabled', enabled);
  }

  // --- RGB & Themes ---
  Future<void> saveRgbMode(RgbEffectMode mode) async {
    await _prefs?.setInt('rgb_mode', mode.index);
  }

  Future<void> saveTheme(AxiomTheme theme) async {
    await _prefs?.setString('theme_name', theme.name);
  }

  // --- Ergonomic Split Keyboard Settings ---
  double loadErgoLeftScale() => _prefs?.getDouble('ergo_left_scale') ?? _prefs?.getDouble('ergo_scale') ?? 0.85;
  double loadErgoRightScale() => _prefs?.getDouble('ergo_right_scale') ?? _prefs?.getDouble('ergo_scale') ?? 0.85;
  double loadErgoScale() => loadErgoLeftScale();
  double loadErgoAngle() => _prefs?.getDouble('ergo_angle') ?? 8.0;
  double loadErgoGap() => _prefs?.getDouble('ergo_gap') ?? 32.0;

  Offset loadErgoLeftOffset() {
    final x = _prefs?.getDouble('ergo_left_x') ?? 0.0;
    final y = _prefs?.getDouble('ergo_left_y') ?? 0.0;
    return Offset(x, y);
  }

  Offset loadErgoRightOffset() {
    final x = _prefs?.getDouble('ergo_right_x') ?? 0.0;
    final y = _prefs?.getDouble('ergo_right_y') ?? 0.0;
    return Offset(x, y);
  }

  Future<void> saveErgoConfig({
    required double leftScale,
    required double rightScale,
    required double angle,
    required double gap,
    required Offset leftOffset,
    required Offset rightOffset,
  }) async {
    await _prefs?.setDouble('ergo_left_scale', leftScale);
    await _prefs?.setDouble('ergo_right_scale', rightScale);
    await _prefs?.setDouble('ergo_angle', angle);
    await _prefs?.setDouble('ergo_gap', gap);
    await _prefs?.setDouble('ergo_left_x', leftOffset.dx);
    await _prefs?.setDouble('ergo_left_y', leftOffset.dy);
    await _prefs?.setDouble('ergo_right_x', rightOffset.dx);
    await _prefs?.setDouble('ergo_right_y', rightOffset.dy);
  }

  // --- Connection / Session Persistence ---
  String? loadSessionToken() => _prefs?.getString('session_token');
  Future<void> saveSessionToken(String token) async => await _prefs?.setString('session_token', token);

  String? loadLastHostIp() => _prefs?.getString('last_host_ip');
  Future<void> saveLastHostIp(String ip) async => await _prefs?.setString('last_host_ip', ip);

  int? loadLastPort() => _prefs?.getInt('last_port');
  Future<void> saveLastPort(int port) async => await _prefs?.setInt('last_port', port);
}
