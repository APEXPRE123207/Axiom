import 'dart:async';
import 'package:flutter/foundation.dart';
import '../audio/sound_engine.dart';
import '../core/protocol/protocol.dart';
import '../core/transport/itransport.dart';
import 'key_model.dart';
import 'rgb_effects.dart';
import 'standard_layout.dart';

class KeyboardEngine extends ChangeNotifier {
  ITransport transport;
  List<List<KeyModel>> rows = [];
  final Set<String> _activeDownKeys = {};

  // Long-press auto-repeat state
  Timer? _repeatInitialTimer;
  Timer? _repeatPeriodicTimer;
  String? _repeatingKeyId;

  void setTransport(ITransport newTransport) {
    transport = newTransport;
  }

  bool isShiftActive = false;
  bool isCapsLockActive = false;
  bool isCtrlActive = false;
  bool isAltActive = false;

  KeyboardEngine({required this.transport}) {
    loadLayout(StandardLayout.getRows());
  }

  void loadLayout(List<List<KeyModel>> newRows) {
    _cancelRepeat();
    rows = newRows;
    _activeDownKeys.clear();
    notifyListeners();
  }

  bool _isRepeatableKey(String logicalCode) {
    switch (logicalCode) {
      case 'BACKSPACE':
      case 'DELETE':
      case 'ARROW_LEFT':
      case 'ARROW_RIGHT':
      case 'ARROW_UP':
      case 'ARROW_DOWN':
      case 'SPACE':
        return true;
      default:
        return false;
    }
  }

  void _cancelRepeat() {
    _repeatInitialTimer?.cancel();
    _repeatInitialTimer = null;
    _repeatPeriodicTimer?.cancel();
    _repeatPeriodicTimer = null;
    _repeatingKeyId = null;
  }

  void onKeyDown(KeyModel key, {int row = 0, int col = 0}) {
    if (_activeDownKeys.contains(key.id)) return;
    _activeDownKeys.add(key.id);
    key.isPressed = true;

    // Trigger local mechanical sound & haptics
    SoundEngine.instance.playKeySound();

    // Trigger dynamic RGB lighting reaction
    RgbEngine.instance.triggerKeyPress(row, col);

    // Handle toggles / modifiers
    if (key.logicalCode == "CAPS_LOCK") {
      isCapsLockActive = !isCapsLockActive;
      key.isToggled = isCapsLockActive;
    } else if (key.logicalCode == "SHIFT") {
      isShiftActive = true;
    } else if (key.logicalCode == "CTRL") {
      isCtrlActive = true;
    } else if (key.logicalCode == "ALT") {
      isAltActive = true;
    }

    notifyListeners();

    // Send packet via transport
    transport.send(AxiomPacket(
      type: AxiomEventType.keyDown,
      data: {
        'key': key.logicalCode,
        'vk': key.vk,
      },
    ));

    // Handle long-press auto-repeat for navigation & editing keys
    _cancelRepeat();
    if (_isRepeatableKey(key.logicalCode)) {
      _repeatingKeyId = key.id;
      _repeatInitialTimer = Timer(const Duration(milliseconds: 350), () {
        if (!_activeDownKeys.contains(key.id)) return;
        _repeatPeriodicTimer = Timer.periodic(const Duration(milliseconds: 50), (_) {
          if (!_activeDownKeys.contains(key.id)) {
            _cancelRepeat();
            return;
          }

          // Dispatch repeat event (silent during continuous hold)
          transport.send(AxiomPacket(
            type: AxiomEventType.keyDown,
            data: {
              'key': key.logicalCode,
              'vk': key.vk,
            },
          ));
        });
      });
    }
  }

  void onKeyUp(KeyModel key) {
    if (!_activeDownKeys.contains(key.id)) return;
    _activeDownKeys.remove(key.id);
    key.isPressed = false;

    if (_repeatingKeyId == key.id) {
      _cancelRepeat();
    }

    if (key.logicalCode == "SHIFT") {
      isShiftActive = false;
    } else if (key.logicalCode == "CTRL") {
      isCtrlActive = false;
    } else if (key.logicalCode == "ALT") {
      isAltActive = false;
    }

    notifyListeners();

    // Send packet via transport
    transport.send(AxiomPacket(
      type: AxiomEventType.keyUp,
      data: {
        'key': key.logicalCode,
        'vk': key.vk,
      },
    ));
  }

  void releaseAll() {
    _cancelRepeat();
    for (final row in rows) {
      for (final key in row) {
        if (key.isPressed) {
          key.isPressed = false;
          transport.send(AxiomPacket(
            type: AxiomEventType.keyUp,
            data: {'key': key.logicalCode, 'vk': key.vk},
          ));
        }
      }
    }
    _activeDownKeys.clear();
    isShiftActive = false;
    isCtrlActive = false;
    isAltActive = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _cancelRepeat();
    super.dispose();
  }
}
