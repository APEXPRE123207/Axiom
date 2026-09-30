"""
Axiom Desktop GUI Application
Modern Dark Glassmorphic Interface for the Windows Input Receiver.
"""
import sys
import os
import threading
import time
import tkinter as tk
from tkinter import ttk, messagebox

# Add current directory and bundle directory to path
if getattr(sys, 'frozen', False) and hasattr(sys, '_MEIPASS'):
    BASE_DIR = sys._MEIPASS
else:
    BASE_DIR = os.path.dirname(os.path.abspath(__file__))

if BASE_DIR not in sys.path:
    sys.path.insert(0, BASE_DIR)

from axiom_desktop import AxiomDesktopDaemon, get_local_ips

# Aesthetics constants
BG_COLOR = "#070A10"
PANEL_BG = "#0E131F"
CARD_BG = "#141A29"
BORDER_COLOR = "#1E293B"
ACCENT_CYAN = "#00E5FF"
ACCENT_GREEN = "#00FF66"
ACCENT_RED = "#FF3366"
ACCENT_AMBER = "#FFB700"
TEXT_PRIMARY = "#FFFFFF"
TEXT_MUTED = "#94A3B8"
FONT_TITLE = ("Segoe UI", 16, "bold")
FONT_SUBTITLE = ("Segoe UI", 10)
FONT_HEADING = ("Segoe UI", 11, "bold")
FONT_CODE = ("Consolas", 10)
FONT_PIN = ("Segoe UI", 26, "bold")

