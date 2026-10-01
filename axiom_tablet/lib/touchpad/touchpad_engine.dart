import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import '../core/protocol/protocol.dart';
import '../core/settings_service.dart';
import '../core/transport/itransport.dart';

enum TouchpadModeState {
  idle,
  tracking1Finger,
  tracking2Finger,
  tracking3Finger,
  tracking4Finger,
  dragging,
}

class TouchpadEngine {
  ITransport transport;

  void setTransport(ITransport newTransport) {
    transport = newTransport;
  }

  // Settings
  double sensitivity = 1.6;
  double scrollSensitivity = 0.5;
  bool showMouseButtons = false;

  // Gesture Preference: True = Browser Tabs (Ctrl+Tab), False = Windows Apps (Alt+Tab)
  bool threeFingerTabMode = false;

  // Real-time gesture feedback notifications for HUD
  final ValueNotifier<String?> activeGestureFeedback = ValueNotifier<String?>(null);
  final ValueNotifier<int> activePointerCount = ValueNotifier<int>(0);

  // Multi-touch tracking
  final Map<int, Offset> _pointerPositions = {};
  final Map<int, Offset> _initialDownPositions = {};
  final Map<int, int> _pointerDownTimes = {};

  Map<int, Offset> get pointerPositions => Map.unmodifiable(_pointerPositions);

  TouchpadModeState _state = TouchpadModeState.idle;
  TouchpadModeState get state => _state;

  // Session metadata to prevent misclassifications
  int _maxPointersInSession = 0;
  bool _gestureTriggeredInSession = false;
  int _sessionStartTime = 0;

  // 1-Finger Tap & Drag thresholds
  static const int kTapMaxDurationMs = 260;
  static const double kTapMaxDisplacement = 14.0;
  static const int kDoubleTapMaxIntervalMs = 300;

  int _lastTapTime = 0;
  Offset _lastTapPosition = Offset.zero;
  bool _isDragging = false;

  // 2-Finger Scroll & Pinch tracking
  bool _hasScrolled = false;
  double _twoFingerTotalMovement = 0.0;
  double _initialPinchDistance = 0.0;
  bool _pinchZoomTriggered = false;

  // 3-Finger Windows App Switcher (Alt-Tab) state
  bool _isAltTabActive = false;
  double _lastAltTabDisplacementX = 0.0;
  double _lastAltTabDisplacementY = 0.0;
  int _lastAltTabStepTime = 0;
  static const double kAltTabStepDistance = 55.0;
  static const int kAltTabStepCooldownMs = 180;

  bool get isAltTabActive => _isAltTabActive;

  TouchpadEngine({required this.transport}) {
    threeFingerTabMode = SettingsService.instance.loadThreeFingerTabMode();
  }

  void onPointerDown(PointerDownEvent event) {
    final now = DateTime.now().millisecondsSinceEpoch;
    _pointerPositions[event.pointer] = event.position;
    _initialDownPositions[event.pointer] = event.position;
    _pointerDownTimes[event.pointer] = now;

    activePointerCount.value = _pointerPositions.length;

    if (_pointerPositions.length == 1 && _maxPointersInSession == 0) {
      _sessionStartTime = now;
      _maxPointersInSession = 1;
      _gestureTriggeredInSession = false;
      _isAltTabActive = false;
      _lastAltTabDisplacementX = 0.0;
      _lastAltTabDisplacementY = 0.0;
      _lastAltTabStepTime = 0;

      // Check for tap-and-hold (drag gesture)
      if (now - _lastTapTime < kDoubleTapMaxIntervalMs &&
          (event.position - _lastTapPosition).distance < 28.0) {
        _isDragging = true;
        _state = TouchpadModeState.dragging;
        _sendMouseButton(AxiomEventType.mouseDown, "LEFT");
      } else {
        _state = TouchpadModeState.tracking1Finger;
      }
    } else {
      _maxPointersInSession = max(_maxPointersInSession, _pointerPositions.length);
      _cancelDrag();

      if (_pointerPositions.length == 2) {
        _state = TouchpadModeState.tracking2Finger;
        _hasScrolled = false;
        _twoFingerTotalMovement = 0.0;
        _initialPinchDistance = 0.0;
        _pinchZoomTriggered = false;
      } else if (_pointerPositions.length == 3) {
        _state = TouchpadModeState.tracking3Finger;
      } else if (_pointerPositions.length >= 4) {
        _state = TouchpadModeState.tracking4Finger;
      }
    }
  }

