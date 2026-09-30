"""
Wi-Fi Transport Server with TCP Streaming & UDP LAN Auto-Discovery.
"""
import socket
import threading
import json
import time
from typing import Callable, Any, Dict, Optional, Set
from transport.base import ITransportServer
from core.protocol import serialize_packet, parse_packet, PROTOCOL_VERSION

DEFAULT_TCP_PORT = 8890
DEFAULT_UDP_DISCOVERY_PORT = 8891

class WifiTransportServer(ITransportServer):
    def __init__(self, tcp_port: int = DEFAULT_TCP_PORT, discovery_port: int = DEFAULT_UDP_DISCOVERY_PORT):
        self.tcp_port = tcp_port
        self.discovery_port = discovery_port
        self.running = False
        self.on_event_callback: Optional[Callable[[Dict[str, Any], Any], None]] = None

        self._tcp_server: Optional[socket.socket] = None
        self._udp_server: Optional[socket.socket] = None
        
        self._tcp_thread: Optional[threading.Thread] = None
        self._discovery_thread: Optional[threading.Thread] = None
        self._active_clients: Set[socket.socket] = set()
        self._lock = threading.Lock()

    def start(self, on_event: Callable[[Dict[str, Any], Any], None]):
        self.running = True
        self.on_event_callback = on_event

        # 1. Start TCP Input Stream Server
        self._tcp_server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        self._tcp_server.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        self._tcp_server.bind(("0.0.0.0", self.tcp_port))
        self._tcp_server.listen(5)

        self._tcp_thread = threading.Thread(target=self._accept_loop, daemon=True, name="Axiom-TCP-Accept")
        self._tcp_thread.start()

        # 2. Start UDP Discovery Beacon
        self._discovery_thread = threading.Thread(target=self._discovery_loop, daemon=True, name="Axiom-UDP-Discovery")
        self._discovery_thread.start()

        print(f"[Wi-Fi Transport] Listening on TCP port {self.tcp_port} & UDP discovery port {self.discovery_port}")

    def _accept_loop(self):
        while self.running and self._tcp_server:
            try:
                client_sock, client_addr = self._tcp_server.accept()
                # Optimize for lowest possible latency: disable Nagle's algorithm
                client_sock.setsockopt(socket.IPPROTO_TCP, socket.TCP_NODELAY, 1)
                
                with self._lock:
                    self._active_clients.add(client_sock)
                
                client_handler = threading.Thread(
                    target=self._client_read_loop,
                    args=(client_sock, client_addr),
                    daemon=True,
                    name=f"Axiom-Client-{client_addr}"
                )
                client_handler.start()
            except Exception:
                break

    def _client_read_loop(self, sock: socket.socket, addr: Any):
        buffer = ""
        try:
            while self.running:
                chunk = sock.recv(4096)
                if not chunk:
                    break
                buffer += chunk.decode("utf-8", errors="ignore")
                while "\n" in buffer:
                    line, buffer = buffer.split("\n", 1)
                    if line.strip():
                        packet = parse_packet(line)
                        if packet and self.on_event_callback:
                            self.on_event_callback(packet, sock)
        except Exception:
            pass
        finally:
            with self._lock:
                self._active_clients.discard(sock)
            try:
                sock.close()
            except Exception:
                pass
            if self.on_event_callback:
                # Notify client disconnect event
                self.on_event_callback({"type": "DISCONNECT"}, sock)

    def _discovery_loop(self):
        """Responds to tablet discovery broadcasts so no IP entry is needed."""
        try:
            self._udp_server = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
            self._udp_server.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
            self._udp_server.setsockopt(socket.SOL_SOCKET, socket.SO_BROADCAST, 1)
            self._udp_server.bind(("0.0.0.0", self.discovery_port))
        except Exception as e:
            print(f"[Wi-Fi Discovery] Could not bind UDP port {self.discovery_port}: {e}")
            return

        hostname = socket.gethostname()

        while self.running and self._udp_server:
            try:
                data, addr = self._udp_server.recvfrom(1024)
                message = data.decode("utf-8", errors="ignore").strip()
                if message.startswith("AXIOM_DISCOVER_REQ"):
                    reply = {
                        "type": "AXIOM_DISCOVER_RES",
                        "v": PROTOCOL_VERSION,
                        "name": hostname,
                        "port": self.tcp_port
                    }
                    reply_bytes = (json.dumps(reply) + "\n").encode("utf-8")
                    self._udp_server.sendto(reply_bytes, addr)
            except Exception:
                break

    def send_to_client(self, client_handle: Any, packet: Dict[str, Any]):
        if isinstance(client_handle, socket.socket):
            try:
                raw_bytes = serialize_packet(packet)
                client_handle.sendall(raw_bytes)
            except Exception:
                pass

    def stop(self):
        self.running = False
        with self._lock:
            for sock in list(self._active_clients):
                try:
                    sock.close()
                except Exception:
                    pass
            self._active_clients.clear()

        if self._tcp_server:
            try:
                self._tcp_server.close()
            except Exception:
                pass

        if self._udp_server:
            try:
                self._udp_server.close()
            except Exception:
                pass
