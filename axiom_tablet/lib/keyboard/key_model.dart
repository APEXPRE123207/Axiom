class KeyModel {
  final String id;
  final String label;
  final String? subLabel;
  final String logicalCode;
  final int? vk;
  final double flex; // Layout width weight (default 1.0)
  final bool isModifier;

  // Visual & Transformation parameters (independent of logical identity)
  double x;
  double y;
  double width;
  double height;
  double rotation; // In degrees (e.g. 0 for standard, 45 for ergonomic)
  bool isPressed;
  bool isToggled;

  KeyModel({
    required this.id,
    required this.label,
    this.subLabel,
    required this.logicalCode,
    this.vk,
    this.flex = 1.0,
    this.isModifier = false,
    this.x = 0.0,
    this.y = 0.0,
    this.width = 0.0,
    this.height = 0.0,
    this.rotation = 0.0,
    this.isPressed = false,
    this.isToggled = false,
  });

  KeyModel copyWith({
    double? x,
    double? y,
    double? width,
    double? height,
    double? rotation,
    bool? isPressed,
    bool? isToggled,
  }) {
    return KeyModel(
      id: id,
      label: label,
      subLabel: subLabel,
      logicalCode: logicalCode,
      vk: vk,
      flex: flex,
      isModifier: isModifier,
      x: x ?? this.x,
      y: y ?? this.y,
      width: width ?? this.width,
      height: height ?? this.height,
      rotation: rotation ?? this.rotation,
      isPressed: isPressed ?? this.isPressed,
      isToggled: isToggled ?? this.isToggled,
    );
  }
}
