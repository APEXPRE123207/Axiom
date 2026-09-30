# AXIOM — Universal Wireless Tablet Input Surface

## 1. Project Overview

Build an application called **Axiom** that repurposes an old Samsung Tab A Android tablet into a futuristic wireless input device for a laptop/desktop computer.

Axiom consists of **two applications**:

1. **Axiom Tablet App**

   * Android application built with Flutter.
   * Runs on the Samsung Tab A.
   * Provides the keyboard, ergonomic keyboard, touchpad/mouse interface, themes, animations, sounds, settings, and connection UI.

2. **Axiom Desktop App**

   * Runs on the laptop.
   * Prefer **C#/.NET** for Windows because it provides good access to Windows input APIs.
   * Receives input events from the tablet.
   * Converts those events into actual OS keyboard/mouse input.

The tablet should feel like a premium futuristic mechanical keyboard rather than a conventional Android keyboard.

The project should be modular so that the communication layer, input system, UI, sound system, and layouts are independent.

---

# 2. VERY IMPORTANT DEVELOPMENT RULE

## DO NOT PERFORM ANY ACTION WITHOUT USER PERMISSION

The coding agent must follow this rule throughout the entire project.

Before doing anything that changes the user's environment, repository, files, dependencies, configuration, system settings, or external services:

* Explain what will be done.
* Explain why it is needed.
* Ask for explicit permission.
* Wait for confirmation.
* Only then perform the action.

Examples of actions requiring permission:

* Installing packages.
* Installing Flutter/Dart/.NET dependencies.
* Creating or deleting files.
* Modifying existing project files.
* Running scripts that modify files.
* Changing environment variables.
* Installing drivers.
* Modifying Windows settings.
* Opening firewall ports.
* Creating firewall rules.
* Running commands that require administrator privileges.
* Building/installing APKs.
* Installing applications.
* Starting/stopping system services.
* Adding Bluetooth devices.
* Changing Bluetooth settings.
* Creating certificates or keys.
* Creating network configuration.
* Git commits.
* Git pushes.
* Creating branches.
* Uploading anything.
* Publishing releases.
* Sending network requests that modify external state.

Read-only operations such as inspecting existing source code, listing directories, checking installed versions, and reading configuration are allowed without permission unless they expose sensitive information.

### Git rule

NEVER run:

```bash
git push
```

without explicit user permission.

Also do not automatically commit changes.

The agent may prepare changes and show the user what changed, but the user decides when changes are committed or pushed.

### Destructive-operation rule

Never delete, overwrite, reset, clean, uninstall, or replace existing files/projects without explicit permission.

Never run commands such as:

```bash
git reset --hard
git clean
rm -rf
del /s
```

or equivalent destructive operations without permission.

---

# 3. EXISTING BLUETOOTH PROJECT

The user already has an existing controller application that contains Bluetooth functionality.

IMPORTANT:

**Do NOT integrate the controller itself into Axiom.**

Do not copy the controller UI, controller modes, controller mappings, or controller functionality into Axiom.

Instead:

### Reuse only the Bluetooth module/transport code.

Inspect the existing project and identify reusable components related specifically to:

* Bluetooth discovery
* Bluetooth scanning
* Bluetooth connection
* Pairing
* Connection state
* Reconnection
* Device identification
* Bluetooth message transport
* Serialization/deserialization
* Error handling

The reusable Bluetooth code should be separated conceptually from the controller logic.

Architecture:

```text
Existing Controller Project

        ┌─────────────────────────┐
        │ Bluetooth Module        │  ← REUSE THIS
        ├─────────────────────────┤
        │ Controller UI           │  ← DO NOT REUSE
        │ Controller Mapping      │  ← DO NOT REUSE
        │ Controller Logic        │  ← DO NOT REUSE
        └─────────────────────────┘
```

Axiom should eventually have:

```text
Axiom Transport Layer
        │
        ├── Wi-Fi Transport
        │
        └── Bluetooth Transport
```

Bluetooth is a transport mechanism, not an application mode.

Do not expose a "Controller" mode anywhere in Axiom.

---

# 4. CORE FUNCTIONALITY

Axiom has three primary modes:

```text
┌──────────────────────────────┐
│          AXIOM               │
│                              │
│   ⌨ Keyboard                │
│   ◇ Ergonomic Keyboard      │
│   🖱 Touchpad               │
│                              │
└──────────────────────────────┘
```

The user can switch between these modes from the tablet.

---

# 5. STANDARD KEYBOARD MODE

