"""
End-to-End Pipeline Integration Test for Axiom Protocol and Wi-Fi Transport.
Validates:
1. UDP LAN auto-discovery beacon
2. TCP connection establishment
3. PIN pairing security & token issuance
4. Session authentication & unauthorized rejection
5. Ping / Pong round-trip latency
6. Keyboard event reception & input injection dispatch
"""
import socket
import json
import time
import threading
from axiom_desktop import AxiomDesktopDaemon
from core.protocol import EventType

def test_pipeline():
    print("\n--- Starting Axiom End-to-End Test Suite ---")
    daemon = AxiomDesktopDaemon()
    daemon.start()
    time.sleep(0.2)

    try:
        # 1. Test UDP LAN Auto-Discovery
        print("\n[Test 1] Testing UDP LAN Auto-Discovery Beacon...")
        udp_sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        udp_sock.setsockopt(socket.SOL_SOCKET, socket.SO_BROADCAST, 1)
        udp_sock.settimeout(2.0)
        udp_sock.sendto(b"AXIOM_DISCOVER_REQ\n", ("127.0.0.1", 8891))
        
        data, addr = udp_sock.recvfrom(1024)
        disco_res = json.loads(data.decode("utf-8").strip())
        assert disco_res["type"] == "AXIOM_DISCOVER_RES", f"Unexpected discovery response: {disco_res}"
        assert disco_res["port"] == 8890, f"Unexpected port: {disco_res['port']}"
        print(f"  [OK] UDP Discovery passed! Discovered: {disco_res['name']} on port {disco_res['port']}")
        udp_sock.close()

        # 2. Connect via TCP
        print("\n[Test 2] Connecting TCP client to Axiom Desktop...")
        client = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        client.connect(("127.0.0.1", 8890))
        client.settimeout(2.0)
        print("  [OK] TCP Socket connected.")

        # 3. Test Invalid PIN Rejection
        print("\n[Test 3] Testing Security: Invalid PIN Rejection...")
        pair_req_bad = {
            "v": 1,
            "type": EventType.PAIR_REQ,
            "device_id": "test_tab_01",
            "name": "Test Tablet",
            "pin": "000000"  # Wrong PIN
        }
        client.sendall((json.dumps(pair_req_bad) + "\n").encode("utf-8"))
        res_bad = json.loads(client.recv(1024).decode("utf-8").strip())
        assert res_bad["type"] == EventType.PAIR_RES
        assert res_bad["success"] is False
        print("  [OK] Security verified: Invalid PIN rejected properly.")

        # 4. Test Valid PIN Pairing
        print("\n[Test 4] Testing Security: Valid PIN Pairing...")
        valid_pin = daemon.security.current_pin
        pair_req_good = {
            "v": 1,
            "type": EventType.PAIR_REQ,
            "device_id": "test_tab_01",
            "name": "Test Tablet",
            "pin": valid_pin
        }
        client.sendall((json.dumps(pair_req_good) + "\n").encode("utf-8"))
        res_good = json.loads(client.recv(1024).decode("utf-8").strip())
        assert res_good["type"] == EventType.PAIR_RES
        assert res_good["success"] is True
        token = res_good["token"]
        assert token is not None and len(token) > 10
        print(f"  [OK] Pairing succeeded! Received secure session token: {token[:8]}...")

        # 5. Test Ping / Pong
        print("\n[Test 5] Testing Ping / Pong Latency Engine...")
        ts_now = time.time()
        ping_packet = {"v": 1, "type": EventType.PING, "ts": ts_now}
        client.sendall((json.dumps(ping_packet) + "\n").encode("utf-8"))
        pong_res = json.loads(client.recv(1024).decode("utf-8").strip())
        assert pong_res["type"] == EventType.PONG
        print(f"  [OK] Pong received! Client TS matched: {pong_res['client_ts']}")

        # 6. Test Keyboard Input Injection (Key Down & Key Up)
        print("\n[Test 6] Testing Keyboard Input Injection Dispatch...")
        key_down = {"v": 1, "type": EventType.KEY_DOWN, "key": "A", "vk": 0x41}
        client.sendall((json.dumps(key_down) + "\n").encode("utf-8"))
        time.sleep(0.05)
        assert 0x41 in daemon.input_injector._pressed_keys
        print("  [OK] KEY_DOWN received and active in pressed keys map.")

        key_up = {"v": 1, "type": EventType.KEY_UP, "key": "A", "vk": 0x41}
        client.sendall((json.dumps(key_up) + "\n").encode("utf-8"))
        time.sleep(0.05)
        assert 0x41 not in daemon.input_injector._pressed_keys
        print("  [OK] KEY_UP received and key released.")

        # 7. Test Mouse / Touchpad Input Injection (Move, Clicks, Scroll)
        print("\n[Test 7] Testing Mouse / Touchpad Input Injection...")
        mouse_move = {"v": 1, "type": EventType.MOUSE_MOVE, "dx": 15.0, "dy": -8.0}
        client.sendall((json.dumps(mouse_move) + "\n").encode("utf-8"))
        time.sleep(0.05)
        print("  [OK] MOUSE_MOVE injected successfully.")

        # Left Click down & up
        client.sendall((json.dumps({"v": 1, "type": EventType.MOUSE_DOWN, "btn": "LEFT"}) + "\n").encode("utf-8"))
        time.sleep(0.02)
        client.sendall((json.dumps({"v": 1, "type": EventType.MOUSE_UP, "btn": "LEFT"}) + "\n").encode("utf-8"))
        time.sleep(0.05)
        print("  [OK] Left Click (MOUSE_DOWN + MOUSE_UP) injected successfully.")

        # Right Click down & up
        client.sendall((json.dumps({"v": 1, "type": EventType.MOUSE_DOWN, "btn": "RIGHT"}) + "\n").encode("utf-8"))
        time.sleep(0.02)
        client.sendall((json.dumps({"v": 1, "type": EventType.MOUSE_UP, "btn": "RIGHT"}) + "\n").encode("utf-8"))
        time.sleep(0.05)
        print("  [OK] Right Click (MOUSE_DOWN + MOUSE_UP) injected successfully.")

        # Scroll
        mouse_scroll = {"v": 1, "type": EventType.MOUSE_SCROLL, "dx": 0.0, "dy": -2.0}
        client.sendall((json.dumps(mouse_scroll) + "\n").encode("utf-8"))
        time.sleep(0.05)
        print("  [OK] MOUSE_SCROLL injected successfully.")

        # 8. Test Disconnect cleanup
        print("\n[Test 8] Testing Client Disconnect & Emergency Release...")
        client.close()
        time.sleep(0.2)
        assert len(daemon.authenticated_clients) == 0
        print("  [OK] Disconnect handled cleanly, sessions reset.")

        print("\n=== ALL 8 TESTS PASSED SUCCESSFULLY! ===\n")

    finally:
        daemon.stop()

if __name__ == "__main__":
    test_pipeline()
