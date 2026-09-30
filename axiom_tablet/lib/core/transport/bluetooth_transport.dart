import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_classic_bluetooth/flutter_classic_bluetooth.dart';
import '../protocol/protocol.dart';
import 'itransport.dart';

class BluetoothTransport implements ITransport {
  @override
  TransportType get type => TransportType.bluetooth;

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

  final FlutterClassicBluetooth _bluetooth = FlutterClassicBluetooth();
  BtcConnection? _connection;
  Timer? _heartbeatTimer;
  int _lastPingSent = 0;
  String _receiveBuffer = '';

  void _setStatus(ConnectionStatus newStatus) {
    if (_status != newStatus) {
      _status = newStatus;
      _statusController.add(newStatus);
    }
  }

  /// Checks if Bluetooth is supported and enabled
  Future<bool> isBluetoothReady() async {
    try {
      final supported = await _bluetooth.isSupported();
      final enabled = await _bluetooth.isEnabled();
      return supported && enabled;
    } catch (_) {
      return false;
    }
  }

  /// Requests enabling Bluetooth on the device
  Future<bool> requestEnableBluetooth() async {
    try {
      final caps = await _bluetooth.getPlatformCapabilities();
      if (caps.canEnableBluetooth) {
        await _bluetooth.enableBluetooth();
        await Future.delayed(const Duration(milliseconds: 500));
        return await _bluetooth.isEnabled();
      }
    } catch (_) {}
    return false;
  }

  /// Fetches bonded/paired Bluetooth hosts
  Future<List<BtcDevice>> getPairedDevices() async {
    try {
      final enabled = await _bluetooth.isEnabled();
      if (enabled) {
        return await _bluetooth.getPairedDevices();
      }
    } catch (_) {}
    return [];
  }

  /// Connects to a specific Bluetooth host device
  Future<void> connectDevice(BtcDevice device) async {
    await disconnect();
    _setStatus(ConnectionStatus.connecting);
    _connectedHostName = device.name ?? device.address;

    try {
      // Try secure RFCOMM first, fallback to insecure RFCOMM
      try {
        _connection = await _bluetooth.connect(
          address: device.address,
          secure: true,
          timeout: const Duration(seconds: 8),
        );
      } catch (e1) {
        debugPrint("[BT] Secure RFCOMM failed, trying insecure: $e1");
        _connection = await _bluetooth.connect(
          address: device.address,
          secure: false,
          timeout: const Duration(seconds: 8),
        );
      }

      if (_connection == null || !_connection!.isConnected) {
        throw Exception("Bluetooth RFCOMM connection could not be established.");
      }

      _setStatus(ConnectionStatus.authenticating);
      _receiveBuffer = '';

      _connection!.input.listen(
        _onDataReceived,
        onDone: () => _handleDisconnect("Bluetooth connection closed by host"),
        onError: (err) => _handleDisconnect("Bluetooth error: $err"),
        cancelOnError: false,
      );

      _startHeartbeat();
    } catch (e) {
      _setStatus(ConnectionStatus.failed);
      rethrow;
    }
  }

  @override
  Future<void> connect(String host, int port) async {
    // If called via generic ITransport with device address
    final device = BtcDevice(address: host, name: host);
    await connectDevice(device);
  }

  void _onDataReceived(Uint8List data) {
    _receiveBuffer += utf8.decode(data, allowMalformed: true);
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
    if (_connection != null && _connection!.isConnected) {
      try {
        final raw = utf8.encode(packet.serialize());
        _connection!.output.add(raw);
      } catch (_) {}
    }
  }

  void _handleDisconnect(String reason) {
    _heartbeatTimer?.cancel();
    try {
      _connection?.dispose();
    } catch (_) {}
    _connection = null;
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