Create a complete virtual keyboard.

It should support:

* QWERTY layout
* Number row
* Function keys where practical
* Modifier keys
* Ctrl
* Shift
* Alt
* Windows/Meta
* Tab
* Caps Lock
* Backspace
* Enter
* Escape
* Arrow keys
* Insert/Delete/Home/End where practical
* Page Up/Page Down
* Space
* Media keys where practical

The layout should be designed for a landscape tablet.

The keyboard must generate logical keyboard events rather than directly embedding platform-specific behavior into every key.

Example internal event:

```text
KEY_DOWN("A")
KEY_UP("A")
```

The desktop application translates this into a Windows keyboard event.

---

# 6. ERGONOMIC KEYBOARD MODE

Axiom must have a dedicated ergonomic keyboard mode.

This is NOT simply a conventional split keyboard.

The user wants the complete keyboard retained while visually transforming the two halves.

The two keyboard halves should be angled inward approximately **45 degrees around the lower center/bottom corners**.

Conceptually:

```text
             LEFT HALF

          Q W E R T
        A S D F G
      Z X C V B
                 

                    Y U I O P
                     H J K L
                      N M , . /
             
             RIGHT HALF
```

The visual geometry should resemble two keyboard sections tilted toward each other.

The exact angle should be configurable internally, with approximately 45° as the default.

### Requirements

* Do not remove normal keys.
* Preserve the complete keyboard functionality.
* Maintain logical key identities independently from visual positions.
* Each key should have:

  * logical key code
  * position
  * size
  * rotation
  * visual state
* The keyboard engine must not depend on a particular visual layout.

For example:

```text
Key {
    id: "A",
    logicalCode: KEY_A,
    x: ...,
    y: ...,
    rotation: 45,
    width: ...,
    height: ...
}
```

This will allow future custom layouts.

The ergonomic layout should still feel visually coherent and usable on the Samsung Tab A.

---

# 7. TOUCHPAD / MOUSE MODE

Axiom must have a mode that turns the **entire tablet display into a wireless touchpad**.

There should be an obvious button to switch to this mode.

Example:

```text
[ ⌨ KEYBOARD ]     [ 🖱 TOUCHPAD ]
```

When Touchpad mode is active, the keyboard disappears and the entire display becomes the touch surface.

### Default gestures

| Gesture                        | Action            |
| ------------------------------ | ----------------- |
| One finger movement            | Mouse movement    |
| One finger tap                 | Left click        |
| Double tap                     | Double click      |
| Two-finger tap                 | Right click       |
| Two-finger movement            | Scroll            |
| Two-finger horizontal movement | Horizontal scroll |
| Tap + hold + move              | Drag              |
| Optional three-finger gesture  | Configurable      |

The implementation should use relative mouse movement rather than trying to map tablet coordinates directly to screen coordinates.

Example:

```text
Tablet:
dx = +15
dy = -8

Send:

MOUSE_MOVE(+15, -8)
```

The desktop application then converts this into an OS mouse movement.

---

# 8. OPTIONAL MOUSE BUTTON UI

Although the default experience should be a clean full-screen trackpad, provide an optional setting for visible mouse buttons.

Possible configuration:

```text
Mouse Button Overlay

[ OFF ]

or

[ LEFT CLICK ]              [ RIGHT CLICK ]
```

This should not permanently consume screen space unless the user enables it.

---

# 9. INPUT EVENT ARCHITECTURE

Do NOT make the desktop app understand Flutter widgets.

Create a platform-independent input-event protocol.

Example:

```text
InputEvent
```

Possible event types:

```text
KEY_DOWN
KEY_UP
TEXT_INPUT

MOUSE_MOVE
MOUSE_LEFT_DOWN
MOUSE_LEFT_UP
MOUSE_RIGHT_DOWN
MOUSE_RIGHT_UP
MOUSE_MIDDLE_DOWN
MOUSE_MIDDLE_UP
MOUSE_SCROLL

PING
PONG
DEVICE_INFO
SESSION_START
SESSION_END
```

Example:

```json
{
  "type": "KEY_DOWN",
  "key": "A"
}
```

Mouse:

```json
{
  "type": "MOUSE_MOVE",
  "dx": 12,
  "dy": -4
}
```

Scroll:

```json
{
  "type": "MOUSE_SCROLL",
  "dx": 0,
  "dy": -3
}
```

The protocol should be versioned:

```text
protocol_version: 1
```

so it can evolve later.

---

