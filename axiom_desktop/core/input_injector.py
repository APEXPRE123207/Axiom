"""
Windows Native Input Injection Engine using SendInput API via ctypes.
Provides ultra-low latency, game/DirectX compatible keyboard and mouse simulation.
"""
import ctypes
from ctypes import wintypes
import time
from typing import Optional, Set
from .protocol import VK_MAP, MOUSE_BTN_LEFT, MOUSE_BTN_RIGHT, MOUSE_BTN_MIDDLE

user32 = ctypes.windll.user32

# Input Types
INPUT_MOUSE = 0
INPUT_KEYBOARD = 1
INPUT_HARDWARE = 2

# Keyboard Flags
KEYEVENTF_EXTENDEDKEY = 0x0001
KEYEVENTF_KEYUP = 0x0002
KEYEVENTF_UNICODE = 0x0004
KEYEVENTF_SCANCODE = 0x0008

# Mouse Flags
MOUSEEVENTF_MOVE = 0x0001
MOUSEEVENTF_LEFTDOWN = 0x0002
MOUSEEVENTF_LEFTUP = 0x0004
MOUSEEVENTF_RIGHTDOWN = 0x0008
MOUSEEVENTF_RIGHTUP = 0x0010
MOUSEEVENTF_MIDDLEDOWN = 0x0020
MOUSEEVENTF_MIDDLEUP = 0x0040
MOUSEEVENTF_WHEEL = 0x0800
MOUSEEVENTF_HWHEEL = 0x1000

# MapVirtualKey mapping types
MAPVK_VK_TO_VSC = 0

# C Struct Definitions for Win32 SendInput
ULONG_PTR = wintypes.WPARAM

class MOUSEINPUT(ctypes.Structure):
    _fields_ = (
        ("dx", wintypes.LONG),
        ("dy", wintypes.LONG),
        ("mouseData", wintypes.DWORD),
        ("dwFlags", wintypes.DWORD),
        ("time", wintypes.DWORD),
        ("dwExtraInfo", ULONG_PTR),
    )

class KEYBDINPUT(ctypes.Structure):
    _fields_ = (
        ("wVk", wintypes.WORD),
        ("wScan", wintypes.WORD),
        ("dwFlags", wintypes.DWORD),
        ("time", wintypes.DWORD),
        ("dwExtraInfo", ULONG_PTR),
    )

class HARDWAREINPUT(ctypes.Structure):
    _fields_ = (
        ("uMsg", wintypes.DWORD),
        ("wParamL", wintypes.WORD),
        ("wParamH", wintypes.WORD),
    )

class _INPUTunion(ctypes.Union):
    _fields_ = (
        ("mi", MOUSEINPUT),
        ("ki", KEYBDINPUT),
        ("hi", HARDWAREINPUT),
    )

class INPUT(ctypes.Structure):
    _fields_ = (
        ("type", wintypes.DWORD),
        ("union", _INPUTunion),
    )

LPINPUT = ctypes.POINTER(INPUT)
user32.SendInput.argtypes = (wintypes.UINT, LPINPUT, ctypes.c_int)
user32.SendInput.restype = wintypes.UINT

user32.MapVirtualKeyW.argtypes = (wintypes.UINT, wintypes.UINT)
user32.MapVirtualKeyW.restype = wintypes.UINT

# Extended keys set for KEYEVENTF_EXTENDEDKEY flag
EXTENDED_KEYS = {
    0x21, 0x22, 0x23, 0x24, 0x25, 0x26, 0x27, 0x28,  # PageUp, PageDown, End, Home, Arrows
    0x2D, 0x2E,                                      # Insert, Delete
    0x5B, 0x5C,                                      # Windows keys
    0xA3, 0xA5,                                      # RCtrl, RAlt
    0x0D,                                            # Numpad Enter (if mapped)
    0x6F,                                            # Divide
}


