import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/protocol/protocol.dart';
import 'core/settings_service.dart';
import 'core/transport/itransport.dart';
import 'core/transport/wifi_transport.dart';
import 'core/transport/bluetooth_transport.dart';
import 'audio/sound_engine.dart';
import 'keyboard/keyboard_engine.dart';
import 'keyboard/rgb_effects.dart';
import 'touchpad/touchpad_engine.dart';
import 'ui/connection_bar.dart';
import 'ui/connection_dialog.dart';
import 'ui/ergonomic_view.dart';
import 'ui/hidable_mode_banners.dart';
import 'ui/keyboard_view.dart';
import 'ui/settings_modal.dart';
import 'ui/touchpad_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await SettingsService.instance.init().timeout(const Duration(milliseconds: 350));
  } catch (_) {}
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  runApp(const AxiomApp());
}

class AxiomApp extends StatelessWidget {
  const AxiomApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Axiom',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF070A10),
      ),
      home: const AxiomHomeScreen(),
    );
  }
}

class AxiomHomeScreen extends StatefulWidget {
  const AxiomHomeScreen({super.key});

  @override
  State<AxiomHomeScreen> createState() => _AxiomHomeScreenState();
}

class _AxiomHomeScreenState extends State<AxiomHomeScreen>
    with SingleTickerProviderStateMixin {
  late final WifiTransport _wifiTransport;
  late final BluetoothTransport _btTransport;
  late ITransport _activeTransport;
  late final KeyboardEngine _keyboardEngine;
  late final TouchpadEngine _touchpadEngine;

  StreamSubscription? _statusSub;
  StreamSubscription? _latencySub;
  StreamSubscription? _packetSub;

  AxiomMode _currentMode = AxiomMode.standard;
  ConnectionStatus _status = ConnectionStatus.disconnected;
  int _latencyMs = 0;
  String? _connectedHostName;

  String _hostIp = "127.0.0.1";
  int _port = 8890;
  String? _savedSessionToken;
  final String _deviceId = "samsung_tab_a_01";
  final String _deviceName = "Samsung Tab A";

  @override
  void initState() {
    super.initState();
    _currentMode = SettingsService.instance.loadMode();
    _savedSessionToken = SettingsService.instance.loadSessionToken();
    final lastHost = SettingsService.instance.loadLastHostIp();
    if (lastHost != null && lastHost.isNotEmpty) {
      _hostIp = lastHost;
    }
    final lastPort = SettingsService.instance.loadLastPort();
    if (lastPort != null && lastPort > 0) {
      _port = lastPort;
    }

    _wifiTransport = WifiTransport();
    _btTransport = BluetoothTransport();
    _activeTransport = _wifiTransport;

    _keyboardEngine = KeyboardEngine(transport: _activeTransport);
    _touchpadEngine = TouchpadEngine(transport: _activeTransport);

    // Initialize mechanical sounds & RGB effects engine
    SoundEngine.instance.init();
    RgbEngine.instance.init(this);

    _setActiveTransport(_wifiTransport);
  }

  void _setActiveTransport(ITransport transport) {
    _statusSub?.cancel();
    _latencySub?.cancel();
    _packetSub?.cancel();

    _activeTransport = transport;
    _keyboardEngine.setTransport(transport);
    _touchpadEngine.setTransport(transport);

    _statusSub = _activeTransport.statusStream.listen((status) {
      if (mounted) {
        setState(() {
          _status = status;
          _connectedHostName = _activeTransport.connectedHostName;
        });
        if (status == ConnectionStatus.authenticating) {
          _handleAuthentication();
        }
      }
    });

    _latencySub = _activeTransport.latencyStream.listen((ms) {
      if (mounted) {
        setState(() {
          _latencyMs = ms;
        });
      }
    });

    _packetSub = _activeTransport.packetStream.listen(_onPacketReceived);
  }

  void _onPacketReceived(AxiomPacket packet) {
    if (packet.type == AxiomEventType.pairRes) {
      final success = packet.data['success'] as bool? ?? false;
      if (success) {
        _savedSessionToken = packet.data['token'] as String?;
        if (_savedSessionToken != null) {
          SettingsService.instance.saveSessionToken(_savedSessionToken!);
        }
        if (_activeTransport is WifiTransport) {
          (_activeTransport as WifiTransport).markAuthenticated();
        } else if (_activeTransport is BluetoothTransport) {
          (_activeTransport as BluetoothTransport).markAuthenticated();
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("✨ Paired & Connected to Desktop!"),
            backgroundColor: Color(0xFF00FF66),
          ),
        );
      } else {
        final msg = packet.data['message'] as String? ?? "Pairing failed";
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("❌ $msg"),
            backgroundColor: const Color(0xFFFF3366),
          ),
        );
        _promptForPin();
      }
    } else if (packet.type == AxiomEventType.authRes) {
      final success = packet.data['success'] as bool? ?? false;
      if (success) {
        if (_activeTransport is WifiTransport) {
          (_activeTransport as WifiTransport).markAuthenticated();
        } else if (_activeTransport is BluetoothTransport) {
          (_activeTransport as BluetoothTransport).markAuthenticated();
        }
      } else {
        _promptForPin();
      }
    }
  }

  void _handleAuthentication() {
    if (_savedSessionToken != null) {
      _activeTransport.send(AxiomPacket(
        type: AxiomEventType.authReq,
        data: {
          'device_id': _deviceId,
          'token': _savedSessionToken,
        },
      ));
    } else {
      _promptForPin();
    }
  }

  Future<void> _promptForPin() async {
    final pinController = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF141923),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Color(0xFF00E5FF), width: 1.5),
          ),
          title: const Row(
            children: [
              Icon(Icons.security, color: Color(0xFF00E5FF)),
              SizedBox(width: 8),
              Text(
                "Axiom Pairing Required",
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Enter the 6-digit PIN displayed on your laptop:",
                style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: pinController,
                autofocus: true,
                keyboardType: TextInputType.number,
                maxLength: 6,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF00E5FF),
                  fontSize: 24,
                  letterSpacing: 8,
                  fontWeight: FontWeight.bold,
                ),
                decoration: InputDecoration(
                  counterText: "",
                  filled: true,
                  fillColor: const Color(0xFF0B0F19),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFF334155)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFF00E5FF), width: 2),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, null),
              child: const Text("Cancel", style: TextStyle(color: Colors.white54)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, pinController.text.trim()),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00E5FF),
                foregroundColor: Colors.black,
              ),
              child: const Text("Pair Device", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );

    if (result != null && result.isNotEmpty) {
      _activeTransport.send(AxiomPacket(
        type: AxiomEventType.pairReq,
        data: {
          'device_id': _deviceId,
          'name': _deviceName,
          'pin': result,
        },
      ));
    }
  }

  Future<void> _scanLan() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("📡 Scanning LAN for Axiom Desktop..."),
        duration: Duration(seconds: 2),
      ),
    );

    final host = await WifiTransport.discoverDesktop();
    if (!mounted) return;
    if (host != null) {
      setState(() {
        _hostIp = host.ip;
        _port = host.port;
        _connectedHostName = host.name;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("🎯 Found Desktop: ${host.name} (${host.ip})"),
          backgroundColor: const Color(0xFF00FF66),
        ),
      );

      _setActiveTransport(_wifiTransport);
      _connect();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("⚠️ No Axiom Desktop found on LAN. Please check that desktop is running."),
          backgroundColor: Color(0xFFFFB700),
        ),
      );
    }
  }

  Future<void> _connect() async {
    try {
      await _activeTransport.connect(_hostIp, _port);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Connection failed: $e"),
          backgroundColor: const Color(0xFFFF3366),
        ),
      );
    }
  }

  void _openConnectDialog() {
    ConnectionDialog.show(
      context: context,
      wifiTransport: _wifiTransport,
      btTransport: _btTransport,
      onConnect: (selectedTransport, hostOrAddress, port) async {
        await _activeTransport.disconnect();
        _setActiveTransport(selectedTransport);
        try {
          if (selectedTransport is BluetoothTransport) {
            await selectedTransport.connect(hostOrAddress, 0);
          } else {
            _hostIp = hostOrAddress;
            _port = port ?? 8890;
            SettingsService.instance.saveLastHostIp(_hostIp);
            SettingsService.instance.saveLastPort(_port);
            await selectedTransport.connect(hostOrAddress, _port);
          }
        } catch (e) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Connection failed: $e"),
              backgroundColor: const Color(0xFFFF3366),
            ),
          );
        }
      },
    );
  }

  @override
  void dispose() {
    _statusSub?.cancel();
    _latencySub?.cancel();
    _packetSub?.cancel();
    _wifiTransport.dispose();
    _btTransport.dispose();
    SoundEngine.instance.dispose();
    RgbEngine.instance.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            ConnectionBar(
              status: _status,
              hostName: _connectedHostName ?? _hostIp,
              latencyMs: _latencyMs,
              currentMode: _currentMode,
              onModeChanged: (mode) {
                setState(() {
                  _currentMode = mode;
                });
                SettingsService.instance.saveMode(mode);
              },
              onScanPressed: _scanLan,
              onConnectPressed: _openConnectDialog,
              onDisconnectPressed: () => _activeTransport.disconnect(),
              onSettingsPressed: () => SettingsModal.show(context),
              onScreenshotPressed: () => _touchpadEngine.takeScreenshot(),
            ),
            Expanded(
              child: HidableSideBanners(
                currentMode: _currentMode,
                onModeChanged: (mode) {
                  setState(() {
                    _currentMode = mode;
                  });
                  SettingsService.instance.saveMode(mode);
                },
                child: _buildActiveSurface(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveSurface() {
    switch (_currentMode) {
      case AxiomMode.standard:
        return KeyboardView(engine: _keyboardEngine);
      case AxiomMode.ergonomic:
        return ErgonomicView(engine: _keyboardEngine);
      case AxiomMode.touchpad:
        return TouchpadScreen(engine: _touchpadEngine);
    }
  }
}