# 10. TRANSPORT ARCHITECTURE

Axiom should support two transport methods:

```text
                Axiom Transport
                       │
             ┌─────────┴─────────┐
             │                   │
           Wi-Fi             Bluetooth
             │                   │
        WebSocket/TCP       Reused BT module
```

The application should not care which transport is being used.

Create a common interface such as:

```text
ITransport
```

Conceptually:

```text
connect()
disconnect()
send()
receive()
isConnected()
```

Then:

```text
WifiTransport
BluetoothTransport
```

implement that interface.

---

# 11. WI-FI CONNECTION

Wi-Fi should be the primary transport.

The tablet and laptop will normally be connected to the same local network.

Preferred communication:

```text
Tablet
   │
   │ Secure WebSocket
   ▼
Laptop
```

The system should support automatic device discovery.

Potential discovery architecture:

```text
Tablet
   │
   │ LAN discovery
   ▼
Axiom Desktop
   │
   └── Advertises Axiom service
```

Use an appropriate discovery mechanism such as mDNS where practical.

Do not require the user to manually type an IP address during normal operation.

However, provide manual IP/port configuration as an advanced fallback.

---

# 12. WI-FI SECURITY

Security is a core requirement.

Never create an unauthenticated keyboard-control server.

The desktop must not accept arbitrary commands from anyone on the LAN.

The first connection should involve explicit pairing.

Possible pairing flow:

```text
Laptop

AXIOM PAIRING

Code:
483921

Waiting for tablet...
```

Tablet:

```text
Connect to:

DESKTOP-7F2A

Code:
483921

[ PAIR ]
```

After successful pairing, establish an authenticated encrypted session.

Use established cryptographic libraries/protocols.

DO NOT invent custom encryption.

The connection should provide:

* Encryption
* Authentication
* Device identity
* Session authentication
* Replay protection where applicable
* Unknown-device rejection
* Pairing approval
* Trusted-device storage
* Secure reconnection

The desktop should have a way to revoke trusted devices.

Example:

```text
Trusted Devices

✓ Samsung Tab A
  Last connected: Today

[ Revoke ]
```

Do not expose keyboard/mouse functionality to an unpaired client.

---

# 13. BLUETOOTH SECURITY

Bluetooth should use the capabilities of the existing reusable Bluetooth module where appropriate.

Do not force Bluetooth to behave exactly like Wi-Fi.

Create a common transport abstraction while allowing each transport to have its own pairing/connection implementation.

The existing Bluetooth module should be inspected before implementation.

Do not modify the existing Bluetooth project unless explicitly requested.

Do not overwrite or move its files without permission.

---

# 14. DESKTOP INPUT INJECTION

For Windows, use the appropriate native Windows APIs to generate:

* Keyboard input
* Mouse movement
* Mouse clicks
* Mouse wheel events

Prefer Windows `SendInput` or the appropriate modern equivalent.

Do not implement a kernel-level driver for the MVP.

The desktop application should translate:

```text
KEY_DOWN
```

into an actual Windows keyboard event.

Similarly:

```text
MOUSE_MOVE
MOUSE_LEFT_DOWN
MOUSE_LEFT_UP
```

must produce actual OS mouse behavior.

---

# 15. FUTURISTIC UI

The visual design is a major part of Axiom.

The application should look like a futuristic mechanical keyboard rather than a normal Android keyboard.

Design principles:

* Dark background
* High contrast keys
* Subtle glow
* Smooth animations
* Minimal UI chrome
* Mechanical keyboard aesthetic
* Futuristic HUD elements
* Responsive keypress animations
* Premium appearance

Avoid excessive visual clutter.

The UI should still be readable and practical.

---

# 16. COLOR MODES

Include several built-in themes.

Suggested themes:

```text
Cyber Blue
Neon Purple
Matrix Green
Crimson
Amber
Arctic
Stealth
```

The user should eventually be able to customize:

* Background
* Key color
* Key pressed color
* Accent color
* Text color
* Glow intensity
* Animation intensity

The architecture should allow custom themes later.

---

# 17. RGB-STYLE EFFECTS

Provide keyboard lighting effects inspired by mechanical RGB keyboards.

Initial effects:

### Static

All keys remain illuminated.

### Reactive

Only pressed keys illuminate.

### Ripple

A keypress produces a wave around the pressed key.

### Wave

A continuous lighting wave moves across the keyboard.

### Breathing

The keyboard gradually brightens and dims.

These effects should be configurable.

Avoid excessive GPU usage because the target hardware is an older Samsung Tab A.

