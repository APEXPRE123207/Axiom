"""
Axiom Desktop Application (Windows Receiver Daemon)
Receives wireless input events from Samsung Tab A (via Wi-Fi or Bluetooth)
and translates them into native Windows input.
"""
import sys
import time
import os
import signal
import socket
from typing import Dict, Any, Callable, Optional, List

from core.protocol import EventType
from core.input_injector import WindowsInputInjector
from core.security import SecurityManager
from transport.wifi_transport import WifiTransportServer
from transport.bluetooth_transport import BluetoothTransportServer

def get_local_ips() -> List[str]:
    ips = []
    try:
        hostname = socket.gethostname()
        for info in socket.getaddrinfo(hostname, None):
            ip = info[4][0]
            if ":" not in ip and not ip.startswith("127.") and ip not in ips:
                ips.append(ip)
    except Exception:
        pass
    if not ips:
        try:
            s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
            s.connect(("8.8.8.8", 80))
            ips.append(s.getsockname()[0])
            s.close()
        except Exception:
            ips.append("127.0.0.1")
    return ips

class AxiomDesktopDaemon:
    def __init__(self, on_log: Optional[Callable[[str], None]] = None, on_clients_changed: Optional[Callable[[], None]] = None):
        self.on_log_callback = on_log
        self.on_clients_changed_callback = on_clients_changed
        self.is_running = False

        self.log("=" * 60)
        self.log("          AXIOM — Universal Wireless Input Receiver         ")
        self.log("=" * 60)

        self.input_injector = WindowsInputInjector()
        self.security = SecurityManager()
        self.wifi_server = WifiTransportServer()
        self.bt_server = BluetoothTransportServer()
        
        # Track connected and authenticated clients: client_handle -> device_id
        self.authenticated_clients: Dict[Any, str] = {}

        self.log(f"[Security] Current Pairing PIN: >>> {self.security.current_pin} <<<")
        self.log(f"[Security] Trusted Devices: {len(self.security.trusted_devices)}")
        for dev_id, dev_info in self.security.trusted_devices.items():
            self.log(f"   • {dev_info.get('name', 'Unknown')} ({dev_id})")

    def log(self, message: str):
        print(message)
        if self.on_log_callback:
            try:
                self.on_log_callback(message)
            except Exception:
                pass

    def _notify_clients_changed(self):
        if self.on_clients_changed_callback:
            try:
                self.on_clients_changed_callback()
            except Exception:
                pass

    def start(self):
        self.wifi_server.start(self.on_event)
        if self.bt_server.is_supported:
            self.bt_server.start(self.on_event)
        self.is_running = True
        self.log("[Axiom Desktop] Server active and listening for tablet connections (Wi-Fi & Bluetooth).")

    def send_reply(self, client_handle: Any, packet: Dict[str, Any]):
        """Dispatches reply packet through whichever transport client_handle belongs to."""
        if client_handle in self.wifi_server._active_clients:
            self.wifi_server.send_to_client(client_handle, packet)
        elif self.bt_server.is_supported and client_handle in self.bt_server._active_clients:
            self.bt_server.send_to_client(client_handle, packet)
        else:
            self.wifi_server.send_to_client(client_handle, packet)

    def on_event(self, packet: Dict[str, Any], client_handle: Any):
        event_type = packet.get("type")

        # 1. Handle Client Disconnection
        if event_type == "DISCONNECT":
            dev_id = self.authenticated_clients.pop(client_handle, None)
            if dev_id:
                self.log(f"[Axiom] Device disconnected: {dev_id}")
                self._notify_clients_changed()
            self.input_injector.release_all_keys()
            return

        # 2. Handle Pairing Request
        if event_type == EventType.PAIR_REQ:
            dev_id = packet.get("device_id", "unknown")
            dev_name = packet.get("name", "Tablet")
            pin = packet.get("pin", "")
            
            token = self.security.verify_pin_and_register(dev_id, dev_name, pin)
            if token:
                self.log(f"[Security] Successfully paired with '{dev_name}' ({dev_id})!")
                self.authenticated_clients[client_handle] = dev_id
                self._notify_clients_changed()
                self.send_reply(client_handle, {
                    "type": EventType.PAIR_RES,
                    "success": True,
                    "token": token,
                    "message": "Paired successfully"
                })
            else:
                self.log(f"[Security] Pairing failed for '{dev_name}' (Incorrect PIN: {pin})")
                self.send_reply(client_handle, {
                    "type": EventType.PAIR_RES,
                    "success": False,
                    "message": "Invalid PIN code"
                })
            return

        # 3. Handle Session Authentication (for already paired devices)
        if event_type == EventType.AUTH_REQ:
            dev_id = packet.get("device_id", "")
            token = packet.get("token", "")
            
            if self.security.authenticate_session(dev_id, token):
                self.authenticated_clients[client_handle] = dev_id
                self.log(f"[Security] Authenticated trusted device: {dev_id}")
                self._notify_clients_changed()
                self.send_reply(client_handle, {
                    "type": EventType.AUTH_RES,
                    "success": True
                })
            else:
                self.log(f"[Security] Authentication rejected for device: {dev_id}")
                self.send_reply(client_handle, {
                    "type": EventType.AUTH_RES,
                    "success": False,
                    "message": "Unauthorized or revoked device"
                })
            return

        # 4. Enforce Authentication Requirement for Input Events
        if client_handle not in self.authenticated_clients:
            # Drop unauthenticated input packets
            return

        # 5. Heartbeat Ping / Pong
        if event_type == EventType.PING:
            self.send_reply(client_handle, {
                "type": EventType.PONG,
                "client_ts": packet.get("ts"),
                "server_ts": time.time()
            })
            return

        # 6. Keyboard Input Events
        if event_type == EventType.KEY_DOWN:
            key = packet.get("key", "")
            vk = packet.get("vk")
            self.input_injector.key_down(key, vk)

        elif event_type == EventType.KEY_UP:
            key = packet.get("key", "")
            vk = packet.get("vk")
            self.input_injector.key_up(key, vk)

        # 7. Mouse / Touchpad Input Events
        elif event_type == EventType.MOUSE_MOVE:
            dx = float(packet.get("dx", 0.0))
            dy = float(packet.get("dy", 0.0))
            self.input_injector.mouse_move(dx, dy)

        elif event_type == EventType.MOUSE_DOWN:
            btn = packet.get("btn", "LEFT")
            self.input_injector.mouse_button(btn, True)

        elif event_type == EventType.MOUSE_UP:
            btn = packet.get("btn", "LEFT")
            self.input_injector.mouse_button(btn, False)

        elif event_type == EventType.MOUSE_SCROLL:
            dx = float(packet.get("dx", 0.0))
            dy = float(packet.get("dy", 0.0))
            self.input_injector.mouse_scroll(dx, dy)

        elif event_type == EventType.GESTURE:
            action = packet.get("action", "")
            if action:
                self.input_injector.trigger_gesture(action)

    def stop(self):
        print("\n[Axiom Desktop] Shutting down...")
        self.input_injector.release_all_keys()
        self.wifi_server.stop()
        if self.bt_server.is_supported:
            self.bt_server.stop()
        print("[Axiom Desktop] Stopped cleanly.")

if __name__ == "__main__":
    daemon = AxiomDesktopDaemon()
    daemon.start()

    def handle_sigint(sig, frame):
        daemon.stop()
        sys.exit(0)

    signal.signal(signal.SIGINT, handle_sigint)

    try:
        while True:
            time.sleep(1)
    except KeyboardInterrupt:
        daemon.stop()
