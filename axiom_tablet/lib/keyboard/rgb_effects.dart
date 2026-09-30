import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../themes/theme_model.dart';

enum RgbEffectMode {
  staticGlow,
  reactive,
  ripple,
  wave,
  breathing,
}

class RippleWave {
  final int originRow;
  final int originCol;
  final int birthTime;
  double radius = 0.0;

  RippleWave({
    required this.originRow,
    required this.originCol,
    required this.birthTime,
  });
}

class RgbEngine extends ChangeNotifier {
  static final RgbEngine instance = RgbEngine._internal();
  RgbEngine._internal();

  RgbEffectMode currentMode = RgbEffectMode.reactive;
  AxiomTheme currentTheme = AxiomTheme.cyberBlue;

  // Active ripples
  final List<RippleWave> _activeRipples = [];

  // Wave & Breathing state
  Ticker? _ticker;
  double _animationPhase = 0.0;
  double _breathingFactor = 1.0;
  int _lastTickMs = 0;

  void init(TickerProvider vsync) {
    _ticker?.dispose();
    _ticker = vsync.createTicker(_onTick);
    _lastTickMs = 0;
    _updateTickerState();
  }

  void _updateTickerState() {
    if (_ticker == null) return;
    final needsTicker = currentMode == RgbEffectMode.wave ||
        currentMode == RgbEffectMode.breathing ||
        (currentMode == RgbEffectMode.ripple && _activeRipples.isNotEmpty);

    if (needsTicker && !_ticker!.isActive) {
      _lastTickMs = 0;
      _ticker!.start();
    } else if (!needsTicker && _ticker!.isActive) {
      _ticker!.stop();
      _lastTickMs = 0;
    }
  }

  void _onTick(Duration elapsed) {
    final ms = elapsed.inMilliseconds;

    // Reset if clock wrapped, stopped, or restarted
    if (ms < _lastTickMs) {
      _lastTickMs = ms;
    }

    if (currentMode == RgbEffectMode.wave || currentMode == RgbEffectMode.breathing) {
      // Cap ambient wave/breathing at ~30 FPS (33ms per frame) to preserve tablet CPU & GPU
      if (ms - _lastTickMs < 33) return;
      _lastTickMs = ms;

      if (currentMode == RgbEffectMode.wave) {
        _animationPhase = (ms / 1500.0) % (2 * pi);
      } else {
        _breathingFactor = 0.65 + 0.35 * sin(ms / 800.0);
      }
      notifyListeners();
    } else if (currentMode == RgbEffectMode.ripple) {
      _lastTickMs = ms;
      if (_activeRipples.isEmpty) {
        _updateTickerState();
        return;
      }
      final now = DateTime.now().millisecondsSinceEpoch;
      _activeRipples.removeWhere((r) {
        final age = (now - r.birthTime) / 600.0;
        r.radius = age * 16.0;
        return age >= 1.0;
      });
      notifyListeners();
      if (_activeRipples.isEmpty) {
        _updateTickerState();
      }
    }
  }

  void triggerKeyPress(int row, int col) {
    if (currentMode == RgbEffectMode.ripple) {
      _activeRipples.add(RippleWave(
        originRow: row,
        originCol: col,
        birthTime: DateTime.now().millisecondsSinceEpoch,
      ));
      _updateTickerState();
      notifyListeners();
    }
  }

  void setMode(RgbEffectMode mode) {
    currentMode = mode;
    _activeRipples.clear();
    _lastTickMs = 0;
    _updateTickerState();
    notifyListeners();
  }

  void setTheme(AxiomTheme theme) {
    currentTheme = theme;
    notifyListeners();
  }

  /// Calculates the dynamic illumination color for a specific key
  Color getKeyColor({
    required int row,
    required int col,
    required bool isPressed,
    required bool isModifier,
  }) {
    if (isPressed) {
      return currentTheme.accentPressed;
    }

    final base = isModifier ? currentTheme.keyModifier : currentTheme.keyBase;

    switch (currentMode) {
      case RgbEffectMode.staticGlow:
        return base;

      case RgbEffectMode.reactive:
        // When not pressed in reactive mode, returns sleek dark keycap
        return base;

      case RgbEffectMode.wave:
        // Horizontal spectrum phase
        final waveVal = (sin(_animationPhase + (col * 0.45) + (row * 0.2)) + 1.0) / 2.0;
        return Color.lerp(base, currentTheme.accentGlow, waveVal * 0.55)!;

      case RgbEffectMode.breathing:
        return Color.lerp(base, currentTheme.accentGlow, _breathingFactor * 0.4)!;

      case RgbEffectMode.ripple:
        if (_activeRipples.isEmpty) return base;
        double maxWaveIntensity = 0.0;
        for (final ripple in _activeRipples) {
          final dist = sqrt(pow(row - ripple.originRow, 2) + pow(col - ripple.originCol, 2));
          final diff = (dist - ripple.radius).abs();
          if (diff < 1.8) {
            final intensity = (1.0 - (diff / 1.8)) * (1.0 - (ripple.radius / 16.0)).clamp(0.0, 1.0);
            if (intensity > maxWaveIntensity) maxWaveIntensity = intensity;
          }
        }
        if (maxWaveIntensity > 0.05) {
          return Color.lerp(base, currentTheme.accentGlow, maxWaveIntensity * 0.85)!;
        }
        return base;
    }
  }

  Color getKeyBorderColor({
    required int row,
    required int col,
    required bool isPressed,
    required bool isModifier,
  }) {
    if (isPressed) {
      return currentTheme.accentGlow;
    }

    if (currentMode == RgbEffectMode.wave) {
      final waveVal = (sin(_animationPhase + (col * 0.45) + (row * 0.2)) + 1.0) / 2.0;
      return Color.lerp(currentTheme.borderColor, currentTheme.accentGlow, waveVal * 0.8)!;
    } else if (currentMode == RgbEffectMode.breathing) {
      return Color.lerp(currentTheme.borderColor, currentTheme.accentGlow, _breathingFactor * 0.6)!;
    } else if (currentMode == RgbEffectMode.ripple && _activeRipples.isNotEmpty) {
      for (final ripple in _activeRipples) {
        final dist = sqrt(pow(row - ripple.originRow, 2) + pow(col - ripple.originCol, 2));
        final diff = (dist - ripple.radius).abs();
        if (diff < 1.8) {
          final intensity = (1.0 - (diff / 1.8)) * (1.0 - (ripple.radius / 16.0)).clamp(0.0, 1.0);
          if (intensity > 0.1) {
            return Color.lerp(currentTheme.borderColor, currentTheme.accentGlow, intensity * 0.9)!;
          }
        }
      }
    }

    return currentTheme.borderColor;
  }

  @override
  void dispose() {
    _ticker?.dispose();
    super.dispose();
  }
}
