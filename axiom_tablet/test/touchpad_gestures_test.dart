import 'package:flutter_test/flutter_test.dart';
import 'package:axiom_tablet/touchpad/touchpad_engine.dart';
import 'package:axiom_tablet/core/transport/itransport.dart';
import 'package:axiom_tablet/core/protocol/protocol.dart';
import 'package:flutter/gestures.dart';

class MockTransport implements ITransport {
  final List<AxiomPacket> sentPackets = [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  void send(AxiomPacket packet) {
    sentPackets.add(packet);
  }
}

void main() {
  test('TouchpadEngine 3-finger horizontal swipe activates Alt-Tab, cycles in 2D (left/right/down/up), and commits on lift', () async {
    final transport = MockTransport();
    final engine = TouchpadEngine(transport: transport);
    expect(engine.threeFingerTabMode, isFalse);

    // 1. Pointer down 3 fingers
    engine.onPointerDown(const PointerDownEvent(pointer: 1, position: Offset(100, 100)));
    engine.onPointerDown(const PointerDownEvent(pointer: 2, position: Offset(120, 100)));
    engine.onPointerDown(const PointerDownEvent(pointer: 3, position: Offset(140, 100)));

    expect(engine.state, TouchpadModeState.tracking3Finger);
    expect(engine.isAltTabActive, isFalse);

    // 2. Swipe right by 60px -> Activates Alt-Tab and sends first APP_NEXT
    engine.onPointerMove(const PointerMoveEvent(pointer: 1, position: Offset(160, 100)));
    engine.onPointerMove(const PointerMoveEvent(pointer: 2, position: Offset(180, 100)));
    engine.onPointerMove(const PointerMoveEvent(pointer: 3, position: Offset(200, 100)));

    expect(engine.isAltTabActive, isTrue);
    var gesturePackets = transport.sentPackets.where((p) => p.type == AxiomEventType.gesture).toList();
    expect(gesturePackets.last.data['action'], equals('APP_NEXT'));

    // Wait past cooldown (200ms)
    await Future.delayed(const Duration(milliseconds: 200));

    // 3. Slide right another 60px -> Cycles to next app (APP_RIGHT)
    engine.onPointerMove(const PointerMoveEvent(pointer: 1, position: Offset(220, 100)));
    engine.onPointerMove(const PointerMoveEvent(pointer: 2, position: Offset(240, 100)));
    engine.onPointerMove(const PointerMoveEvent(pointer: 3, position: Offset(260, 100)));

    expect(engine.isAltTabActive, isTrue);
    gesturePackets = transport.sentPackets.where((p) => p.type == AxiomEventType.gesture).toList();
    expect(gesturePackets.length, equals(2));
    expect(gesturePackets.last.data['action'], equals('APP_RIGHT'));

    // Wait past cooldown again
    await Future.delayed(const Duration(milliseconds: 200));

    // 4. Slide down by 60px -> Cycles down in grid (APP_DOWN)
    engine.onPointerMove(const PointerMoveEvent(pointer: 1, position: Offset(220, 160)));
    engine.onPointerMove(const PointerMoveEvent(pointer: 2, position: Offset(240, 160)));
    engine.onPointerMove(const PointerMoveEvent(pointer: 3, position: Offset(260, 160)));

    gesturePackets = transport.sentPackets.where((p) => p.type == AxiomEventType.gesture).toList();
    expect(gesturePackets.length, equals(3));
    expect(gesturePackets.last.data['action'], equals('APP_DOWN'));

    // 5. User lifts 1 finger -> Alt-Tab MUST REMAIN ACTIVE!
    engine.onPointerUp(const PointerUpEvent(pointer: 1, position: Offset(220, 160)));
    expect(engine.isAltTabActive, isTrue);
    gesturePackets = transport.sentPackets.where((p) => p.type == AxiomEventType.gesture).toList();
    expect(gesturePackets.length, equals(3)); // Still 3, not dismissed!

    // 6. User lifts 2nd finger -> Still active!
    engine.onPointerUp(const PointerUpEvent(pointer: 2, position: Offset(240, 160)));
    expect(engine.isAltTabActive, isTrue);

    // 7. Last finger lifts -> Now all fingers off, commits app selection (APP_SWITCH_END)
    engine.onPointerUp(const PointerUpEvent(pointer: 3, position: Offset(260, 160)));
    expect(engine.isAltTabActive, isFalse);

    gesturePackets = transport.sentPackets.where((p) => p.type == AxiomEventType.gesture).toList();
    expect(gesturePackets.length, equals(4));
    expect(gesturePackets.last.data['action'], equals('APP_SWITCH_END'));
  });

  test('TouchpadEngine 3-finger horizontal swipe triggers TAB_NEXT when enabled', () {
    final transport = MockTransport();
    final engine = TouchpadEngine(transport: transport);
    engine.threeFingerTabMode = true;

    // Pointer down 3 fingers
    engine.onPointerDown(const PointerDownEvent(pointer: 1, position: Offset(100, 100)));
    engine.onPointerDown(const PointerDownEvent(pointer: 2, position: Offset(120, 100)));
    engine.onPointerDown(const PointerDownEvent(pointer: 3, position: Offset(140, 100)));

    // Swipe right by 60px
    engine.onPointerMove(const PointerMoveEvent(pointer: 1, position: Offset(160, 100)));
    engine.onPointerMove(const PointerMoveEvent(pointer: 2, position: Offset(180, 100)));
    engine.onPointerMove(const PointerMoveEvent(pointer: 3, position: Offset(200, 100)));

    final gesturePackets = transport.sentPackets.where((p) => p.type == AxiomEventType.gesture).toList();
    expect(gesturePackets.isNotEmpty, isTrue);
    expect(gesturePackets.last.data['action'], equals('TAB_NEXT'));
  });

  test('TouchpadEngine 4-finger swipe triggers DESKTOP_NEXT', () {
    final transport = MockTransport();
    final engine = TouchpadEngine(transport: transport);

    // Pointer down 4 fingers
    engine.onPointerDown(const PointerDownEvent(pointer: 1, position: Offset(100, 100)));
    engine.onPointerDown(const PointerDownEvent(pointer: 2, position: Offset(120, 100)));
    engine.onPointerDown(const PointerDownEvent(pointer: 3, position: Offset(140, 100)));
    engine.onPointerDown(const PointerDownEvent(pointer: 4, position: Offset(160, 100)));

    expect(engine.state, TouchpadModeState.tracking4Finger);

    // Swipe right by 60px
    engine.onPointerMove(const PointerMoveEvent(pointer: 1, position: Offset(160, 100)));
    engine.onPointerMove(const PointerMoveEvent(pointer: 2, position: Offset(180, 100)));
    engine.onPointerMove(const PointerMoveEvent(pointer: 3, position: Offset(200, 100)));
    engine.onPointerMove(const PointerMoveEvent(pointer: 4, position: Offset(220, 100)));

    final gesturePackets = transport.sentPackets.where((p) => p.type == AxiomEventType.gesture).toList();
    expect(gesturePackets.isNotEmpty, isTrue);
    expect(gesturePackets.last.data['action'], equals('DESKTOP_NEXT'));
  });
}
