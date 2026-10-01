import 'package:flutter/material.dart';
import '../touchpad/touchpad_engine.dart';

class TouchpadScreen extends StatefulWidget {
  final TouchpadEngine engine;

  const TouchpadScreen({super.key, required this.engine});

  @override
  State<TouchpadScreen> createState() => _TouchpadScreenState();
}

class _TouchpadScreenState extends State<TouchpadScreen> {
  bool _showButtons = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Main Touch Surface
        Expanded(
          child: Listener(
            onPointerDown: (event) {
              setState(() {});
              widget.engine.onPointerDown(event);
            },
            onPointerMove: (event) {
              setState(() {});
              widget.engine.onPointerMove(event);
            },
            onPointerUp: (event) {
              setState(() {});
              widget.engine.onPointerUp(event);
            },
            onPointerCancel: (event) {
              setState(() {});
              widget.engine.onPointerCancel(event);
            },
            child: Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFF070A10),
                border: Border.all(color: const Color(0xFF1E293B), width: 1.0),
              ),
              child: Stack(
                children: [
                  // Subtle Futuristic Grid Pattern
                  CustomPaint(
                    size: Size.infinite,
                    painter: _TouchpadGridPainter(),
                  ),

                  // Center Subtle Watermark
                  const Center(
                    child: Opacity(
                      opacity: 0.15,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.touch_app_outlined, size: 40, color: Color(0xFF00E5FF)),
                          SizedBox(height: 6),
                          Text(
                            "AXIOM TOUCHPAD",
                            style: TextStyle(
                              color: Color(0xFF00E5FF),
                              letterSpacing: 3.0,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Interactive Multi-Touch Glowing Reticles under every active finger
                  for (final pos in widget.engine.pointerPositions.values)
                    Positioned(
                      left: pos.dx - 25,
                      top: pos.dy - 25,
                      child: IgnorePointer(
                        child: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFF00E5FF), width: 1.5),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF00E5FF).withValues(alpha: 0.45),
                                blurRadius: 15.0,
                                spreadRadius: 2.0,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),



                  // Top Right: Button overlay toggle button
                  Positioned(
                    right: 12,
                    top: 12,
                    child: IconButton(
                      icon: Icon(
                        _showButtons ? Icons.mouse : Icons.mouse_outlined,
                        color: _showButtons ? const Color(0xFF00E5FF) : const Color(0xFF64748B),
                        size: 20,
                      ),
                      tooltip: "Toggle On-Screen Mouse Buttons",
                      onPressed: () {
                        setState(() {
                          _showButtons = !_showButtons;
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Optional Physical Mouse Buttons UI
        if (_showButtons)
          Container(
            height: 64,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: const Color(0xFF0B0F19),
            child: Row(
              children: [
                Expanded(
                  child: Listener(
                    onPointerDown: (_) => widget.engine.leftMouseDown(),
                    onPointerUp: (_) => widget.engine.leftMouseUp(),
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF141923),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFF28364F)),
                      ),
                      child: const Center(
                        child: Text(
                          "LEFT CLICK",
                          style: TextStyle(
                            color: Color(0xFFE2E8F0),
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Listener(
                    onPointerDown: (_) => widget.engine.rightMouseDown(),
                    onPointerUp: (_) => widget.engine.rightMouseUp(),
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF141923),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFF28364F)),
                      ),
                      child: const Center(
                        child: Text(
                          "RIGHT CLICK",
                          style: TextStyle(
                            color: Color(0xFFE2E8F0),
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _TouchpadGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF141B2D).withValues(alpha: 0.6)
      ..strokeWidth = 0.8;

    const step = 40.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
