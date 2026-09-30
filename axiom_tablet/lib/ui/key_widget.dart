import 'package:flutter/material.dart';
import '../keyboard/key_model.dart';
import '../keyboard/keyboard_engine.dart';
import '../keyboard/rgb_effects.dart';

class KeyWidget extends StatelessWidget {
  final KeyModel keyModel;
  final KeyboardEngine engine;
  final int rowIndex;
  final int colIndex;

  const KeyWidget({
    super.key,
    required this.keyModel,
    required this.engine,
    required this.rowIndex,
    required this.colIndex,
  });

  @override
  Widget build(BuildContext context) {
    final isPressed = keyModel.isPressed || keyModel.isToggled;
    final isModifier = keyModel.isModifier;
    final rgb = RgbEngine.instance;
    final theme = rgb.currentTheme;

    final keyBg = rgb.getKeyColor(
      row: rowIndex,
      col: colIndex,
      isPressed: isPressed,
      isModifier: isModifier,
    );

    final borderColor = rgb.getKeyBorderColor(
      row: rowIndex,
      col: colIndex,
      isPressed: isPressed,
      isModifier: isModifier,
    );

    final textColor = isPressed
        ? const Color(0xFF070A10)
        : (isModifier ? theme.textSecondary : theme.textPrimary);

    return Expanded(
      flex: (keyModel.flex * 10).round(),
      child: Padding(
        padding: const EdgeInsets.all(2.0),
        child: Listener(
          onPointerDown: (_) => engine.onKeyDown(keyModel, row: rowIndex, col: colIndex),
          onPointerUp: (_) => engine.onKeyUp(keyModel),
          onPointerCancel: (_) => engine.onKeyUp(keyModel),
          child: Container(
            decoration: BoxDecoration(
              color: keyBg,
              borderRadius: BorderRadius.circular(6.0),
              border: Border.all(
                color: borderColor,
                width: isPressed ? 1.5 : 1.0,
              ),
              boxShadow: [
                if (isPressed)
                  BoxShadow(
                    color: theme.accentGlow.withValues(alpha: 0.6),
                    blurRadius: 8.0,
                    spreadRadius: 1.0,
                  )
                else
                  // Fast flat offset shadow for 3D keycap depth without costly GPU blur
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.35),
                    offset: const Offset(0, 1.5),
                    blurRadius: 0.5,
                  ),
              ],
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (keyModel.subLabel != null)
                    Text(
                      keyModel.subLabel!,
                      style: TextStyle(
                        fontSize: 9.0,
                        color: isPressed ? Colors.black54 : theme.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  Text(
                    keyModel.label,
                    style: TextStyle(
                      fontSize: keyModel.label.length > 2 ? 11.0 : 14.0,
                      color: textColor,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
