import 'dart:math';
import 'package:flutter/material.dart';
import '../core/settings_service.dart';
import '../keyboard/ergonomic_layout.dart';
import '../keyboard/key_model.dart';
import '../keyboard/keyboard_engine.dart';
import '../keyboard/rgb_effects.dart';
import 'key_widget.dart';

class ErgonomicView extends StatefulWidget {
  final KeyboardEngine engine;

  const ErgonomicView({super.key, required this.engine});

  @override
  State<ErgonomicView> createState() => _ErgonomicViewState();
}

class _ErgonomicViewState extends State<ErgonomicView> {
  late List<List<KeyModel>> _leftRows;
  late List<List<KeyModel>> _rightRows;

  // Customization controls
  double _leftScale = 0.85;
  double _rightScale = 0.85;
  double _baseLeftScale = 0.85;
  double _baseRightScale = 0.85;

  double _tiltAngle = 8.0; // Comfortable gentle default angle
  double _splitGap = 32.0;

  Offset _leftOffset = Offset.zero;
  Offset _rightOffset = Offset.zero;

  bool _isCustomizing = false;

  @override
  void initState() {
    super.initState();
    _leftRows = ErgonomicLayout.getLeftRows();
    _rightRows = ErgonomicLayout.getRightRows();

    final settings = SettingsService.instance;
    _leftScale = settings.loadErgoLeftScale();
    _rightScale = settings.loadErgoRightScale();
    _tiltAngle = settings.loadErgoAngle();
    _splitGap = settings.loadErgoGap();
    _leftOffset = settings.loadErgoLeftOffset();
    _rightOffset = settings.loadErgoRightOffset();
  }