  void onPointerMove(PointerMoveEvent event) {
    if (!_pointerPositions.containsKey(event.pointer)) return;

    final oldPos = _pointerPositions[event.pointer]!;
    final currentPos = event.position;
    final delta = currentPos - oldPos;
    _pointerPositions[event.pointer] = currentPos;

    final count = _pointerPositions.length;
    _maxPointersInSession = max(_maxPointersInSession, count);

    // --- 1 FINGER: Cursor Movement ---
    if (count == 1 && _maxPointersInSession == 1 && !_hasScrolled) {
      final dx = delta.dx * sensitivity;
      final dy = delta.dy * sensitivity;

      transport.send(AxiomPacket(
        type: AxiomEventType.mouseMove,
        data: {'dx': dx, 'dy': dy},
      ));
      return;
    }

    // --- 2 FINGERS: Scroll or Pinch-to-Zoom ---
    if (count == 2) {
      final keys = _pointerPositions.keys.toList();
      final p1 = _pointerPositions[keys[0]]!;
      final p2 = _pointerPositions[keys[1]]!;
      final currentSpan = (p1 - p2).distance;

      if (_initialPinchDistance == 0.0) {
        _initialPinchDistance = currentSpan;
      } else {
        final spanDelta = currentSpan - _initialPinchDistance;
        // If fingers are spreading or pinching together significantly
        if (spanDelta.abs() > 40.0 && !_pinchZoomTriggered) {
          _pinchZoomTriggered = true;
          _hasScrolled = true;
          _gestureTriggeredInSession = true;

          if (spanDelta > 0) {
            _sendGesture("ZOOM_IN");
          } else {
            _sendGesture("ZOOM_OUT");
          }
          return;
        }
      }

      // If not pinching, execute smooth 2-finger scroll
      _twoFingerTotalMovement += delta.distance;
      if (_twoFingerTotalMovement > 5.0) {
        _hasScrolled = true;
      }

      final scrollDx = delta.dx * scrollSensitivity;
      final scrollDy = delta.dy * scrollSensitivity;

      transport.send(AxiomPacket(
        type: AxiomEventType.mouseScroll,
        data: {'dx': scrollDx, 'dy': scrollDy},
      ));
      return;
    }

    // --- 3 FINGERS: Navigation & Window Gestures ---
    if (count == 3) {
      if (_isAltTabActive) {
        final avgDelta = _computeAverageDisplacement();
        final diffX = avgDelta.dx - _lastAltTabDisplacementX;
        final diffY = avgDelta.dy - _lastAltTabDisplacementY;
        final now = DateTime.now().millisecondsSinceEpoch;

        if (now - _lastAltTabStepTime >= kAltTabStepCooldownMs) {
          if (diffX.abs() >= diffY.abs()) {
            // Horizontal navigation
            if (diffX > kAltTabStepDistance) {
              _lastAltTabDisplacementX = avgDelta.dx;
              _lastAltTabDisplacementY = avgDelta.dy;
              _lastAltTabStepTime = now;
              _sendGesture("APP_RIGHT");
            } else if (diffX < -kAltTabStepDistance) {
              _lastAltTabDisplacementX = avgDelta.dx;
              _lastAltTabDisplacementY = avgDelta.dy;
              _lastAltTabStepTime = now;
              _sendGesture("APP_LEFT");
            }
          } else {
            // Vertical navigation in Alt-Tab grid
            if (diffY > kAltTabStepDistance) {
              _lastAltTabDisplacementX = avgDelta.dx;
              _lastAltTabDisplacementY = avgDelta.dy;
              _lastAltTabStepTime = now;
              _sendGesture("APP_DOWN");
            } else if (diffY < -kAltTabStepDistance) {
              _lastAltTabDisplacementX = avgDelta.dx;
              _lastAltTabDisplacementY = avgDelta.dy;
              _lastAltTabStepTime = now;
              _sendGesture("APP_UP");
            }
          }
        }
        return;
      }

      if (!_gestureTriggeredInSession) {
        final avgDelta = _computeAverageDisplacement();
        if (avgDelta.distance > 40.0) {
          if (avgDelta.dx.abs() > avgDelta.dy.abs()) {
            if (threeFingerTabMode) {
              _gestureTriggeredInSession = true;
              if (avgDelta.dx > 0) {
                _sendGesture("TAB_NEXT");
              } else {
                _sendGesture("TAB_PREV");
              }
            } else {
              // Horizontal Swipe: Windows App Switcher (Alt-Tab)
              _isAltTabActive = true;
              _gestureTriggeredInSession = true;
              _lastAltTabDisplacementX = avgDelta.dx;
              _lastAltTabDisplacementY = avgDelta.dy;
              _lastAltTabStepTime = DateTime.now().millisecondsSinceEpoch;
              if (avgDelta.dx > 0) {
                _sendGesture("APP_NEXT");
              } else {
                _sendGesture("APP_PREV");
              }
            }
          } else {
            // Vertical Swipe: Task View / Show Desktop
            _gestureTriggeredInSession = true;
            if (avgDelta.dy < 0) {
              _sendGesture("TASK_VIEW");
            } else {
              _sendGesture("SHOW_DESKTOP");
            }
          }
        }
        return;
      }
    }

    // --- 4 FINGERS: Virtual Desktops & Action Center ---
    if (count >= 4 && !_gestureTriggeredInSession) {
      final avgDelta = _computeAverageDisplacement();
      if (avgDelta.distance > 45.0) {
        _gestureTriggeredInSession = true;

        if (avgDelta.dx.abs() > avgDelta.dy.abs()) {
          // Horizontal Swipe
          if (avgDelta.dx > 0) {
            _sendGesture("DESKTOP_NEXT");
          } else {
            _sendGesture("DESKTOP_PREV");
          }
        } else {
          // Vertical Swipe
          if (avgDelta.dy < 0) {
            _sendGesture("ACTION_CENTER");
          } else {
            _sendGesture("SHOW_DESKTOP");
          }
        }
      }
      return;
    }
  }