Performance is important.

---

# 18. MECHANICAL KEYBOARD SOUNDS

Axiom should produce mechanical-keyboard-style sounds when keys are pressed.

Include several sound profiles:

```text
Linear
Tactile
Clicky
Soft
```

Each key press should have:

```text
visual animation
+
sound
+
optional haptic feedback
```

Sound should be generated locally on the tablet.

Do NOT send audio events to the laptop.

The laptop only needs to receive the input event.

Provide:

```text
Sound: ON/OFF
Volume: 0-100
Sound profile
```

The architecture should support custom sound packs later.

---

# 19. HAPTIC FEEDBACK

If the Samsung Tab A hardware supports usable haptic feedback:

```text
Haptic Feedback
[ ON ]
```

Provide adjustable intensity where Android allows it.

If hardware does not support it properly, fail gracefully without breaking keyboard operation.

---

# 20. CONNECTION UI

The tablet should always make connection status obvious.

Possible states:

```text
● Connected
○ Connecting
○ Disconnected
⚠ Authentication Required
```

Show:

* Connection type
* Connected desktop name
* Signal/connection status where available
* Reconnect button
* Pairing status

Example:

```text
AXIOM

● CONNECTED

DESKTOP-7F2A
Wi-Fi

[ Keyboard ]
[ Ergonomic ]
[ Touchpad ]

                         ⚙
```

---

# 21. DESKTOP APPLICATION

The desktop application should primarily run in the background.

It should have:

* System tray icon
* Connection manager
* Pairing UI
* Security settings
* Trusted device management
* Transport selection
* Input event processor
* Windows input injection
* Logging/debug mode

Example:

```text
Axiom

● Samsung Tab A — Connected

Transport:
Wi-Fi

[ Disconnect ]

Settings
Trusted Devices
Diagnostics
```

---

# 22. DESKTOP SETTINGS

Include:

### General

* Start with Windows
* Minimize to tray
* Auto reconnect

### Connection

* Wi-Fi
* Bluetooth
* Port
* Discovery
* Pairing

### Security

* Trusted devices
* Revoke device
* Require pairing approval

### Input

* Mouse sensitivity
* Scroll sensitivity
* Keyboard behavior

### Diagnostics

* Connection latency
* Events/sec
* Packet count
* Connection errors

---

# 23. LOW-LATENCY REQUIREMENT

Axiom is an input device.

Latency is extremely important.

Optimize for:

```text
Touch
  ↓
Flutter event
  ↓
Input event
  ↓
Transport
  ↓
Desktop receiver
  ↓
OS input
```

Avoid unnecessary processing.

Do not send large JSON payloads for every mouse movement if a more efficient representation becomes necessary.

JSON is acceptable for the MVP.

The architecture should allow a binary protocol later.

Keyboard events should be reliable.

Mouse movement can be optimized/coalesced if necessary.

---

# 24. RELIABILITY

The system should handle:

* Wi-Fi temporarily disconnecting
* Laptop sleeping
* Tablet sleeping
* Application restart
* Laptop restart
* Bluetooth disconnect
* Network change
* Duplicate packets where applicable
* Malformed packets
* Unknown event types

The tablet should not get stuck thinking it is connected when the desktop has disappeared.

Provide automatic reconnect.

---

# 25. BATTERY / PERFORMANCE

The Samsung Tab A is old hardware.

Optimize accordingly.

Avoid:

* continuously running heavy animations
* unnecessary polling
* excessive network traffic
* constantly playing audio
* high-frequency full-screen redraws
* background services unless necessary

When the keyboard is idle:

* reduce animation
* reduce network traffic
* avoid unnecessary CPU usage

Touchpad mode should remain responsive without continuously polling the screen.

Use Android touch events.

---

# 26. RESPONSIVE TABLET UI

The design must adapt to the actual tablet resolution.

Do not hard-code a single resolution.

Support:

* landscape
* portrait where reasonable
* different aspect ratios

However, optimize primarily for **landscape mode**, because this is intended to function as a laptop keyboard.

The UI should dynamically calculate:

```text
available width
available height
key size
key spacing
keyboard position
```

---

# 27. PROJECT ARCHITECTURE

Suggested Flutter structure:

