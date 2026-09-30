import 'dart:convert';

const int kProtocolVersion = 1;

class AxiomEventType {
  static const String keyDown = "KEY_DOWN";
  static const String keyUp = "KEY_UP";
  static const String mouseMove = "MOUSE_MOVE";
  static const String mouseDown = "MOUSE_DOWN";
  static const String mouseUp = "MOUSE_UP";
  static const String mouseScroll = "MOUSE_SCROLL";
  
  static const String ping = "PING";
  static const String pong = "PONG";
  
  static const String pairReq = "PAIR_REQ";
  static const String pairRes = "PAIR_RES";
  static const String authReq = "AUTH_REQ";
  static const String authRes = "AUTH_RES";
  
  static const String discoverReq = "AXIOM_DISCOVER_REQ";
  static const String discoverRes = "AXIOM_DISCOVER_RES";
}

class AxiomPacket {
  final String type;
  final Map<String, dynamic> data;

  AxiomPacket({required this.type, Map<String, dynamic>? data})
      : data = data ?? {};

  String serialize() {
    final map = <String, dynamic>{
      'v': kProtocolVersion,
      'type': type,
      ...data,
    };
    return "${jsonEncode(map)}\n";
  }

  static AxiomPacket? parse(String rawLine) {
    try {
      final decoded = jsonDecode(rawLine.trim());
      if (decoded is Map<String, dynamic>) {
        final type = decoded['type'] as String? ?? '';
        return AxiomPacket(type: type, data: decoded);
      }
    } catch (_) {}
    return null;
  }
}