class AxiomDesktopGUI:
    def __init__(self, root: tk.Tk):
        self.root = root
        self.root.title("Axiom — Universal Wireless Input Receiver")
        self.root.geometry("780x640")
        self.root.minsize(700, 580)
        self.root.configure(bg=BG_COLOR)

        self.logo_path = os.path.join(os.path.dirname(BASE_DIR), "logo.png")
        if not os.path.exists(self.logo_path):
            self.logo_path = os.path.join(BASE_DIR, "logo.png")

        # Set Window Icon
        self._set_window_icon()

        # Daemon instance & thread
        self.daemon = None
        self.daemon_thread = None

        # Build UI layout
        self._build_header()
        self._build_content()
        self._build_footer()

        # Handle window close
        self.root.protocol("WM_DELETE_WINDOW", self.on_close)

        # Auto-start receiver daemon
        self.start_server()

    def _set_window_icon(self):
        try:
            if os.path.exists(self.logo_path):
                self.icon_img = tk.PhotoImage(file=self.logo_path)
                self.root.iconphoto(True, self.icon_img)
        except Exception as e:
            print(f"Could not set window icon: {e}")

    def _build_header(self):
        header_frame = tk.Frame(self.root, bg=PANEL_BG, height=72, highlightthickness=1, highlightbackground=BORDER_COLOR)
        header_frame.pack(fill=tk.X, side=tk.TOP)
        header_frame.pack_propagate(False)

        inner = tk.Frame(header_frame, bg=PANEL_BG)
        inner.pack(fill=tk.BOTH, expand=True, padx=20, pady=10)

        # Logo display
        try:
            if os.path.exists(self.logo_path):
                # Downsample large logo for 44x44 header icon
                raw_logo = tk.PhotoImage(file=self.logo_path)
                step = max(1, raw_logo.width() // 44)
                self.header_logo = raw_logo.subsample(step, step)
                logo_lbl = tk.Label(inner, image=self.header_logo, bg=PANEL_BG)
                logo_lbl.pack(side=tk.LEFT, padx=(0, 14))
        except Exception:
            logo_lbl = tk.Label(inner, text="⚡", font=("Segoe UI", 24), fg=ACCENT_CYAN, bg=PANEL_BG)
            logo_lbl.pack(side=tk.LEFT, padx=(0, 14))

        # Title & Subtitle
        title_box = tk.Frame(inner, bg=PANEL_BG)
        title_box.pack(side=tk.LEFT, fill=tk.Y)

        title_lbl = tk.Label(title_box, text="AXIOM DESKTOP", font=FONT_TITLE, fg=TEXT_PRIMARY, bg=PANEL_BG)
        title_lbl.pack(anchor="w")

        sub_lbl = tk.Label(title_box, text="High-Performance Universal Tablet Controller Receiver", font=FONT_SUBTITLE, fg=TEXT_MUTED, bg=PANEL_BG)
        sub_lbl.pack(anchor="w")

        # Right side status pill & toggle
        status_box = tk.Frame(inner, bg=PANEL_BG)
        status_box.pack(side=tk.RIGHT)

        self.status_pill = tk.Label(
            status_box,
            text="● INITIALIZING",
            font=("Segoe UI", 10, "bold"),
            fg=ACCENT_AMBER,
            bg="#1B2234",
            padx=12,
            pady=4,
            relief=tk.FLAT
        )
        self.status_pill.pack(side=tk.RIGHT, padx=(10, 0))

        self.toggle_btn = tk.Button(
            status_box,
            text="Stop Server",
            font=("Segoe UI", 9, "bold"),
            bg="#25161C",
            fg=ACCENT_RED,
            activebackground="#3D1A25",
            activeforeground=ACCENT_RED,
            relief=tk.FLAT,
            padx=10,
            pady=4,
            cursor="hand2",
            command=self.toggle_server
        )
        self.toggle_btn.pack(side=tk.RIGHT)

    def _build_content(self):
        content_frame = tk.Frame(self.root, bg=BG_COLOR)
        content_frame.pack(fill=tk.BOTH, expand=True, padx=20, pady=16)

        # Top row: Left = Pairing Hero Card, Right = Network Info Card
        top_row = tk.Frame(content_frame, bg=BG_COLOR)
        top_row.pack(fill=tk.X, pady=(0, 14))

        self._build_pin_card(top_row)
        self._build_network_card(top_row)

        # Middle: Connected Devices Card
        self._build_devices_card(content_frame)

        # Bottom: Live Activity Console
        self._build_console_card(content_frame)

    def _build_pin_card(self, parent):
        pin_card = tk.Frame(parent, bg=CARD_BG, highlightthickness=1, highlightbackground=BORDER_COLOR)
        pin_card.pack(side=tk.LEFT, fill=tk.BOTH, expand=True, padx=(0, 8))

        inner = tk.Frame(pin_card, bg=CARD_BG, padx=16, pady=14)
        inner.pack(fill=tk.BOTH, expand=True)

        header = tk.Frame(inner, bg=CARD_BG)
        header.pack(fill=tk.X)
        tk.Label(header, text="🔑 PAIRING SECURITY PIN", font=FONT_HEADING, fg=ACCENT_CYAN, bg=CARD_BG).pack(side=tk.LEFT)

        self.pin_label = tk.Label(
            inner,
            text="------",
            font=FONT_PIN,
            fg=ACCENT_CYAN,
            bg="#0B0F19",
            padx=20,
            pady=6,
            relief=tk.GROOVE
        )
        self.pin_label.pack(fill=tk.X, pady=(10, 8))

        btn_row = tk.Frame(inner, bg=CARD_BG)
        btn_row.pack(fill=tk.X)

        copy_btn = tk.Button(
            btn_row,
            text="📋 Copy PIN",
            font=("Segoe UI", 9, "bold"),
            bg="#1E293B",
            fg=TEXT_PRIMARY,
            activebackground=ACCENT_CYAN,
            activeforeground="#000000",
            relief=tk.FLAT,
            padx=10,
            pady=4,
            cursor="hand2",
            command=self.copy_pin
        )
        copy_btn.pack(side=tk.LEFT, expand=True, fill=tk.X, padx=(0, 4))

        regen_btn = tk.Button(
            btn_row,
            text="🔄 New PIN",
            font=("Segoe UI", 9),
            bg="#1E293B",
            fg=TEXT_MUTED,
            activebackground="#334155",
            activeforeground=TEXT_PRIMARY,
            relief=tk.FLAT,
            padx=8,
            pady=4,
            cursor="hand2",
            command=self.regenerate_pin
        )
        regen_btn.pack(side=tk.RIGHT, expand=True, fill=tk.X, padx=(4, 0))

        tk.Label(
            inner,
            text="Enter this 6-digit PIN on your tablet to authenticate.",
            font=("Segoe UI", 9),
            fg=TEXT_MUTED,
            bg=CARD_BG
        ).pack(anchor="w", pady=(8, 0))

    def _build_network_card(self, parent):
        net_card = tk.Frame(parent, bg=CARD_BG, highlightthickness=1, highlightbackground=BORDER_COLOR)
        net_card.pack(side=tk.RIGHT, fill=tk.BOTH, expand=True, padx=(8, 0))

        inner = tk.Frame(net_card, bg=CARD_BG, padx=16, pady=14)
        inner.pack(fill=tk.BOTH, expand=True)

        tk.Label(inner, text="📡 NETWORK & DISCOVERY", font=FONT_HEADING, fg=ACCENT_CYAN, bg=CARD_BG).pack(anchor="w")

        # IP addresses
        ips = get_local_ips()
        main_ip = ips[0] if ips else "127.0.0.1"

        info_grid = tk.Frame(inner, bg=CARD_BG)
        info_grid.pack(fill=tk.X, pady=(10, 0))

        self._add_info_row(info_grid, "Local IP Address:", main_ip, ACCENT_GREEN)
        self._add_info_row(info_grid, "Service Port:", "8890 (TCP / UDP)", TEXT_PRIMARY)
        self._add_info_row(info_grid, "mDNS Beacon:", "Axiom-PC (Auto-Discovery)", ACCENT_CYAN)
        self._add_info_row(info_grid, "Bluetooth RFCOMM:", "Supported / Listening", TEXT_MUTED)

    def _add_info_row(self, parent, label: str, val: str, val_color: str):
        row = tk.Frame(parent, bg=CARD_BG)
        row.pack(fill=tk.X, pady=2)
        tk.Label(row, text=label, font=("Segoe UI", 9), fg=TEXT_MUTED, bg=CARD_BG, width=17, anchor="w").pack(side=tk.LEFT)
        tk.Label(row, text=val, font=("Segoe UI", 9, "bold"), fg=val_color, bg=CARD_BG, anchor="w").pack(side=tk.LEFT)

    def _build_devices_card(self, parent):
        dev_card = tk.Frame(parent, bg=CARD_BG, highlightthickness=1, highlightbackground=BORDER_COLOR)
        dev_card.pack(fill=tk.X, pady=(0, 14))

        inner = tk.Frame(dev_card, bg=CARD_BG, padx=16, pady=10)
        inner.pack(fill=tk.BOTH, expand=True)

        header = tk.Frame(inner, bg=CARD_BG)
        header.pack(fill=tk.X)
        tk.Label(header, text="📱 CONNECTED TABLET CONTROLLERS", font=FONT_HEADING, fg=ACCENT_CYAN, bg=CARD_BG).pack(side=tk.LEFT)

        self.dev_count_lbl = tk.Label(header, text="0 Active", font=("Segoe UI", 9, "bold"), fg=TEXT_MUTED, bg=CARD_BG)
        self.dev_count_lbl.pack(side=tk.RIGHT)

        self.dev_list_frame = tk.Frame(inner, bg=CARD_BG)
        self.dev_list_frame.pack(fill=tk.X, pady=(8, 0))

        self.no_dev_lbl = tk.Label(
            self.dev_list_frame,
            text="Waiting for tablet connection... Launch Axiom on your tablet and tap 'Scan LAN'.",
            font=("Segoe UI", 9, "italic"),
            fg=TEXT_MUTED,
            bg=CARD_BG,
            pady=4
        )
        self.no_dev_lbl.pack(anchor="w")

    def _build_console_card(self, parent):
        console_card = tk.Frame(parent, bg=CARD_BG, highlightthickness=1, highlightbackground=BORDER_COLOR)
        console_card.pack(fill=tk.BOTH, expand=True)

        inner = tk.Frame(console_card, bg=CARD_BG, padx=16, pady=10)
        inner.pack(fill=tk.BOTH, expand=True)

        header = tk.Frame(inner, bg=CARD_BG)
        header.pack(fill=tk.X, pady=(0, 6))

        tk.Label(header, text="💻 LIVE ACTIVITY CONSOLE", font=FONT_HEADING, fg=ACCENT_CYAN, bg=CARD_BG).pack(side=tk.LEFT)

        clear_btn = tk.Button(
            header,
            text="Clear",
            font=("Segoe UI", 8),
            bg="#1E293B",
            fg=TEXT_MUTED,
            activebackground="#334155",
            activeforeground=TEXT_PRIMARY,
            relief=tk.FLAT,
            padx=8,
            pady=1,
            cursor="hand2",
            command=self.clear_console
        )
        clear_btn.pack(side=tk.RIGHT)

        # Scrolled Text Widget
        text_container = tk.Frame(inner, bg="#05080E")
        text_container.pack(fill=tk.BOTH, expand=True)

        self.console_text = tk.Text(
            text_container,
            bg="#05080E",
            fg="#70DF92",
            insertbackground=ACCENT_CYAN,
            font=FONT_CODE,
            wrap=tk.WORD,
            bd=0,
            highlightthickness=0,
            padx=8,
            pady=6
        )
        scrollbar = tk.Scrollbar(text_container, command=self.console_text.yview, bg="#0E131F")
        self.console_text.configure(yscrollcommand=scrollbar.set)

        scrollbar.pack(side=tk.RIGHT, fill=tk.Y)
        self.console_text.pack(side=tk.LEFT, fill=tk.BOTH, expand=True)

    def _build_footer(self):
        footer_frame = tk.Frame(self.root, bg=PANEL_BG, height=28, highlightthickness=1, highlightbackground=BORDER_COLOR)
        footer_frame.pack(fill=tk.X, side=tk.BOTTOM)
        footer_frame.pack_propagate(False)

        inner = tk.Frame(footer_frame, bg=PANEL_BG)
        inner.pack(fill=tk.BOTH, expand=True, padx=16)

        tk.Label(inner, text="Axiom Controller Receiver • Standalone Windows Edition", font=("Segoe UI", 8), fg=TEXT_MUTED, bg=PANEL_BG).pack(side=tk.LEFT)
        tk.Label(inner, text="Low-Latency UDP/TCP Engine Active", font=("Segoe UI", 8), fg=ACCENT_CYAN, bg=PANEL_BG).pack(side=tk.RIGHT)

    def log(self, message: str):
        def _append():
            timestamp = time.strftime("%H:%M:%S")
            self.console_text.insert(tk.END, f"[{timestamp}] {message}\n")
            self.console_text.see(tk.END)
        self.root.after(0, _append)

    def clear_console(self):
        self.console_text.delete("1.0", tk.END)

    def copy_pin(self):
        if self.daemon:
            pin = self.daemon.security.current_pin
            self.root.clipboard_clear()
            self.root.clipboard_append(pin)
            self.log(f"[GUI] PIN {pin} copied to clipboard.")
            messagebox.showinfo("PIN Copied", f"Pairing PIN '{pin}' copied to clipboard!")

    def regenerate_pin(self):
        if self.daemon:
            new_pin = self.daemon.security.generate_new_pin()
            self.pin_label.config(text=f"{new_pin[:3]} {new_pin[3:]}")
            self.log(f"[Security] Generated new Pairing PIN: {new_pin}")

    def update_clients_display(self):
        def _update():
            if not self.daemon:
                return

            for w in self.dev_list_frame.winfo_children():
                w.destroy()

            clients = self.daemon.authenticated_clients
            count = len(clients)
            self.dev_count_lbl.config(text=f"{count} Active" if count > 0 else "0 Active")

            if count == 0:
                lbl = tk.Label(
                    self.dev_list_frame,
                    text="Waiting for tablet connection... Launch Axiom on your tablet and tap 'Scan LAN'.",
                    font=("Segoe UI", 9, "italic"),
                    fg=TEXT_MUTED,
                    bg=CARD_BG,
                    pady=4
                )
                lbl.pack(anchor="w")
            else:
                for handle, dev_id in clients.items():
                    dev_info = self.daemon.security.trusted_devices.get(dev_id, {})
                    dev_name = dev_info.get("name", "Axiom Tablet")
                    row = tk.Frame(self.dev_list_frame, bg="#0E1626", padx=10, pady=6)
                    row.pack(fill=tk.X, pady=3)

                    tk.Label(row, text="📱", font=("Segoe UI", 12), bg="#0E1626").pack(side=tk.LEFT, padx=(0, 8))
                    tk.Label(row, text=dev_name, font=("Segoe UI", 10, "bold"), fg=TEXT_PRIMARY, bg="#0E1626").pack(side=tk.LEFT)
                    tk.Label(row, text=f"({dev_id})", font=("Segoe UI", 9), fg=TEXT_MUTED, bg="#0E1626").pack(side=tk.LEFT, padx=6)
                    
                    status = tk.Label(row, text="● CONNECTED", font=("Segoe UI", 9, "bold"), fg=ACCENT_GREEN, bg="#0E1626")
                    status.pack(side=tk.RIGHT)
        self.root.after(0, _update)

    def start_server(self):
        if self.daemon and self.daemon.is_running:
            return

        def _run():
            self.daemon = AxiomDesktopDaemon(
                on_log=self.log,
                on_clients_changed=self.update_clients_display
            )
            # Update PIN in UI
            pin = self.daemon.security.current_pin
            self.root.after(0, lambda: self.pin_label.config(text=f"{pin[:3]} {pin[3:]}"))
            self.daemon.start()

            # Update status pill in UI
            self.root.after(0, lambda: self.status_pill.config(text="● SERVER ACTIVE", fg=ACCENT_GREEN, bg="#112B1F"))
            self.root.after(0, lambda: self.toggle_btn.config(text="Stop Server", fg=ACCENT_RED, bg="#25161C"))

        self.daemon_thread = threading.Thread(target=_run, daemon=True)
        self.daemon_thread.start()

    def stop_server(self):
        if self.daemon:
            self.daemon.stop()
            self.daemon.is_running = False
            self.status_pill.config(text="○ STOPPED", fg=TEXT_MUTED, bg="#1B2234")
            self.toggle_btn.config(text="Start Server", fg=ACCENT_GREEN, bg="#112B1F")
            self.log("[Axiom Desktop] Server paused.")
            self.update_clients_display()

    def toggle_server(self):
        if self.daemon and self.daemon.is_running:
            self.stop_server()
        else:
            self.start_server()

    def on_close(self):
        if self.daemon:
            self.daemon.stop()
        self.root.destroy()
        sys.exit(0)

def main():
    root = tk.Tk()
    app = AxiomDesktopGUI(root)
    root.mainloop()

if __name__ == "__main__":
    main()
