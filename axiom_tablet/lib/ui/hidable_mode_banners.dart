import 'package:flutter/material.dart';
import '../core/settings_service.dart';
import '../keyboard/rgb_effects.dart';
import 'connection_bar.dart';

class HidableSideBanners extends StatefulWidget {
  final AxiomMode currentMode;
  final ValueChanged<AxiomMode> onModeChanged;
  final Widget child;

  const HidableSideBanners({
    super.key,
    required this.currentMode,
    required this.onModeChanged,
    required this.child,
  });

  @override
  State<HidableSideBanners> createState() => _HidableSideBannersState();
}

class _HidableSideBannersState extends State<HidableSideBanners>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animCtrl;
  late final Animation<double> _slideAnimation;

  // -1 = Left open, 1 = Right open, 0 = Closed
  int _activeSide = 0;
  static const double _bannerWidth = 250.0;
  double _dragAccumulator = 0.0;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _slideAnimation = CurvedAnimation(
      parent: _animCtrl,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  void _close() {
    _animCtrl.reverse().then((_) {
      if (mounted) setState(() => _activeSide = 0);
    });
  }

  void _selectMode(AxiomMode mode) {
    widget.onModeChanged(mode);
    SettingsService.instance.saveMode(mode);
    _close();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: RgbEngine.instance,
      builder: (context, _) {
        final theme = RgbEngine.instance.currentTheme;

        return Stack(
          fit: StackFit.expand,
          children: [
            // 1. BASE LAYER: Main Surface (Always 100% full screen & active)
            widget.child,

            // 2. SCRIM BACKDROP (Only intercepts when banner is sliding or open)
            AnimatedBuilder(
              animation: _slideAnimation,
              builder: (context, child) {
                if (_activeSide == 0 && _slideAnimation.value == 0.0) {
                  return const SizedBox.shrink();
                }
                return Positioned.fill(
                  child: GestureDetector(
                    onTap: _close,
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      color: Colors.black.withValues(alpha: 0.5 * _slideAnimation.value),
                    ),
                  ),
                );
              },
            ),

            // 3. LEFT BANNER DRAWER
            AnimatedBuilder(
              animation: _slideAnimation,
              builder: (context, _) {
                final isOpen = _activeSide == -1;
                final progress = isOpen ? _slideAnimation.value : 0.0;
                final left = -_bannerWidth + (progress * _bannerWidth);

                if (progress == 0.0 && _activeSide != -1) {
                  return const SizedBox.shrink();
                }

                return Positioned(
                  top: 0,
                  bottom: 0,
                  left: left,
                  width: _bannerWidth,
                  child: GestureDetector(
                    onHorizontalDragUpdate: (details) {
                      _activeSide = -1;
                      final delta = details.primaryDelta ?? 0;
                      _animCtrl.value += delta / _bannerWidth;
                    },
                    onHorizontalDragEnd: (details) {
                      if (_animCtrl.value > 0.4 || (details.primaryVelocity ?? 0) > 200) {
                        _animCtrl.forward();
                      } else {
                        _close();
                      }
                    },
                    child: _buildBannerContent(isLeft: true, theme: theme),
                  ),
                );
              },
            ),

            // 4. RIGHT BANNER DRAWER
            AnimatedBuilder(
              animation: _slideAnimation,
              builder: (context, _) {
                final isOpen = _activeSide == 1;
                final progress = isOpen ? _slideAnimation.value : 0.0;
                final right = -_bannerWidth + (progress * _bannerWidth);

                if (progress == 0.0 && _activeSide != 1) {
                  return const SizedBox.shrink();
                }

                return Positioned(
                  top: 0,
                  bottom: 0,
                  right: right,
                  width: _bannerWidth,
                  child: GestureDetector(
                    onHorizontalDragUpdate: (details) {
                      _activeSide = 1;
                      final delta = details.primaryDelta ?? 0;
                      _animCtrl.value -= delta / _bannerWidth;
                    },
                    onHorizontalDragEnd: (details) {
                      if (_animCtrl.value > 0.4 || (details.primaryVelocity ?? 0) < -200) {
                        _animCtrl.forward();
                      } else {
                        _close();
                      }
                    },
                    child: _buildBannerContent(isLeft: false, theme: theme),
                  ),
                );
              },
            ),

            // 5. FULL-HEIGHT LEFT GLOWING EDGE & INTENTIONAL SWIPE TRIGGER
            AnimatedBuilder(
              animation: _slideAnimation,
              builder: (context, _) {
                final isLeftOpen = _activeSide == -1;
                final leftOffset = isLeftOpen
                    ? (_bannerWidth * _slideAnimation.value)
                    : 0.0;

                return Positioned(
                  top: 0,
                  bottom: 0,
                  left: leftOffset,
                  // Keep hit width ultra-slim (14px) so it stays purely on the bezel and never overlaps keys
                  width: 14.0,
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    // DO NOT open on tap! Taps must never open the drawer accidentally while typing
                    onHorizontalDragStart: (_) {
                      _dragAccumulator = 0.0;
                    },
                    onHorizontalDragUpdate: (details) {
                      final delta = details.primaryDelta ?? 0;
                      if (!isLeftOpen) {
                        // Only activate on deliberate INWARD (positive) drag
                        if (delta > 0) {
                          _dragAccumulator += delta;
                          if (_dragAccumulator > 28.0) {
                            _activeSide = -1;
                            _animCtrl.value = (_dragAccumulator - 28.0) / _bannerWidth;
                          }
                        }
                      } else {
                        // When open, dragging left closes it
                        _animCtrl.value += delta / _bannerWidth;
                      }
                    },
                    onHorizontalDragEnd: (details) {
                      final velocity = details.primaryVelocity ?? 0;
                      if (_animCtrl.value > 0.50 || velocity > 600) {
                        _animCtrl.forward();
                      } else {
                        _close();
                      }
                    },
                    child: Stack(
                      children: [
                        // Full-Height Glowing Edge Light Strip
                        Positioned(
                          top: 0,
                          bottom: 0,
                          left: 0,
                          width: 3.5,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  theme.accentGlow.withValues(alpha: 0.15),
                                  theme.accentGlow.withValues(alpha: 0.75),
                                  theme.accentGlow,
                                  theme.accentGlow.withValues(alpha: 0.75),
                                  theme.accentGlow.withValues(alpha: 0.15),
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: theme.accentGlow.withValues(alpha: 0.7),
                                  blurRadius: 8,
                                  spreadRadius: 1,
                                ),
                                BoxShadow(
                                  color: theme.accentGlow.withValues(alpha: 0.35),
                                  blurRadius: 16,
                                  spreadRadius: 2.5,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            // 6. FULL-HEIGHT RIGHT GLOWING EDGE & INTENTIONAL SWIPE TRIGGER
            AnimatedBuilder(
              animation: _slideAnimation,
              builder: (context, _) {
                final isRightOpen = _activeSide == 1;
                final rightOffset = isRightOpen
                    ? (_bannerWidth * _slideAnimation.value)
                    : 0.0;

                return Positioned(
                  top: 0,
                  bottom: 0,
                  right: rightOffset,
                  // Keep hit width ultra-slim (14px) so it stays purely on the bezel and never overlaps keys
                  width: 14.0,
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    // DO NOT open on tap! Taps must never open the drawer accidentally while typing
                    onHorizontalDragStart: (_) {
                      _dragAccumulator = 0.0;
                    },
                    onHorizontalDragUpdate: (details) {
                      final delta = details.primaryDelta ?? 0;
                      if (!isRightOpen) {
                        // Only activate on deliberate INWARD (negative) drag
                        if (delta < 0) {
                          _dragAccumulator += -delta;
                          if (_dragAccumulator > 28.0) {
                            _activeSide = 1;
                            _animCtrl.value = (_dragAccumulator - 28.0) / _bannerWidth;
                          }
                        }
                      } else {
                        // When open, dragging right closes it
                        _animCtrl.value -= delta / _bannerWidth;
                      }
                    },
                    onHorizontalDragEnd: (details) {
                      final velocity = details.primaryVelocity ?? 0;
                      if (_animCtrl.value > 0.50 || velocity < -600) {
                        _animCtrl.forward();
                      } else {
                        _close();
                      }
                    },
                    child: Stack(
                      children: [
                        // Full-Height Glowing Edge Light Strip
                        Positioned(
                          top: 0,
                          bottom: 0,
                          right: 0,
                          width: 3.5,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  theme.accentGlow.withValues(alpha: 0.15),
                                  theme.accentGlow.withValues(alpha: 0.75),
                                  theme.accentGlow,
                                  theme.accentGlow.withValues(alpha: 0.75),
                                  theme.accentGlow.withValues(alpha: 0.15),
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: theme.accentGlow.withValues(alpha: 0.7),
                                  blurRadius: 8,
                                  spreadRadius: 1,
                                ),
                                BoxShadow(
                                  color: theme.accentGlow.withValues(alpha: 0.35),
                                  blurRadius: 16,
                                  spreadRadius: 2.5,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  // Futuristic Banner Content
  Widget _buildBannerContent({required bool isLeft, required dynamic theme}) {
    return Container(
      height: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF080C14).withValues(alpha: 0.98),
        border: Border(
          right: isLeft
              ? BorderSide(color: theme.accentGlow.withValues(alpha: 0.6), width: 1.5)
              : BorderSide.none,
          left: !isLeft
              ? BorderSide(color: theme.accentGlow.withValues(alpha: 0.6), width: 1.5)
              : BorderSide.none,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.accentGlow.withValues(alpha: 0.25),
            blurRadius: 24,
            spreadRadius: 2,
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Banner Header
          Row(
            children: [
              Icon(Icons.dashboard_customize_outlined, color: theme.accentGlow, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  "AXIOM MODES",
                  style: TextStyle(
                    color: theme.accentGlow,
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
              GestureDetector(
                onTap: _close,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF141923),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(Icons.close, color: Colors.white54, size: 14),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: Color(0xFF1E293B), height: 1),
          const SizedBox(height: 16),

          // 1. Standard Mode Card
          _buildModeCard(
            mode: AxiomMode.standard,
            title: "Standard Mode",
            subtitle: "Full QWERTY mechanical layout",
            icon: Icons.keyboard_outlined,
            theme: theme,
          ),
          const SizedBox(height: 12),

          // 2. Ergonomic Mode Card
          _buildModeCard(
            mode: AxiomMode.ergonomic,
            title: "Ergonomic Mode",
            subtitle: "Split angled dual-wing layout",
            icon: Icons.auto_awesome_mosaic_outlined,
            theme: theme,
          ),
          const SizedBox(height: 12),

          // 3. Touchpad Mode Card
          _buildModeCard(
            mode: AxiomMode.touchpad,
            title: "Touchpad Mode",
            subtitle: "Precision trackpad with gestures",
            icon: Icons.mouse_outlined,
            theme: theme,
          ),

          const Spacer(),

          // Swipe edge to hide cue
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(isLeft ? Icons.arrow_back : Icons.arrow_forward, size: 12, color: Colors.white38),
                const SizedBox(width: 4),
                const Text(
                  "Swipe edge to hide",
                  style: TextStyle(color: Colors.white38, fontSize: 10),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildModeCard({
    required AxiomMode mode,
    required String title,
    required String subtitle,
    required IconData icon,
    required dynamic theme,
  }) {
    final isSelected = widget.currentMode == mode;

    return InkWell(
      onTap: () => _selectMode(mode),
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.accentGlow.withValues(alpha: 0.16)
              : const Color(0xFF111622),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? theme.accentGlow : const Color(0xFF1E293B),
            width: isSelected ? 1.5 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: theme.accentGlow.withValues(alpha: 0.25),
                    blurRadius: 10,
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected ? theme.accentGlow : const Color(0xFF1A2234),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.black : theme.accentGlow,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: isSelected ? Colors.white : const Color(0xFFCBD5E1),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: isSelected ? theme.accentGlow : const Color(0xFF64748B),
                      fontSize: 9,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: theme.accentGlow, size: 16),
          ],
        ),
      ),
    );
  }
}