  void onPointerUp(PointerUpEvent event) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final sessionDuration = now - _sessionStartTime;
    final initialPos = _initialDownPositions[event.pointer] ?? event.position;
    final displacement = (event.position - initialPos).distance;

    final sessionPointers = _maxPointersInSession;
    final gestureFired = _gestureTriggeredInSession;
    final hadScrolled = _hasScrolled;

    _pointerPositions.remove(event.pointer);
    _pointerDownTimes.remove(event.pointer);
    _initialDownPositions.remove(event.pointer);

    activePointerCount.value = _pointerPositions.length;

    if (_isDragging) {
      _isDragging = false;
      _sendMouseButton(AxiomEventType.mouseUp, "LEFT");
      _state = TouchpadModeState.idle;
      return;
    }

    // --- TAP GESTURES (Only when session is stationary and fast) ---
    if (!hadScrolled && !gestureFired && !_isAltTabActive && displacement <= kTapMaxDisplacement && sessionDuration <= kTapMaxDurationMs) {
      if (sessionPointers == 1 && _pointerPositions.isEmpty) {
        // 1-Finger Tap: Left Click
        _sendClick("LEFT");
        _lastTapTime = now;
        _lastTapPosition = event.position;
      } else if (sessionPointers == 2 && !_gestureTriggeredInSession && _twoFingerTotalMovement < 8.0) {
        // 2-Finger Tap: Right Click
        _gestureTriggeredInSession = true;
        _sendClick("RIGHT");
      } else if (sessionPointers == 3 && !_gestureTriggeredInSession) {
        // 3-Finger Tap: Middle Click
        _gestureTriggeredInSession = true;
        _sendGesture("MIDDLE_CLICK");
      } else if (sessionPointers >= 4 && !_gestureTriggeredInSession) {
        // 4-Finger Tap: Notification Center (Win + N)
        _gestureTriggeredInSession = true;
        _sendGesture("NOTIFICATIONS");
      }
    }

