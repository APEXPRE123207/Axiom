"""
Bluetooth RFCOMM Transport Server for Windows.
Registers Serial Port Profile (SPP) with Windows Bluetooth SDP database
and processes Axiom input events from connected tablets.
"""
import socket
import threading
import ctypes
from ctypes import wintypes
from typing import Callable, Any, Dict, Optional, Set

from transport.base import ITransportServer
from core.protocol import serialize_packet, parse_packet

# Windows Winsock Bluetooth SDP Registration Structures
class _GUID(ctypes.Structure):
    _fields_ = [
        ('Data1', wintypes.DWORD),
        ('Data2', wintypes.WORD),
        ('Data3', wintypes.WORD),
        ('Data4', ctypes.c_byte * 8)
    ]

_SPP_GUID = _GUID(0x00001101, 0x0000, 0x1000, (ctypes.c_byte * 8)(0x80, 0x00, 0x00, 0x80, 0x5F, 0x9B, 0x34, 0xFB))

class _SOCKADDR_BTH(ctypes.Structure):
    _fields_ = [
        ('addressFamily', ctypes.c_ushort),
        ('btAddr', ctypes.c_ulonglong),
        ('serviceClassId', _GUID),
        ('port', ctypes.c_ulong)
    ]

class _SOCKET_ADDRESS(ctypes.Structure):
    _fields_ = [
        ('lpSockaddr', ctypes.c_void_p),
        ('iSockaddrLength', ctypes.c_int)
    ]

class _CSADDR_INFO(ctypes.Structure):
    _fields_ = [
        ('LocalAddr', _SOCKET_ADDRESS),
        ('RemoteAddr', _SOCKET_ADDRESS),
        ('iSocketType', ctypes.c_int),
        ('iProtocol', ctypes.c_int)
    ]

class _WSAQUERYSET(ctypes.Structure):
    _fields_ = [
        ('dwSize', wintypes.DWORD),
        ('lpszServiceInstanceName', wintypes.LPWSTR),
        ('lpServiceClassId', ctypes.POINTER(_GUID)),
        ('lpVersion', ctypes.c_void_p),
        ('lpszComment', wintypes.LPWSTR),
        ('dwNameSpace', wintypes.DWORD),
        ('lpNSProviderId', ctypes.c_void_p),
        ('lpszContext', wintypes.LPWSTR),
        ('dwNumberOfProtocols', wintypes.DWORD),
        ('lpafpProtocols', ctypes.c_void_p),
        ('lpszQueryString', wintypes.LPWSTR),
        ('dwNumberOfCsAddrs', wintypes.DWORD),
        ('lpcsaBuffer', ctypes.POINTER(_CSADDR_INFO)),
        ('dwOutputFlags', wintypes.DWORD),
        ('lpBlob', ctypes.c_void_p)
    ]