class WindowsInputInjector:
    """Thread-safe native input injector for Windows."""

    def __init__(self):
        self._pressed_keys: Set[int] = set()
        self._mouse_sub_pixel_x: float = 0.0
        self._mouse_sub_pixel_y: float = 0.0
        self._scroll_accum_y: float = 0.0
        self._scroll_accum_x: float = 0.0
        self._alt_tab_active: bool = False

    def _end_alt_tab(self):
        """Releases Alt key if Alt-Tab switcher was active."""
        if self._alt_tab_active:
            user32.keybd_event(0x12, 0, KEYEVENTF_KEYUP, 0)
            self._alt_tab_active = False

    def key_down(self, key_id: str, custom_vk: Optional[int] = None) -> bool:
        """Injects a key press down event with both Virtual Key and ScanCode."""
        vk = custom_vk if custom_vk is not None else VK_MAP.get(key_id.upper())
        if vk is None:
            return False

        scan_code = user32.MapVirtualKeyW(vk, MAPVK_VK_TO_VSC)
        flags = KEYEVENTF_SCANCODE
        if vk in EXTENDED_KEYS:
            flags |= KEYEVENTF_EXTENDEDKEY

        inp = INPUT()
        inp.type = INPUT_KEYBOARD
        inp.union.ki = KEYBDINPUT(
            wVk=vk,
            wScan=scan_code,
            dwFlags=flags,
            time=0,
            dwExtraInfo=0
        )

        self._pressed_keys.add(vk)
        res = user32.SendInput(1, ctypes.byref(inp), ctypes.sizeof(INPUT))
        return res == 1

    def key_up(self, key_id: str, custom_vk: Optional[int] = None) -> bool:
        """Injects a key release event."""
        vk = custom_vk if custom_vk is not None else VK_MAP.get(key_id.upper())
        if vk is None:
            return False

        scan_code = user32.MapVirtualKeyW(vk, MAPVK_VK_TO_VSC)
        flags = KEYEVENTF_SCANCODE | KEYEVENTF_KEYUP
        if vk in EXTENDED_KEYS:
            flags |= KEYEVENTF_EXTENDEDKEY

        inp = INPUT()
        inp.type = INPUT_KEYBOARD
        inp.union.ki = KEYBDINPUT(
            wVk=vk,
            wScan=scan_code,
            dwFlags=flags,
            time=0,
            dwExtraInfo=0
        )

        self._pressed_keys.discard(vk)
        res = user32.SendInput(1, ctypes.byref(inp), ctypes.sizeof(INPUT))
        return res == 1

    def release_all_keys(self):
        """Emergency release for all currently held keys on disconnect."""
        self._end_alt_tab()
        keys = list(self._pressed_keys)
        for vk in keys:
            scan_code = user32.MapVirtualKeyW(vk, MAPVK_VK_TO_VSC)
            flags = KEYEVENTF_SCANCODE | KEYEVENTF_KEYUP
            if vk in EXTENDED_KEYS:
                flags |= KEYEVENTF_EXTENDEDKEY

            inp = INPUT()
            inp.type = INPUT_KEYBOARD
            inp.union.ki = KEYBDINPUT(wVk=vk, wScan=scan_code, dwFlags=flags, time=0, dwExtraInfo=0)
            user32.SendInput(1, ctypes.byref(inp), ctypes.sizeof(INPUT))
        self._pressed_keys.clear()

    def mouse_move(self, dx: float, dy: float):
        """Injects smooth relative mouse movement with sub-pixel accumulation."""
        self._mouse_sub_pixel_x += dx
        self._mouse_sub_pixel_y += dy

        int_x = int(self._mouse_sub_pixel_x)
        int_y = int(self._mouse_sub_pixel_y)

        self._mouse_sub_pixel_x -= int_x
        self._mouse_sub_pixel_y -= int_y

        if int_x == 0 and int_y == 0:
            return

        inp = INPUT()
        inp.type = INPUT_MOUSE
        inp.union.mi = MOUSEINPUT(
            dx=int_x,
            dy=int_y,
            mouseData=0,
            dwFlags=MOUSEEVENTF_MOVE,
            time=0,
            dwExtraInfo=0
        )
        user32.SendInput(1, ctypes.byref(inp), ctypes.sizeof(INPUT))

    def mouse_button(self, button: str, is_down: bool):
        """Injects mouse button press or release."""
        btn_flag = 0
        if button == MOUSE_BTN_LEFT:
            btn_flag = MOUSEEVENTF_LEFTDOWN if is_down else MOUSEEVENTF_LEFTUP
        elif button == MOUSE_BTN_RIGHT:
            btn_flag = MOUSEEVENTF_RIGHTDOWN if is_down else MOUSEEVENTF_RIGHTUP
        elif button == MOUSE_BTN_MIDDLE:
            btn_flag = MOUSEEVENTF_MIDDLEDOWN if is_down else MOUSEEVENTF_MIDDLEUP

        if btn_flag == 0:
            return

        inp = INPUT()
        inp.type = INPUT_MOUSE
        inp.union.mi = MOUSEINPUT(
            dx=0,
            dy=0,
            mouseData=0,
            dwFlags=btn_flag,
            time=0,
            dwExtraInfo=0
        )
        user32.SendInput(1, ctypes.byref(inp), ctypes.sizeof(INPUT))

    def mouse_scroll(self, dx: float, dy: float):
        """Injects smooth vertical and horizontal mouse wheel movement."""
        # Sensitivity multiplier: ~30px 2-finger drag = 1 standard wheel notch (120 units)
        SCALE = 4.0

        if dy != 0:
            self._scroll_accum_y += dy * SCALE
            clicks = int(self._scroll_accum_y)
            if clicks != 0:
                self._scroll_accum_y -= clicks
                inp = INPUT()
                inp.type = INPUT_MOUSE
                inp.union.mi = MOUSEINPUT(
                    dx=0,
                    dy=0,
                    mouseData=clicks,
                    dwFlags=MOUSEEVENTF_WHEEL,
                    time=0,
                    dwExtraInfo=0
                )
                user32.SendInput(1, ctypes.byref(inp), ctypes.sizeof(INPUT))

        if dx != 0:
            self._scroll_accum_x += dx * SCALE
            clicks = int(self._scroll_accum_x)
            if clicks != 0:
                self._scroll_accum_x -= clicks
                inp = INPUT()
                inp.type = INPUT_MOUSE
                inp.union.mi = MOUSEINPUT(
                    dx=0,
                    dy=0,
                    mouseData=clicks,
                    dwFlags=MOUSEEVENTF_HWHEEL,
                    time=0,
                    dwExtraInfo=0
                )
                user32.SendInput(1, ctypes.byref(inp), ctypes.sizeof(INPUT))

    def _send_combo(self, modifiers: list, key: str):
        """Sends a modifier + key combination with proper press duration."""
        for mod in modifiers:
            self.key_down(mod)
        time.sleep(0.02)
        self.key_down(key)
        time.sleep(0.02)
        self.key_up(key)
        time.sleep(0.01)
        for mod in reversed(modifiers):
            self.key_up(mod)

    def _send_sys_combo(self, vks: list):
        """Sends Windows system combos (Alt+Tab, Win+Tab, etc.) directly via virtual keys."""
        for vk in vks:
            user32.keybd_event(vk, 0, 0, 0)
            time.sleep(0.01)
        time.sleep(0.03)
        for vk in reversed(vks):
            user32.keybd_event(vk, 0, KEYEVENTF_KEYUP, 0)
            time.sleep(0.01)

    def trigger_gesture(self, action: str):
        """Executes Windows Precision Touchpad gesture actions natively via SendInput and keybd_event."""
        print(f"[Axiom Input] Executing gesture: {action}")
        if action in ("APP_NEXT", "APP_RIGHT"):
            if not self._alt_tab_active:
                self._alt_tab_active = True
                user32.keybd_event(0x12, 0, 0, 0)  # Hold Alt down
                time.sleep(0.02)
                user32.keybd_event(0x09, 0, 0, 0)  # Tab down
                time.sleep(0.02)
                user32.keybd_event(0x09, 0, KEYEVENTF_KEYUP, 0)
            else:
                user32.keybd_event(0x27, 0, 0, 0)  # Arrow Right down
                time.sleep(0.02)
                user32.keybd_event(0x27, 0, KEYEVENTF_KEYUP, 0)
        elif action in ("APP_PREV", "APP_LEFT"):
            if not self._alt_tab_active:
                self._alt_tab_active = True
                user32.keybd_event(0x12, 0, 0, 0)  # Hold Alt down
                time.sleep(0.02)
                user32.keybd_event(0x10, 0, 0, 0)  # Shift down
                user32.keybd_event(0x09, 0, 0, 0)  # Tab down
                time.sleep(0.02)
                user32.keybd_event(0x09, 0, KEYEVENTF_KEYUP, 0)
                user32.keybd_event(0x10, 0, KEYEVENTF_KEYUP, 0)
            else:
                user32.keybd_event(0x25, 0, 0, 0)  # Arrow Left down
                time.sleep(0.02)
                user32.keybd_event(0x25, 0, KEYEVENTF_KEYUP, 0)
        elif action == "APP_DOWN":
            if self._alt_tab_active:
                user32.keybd_event(0x28, 0, 0, 0)  # Arrow Down down
                time.sleep(0.02)
                user32.keybd_event(0x28, 0, KEYEVENTF_KEYUP, 0)
        elif action == "APP_UP":
            if self._alt_tab_active:
                user32.keybd_event(0x26, 0, 0, 0)  # Arrow Up down
                time.sleep(0.02)
                user32.keybd_event(0x26, 0, KEYEVENTF_KEYUP, 0)
        elif action == "APP_SWITCH_END":
            self._end_alt_tab()
        else:
            self._end_alt_tab()
            if action == "TAB_NEXT":
                self._send_sys_combo([0x11, 0x09])  # Ctrl + Tab
            elif action == "TAB_PREV":
                self._send_sys_combo([0x11, 0x10, 0x09])  # Ctrl + Shift + Tab
            elif action == "TASK_VIEW":
                self._send_sys_combo([0x5B, 0x09])  # Win + Tab
            elif action == "SHOW_DESKTOP":
                self._send_sys_combo([0x5B, 0x44])  # Win + D
            elif action == "SEARCH":
                self._send_sys_combo([0x5B, 0x53])  # Win + S
            elif action == "MIDDLE_CLICK":
                self.mouse_button(MOUSE_BTN_MIDDLE, True)
                time.sleep(0.03)
                self.mouse_button(MOUSE_BTN_MIDDLE, False)
            elif action == "DESKTOP_NEXT":
                self._send_sys_combo([0x11, 0x5B, 0x27])  # Ctrl + Win + Arrow Right
            elif action == "DESKTOP_PREV":
                self._send_sys_combo([0x11, 0x5B, 0x25])  # Ctrl + Win + Arrow Left
            elif action == "ACTION_CENTER":
                self._send_sys_combo([0x5B, 0x41])  # Win + A
            elif action == "NOTIFICATIONS":
                self._send_sys_combo([0x5B, 0x4E])  # Win + N
            elif action == "ZOOM_IN":
                self.key_down("CTRL")
                time.sleep(0.02)
                self.mouse_scroll(0, 120)
                time.sleep(0.02)
                self.key_up("CTRL")
            elif action == "ZOOM_OUT":
                self.key_down("CTRL")
                time.sleep(0.02)
                self.mouse_scroll(0, -120)
                time.sleep(0.02)
                self.key_up("CTRL")
