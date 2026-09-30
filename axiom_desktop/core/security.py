"""
Axiom Security and Device Pairing Manager.
Handles 6-digit PIN challenges, session tokens, and trusted device persistence.
"""
import os
import json
import secrets
import time
from typing import Dict, Optional, Set

CONFIG_DIR = os.path.expanduser("~/.axiom")
TRUSTED_DEVICES_FILE = os.path.join(CONFIG_DIR, "trusted_devices.json")

PIN_FILE = os.path.join(CONFIG_DIR, "pairing_pin.txt")

class SecurityManager:
    def __init__(self):
        os.makedirs(CONFIG_DIR, exist_ok=True)
        self.current_pin: str = self._load_or_generate_pin()
        self.active_sessions: Dict[str, str] = {}  # device_id -> session_token
        self.trusted_devices: Dict[str, Dict] = self._load_trusted_devices()

    def _load_or_generate_pin(self) -> str:
        """Loads persistent pairing PIN or generates a new 6-digit PIN."""
        if os.path.exists(PIN_FILE):
            try:
                with open(PIN_FILE, "r", encoding="utf-8") as f:
                    pin = f.read().strip()
                    if pin:
                        return pin
            except Exception:
                pass
        
        pin = f"{secrets.randbelow(900000) + 100000}"
        try:
            with open(PIN_FILE, "w", encoding="utf-8") as f:
                f.write(pin)
        except Exception:
            pass
        return pin

    def generate_pin(self) -> str:
        """Generates and persists a new 6-digit numeric pairing PIN."""
        self.current_pin = f"{secrets.randbelow(900000) + 100000}"
        try:
            with open(PIN_FILE, "w", encoding="utf-8") as f:
                f.write(self.current_pin)
        except Exception:
            pass
        return self.current_pin

    def _load_trusted_devices(self) -> Dict[str, Dict]:
        if os.path.exists(TRUSTED_DEVICES_FILE):
            try:
                with open(TRUSTED_DEVICES_FILE, "r", encoding="utf-8") as f:
                    return json.load(f)
            except Exception:
                return {}
        return {}

    def _save_trusted_devices(self):
        try:
            with open(TRUSTED_DEVICES_FILE, "w", encoding="utf-8") as f:
                json.dump(self.trusted_devices, f, indent=2)
        except Exception as e:
            print(f"[Security] Error saving trusted devices: {e}")

    def is_trusted(self, device_id: str, secret_token: str) -> bool:
        """Checks if a device has an already established trusted authorization token."""
        record = self.trusted_devices.get(device_id)
        if record and record.get("token") == secret_token:
            return True
        return False

    def verify_pin_and_register(self, device_id: str, device_name: str, pin: str) -> Optional[str]:
        """Validates pairing PIN; if matched, generates permanent trust token and active session."""
        if pin.strip() == self.current_pin.strip():
            token = secrets.token_hex(32)
            self.trusted_devices[device_id] = {
                "name": device_name,
                "token": token,
                "paired_at": time.time(),
                "last_connected": time.time()
            }
            self._save_trusted_devices()
            self.active_sessions[device_id] = token
            return token
        return None

    def authenticate_session(self, device_id: str, token: str) -> bool:
        """Validates if connection provides a valid trusted or active session token."""
        if self.is_trusted(device_id, token):
            self.active_sessions[device_id] = token
            self.trusted_devices[device_id]["last_connected"] = time.time()
            self._save_trusted_devices()
            return True
        return False

    def revoke_device(self, device_id: str):
        """Revokes trust for a device."""
        if device_id in self.trusted_devices:
            del self.trusted_devices[device_id]
            self._save_trusted_devices()
        self.active_sessions.pop(device_id, None)

    def is_session_active(self, device_id: str, token: str) -> bool:
        return self.active_sessions.get(device_id) == token
