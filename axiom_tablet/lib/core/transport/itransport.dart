import 'dart:async';
import '../protocol/protocol.dart';

enum ConnectionStatus {
  disconnected,
  discovering,
  connecting,
  authenticating,
  connected,
  failed,
}

enum TransportType {
  wifi,
  bluetooth,
}

abstract class ITransport {
  ConnectionStatus get status;
  TransportType get type;
  int get latencyMs;
  String? get connectedHostName;

  Stream<ConnectionStatus> get statusStream;
  Stream<AxiomPacket> get packetStream;
  Stream<int> get latencyStream;

  Future<void> connect(String host, int port);
  Future<void> disconnect();
  void send(AxiomPacket packet);
  void dispose();
}