    // Session cleanup when all fingers leave the screen
    if (_pointerPositions.isEmpty) {
      if (_isAltTabActive) {
        _isAltTabActive = false;
        _sendGesture("APP_SWITCH_END");
      }
      _hasScrolled = false;
      _maxPointersInSession = 0;
      _gestureTriggeredInSession = false;
      _initialPinchDistance = 0.0;
      _pinchZoomTriggered = false;
      _twoFingerTotalMovement = 0.0;
      _lastAltTabDisplacementX = 0.0;
      _lastAltTabDisplacementY = 0.0;
      _lastAltTabStepTime = 0;
      _state = TouchpadModeState.idle;
    }
  }

  void onPointerCancel(PointerCancelEvent event) {
    _pointerPositions.remove(event.pointer);
    _pointerDownTimes.remove(event.pointer);
    _initialDownPositions.remove(event.pointer);
    activePointerCount.value = _pointerPositions.length;
    _cancelDrag();

    if (_pointerPositions.isEmpty) {
      if (_isAltTabActive) {
        _isAltTabActive = false;
        _sendGesture("APP_SWITCH_END");
      }
      _hasScrolled = false;
      _maxPointersInSession = 0;
      _gestureTriggeredInSession = false;
      _initialPinchDistance = 0.0;
      _pinchZoomTriggered = false;
      _twoFingerTotalMovement = 0.0;
      _lastAltTabDisplacementX = 0.0;
      _lastAltTabDisplacementY = 0.0;
      _lastAltTabStepTime = 0;
      _state = TouchpadModeState.idle;
    }
  }

  Offset _computeAverageDisplacement() {
    if (_pointerPositions.isEmpty) return Offset.zero;
    double sumDx = 0.0;
    double sumDy = 0.0;
    int count = 0;

    for (final entry in _pointerPositions.entries) {
      final initPos = _initialDownPositions[entry.key];
      if (initPos != null) {
        sumDx += (entry.value.dx - initPos.dx);
        sumDy += (entry.value.dy - initPos.dy);
        count++;
      }
    }

    if (count == 0) return Offset.zero;
    return Offset(sumDx / count, sumDy / count);
  }

  void _sendGesture(String action) {
    transport.send(AxiomPacket(
      type: AxiomEventType.gesture,
      data: {'action': action},
    ));
  }

  void _sendClick(String button) {
    _sendMouseButton(AxiomEventType.mouseDown, button);
    Future.delayed(const Duration(milliseconds: 30), () {
      _sendMouseButton(AxiomEventType.mouseUp, button);
    });
  }

  void _sendMouseButton(String type, String button) {
    transport.send(AxiomPacket(
      type: type,
      data: {'btn': button},
    ));
  }

  void _cancelDrag() {
    if (_isDragging) {
      _isDragging = false;
      _sendMouseButton(AxiomEventType.mouseUp, "LEFT");
    }
  }

  // Toggle 3-finger swipe mode (Browser Tabs vs Windows Apps)
  void setThreeFingerTabMode(bool isTabMode) {
    threeFingerTabMode = isTabMode;
    SettingsService.instance.saveThreeFingerTabMode(isTabMode);
  }

  // External click handlers (for optional on-screen buttons)
  void leftMouseDown() => _sendMouseButton(AxiomEventType.mouseDown, "LEFT");
  void leftMouseUp() => _sendMouseButton(AxiomEventType.mouseUp, "LEFT");
  void rightMouseDown() => _sendMouseButton(AxiomEventType.mouseDown, "RIGHT");
  void rightMouseUp() => _sendMouseButton(AxiomEventType.mouseUp, "RIGHT");
}
