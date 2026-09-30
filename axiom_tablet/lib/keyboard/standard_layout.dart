import 'key_model.dart';

class StandardLayout {
  static List<List<KeyModel>> getRows() {
    return [
      // Row 0: Function & Esc
      [
        KeyModel(id: "ESC", label: "ESC", logicalCode: "ESCAPE", vk: 0x1B, flex: 1.2, isModifier: true),
        KeyModel(id: "F1", label: "F1", logicalCode: "F1", vk: 0x70),
        KeyModel(id: "F2", label: "F2", logicalCode: "F2", vk: 0x71),
        KeyModel(id: "F3", label: "F3", logicalCode: "F3", vk: 0x72),
        KeyModel(id: "F4", label: "F4", logicalCode: "F4", vk: 0x73),
        KeyModel(id: "F5", label: "F5", logicalCode: "F5", vk: 0x74),
        KeyModel(id: "F6", label: "F6", logicalCode: "F6", vk: 0x75),
        KeyModel(id: "F7", label: "F7", logicalCode: "F7", vk: 0x76),
        KeyModel(id: "F8", label: "F8", logicalCode: "F8", vk: 0x77),
        KeyModel(id: "F9", label: "F9", logicalCode: "F9", vk: 0x78),
        KeyModel(id: "F10", label: "F10", logicalCode: "F10", vk: 0x79),
        KeyModel(id: "F11", label: "F11", logicalCode: "F11", vk: 0x7A),
        KeyModel(id: "F12", label: "F12", logicalCode: "F12", vk: 0x7B),
        KeyModel(id: "DEL", label: "DEL", logicalCode: "DELETE", vk: 0x2E, flex: 1.2),
      ],
      // Row 1: Numbers & symbols
      [
        KeyModel(id: "BACKQUOTE", label: "`", subLabel: "~", logicalCode: "BACKQUOTE", vk: 0xC0),
        KeyModel(id: "1", label: "1", subLabel: "!", logicalCode: "1", vk: 0x31),
        KeyModel(id: "2", label: "2", subLabel: "@", logicalCode: "2", vk: 0x32),
        KeyModel(id: "3", label: "3", subLabel: "#", logicalCode: "3", vk: 0x33),
        KeyModel(id: "4", label: "4", subLabel: r"$", logicalCode: "4", vk: 0x34),
        KeyModel(id: "5", label: "5", subLabel: "%", logicalCode: "5", vk: 0x35),
        KeyModel(id: "6", label: "6", subLabel: "^", logicalCode: "6", vk: 0x36),
        KeyModel(id: "7", label: "7", subLabel: "&", logicalCode: "7", vk: 0x37),
        KeyModel(id: "8", label: "8", subLabel: "*", logicalCode: "8", vk: 0x38),
        KeyModel(id: "9", label: "9", subLabel: "(", logicalCode: "9", vk: 0x39),
        KeyModel(id: "0", label: "0", subLabel: ")", logicalCode: "0", vk: 0x30),
        KeyModel(id: "MINUS", label: "-", subLabel: "_", logicalCode: "MINUS", vk: 0xBD),
        KeyModel(id: "EQUALS", label: "=", subLabel: "+", logicalCode: "EQUALS", vk: 0xBB),
        KeyModel(id: "BACKSPACE", label: "⌫", logicalCode: "BACKSPACE", vk: 0x08, flex: 1.8, isModifier: true),
      ],
      // Row 2: QWERTY
      [
        KeyModel(id: "TAB", label: "TAB", logicalCode: "TAB", vk: 0x09, flex: 1.5, isModifier: true),
        KeyModel(id: "Q", label: "Q", logicalCode: "Q", vk: 0x51),
        KeyModel(id: "W", label: "W", logicalCode: "W", vk: 0x57),
        KeyModel(id: "E", label: "E", logicalCode: "E", vk: 0x45),
        KeyModel(id: "R", label: "R", logicalCode: "R", vk: 0x52),
        KeyModel(id: "T", label: "T", logicalCode: "T", vk: 0x54),
        KeyModel(id: "Y", label: "Y", logicalCode: "Y", vk: 0x59),
        KeyModel(id: "U", label: "U", logicalCode: "U", vk: 0x55),
        KeyModel(id: "I", label: "I", logicalCode: "I", vk: 0x49),
        KeyModel(id: "O", label: "O", logicalCode: "O", vk: 0x4F),
        KeyModel(id: "P", label: "P", logicalCode: "P", vk: 0x50),
        KeyModel(id: "BRACKET_LEFT", label: "[", subLabel: "{", logicalCode: "BRACKET_LEFT", vk: 0xDB),
        KeyModel(id: "BRACKET_RIGHT", label: "]", subLabel: "}", logicalCode: "BRACKET_RIGHT", vk: 0xDD),
        KeyModel(id: "BACKSLASH", label: "\\", subLabel: "|", logicalCode: "BACKSLASH", vk: 0xDC, flex: 1.2),
      ],
      // Row 3: ASDF
      [
        KeyModel(id: "CAPS", label: "CAPS", logicalCode: "CAPS_LOCK", vk: 0x14, flex: 1.8, isModifier: true),
        KeyModel(id: "A", label: "A", logicalCode: "A", vk: 0x41),
        KeyModel(id: "S", label: "S", logicalCode: "S", vk: 0x53),
        KeyModel(id: "D", label: "D", logicalCode: "D", vk: 0x44),
        KeyModel(id: "F", label: "F", logicalCode: "F", vk: 0x46),
        KeyModel(id: "G", label: "G", logicalCode: "G", vk: 0x47),
        KeyModel(id: "H", label: "H", logicalCode: "H", vk: 0x48),
        KeyModel(id: "J", label: "J", logicalCode: "J", vk: 0x4A),
        KeyModel(id: "K", label: "K", logicalCode: "K", vk: 0x4B),
        KeyModel(id: "L", label: "L", logicalCode: "L", vk: 0x4C),
        KeyModel(id: "SEMICOLON", label: ";", subLabel: ":", logicalCode: "SEMICOLON", vk: 0xBA),
        KeyModel(id: "QUOTE", label: "'", subLabel: "\"", logicalCode: "QUOTE", vk: 0xDE),
        KeyModel(id: "ENTER", label: "ENTER", logicalCode: "ENTER", vk: 0x0D, flex: 2.1, isModifier: true),
      ],
      // Row 4: ZXCV
      [
        KeyModel(id: "SHIFT_L", label: "SHIFT", logicalCode: "SHIFT", vk: 0x10, flex: 2.2, isModifier: true),
        KeyModel(id: "Z", label: "Z", logicalCode: "Z", vk: 0x5A),
        KeyModel(id: "X", label: "X", logicalCode: "X", vk: 0x58),
        KeyModel(id: "C", label: "C", logicalCode: "C", vk: 0x43),
        KeyModel(id: "V", label: "V", logicalCode: "V", vk: 0x56),
        KeyModel(id: "B", label: "B", logicalCode: "B", vk: 0x42),
        KeyModel(id: "N", label: "N", logicalCode: "N", vk: 0x4E),
        KeyModel(id: "M", label: "M", logicalCode: "M", vk: 0x4D),
        KeyModel(id: "COMMA", label: ",", subLabel: "<", logicalCode: "COMMA", vk: 0xBC),
        KeyModel(id: "PERIOD", label: ".", subLabel: ">", logicalCode: "PERIOD", vk: 0xBE),
        KeyModel(id: "SLASH", label: "/", subLabel: "?", logicalCode: "SLASH", vk: 0xBF),
        KeyModel(id: "SHIFT_R", label: "SHIFT", logicalCode: "SHIFT", vk: 0x10, flex: 2.7, isModifier: true),
      ],
      // Row 5: Bottom row / Space / Navigation
      [
        KeyModel(id: "CTRL_L", label: "CTRL", logicalCode: "CTRL", vk: 0x11, flex: 1.4, isModifier: true),
        KeyModel(id: "WIN", label: "⊞", logicalCode: "WIN", vk: 0x5B, flex: 1.2, isModifier: true),
        KeyModel(id: "ALT_L", label: "ALT", logicalCode: "ALT", vk: 0x12, flex: 1.3, isModifier: true),
        KeyModel(id: "SPACE", label: "", logicalCode: "SPACE", vk: 0x20, flex: 6.2),
        KeyModel(id: "ALT_R", label: "ALT", logicalCode: "ALT", vk: 0x12, flex: 1.3, isModifier: true),
        KeyModel(id: "CTRL_R", label: "CTRL", logicalCode: "CTRL", vk: 0x11, flex: 1.4, isModifier: true),
        KeyModel(id: "ARROW_L", label: "◀", logicalCode: "ARROW_LEFT", vk: 0x25, flex: 1.1),
        KeyModel(id: "ARROW_U", label: "▲", logicalCode: "ARROW_UP", vk: 0x26, flex: 1.1),
        KeyModel(id: "ARROW_D", label: "▼", logicalCode: "ARROW_DOWN", vk: 0x28, flex: 1.1),
        KeyModel(id: "ARROW_R", label: "▶", logicalCode: "ARROW_RIGHT", vk: 0x27, flex: 1.1),
      ],
    ];
  }
}
