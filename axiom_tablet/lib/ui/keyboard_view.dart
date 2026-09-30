import 'package:flutter/material.dart';
import '../keyboard/keyboard_engine.dart';
import '../keyboard/rgb_effects.dart';
import 'key_widget.dart';

class KeyboardView extends StatelessWidget {
  final KeyboardEngine engine;

  const KeyboardView({super.key, required this.engine});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([engine, RgbEngine.instance]),
      builder: (context, _) {
        final theme = RgbEngine.instance.currentTheme;

        return Container(
          color: theme.bgPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
          child: Column(
            children: engine.rows.asMap().entries.map((rowEntry) {
              final rowIndex = rowEntry.key;
              final row = rowEntry.value;

              return Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: row.asMap().entries.map((colEntry) {
                    final colIndex = colEntry.key;
                    final keyModel = colEntry.value;

                    return KeyWidget(
                      keyModel: keyModel,
                      engine: engine,
                      rowIndex: rowIndex,
                      colIndex: colIndex,
                    );
                  }).toList(),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }
}