  void _saveSettings() {
    SettingsService.instance.saveErgoConfig(
      leftScale: _leftScale,
      rightScale: _rightScale,
      angle: _tiltAngle,
      gap: _splitGap,
      leftOffset: _leftOffset,
      rightOffset: _rightOffset,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([widget.engine, RgbEngine.instance]),
      builder: (context, _) {
        final theme = RgbEngine.instance.currentTheme;
        final angleRad = _tiltAngle * (pi / 180.0);

        return Container(
          color: theme.bgPrimary,
          child: Stack(
            children: [
              // Subtle holographic background ambient arcs
              CustomPaint(
                size: Size.infinite,
                painter: _HolographicArcPainter(theme.accentGlow),
              ),

              // Main Layout: Left Wing - Center HUD - Right Wing
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 8.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // --- LEFT WING (Moveable, Scalable, Rotatable) ---
                    Expanded(
                      flex: 10,
                      child: GestureDetector(
                        behavior: _isCustomizing ? HitTestBehavior.opaque : HitTestBehavior.deferToChild,
                        onScaleStart: _isCustomizing
                            ? (details) => _baseLeftScale = _leftScale
                            : null,
                        onScaleUpdate: _isCustomizing
                            ? (details) {
                                setState(() {
                                  _leftOffset += details.focalPointDelta;
                                  if (details.pointerCount >= 2 && details.scale != 1.0) {
                                    _leftScale = (_baseLeftScale * details.scale).clamp(0.50, 1.40);
                                  }
                                });
                              }
                            : null,
                        onScaleEnd: _isCustomizing ? (_) => _saveSettings() : null,
                        child: Transform.translate(
                          offset: _leftOffset,
                          child: Transform.scale(
                            scale: _leftScale,
                            alignment: Alignment.centerRight,
                            child: Transform(
                              alignment: Alignment.centerRight,
                              transform: Matrix4.identity()
                                ..setEntry(3, 2, 0.001)
                                ..rotateZ(angleRad),
                              child: Container(
                                decoration: _isCustomizing
                                    ? BoxDecoration(
                                        border: Border.all(color: theme.accentGlow, width: 2),
                                        borderRadius: BorderRadius.circular(10),
                                        color: theme.accentGlow.withValues(alpha: 0.08),
                                      )
                                    : null,
                                child: Stack(
                                  children: [
                                    IgnorePointer(
                                      ignoring: _isCustomizing,
                                      child: _buildWing(
                                        rows: _leftRows,
                                        isLeft: true,
                                      ),
                                    ),
                                    if (_isCustomizing)
                                      Positioned(
                                        top: 6,
                                        left: 6,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.black.withValues(alpha: 0.88),
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: theme.accentGlow, width: 1.5),
                                            boxShadow: [
                                              BoxShadow(
                                                color: theme.accentGlow.withValues(alpha: 0.25),
                                                blurRadius: 8,
                                              ),
                                            ],
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(Icons.open_with, size: 12, color: theme.accentGlow),
                                              const SizedBox(width: 4),
                                              Text(
                                                "LEFT",
                                                style: TextStyle(color: theme.accentGlow, fontSize: 10, fontWeight: FontWeight.bold),
                                              ),
                                              const SizedBox(width: 8),
                                              GestureDetector(
                                                onTap: () {
                                                  setState(() {
                                                    _leftScale = (_leftScale - 0.05).clamp(0.50, 1.40);
                                                  });
                                                  _saveSettings();
                                                },
                                                child: Container(
                                                  padding: const EdgeInsets.all(3),
                                                  decoration: BoxDecoration(
                                                    color: Colors.white12,
                                                    borderRadius: BorderRadius.circular(4),
                                                  ),
                                                  child: const Icon(Icons.remove, size: 12, color: Colors.white),
                                                ),
                                              ),
                                              Padding(
                                                padding: const EdgeInsets.symmetric(horizontal: 6),
                                                child: Text(
                                                  "${(_leftScale * 100).round()}%",
                                                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                                ),
                                              ),
                                              GestureDetector(
                                                onTap: () {
                                                  setState(() {
                                                    _leftScale = (_leftScale + 0.05).clamp(0.50, 1.40);
                                                  });
                                                  _saveSettings();
                                                },
                                                child: Container(
                                                  padding: const EdgeInsets.all(3),
                                                  decoration: BoxDecoration(
                                                    color: theme.accentGlow.withValues(alpha: 0.3),
                                                    borderRadius: BorderRadius.circular(4),
                                                    border: Border.all(color: theme.accentGlow.withValues(alpha: 0.6), width: 0.8),
                                                  ),
                                                  child: Icon(Icons.add, size: 12, color: theme.accentGlow),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    SizedBox(width: _splitGap),

                    // --- CENTER STARK CONSOLE / HUD ---
                    Container(
                      width: 76,
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Arc Reactor Center Ring
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: theme.accentGlow, width: 1.5),
                              boxShadow: [
                                BoxShadow(
                                  color: theme.accentGlow.withValues(alpha: 0.35),
                                  blurRadius: 10,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            child: Center(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.asset(
                                  'assets/images/logo.png',
                                  width: 22,
                                  height: 22,
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) => Icon(
                                    Icons.bolt,
                                    color: theme.accentGlow,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            "AXIOM",
                            style: TextStyle(
                              color: theme.accentGlow,
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2.0,
                            ),
                          ),
                          Text(
                            "SPLIT",
                            style: TextStyle(
                              color: theme.textSecondary,
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),

                          // Customization Mode Toggle Button
                          IconButton(
                            icon: Icon(_isCustomizing ? Icons.check_circle : Icons.tune),
                            iconSize: 22,
                            color: _isCustomizing ? const Color(0xFF00FF66) : theme.accentGlow,
                            tooltip: _isCustomizing ? "Lock Splits & Done" : "Adjust Size & Move Splits",
                            onPressed: () {
                              setState(() {
                                _isCustomizing = !_isCustomizing;
                              });
                            },
                          ),
                          Text(
                            _isCustomizing ? "DONE" : "MOVE",
                            style: TextStyle(
                              color: _isCustomizing ? const Color(0xFF00FF66) : theme.accentGlow,
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 10),

                          // Angle quick adjustment
                          IconButton(
                            icon: const Icon(Icons.rotate_right, size: 16, color: Colors.white54),
                            tooltip: "Increase Inward Angle",
                            onPressed: () {
                              setState(() {
                                _tiltAngle = (_tiltAngle + 2.0).clamp(0.0, 25.0);
                              });
                              _saveSettings();
                            },
                          ),
                          Text(
                            "${_tiltAngle.round()}°",
                            style: TextStyle(color: theme.textSecondary, fontSize: 9, fontWeight: FontWeight.bold),
                          ),
                          IconButton(
                            icon: const Icon(Icons.rotate_left, size: 16, color: Colors.white54),
                            tooltip: "Decrease Inward Angle",
                            onPressed: () {
                              setState(() {
                                _tiltAngle = (_tiltAngle - 2.0).clamp(0.0, 25.0);
                              });
                              _saveSettings();
                            },
                          ),
                        ],
                      ),
                    ),

                    SizedBox(width: _splitGap),

                    // --- RIGHT WING (Moveable, Scalable, Rotatable) ---
                    Expanded(
                      flex: 10,
                      child: GestureDetector(
                        behavior: _isCustomizing ? HitTestBehavior.opaque : HitTestBehavior.deferToChild,
                        onScaleStart: _isCustomizing
                            ? (details) => _baseRightScale = _rightScale
                            : null,
                        onScaleUpdate: _isCustomizing
                            ? (details) {
                                setState(() {
                                  _rightOffset += details.focalPointDelta;
                                  if (details.pointerCount >= 2 && details.scale != 1.0) {
                                    _rightScale = (_baseRightScale * details.scale).clamp(0.50, 1.40);
                                  }
                                });
                              }
                            : null,
                        onScaleEnd: _isCustomizing ? (_) => _saveSettings() : null,
                        child: Transform.translate(
                          offset: _rightOffset,
                          child: Transform.scale(
                            scale: _rightScale,
                            alignment: Alignment.centerLeft,
                            child: Transform(
                              alignment: Alignment.centerLeft,
                              transform: Matrix4.identity()
                                ..setEntry(3, 2, 0.001)
                                ..rotateZ(-angleRad),
                              child: Container(
                                decoration: _isCustomizing
                                    ? BoxDecoration(
                                        border: Border.all(color: theme.accentGlow, width: 2),
                                        borderRadius: BorderRadius.circular(10),
                                        color: theme.accentGlow.withValues(alpha: 0.08),
                                      )
                                    : null,
                                child: Stack(
                                  children: [
                                    IgnorePointer(
                                      ignoring: _isCustomizing,
                                      child: _buildWing(
                                        rows: _rightRows,
                                        isLeft: false,
                                      ),
                                    ),
                                    if (_isCustomizing)
                                      Positioned(
                                        top: 6,
                                        right: 6,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.black.withValues(alpha: 0.88),
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: theme.accentGlow, width: 1.5),
                                            boxShadow: [
                                              BoxShadow(
                                                color: theme.accentGlow.withValues(alpha: 0.25),
                                                blurRadius: 8,
                                              ),
                                            ],
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              GestureDetector(
                                                onTap: () {
                                                  setState(() {
                                                    _rightScale = (_rightScale - 0.05).clamp(0.50, 1.40);
                                                  });
                                                  _saveSettings();
                                                },
                                                child: Container(
                                                  padding: const EdgeInsets.all(3),
                                                  decoration: BoxDecoration(
                                                    color: Colors.white12,
                                                    borderRadius: BorderRadius.circular(4),
                                                  ),
                                                  child: const Icon(Icons.remove, size: 12, color: Colors.white),
                                                ),
                                              ),
                                              Padding(
                                                padding: const EdgeInsets.symmetric(horizontal: 6),
                                                child: Text(
                                                  "${(_rightScale * 100).round()}%",
                                                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                                ),
                                              ),
                                              GestureDetector(
                                                onTap: () {
                                                  setState(() {
                                                    _rightScale = (_rightScale + 0.05).clamp(0.50, 1.40);
                                                  });
                                                  _saveSettings();
                                                },
                                                child: Container(
                                                  padding: const EdgeInsets.all(3),
                                                  decoration: BoxDecoration(
                                                    color: theme.accentGlow.withValues(alpha: 0.3),
                                                    borderRadius: BorderRadius.circular(4),
                                                    border: Border.all(color: theme.accentGlow.withValues(alpha: 0.6), width: 0.8),
                                                  ),
                                                  child: Icon(Icons.add, size: 12, color: theme.accentGlow),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Icon(Icons.open_with, size: 12, color: theme.accentGlow),
                                              const SizedBox(width: 4),
                                              Text(
                                                "RIGHT",
                                                style: TextStyle(color: theme.accentGlow, fontSize: 10, fontWeight: FontWeight.bold),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // --- FLOATING CUSTOMIZATION TOOLBAR (Visible in MOVE/EDIT mode) ---
              if (_isCustomizing)
                Positioned(
                  bottom: 8,
                  left: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F1219).withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: theme.accentGlow.withValues(alpha: 0.6)),
                      boxShadow: const [
                        BoxShadow(color: Colors.black87, blurRadius: 16, spreadRadius: 2),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Header row with Reset and Done buttons
                        Row(
                          children: [
                            Icon(Icons.tune, size: 14, color: theme.accentGlow),
                            const SizedBox(width: 6),
                            Text(
                              "SPLIT SIZING & POSITIONING",
                              style: TextStyle(color: theme.accentGlow, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.0),
                            ),
                            const Spacer(),
                            // Reset Button
                            TextButton.icon(
                              icon: const Icon(Icons.restore, size: 13, color: Colors.white70),
                              label: const Text("Reset", style: TextStyle(color: Colors.white70, fontSize: 11)),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              onPressed: () {
                                setState(() {
                                  _leftScale = 0.85;
                                  _rightScale = 0.85;
                                  _tiltAngle = 8.0;
                                  _splitGap = 32.0;
                                  _leftOffset = Offset.zero;
                                  _rightOffset = Offset.zero;
                                });
                                _saveSettings();
                              },
                            ),
                            const SizedBox(width: 10),
                            // Done / Lock Button
                            ElevatedButton.icon(
                              icon: const Icon(Icons.check, size: 13, color: Colors.black),
                              label: const Text("Lock & Save", style: TextStyle(color: Colors.black, fontSize: 11, fontWeight: FontWeight.bold)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: theme.accentGlow,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              onPressed: () {
                                setState(() => _isCustomizing = false);
                                _saveSettings();
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        // Sliders Row
                        Row(
                          children: [
                            // Left Split Size Slider
                            Text("Left Size:", style: TextStyle(color: theme.accentGlow, fontSize: 11, fontWeight: FontWeight.bold)),
                            Expanded(
                              child: Slider(
                                value: _leftScale,
                                min: 0.50,
                                max: 1.40,
                                activeColor: theme.accentGlow,
                                inactiveColor: const Color(0xFF1E293B),
                                onChanged: (v) => setState(() => _leftScale = v),
                                onChangeEnd: (_) => _saveSettings(),
                              ),
                            ),
                            Text("${(_leftScale * 100).round()}%", style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                            const SizedBox(width: 12),

                            // Right Split Size Slider
                            Text("Right Size:", style: TextStyle(color: theme.accentGlow, fontSize: 11, fontWeight: FontWeight.bold)),
                            Expanded(
                              child: Slider(
                                value: _rightScale,
                                min: 0.50,
                                max: 1.40,
                                activeColor: theme.accentGlow,
                                inactiveColor: const Color(0xFF1E293B),
                                onChanged: (v) => setState(() => _rightScale = v),
                                onChangeEnd: (_) => _saveSettings(),
                              ),
                            ),
                            Text("${(_rightScale * 100).round()}%", style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                            const SizedBox(width: 12),

                            // Angle Slider
                            const Text("Angle:", style: TextStyle(color: Colors.white70, fontSize: 11)),
                            Expanded(
                              child: Slider(
                                value: _tiltAngle,
                                min: 0.0,
                                max: 25.0,
                                activeColor: theme.accentGlow,
                                inactiveColor: const Color(0xFF1E293B),
                                onChanged: (v) => setState(() => _tiltAngle = v),
                                onChangeEnd: (_) => _saveSettings(),
                              ),
                            ),
                            Text("${_tiltAngle.round()}°", style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                            const SizedBox(width: 12),

                            // Gap Slider
                            const Text("Gap:", style: TextStyle(color: Colors.white70, fontSize: 11)),
                            Expanded(
                              child: Slider(
                                value: _splitGap,
                                min: 0.0,
                                max: 90.0,
                                activeColor: theme.accentGlow,
                                inactiveColor: const Color(0xFF1E293B),
                                onChanged: (v) => setState(() => _splitGap = v),
                                onChangeEnd: (_) => _saveSettings(),
                              ),
                            ),
                            Text("${_splitGap.round()}px", style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildWing({
    required List<List<KeyModel>> rows,
    required bool isLeft,
  }) {
    return Column(
      children: rows.asMap().entries.map((rowEntry) {
        final rowIndex = rowEntry.key;
        final row = rowEntry.value;

        return Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: row.asMap().entries.map((colEntry) {
              final colIndex = isLeft ? colEntry.key : colEntry.key + 7;
              final keyModel = colEntry.value;

              return KeyWidget(
                keyModel: keyModel,
                engine: widget.engine,
                rowIndex: rowIndex,
                colIndex: colIndex,
              );
            }).toList(),
          ),
        );
      }).toList(),
    );
  }
}

class _HolographicArcPainter extends CustomPainter {
  final Color accentColor;

  _HolographicArcPainter(this.accentColor);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = accentColor.withValues(alpha: 0.04)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final center = Offset(size.width / 2, size.height + 40);

    // Draw concentric holographic guide rings
    for (double r = 120; r < size.width * 0.7; r += 70) {
      canvas.drawCircle(center, r, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
