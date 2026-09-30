import 'dart:async';
import 'package:flutter/gestures.dart';
import '../core/protocol/protocol.dart';
import '../core/transport/itransport.dart';

enum TouchpadModeState {
  idle,
  tracking1Finger,
  tracking2Finger,
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

  // Multi-touch tracking
  final Map<int, Offset> _pointerPositions = {};
  final Map<int, int> _pointerDownTimes = {};
  TouchpadModeState _state = TouchpadModeState.idle;
  TouchpadModeState get state => _state;

  // Tap & Gesture detection thresholds
  static const int kTapMaxDurationMs = 250;
  static const double kTapMaxDisplacement = 12.0;
  static const int kDoubleTapMaxIntervalMs = 300;

  int _lastTapTime = 0;
  Offset _lastTapPosition = Offset.zero;

  // Drag tracking
  Timer? _dragHoldTimer;
  bool _isDragging = false;

  // True initial touch-down tracking for accurate displacement calculation
  final Map<int, Offset> _initialDownPositions = {};
  bool _hasScrolled = false;
  double _twoFingerTotalMovement = 0.0;
  bool _isTwoFingerSession = false;
  bool _rightClickFired = false;

  TouchpadEngine({required this.transport});

  void onPointerDown(PointerDownEvent event) {
    final now = DateTime.now().millisecondsSinceEpoch;
    _pointerPositions[event.pointer] = event.position;
    _initialDownPositions[event.pointer] = event.position;
    _pointerDownTimes[event.pointer] = now;

    if (_pointerPositions.length == 1) {
      if (!_isTwoFingerSession) {
        // Check for tap-and-hold (drag gesture): if user tapped recently and touches down again
        if (now - _lastTapTime < kDoubleTapMaxIntervalMs &&
            (event.position - _lastTapPosition).distance < 25.0) {
          _isDragging = true;
          _state = TouchpadModeState.dragging;
          _sendMouseButton(AxiomEventType.mouseDown, "LEFT");
        } else {
          _state = TouchpadModeState.tracking1Finger;
        }
      }
    } else if (_pointerPositions.length >= 2) {
      _cancelDrag();
      _isTwoFingerSession = true;
      _hasScrolled = false;
      _rightClickFired = false;
      _twoFingerTotalMovement = 0.0;
      _state = TouchpadModeState.tracking2Finger;
    }
  }

  void onPointerMove(PointerMoveEvent event) {
    if (!_pointerPositions.containsKey(event.pointer)) return;

    final oldPos = _pointerPositions[event.pointer]!;
    final currentPos = event.position;
    final delta = currentPos - oldPos;
    _pointerPositions[event.pointer] = currentPos;

    if (_pointerPositions.length == 1 && !_hasScrolled && !_isTwoFingerSession) {
      // 1-finger relative mouse move (with sensitivity & slight velocity curve)
      final dx = delta.dx * sensitivity;
      final dy = delta.dy * sensitivity;

      transport.send(AxiomPacket(
        type: AxiomEventType.mouseMove,
        data: {'dx': dx, 'dy': dy},
      ));
    } else if (_pointerPositions.length >= 2) {
      // ANY pointer moving during 2-finger mode contributes to displacement
      _twoFingerTotalMovement += delta.distance;
      if (_twoFingerTotalMovement > 5.0) {
        _hasScrolled = true;
      }

      // Drive 2-finger scroll using the active event pointer delta
      final scrollDx = delta.dx * scrollSensitivity;
      final scrollDy = delta.dy * scrollSensitivity;

      transport.send(AxiomPacket(
        type: AxiomEventType.mouseScroll,
        data: {'dx': scrollDx, 'dy': scrollDy},
      ));
    }
  }

  void onPointerUp(PointerUpEvent event) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final downTime = _pointerDownTimes[event.pointer] ?? now;
    final initialPos = _initialDownPositions[event.pointer] ?? event.position;
    final duration = now - downTime;
    final displacement = (event.position - initialPos).distance;

    final wasTwoFingerSession = _isTwoFingerSession;
    final hadScrolled = _hasScrolled;

    _pointerPositions.remove(event.pointer);
    _pointerDownTimes.remove(event.pointer);
    _initialDownPositions.remove(event.pointer);

    if (_isDragging) {
      _isDragging = false;
      _sendMouseButton(AxiomEventType.mouseUp, "LEFT");
      _state = TouchpadModeState.idle;
      return;
    }

    // Only register taps if NO scrolling occurred and displacement is minimal
    if (!hadScrolled && _twoFingerTotalMovement < 8.0 && duration <= kTapMaxDurationMs && displacement <= kTapMaxDisplacement) {
      if (wasTwoFingerSession && !_rightClickFired) {
        // Precise Two-finger tap: Right Click (fired once per 2-finger tap session)
        _rightClickFired = true;
        _sendClick("RIGHT");
      } else if (!wasTwoFingerSession && _pointerPositions.isEmpty) {
        // Precise One-finger tap: Left Click
        _sendClick("LEFT");
        _lastTapTime = now;
        _lastTapPosition = event.position;
      }
    }

    if (_pointerPositions.isEmpty) {
      _hasScrolled = false;
      _isTwoFingerSession = false;
      _rightClickFired = false;
      _twoFingerTotalMovement = 0.0;
      _state = TouchpadModeState.idle;
    }
  }

  void onPointerCancel(PointerCancelEvent event) {
    _pointerPositions.remove(event.pointer);
    _pointerDownTimes.remove(event.pointer);
    _initialDownPositions.remove(event.pointer);
    _cancelDrag();
    if (_pointerPositions.isEmpty) {
      _hasScrolled = false;
      _isTwoFingerSession = false;
      _rightClickFired = false;
      _twoFingerTotalMovement = 0.0;
      _state = TouchpadModeState.idle;
    }
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
    _dragHoldTimer?.cancel();
    if (_isDragging) {
      _isDragging = false;
      _sendMouseButton(AxiomEventType.mouseUp, "LEFT");
    }
  }

  // External click handlers (for optional on-screen buttons)
  void leftMouseDown() => _sendMouseButton(AxiomEventType.mouseDown, "LEFT");
  void leftMouseUp() => _sendMouseButton(AxiomEventType.mouseUp, "LEFT");
  void rightMouseDown() => _sendMouseButton(AxiomEventType.mouseDown, "RIGHT");
  void rightMouseUp() => _sendMouseButton(AxiomEventType.mouseUp, "RIGHT");
}