```text
axiom_tablet/
│
├── lib/
│   ├── main.dart
│   │
│   ├── core/
│   │   ├── protocol/
│   │   ├── transport/
│   │   ├── security/
│   │   └── models/
│   │
│   ├── keyboard/
│   │   ├── keyboard_engine.dart
│   │   ├── key_model.dart
│   │   ├── standard_layout.dart
│   │   ├── ergonomic_layout.dart
│   │   └── keyboard_renderer.dart
│   │
│   ├── touchpad/
│   │   ├── touchpad_engine.dart
│   │   ├── gesture_detector.dart
│   │   └── mouse_event_generator.dart
│   │
│   ├── audio/
│   │   ├── sound_engine.dart
│   │   └── sound_profiles.dart
│   │
│   ├── themes/
│   │   ├── theme_model.dart
│   │   └── theme_manager.dart
│   │
│   ├── connection/
│   │   ├── connection_manager.dart
│   │   ├── wifi_transport.dart
│   │   └── bluetooth_transport.dart
│   │
│   ├── security/
│   │   ├── pairing.dart
│   │   └── trusted_devices.dart
│   │
│   └── ui/
│       ├── home_screen.dart
│       ├── keyboard_screen.dart
│       ├── touchpad_screen.dart
│       ├── settings_screen.dart
│       └── pairing_screen.dart
│
└── assets/
    ├── sounds/
    └── themes/
```

Desktop:

```text
axiom_desktop/
│
├── Axiom.Desktop/
│
├── Core/
│   ├── Protocol/
│   ├── Models/
│   └── Security/
│
├── Transport/
│   ├── WifiTransport/
│   └── BluetoothTransport/
│
├── Input/
│   ├── KeyboardInput.cs
│   └── MouseInput.cs
│
├── Pairing/
│
├── Discovery/
│
├── Settings/
│
└── UI/
```

The exact structure can be changed if the coding agent identifies a better architecture, but maintain the same separation of responsibilities.

---

# 28. STATE MANAGEMENT

Do not put the entire application state into widgets.

Separate:

```text
UI
↓
State
↓
Application logic
↓
Transport
```

For Flutter, choose an appropriate state-management solution based on project complexity.

Keep the implementation simple rather than adding unnecessary dependencies.

---

# 29. LOGGING

Both applications should have structured logging.

Example:

```text
[15:32:04] INFO  Wi-Fi discovery started
[15:32:06] INFO  Axiom desktop discovered
[15:32:08] INFO  Pairing requested
[15:32:10] INFO  Pairing successful
[15:32:10] INFO  Secure session established
[15:32:12] INFO  Keyboard mode activated
```

Do not log:

* passwords
* private keys
* authentication secrets
* raw sensitive credentials

Provide a debug mode for development.

---

# 30. ERROR HANDLING

Errors should be user-readable.

Bad:

```text
SocketException: Connection reset by peer
```

Good:

```text
Connection lost.

The laptop is no longer reachable.

[ Reconnect ]
```

Detailed technical information can appear under Diagnostics.

---

# 31. FUTURE EXTENSIBILITY

Do not implement these yet unless explicitly requested, but design the architecture so they can be added:

* Custom keyboard layouts
* Macros
* Application-specific profiles
* Gaming keypad
* Media control
* Volume control
* Brightness control
* Developer keyboard
* Custom gestures
* Multiple connected computers
* Remote desktop shortcuts
* Clipboard integration
* File transfer
* Plugin system
* Bluetooth HID mode
* Custom sound packs
* Custom RGB animations

Do not add these features automatically.

---

# 32. DEVELOPMENT PHASES

Build Axiom incrementally.

## Phase 0 — Inspection

Before changing anything:

1. Inspect the existing Bluetooth controller project.
2. Identify the Bluetooth transport code.
3. Identify what can realistically be reused.
4. Inspect the development environment.
5. Check Flutter version.
6. Check Dart version.
7. Check .NET availability.
8. Check Android SDK availability.
9. Check the Samsung Tab A Android version if accessible.

DO NOT modify anything during this phase.

Report findings first.

---

## Phase 1 — Architecture

Design:

* Input event protocol
* Transport abstraction
* Wi-Fi communication
* Bluetooth abstraction
* Security/pairing architecture
* Keyboard engine
* Touchpad engine

Show the proposed architecture to the user.

WAIT FOR APPROVAL.

---

## Phase 2 — Minimal Prototype

Build only:

```text
Tablet
  ↓ Wi-Fi
Desktop
  ↓
Windows keyboard input
```

Implement:

* connection
* pairing
* secure session
* basic keyboard
* key down/up
* desktop input injection

Do not build the futuristic UI yet.

Test end-to-end functionality.

---

## Phase 3 — Touchpad

