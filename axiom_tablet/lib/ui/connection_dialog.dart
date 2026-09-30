import 'package:flutter/material.dart';
import 'package:flutter_classic_bluetooth/flutter_classic_bluetooth.dart';
import '../core/transport/itransport.dart';
import '../core/transport/wifi_transport.dart';
import '../core/transport/bluetooth_transport.dart';

class ConnectionDialog extends StatefulWidget {
  final WifiTransport wifiTransport;
  final BluetoothTransport btTransport;
  final Function(ITransport selectedTransport, String hostOrAddress, int? port) onConnect;

  const ConnectionDialog({
    super.key,
    required this.wifiTransport,
    required this.btTransport,
    required this.onConnect,
  });

  static Future<void> show({
    required BuildContext context,
    required WifiTransport wifiTransport,
    required BluetoothTransport btTransport,
    required Function(ITransport selectedTransport, String hostOrAddress, int? port) onConnect,
  }) {
    return showDialog(
      context: context,
      builder: (_) => ConnectionDialog(
        wifiTransport: wifiTransport,
        btTransport: btTransport,
        onConnect: onConnect,
      ),
    );
  }

  @override
  State<ConnectionDialog> createState() => _ConnectionDialogState();
}

class _ConnectionDialogState extends State<ConnectionDialog> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Wi-Fi State
  bool _isScanningWifi = false;
  DiscoveredHost? _discoveredHost;
  final _ipController = TextEditingController(text: "127.0.0.1");
  final _portController = TextEditingController(text: "8890");

  // Bluetooth State
  bool _isLoadingBt = false;
  List<BtcDevice> _btDevices = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _scanWifi();
    _loadBtDevices();
  }

  Future<void> _scanWifi() async {
    setState(() => _isScanningWifi = true);
    final host = await WifiTransport.discoverDesktop(timeout: const Duration(seconds: 2));
    if (mounted) {
      setState(() {
        _isScanningWifi = false;
        _discoveredHost = host;
        if (host != null) {
          _ipController.text = host.ip;
          _portController.text = host.port.toString();
        }
      });
    }
  }

  Future<void> _loadBtDevices() async {
    setState(() => _isLoadingBt = true);
    final devices = await widget.btTransport.getPairedDevices();
    if (mounted) {
      setState(() {
        _isLoadingBt = false;
        _btDevices = devices;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _ipController.dispose();
    _portController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const accentColor = Color(0xFF00E5FF);

    return Dialog(
      backgroundColor: const Color(0xFF0C101A),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFF1E293B), width: 1.5),
      ),
      child: Container(
        width: 480,
        height: 410,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Logo & Title
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Image.asset(
                    'assets/images/logo.png',
                    width: 28,
                    height: 28,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) =>
                        const Icon(Icons.bolt, color: accentColor, size: 24),
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  "AXIOM LINK",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    letterSpacing: 2.0,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Tabs: [ Wi-Fi LAN ] [ Bluetooth ]
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF141923),
                borderRadius: BorderRadius.circular(10),
              ),
              child: TabBar(
                controller: _tabController,
                indicatorColor: accentColor,
                labelColor: accentColor,
                unselectedLabelColor: const Color(0xFF94A3B8),
                tabs: const [
                  Tab(icon: Icon(Icons.wifi, size: 16), text: "Wi-Fi LAN"),
                  Tab(icon: Icon(Icons.bluetooth, size: 16), text: "Bluetooth"),
                ],
              ),
            ),
            const SizedBox(height: 12),

            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // 1. Wi-Fi Tab
                  _buildWifiTab(accentColor),

                  // 2. Bluetooth Tab
                  _buildBluetoothTab(accentColor),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWifiTab(Color accentColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_discoveredHost != null) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF101B2B),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: accentColor.withValues(alpha: 0.5)),
            ),
            child: Row(
              children: [
                const Icon(Icons.desktop_windows, color: Color(0xFF00FF66), size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _discoveredHost!.name,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      Text(
                        "${_discoveredHost!.ip}:${_discoveredHost!.port}",
                        style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    widget.onConnect(widget.wifiTransport, _discoveredHost!.ip, _discoveredHost!.port);
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: accentColor, foregroundColor: Colors.black),
                  child: const Text("Connect", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("Manual IP Fallback", style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
            TextButton.icon(
              onPressed: _isScanningWifi ? null : _scanWifi,
              icon: _isScanningWifi
                  ? const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.radar, size: 14),
              label: Text(_isScanningWifi ? "Scanning..." : "Rescan", style: const TextStyle(fontSize: 11)),
            ),
          ],
        ),
        Row(
          children: [
            Expanded(
              flex: 3,
              child: TextField(
                controller: _ipController,
                style: const TextStyle(color: Colors.white, fontSize: 12),
                decoration: const InputDecoration(
                  labelText: "Host IP",
                  labelStyle: TextStyle(fontSize: 11),
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 1,
              child: TextField(
                controller: _portController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white, fontSize: 12),
                decoration: const InputDecoration(
                  labelText: "Port",
                  labelStyle: TextStyle(fontSize: 11),
                  isDense: true,
                ),
              ),
            ),
          ],
        ),
        const Spacer(),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              widget.onConnect(
                widget.wifiTransport,
                _ipController.text.trim(),
                int.tryParse(_portController.text.trim()) ?? 8890,
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E293B), foregroundColor: Colors.white),
            child: const Text("Connect to Manual IP"),
          ),
        ),
      ],
    );
  }

  Widget _buildBluetoothTab(Color accentColor) {
    if (_isLoadingBt) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_btDevices.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.bluetooth_disabled, color: Colors.white38, size: 36),
            const SizedBox(height: 8),
            const Text(
              "No paired PC devices found.\nMake sure tablet is paired with your PC in Android Bluetooth settings.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _loadBtDevices,
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF141923), foregroundColor: accentColor),
              child: const Text("Refresh Paired Devices"),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("Paired Bluetooth Devices:", style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
            IconButton(
              icon: const Icon(Icons.refresh, size: 16, color: Colors.white54),
              onPressed: _loadBtDevices,
            ),
          ],
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _btDevices.length,
            itemBuilder: (context, index) {
              final dev = _btDevices[index];
              return Card(
                color: const Color(0xFF141923),
                child: Material(
                  type: MaterialType.transparency,
                  child: ListTile(
                    dense: true,
                    leading: const Icon(Icons.laptop, color: Color(0xFF00E5FF)),
                    title: Text(dev.name ?? "Unknown PC", style: const TextStyle(color: Colors.white, fontSize: 12)),
                    subtitle: Text(dev.address, style: const TextStyle(color: Color(0xFF64748B), fontSize: 10)),
                    trailing: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        widget.onConnect(widget.btTransport, dev.address, null);
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: accentColor, foregroundColor: Colors.black),
                      child: const Text("Connect", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
