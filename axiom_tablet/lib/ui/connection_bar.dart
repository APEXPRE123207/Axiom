import 'package:flutter/material.dart';
import '../core/transport/itransport.dart';

enum AxiomMode {
  standard,
  ergonomic,
  touchpad,
}

class ConnectionBar extends StatelessWidget {
  final ConnectionStatus status;
  final String? hostName;
  final int latencyMs;
  final AxiomMode currentMode;
  final ValueChanged<AxiomMode> onModeChanged;
  final VoidCallback onScanPressed;
  final VoidCallback onConnectPressed;
  final VoidCallback onDisconnectPressed;
  final VoidCallback onSettingsPressed;

  const ConnectionBar({
    super.key,
    required this.status,
    this.hostName,
    required this.latencyMs,
    required this.currentMode,
    required this.onModeChanged,
    required this.onScanPressed,
    required this.onConnectPressed,
    required this.onDisconnectPressed,
    required this.onSettingsPressed,
  });

  Color _getStatusColor() {
    switch (status) {
      case ConnectionStatus.connected:
        return const Color(0xFF00FF66); // Neon Green
      case ConnectionStatus.connecting:
      case ConnectionStatus.authenticating:
      case ConnectionStatus.discovering:
        return const Color(0xFFFFB700); // Amber
      case ConnectionStatus.failed:
        return const Color(0xFFFF3366); // Crimson
      case ConnectionStatus.disconnected:
        return const Color(0xFF64748B); // Slate
    }
  }

  String _getStatusText() {
    switch (status) {
      case ConnectionStatus.connected:
        return "ONLINE";
      case ConnectionStatus.connecting:
        return "CONNECTING...";
      case ConnectionStatus.authenticating:
        return "PAIRING REQUIRED";
      case ConnectionStatus.discovering:
        return "SCANNING LAN...";
      case ConnectionStatus.failed:
        return "FAILED";
      case ConnectionStatus.disconnected:
        return "OFFLINE";
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor();

    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      decoration: const BoxDecoration(
        color: Color(0xFF0B0F19),
        border: Border(
          bottom: BorderSide(color: Color(0xFF1E293B), width: 1.0),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final barWidth = constraints.maxWidth < 980 ? 980.0 : constraints.maxWidth;
          return FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: SizedBox(
              width: barWidth,
              child: Row(
                children: [
          // Logo & Title
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.asset(
                  'assets/images/logo.png',
                  width: 24,
                  height: 24,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: const Color(0xFF00E5FF).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(Icons.bolt, color: Color(0xFF00E5FF), size: 16),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: statusColor,
                  boxShadow: [
                    BoxShadow(
                      color: statusColor.withValues(alpha: 0.6),
                      blurRadius: 6.0,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                "AXIOM",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  letterSpacing: 2.0,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  _getStatusText(),
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),

          // Host / Latency info
          if (hostName != null && status == ConnectionStatus.connected)
            Row(
              children: [
                const Icon(Icons.wifi, size: 14, color: Color(0xFF00E5FF)),
                const SizedBox(width: 6),
                Text(
                  hostName!,
                  style: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  "⚡ ${latencyMs}ms",
                  style: TextStyle(
                    color: latencyMs < 20 ? const Color(0xFF00FF66) : const Color(0xFFFFB700),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),

          const SizedBox(width: 20),

          // Mode Selector Switcher: [ ⌨ KEYBOARD ] [ 🖱 TOUCHPAD ]
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: const Color(0xFF141923),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF1E293B)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildModeBtn(
                  mode: AxiomMode.standard,
                  icon: Icons.keyboard_outlined,
                  label: "STANDARD",
                ),
                const SizedBox(width: 2),
                _buildModeBtn(
                  mode: AxiomMode.ergonomic,
                  icon: Icons.auto_awesome_mosaic_outlined,
                  label: "ERGONOMIC",
                ),
                const SizedBox(width: 2),
                _buildModeBtn(
                  mode: AxiomMode.touchpad,
                  icon: Icons.mouse_outlined,
                  label: "TOUCHPAD",
                ),
              ],
            ),
          ),

          const Spacer(),

          // Actions
          if (status == ConnectionStatus.connected)
            OutlinedButton(
              onPressed: onDisconnectPressed,
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFFF3366),
                side: const BorderSide(color: Color(0xFFFF3366), width: 1),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                minimumSize: Size.zero,
              ),
              child: const Text("Disconnect", style: TextStyle(fontSize: 11)),
            )
          else ...[
            TextButton.icon(
              onPressed: onScanPressed,
              icon: const Icon(Icons.radar, size: 14, color: Color(0xFF00E5FF)),
              label: const Text(
                "Scan LAN",
                style: TextStyle(color: Color(0xFF00E5FF), fontSize: 11, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: onConnectPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00E5FF),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                minimumSize: Size.zero,
              ),
              child: const Text(
                "Connect",
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
              ),
            ),
          ],
          const SizedBox(width: 10),
          IconButton(
            icon: const Icon(Icons.settings_outlined, size: 18, color: Color(0xFF94A3B8)),
            tooltip: "Hardware Settings",
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: onSettingsPressed,
          ),
        ],
      ),
    ),
  );
},
      ),
    );
  }

  Widget _buildModeBtn({
    required AxiomMode mode,
    required IconData icon,
    required String label,
  }) {
    final isSelected = currentMode == mode;
    return GestureDetector(
      onTap: () => onModeChanged(mode),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF00E5FF) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 13,
              color: isSelected ? const Color(0xFF070A10) : const Color(0xFF94A3B8),
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? const Color(0xFF070A10) : const Color(0xFF94A3B8),
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