Add:

* mouse movement
* left click
* right click
* double click
* drag
* scrolling

Test latency and reliability.

---

## Phase 4 — Futuristic UI

Implement:

* keyboard styling
* animations
* themes
* key glow
* mechanical sounds
* haptic feedback

---

## Phase 5 — Ergonomic Layout

Implement the 45° angled keyboard.

Test:

* all keys
* touch targets
* layout geometry
* usability
* orientation
* performance

---

## Phase 6 — Bluetooth

Integrate the reusable Bluetooth transport module.

Do NOT import controller functionality.

Test:

```text
Wi-Fi
Bluetooth
```

as interchangeable transport methods.

---

## Phase 7 — Polish

Add:

* settings
* trusted devices
* diagnostics
* reconnection
* battery optimization
* animations
* sound profiles
* theme customization

---

# 33. TESTING REQUIREMENTS

Create tests for the core protocol.

Test:

* KEY_DOWN
* KEY_UP
* mouse movement
* mouse clicks
* scrolling
* malformed events
* unknown event types
* disconnect
* reconnect
* pairing
* authentication failure
* unauthorized device
* duplicate connection
* transport failure

For the Flutter keyboard:

* every key should map to the correct logical key.
* standard and ergonomic layouts must generate identical logical key events for equivalent keys.

For example:

```text
Standard A → KEY_A
Ergonomic A → KEY_A
```

Only the visual position changes.

---

# 34. SECURITY TESTING

Verify that:

* an unknown LAN device cannot control the laptop.
* unpaired devices are rejected.
* authentication failures terminate the session.
* session credentials are not logged.
* plaintext keyboard events are not transmitted after secure pairing.
* revoked devices cannot reconnect.
* malformed packets cannot crash the desktop application.

Do not weaken security simply to make development easier.

If a temporary development bypass is absolutely necessary, clearly mark it as development-only and ask permission before introducing it.

---

# 35. USER EXPERIENCE PRINCIPLE

Axiom should feel like a physical premium keyboard even though it is running on an old tablet.

The interaction should be:

```text
Wake tablet
     ↓
Axiom opens
     ↓
Desktop automatically discovered
     ↓
Secure connection
     ↓
Choose:
     ├── Standard
     ├── Ergonomic
     └── Touchpad
```

The user should not have to repeatedly configure networking.

---

# 36. IMPORTANT CONSTRAINTS

Do not:

* Add a controller mode.
* Copy controller UI.
* Copy controller mappings.
* Turn Axiom into a gamepad.
* Assume Bluetooth is the only transport.
* Use insecure unauthenticated Wi-Fi communication.
* Hard-code tablet resolution.
* Hard-code keyboard geometry.
* Couple UI directly to network transport.
* Couple keyboard layouts directly to OS-specific input APIs.
* Add unnecessary dependencies.
* Install software without permission.
* Modify the existing controller project without permission.
* Push Git changes without permission.
* Commit Git changes automatically.
* Delete existing files without permission.

---

# 37. DEFINITION OF DONE

The MVP is considered complete when:

### Tablet

* Axiom launches successfully.
* Futuristic keyboard is displayed.
* Standard keyboard works.
* Ergonomic 45° keyboard works.
* Touchpad mode works.
* Mechanical sounds work.
* Theme system works.
* Connection status is visible.

### Desktop

* Axiom runs in the background.
* Tablet can securely pair.
* Wi-Fi connection works.
* Bluetooth transport works if the reusable module supports it.
* Keyboard events become real Windows keyboard input.
* Mouse events become real Windows mouse input.
* Reconnection works.
* Unknown devices cannot send input.

### Architecture

* Transport is independent of input logic.
* Keyboard layout is independent of input protocol.
* Standard and ergonomic layouts share the same keyboard engine.
* Touchpad uses the same input-event protocol.
* Bluetooth is only a transport.
* No controller functionality exists inside Axiom.

---

# 38. FIRST ACTION

Do NOT start coding immediately.

First perform a read-only inspection of the environment and existing Bluetooth controller project.

Then report:

1. Existing project structure.
2. Bluetooth implementation discovered.
3. Which Bluetooth components can be reused.
4. Flutter environment.
5. .NET environment.
6. Android environment.
7. Proposed Axiom architecture.
8. Any technical risks.
9. Any decisions that require user input.

Then STOP and ask for permission before making any modifications.

The user must explicitly approve the implementation phase before files are created or modified.

# END OF AXIOM SPECIFICATION
