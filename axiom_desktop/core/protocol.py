"""
Axiom Protocol Definitions (v1)
Unified input and handshake event specifications between tablet and desktop.
"""
from dataclasses import dataclass
from typing import Optional, Dict, Any, List
import json

PROTOCOL_VERSION = 1

# Packet Types
class EventType:
    KEY_DOWN = "KEY_DOWN"
    KEY_UP = "KEY_UP"
    TEXT_INPUT = "TEXT_INPUT"
    
    MOUSE_MOVE = "MOUSE_MOVE"
    MOUSE_DOWN = "MOUSE_DOWN"
    MOUSE_UP = "MOUSE_UP"
    MOUSE_SCROLL = "MOUSE_SCROLL"
    GESTURE = "GESTURE"
    
    PING = "PING"
    PONG = "PONG"
    
    PAIR_REQ = "PAIR_REQ"
    PAIR_RES = "PAIR_RES"
    AUTH_REQ = "AUTH_REQ"
    AUTH_RES = "AUTH_RES"
    
    DISCOVER_REQ = "DISCOVER_REQ"
    DISCOVER_RES = "DISCOVER_RES"

# Standard Virtual Key Codes for Windows
VK_MAP = {
    # Alphanumeric
    "A": 0x41, "B": 0x42, "C": 0x43, "D": 0x44, "E": 0x45,
    "F": 0x46, "G": 0x47, "H": 0x48, "I": 0x49, "J": 0x4A,
    "K": 0x4B, "L": 0x4C, "M": 0x4D, "N": 0x4E, "O": 0x4F,
    "P": 0x50, "Q": 0x51, "R": 0x52, "S": 0x53, "T": 0x54,
    "U": 0x55, "V": 0x56, "W": 0x57, "X": 0x58, "Y": 0x59, "Z": 0x5A,
    "0": 0x30, "1": 0x31, "2": 0x32, "3": 0x33, "4": 0x34,
    "5": 0x35, "6": 0x36, "7": 0x37, "8": 0x38, "9": 0x39,
    
    # Function Keys
    "F1": 0x70, "F2": 0x71, "F3": 0x72, "F4": 0x73, "F5": 0x74, "F6": 0x75,
    "F7": 0x76, "F8": 0x77, "F9": 0x78, "F10": 0x79, "F11": 0x7A, "F12": 0x7B,
    
    # Modifiers & System
    "ESCAPE": 0x1B, "TAB": 0x09, "CAPS_LOCK": 0x14,
    "SHIFT_LEFT": 0xA0, "SHIFT_RIGHT": 0xA1, "SHIFT": 0x10,
    "CTRL_LEFT": 0xA2, "CTRL_RIGHT": 0xA3, "CTRL": 0x11,
    "ALT_LEFT": 0xA4, "ALT_RIGHT": 0xA5, "ALT": 0x12,
    "WIN": 0x5B, "SPACE": 0x20, "ENTER": 0x0D, "BACKSPACE": 0x08,
    
    # Navigation & Editing
    "INSERT": 0x2D, "DELETE": 0x2E, "HOME": 0x24, "END": 0x23,
    "PAGE_UP": 0x21, "PAGE_DOWN": 0x22,
    "ARROW_UP": 0x26, "ARROW_DOWN": 0x28, "ARROW_LEFT": 0x25, "ARROW_RIGHT": 0x27,
    "PRT_SCR": 0x2C, "PRINT_SCREEN": 0x2C, "SNAPSHOT": 0x2C,
    
    # Punctuation & Symbols
    "MINUS": 0xBD, "EQUALS": 0xBB, "BRACKET_LEFT": 0xDB, "BRACKET_RIGHT": 0xDD,
    "BACKSLASH": 0xDC, "SEMICOLON": 0xBA, "QUOTE": 0xDE, "BACKQUOTE": 0xC0,
    "COMMA": 0xBC, "PERIOD": 0xBE, "SLASH": 0xBF,
}

# Mouse Button Codes
MOUSE_BTN_LEFT = "LEFT"
MOUSE_BTN_RIGHT = "RIGHT"
MOUSE_BTN_MIDDLE = "MIDDLE"

def serialize_packet(data: Dict[str, Any]) -> bytes:
    """Serializes a dictionary into a newline-delimited JSON byte packet."""
    data["v"] = PROTOCOL_VERSION
    return (json.dumps(data) + "\n").encode("utf-8")

def parse_packet(raw_line: str) -> Optional[Dict[str, Any]]:
    """Parses a JSON line packet and validates protocol version."""
    try:
        data = json.loads(raw_line.strip())
        if not isinstance(data, dict):
            return None
        return data
    except Exception:
        return None