class BluetoothTransportServer(ITransportServer):
    def __init__(self, service_name: str = "Axiom Wireless Input"):
        self.service_name = service_name
        self.running = False
        self.is_supported = False
        self.on_event_callback: Optional[Callable[[Dict[str, Any], Any], None]] = None

        self._bt_server: Optional[socket.socket] = None
        self._accept_thread: Optional[threading.Thread] = None
        self._sdp_queryset: Optional[_WSAQUERYSET] = None
        self._active_clients: Set[socket.socket] = set()
        self._lock = threading.Lock()

        self._check_support()

    def _check_support(self):
        try:
            self.is_supported = hasattr(socket, 'AF_BLUETOOTH') and hasattr(socket, 'BTPROTO_RFCOMM')
        except Exception:
            self.is_supported = False

    def start(self, on_event: Callable[[Dict[str, Any], Any], None]):
        if not self.is_supported:
            print("[Bluetooth] RFCOMM socket not supported by host Python/OS environment.")
            return

        self.running = True
        self.on_event_callback = on_event

        try:
            self._bt_server = socket.socket(socket.AF_BLUETOOTH, socket.SOCK_STREAM, socket.BTPROTO_RFCOMM)
            # Bind to RFCOMM SPP channel 4 on all adapters
            self._bt_server.bind(("00:00:00:00:00:00", 4))
            self._bt_server.listen(1)

            # Register SPP Service with Windows SDP
            self._sdp_queryset = self._register_sdp()

            self._accept_thread = threading.Thread(target=self._accept_loop, daemon=True, name="Axiom-BT-Accept")
            self._accept_thread.start()
            print(f"[Bluetooth Transport] RFCOMM server listening and registered as '{self.service_name}'.")
        except Exception as e:
            print(f"[Bluetooth Transport] Failed to initialize RFCOMM server: {e}")
            self.running = False

    def _register_sdp(self) -> Optional[_WSAQUERYSET]:
        if not self._bt_server:
            return None
        try:
            ws2_32 = ctypes.windll.ws2_32
            local_sa = _SOCKADDR_BTH()
            local_len = ctypes.c_int(ctypes.sizeof(local_sa))
            if ws2_32.getsockname(self._bt_server.fileno(), ctypes.byref(local_sa), ctypes.byref(local_len)) != 0:
                return None

            remote_sa = _SOCKADDR_BTH()
            remote_sa.addressFamily = 32  # AF_BTH
            remote_len = ctypes.c_int(ctypes.sizeof(remote_sa))

            csaddr = _CSADDR_INFO()
            csaddr.LocalAddr.lpSockaddr = ctypes.cast(ctypes.byref(local_sa), ctypes.c_void_p)
            csaddr.LocalAddr.iSockaddrLength = local_len.value
            csaddr.RemoteAddr.lpSockaddr = ctypes.cast(ctypes.byref(remote_sa), ctypes.c_void_p)
            csaddr.RemoteAddr.iSockaddrLength = remote_len.value
            csaddr.iSocketType = socket.SOCK_STREAM
            csaddr.iProtocol = socket.BTPROTO_RFCOMM

            qs = _WSAQUERYSET()
            qs.dwSize = ctypes.sizeof(qs)
            qs.lpszServiceInstanceName = self.service_name
            qs.lpServiceClassId = ctypes.pointer(_SPP_GUID)
            qs.dwNameSpace = 16  # NS_BTH
            qs.dwNumberOfCsAddrs = 1
            qs.lpcsaBuffer = ctypes.pointer(csaddr)

            res = ws2_32.WSASetServiceW(ctypes.byref(qs), 0, 0)
            if res == 0:
                print(f"[Bluetooth] Registered SDP service: {self.service_name}")
                return qs
        except Exception as e:
            print(f"[Bluetooth] Error registering SDP service: {e}")
        return None

    def _unregister_sdp(self):
        if self._sdp_queryset:
            try:
                ctypes.windll.ws2_32.WSASetServiceW(ctypes.byref(self._sdp_queryset), 1, 0) # RNRSERVICE_DEREGISTER = 1
                self._sdp_queryset = None
                print("[Bluetooth] SDP service unregistered.")
            except Exception:
                pass

    def _accept_loop(self):
        while self.running and self._bt_server:
            try:
                client_sock, client_addr = self._bt_server.accept()
                print(f"[Bluetooth] Client connected from address: {client_addr}")
                with self._lock:
                    self._active_clients.add(client_sock)

                client_thread = threading.Thread(
                    target=self._client_read_loop,
                    args=(client_sock, client_addr),
                    daemon=True,
                    name=f"Axiom-BT-Client-{client_addr}"
                )
                client_thread.start()
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
                self.on_event_callback({"type": "DISCONNECT"}, sock)

    def send_to_client(self, client_handle: Any, packet: Dict[str, Any]):
        if isinstance(client_handle, socket.socket):
            try:
                raw_bytes = serialize_packet(packet)
                client_handle.sendall(raw_bytes)
            except Exception:
                pass

    def stop(self):
        self.running = False
        self._unregister_sdp()

        with self._lock:
            for sock in list(self._active_clients):
                try:
                    sock.close()
                except Exception:
                    pass
            self._active_clients.clear()

        if self._bt_server:
            try:
                self._bt_server.close()
            except Exception:
                pass
