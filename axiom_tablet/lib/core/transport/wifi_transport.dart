import 'dart:async';
import 'dart:convert';
import 'dart:io';
import '../protocol/protocol.dart';
import 'itransport.dart';

class DiscoveredHost {
  final String ip;
  final int port;
  final String name;

  DiscoveredHost({required this.ip, required this.port, required this.name});
}

class WifiTransport implements ITransport {
  @override
  TransportType get type => TransportType.wifi;

  ConnectionStatus _status = ConnectionStatus.disconnected;
  @override
  ConnectionStatus get status => _status;

  int _latencyMs = 0;
  @override
  int get latencyMs => _latencyMs;

  String? _connectedHostName;
  @override
  String? get connectedHostName => _connectedHostName;

  final _statusController = StreamController<ConnectionStatus>.broadcast();
  @override
  Stream<ConnectionStatus> get statusStream => _statusController.stream;

  final _packetController = StreamController<AxiomPacket>.broadcast();
  @override
  Stream<AxiomPacket> get packetStream => _packetController.stream;

  final _latencyController = StreamController<int>.broadcast();
  @override
  Stream<int> get latencyStream => _latencyController.stream;

  Socket? _socket;
  Timer? _heartbeatTimer;
  int _lastPingSent = 0;
  String _receiveBuffer = '';

  void _setStatus(ConnectionStatus newStatus) {
    if (_status != newStatus) {
      _status = newStatus;
      _statusController.add(newStatus);
    }
  }

  /// Broadcasts UDP beacon on LAN to find Axiom Desktop automatically
  static Future<DiscoveredHost?> discoverDesktop({Duration timeout = const Duration(seconds: 3)}) async {
    RawDatagramSocket? discoverySocket;
    try {
      discoverySocket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      discoverySocket.broadcastEnabled = true;

      final completer = Completer<DiscoveredHost?>();

      discoverySocket.listen((event) {
        if (event == RawSocketEvent.read) {
          final dg = discoverySocket?.receive();
          if (dg != null) {
            final raw = utf8.decode(dg.data).trim();
            try {
              final json = jsonDecode(raw);
              if (json is Map && json['type'] == 'AXIOM_DISCOVER_RES') {
                final host = DiscoveredHost(
                  ip: dg.address.address,
                  port: json['port'] as int? ?? 8890,
                  name: json['name'] as String? ?? 'Desktop PC',
                );
                if (!completer.isCompleted) {
                  completer.complete(host);
                }
              }
            } catch (_) {}
          }
        }
      });

      // Send discovery query broadcast to port 8891
      final reqBytes = utf8.encode("AXIOM_DISCOVER_REQ\n");
      discoverySocket.send(reqBytes, InternetAddress("255.255.255.255"), 8891);

      return await completer.future.timeout(
        timeout,
        onTimeout: () => null,
      );
    } catch (_) {
      return null;
    } finally {
      discoverySocket?.close();
    }
  }

  @override
  Future<void> connect(String host, int port) async {
    await disconnect();
    _setStatus(ConnectionStatus.connecting);
    _connectedHostName = host;

    try {
      _socket = await Socket.connect(host, port, timeout: const Duration(seconds: 5));
      _socket!.setOption(SocketOption.tcpNoDelay, true); // Zero packet buffering latency

      _setStatus(ConnectionStatus.authenticating);
      _receiveBuffer = '';

      _socket!.listen(
        _onDataReceived,
        onDone: () => _handleDisconnect("Server closed connection"),
        onError: (err) => _handleDisconnect("Socket error: $err"),
        cancelOnError: false,
      );

      _startHeartbeat();
    } catch (e) {
      _setStatus(ConnectionStatus.failed);
      rethrow;
    }
  }

  void _onDataReceived(List<int> data) {
    _receiveBuffer += utf8.decode(data);
    while (_receiveBuffer.contains('\n')) {
      final index = _receiveBuffer.indexOf('\n');
      final line = _receiveBuffer.substring(0, index);
      _receiveBuffer = _receiveBuffer.substring(index + 1);

      if (line.trim().isNotEmpty) {
        final packet = AxiomPacket.parse(line);
        if (packet != null) {
          if (packet.type == AxiomEventType.pong) {
            final now = DateTime.now().millisecondsSinceEpoch;
            _latencyMs = now - _lastPingSent;
            _latencyController.add(_latencyMs);
          } else {
            _packetController.add(packet);
          }
        }
      }
    }
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(milliseconds: 1000), (timer) {
      if (_status == ConnectionStatus.connected || _status == ConnectionStatus.authenticating) {
        _lastPingSent = DateTime.now().millisecondsSinceEpoch;
        send(AxiomPacket(
          type: AxiomEventType.ping,
          data: {'ts': _lastPingSent},
        ));
      }
    });
  }

  void markAuthenticated() {
    _setStatus(ConnectionStatus.connected);
  }

  @override
  void send(AxiomPacket packet) {
    if (_socket != null) {
      try {
        _socket!.write(packet.serialize());
      } catch (_) {}
    }
  }

  void _handleDisconnect(String reason) {
    _heartbeatTimer?.cancel();
    _socket?.destroy();
    _socket = null;
    _setStatus(ConnectionStatus.disconnected);
  }

  @override
  Future<void> disconnect() async {
    _handleDisconnect("User initiated disconnect");
  }

  @override
  void dispose() {
    disconnect();
    _statusController.close();
    _packetController.close();
    _latencyController.close();
  }
}
