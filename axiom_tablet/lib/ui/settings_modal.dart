import 'package:flutter/material.dart';
import '../audio/sound_engine.dart';
import '../core/settings_service.dart';
import '../keyboard/rgb_effects.dart';
import '../themes/theme_model.dart';

class SettingsModal extends StatefulWidget {
  const SettingsModal({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const SettingsModal(),
    );
  }

  @override
  State<SettingsModal> createState() => _SettingsModalState();
}

class _SettingsModalState extends State<SettingsModal> {
  final sound = SoundEngine.instance;
  final rgb = RgbEngine.instance;

  @override
  Widget build(BuildContext context) {
    final theme = rgb.currentTheme;

    return Container(
      height: MediaQuery.of(context).size.height * 0.82,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF0C101A),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border.all(color: theme.accentGlow.withValues(alpha: 0.4), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: theme.accentGlow.withValues(alpha: 0.2),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Bar
          Row(
            children: [
              Icon(Icons.tune, color: theme.accentGlow, size: 20),
              const SizedBox(width: 10),
              Text(
                "AXIOM HARDWARE CONFIGURATION",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                  letterSpacing: 1.5,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white54, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const Divider(color: Color(0xFF1E293B)),

          Expanded(
            child: ListView(
              children: [
                // 1. Mechanical Sound Section
                _buildSectionHeader("MECHANICAL KEYSTROKE SOUNDS", Icons.volume_up_outlined),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildSoundChip(SoundProfile.clicky, "🟢 Clicky (Razer Green)"),
                    _buildSoundChip(SoundProfile.tactile, "🟠 Tactile (Razer Orange)"),
                    _buildSoundChip(SoundProfile.linear, "🟡 Linear (Razer Yellow)"),
                    _buildSoundChip(SoundProfile.off, "🔇 Sound Off"),
                  ],
                ),
                const SizedBox(height: 12),

                // Volume slider
                if (sound.currentProfile != SoundProfile.off) ...[
                  Row(
                    children: [
                      const Text("Volume:", style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
                      Expanded(
                        child: SliderTheme(
                          data: SliderThemeData(
                            activeTrackColor: theme.accentGlow,
                            thumbColor: theme.accentGlow,
                            inactiveTrackColor: const Color(0xFF1E293B),
                          ),
                          child: Slider(
                            value: sound.volume,
                            onChanged: (val) {
                              setState(() {
                                sound.setVolume(val);
                                SettingsService.instance.saveVolume(val);
                              });
                            },
                          ),
                        ),
                      ),
                      Text(
                        "${(sound.volume * 100).round()}%",
                        style: TextStyle(color: theme.accentGlow, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ],
                  ),
                ],

                // Haptics toggle
                Material(
                  type: MaterialType.transparency,
                  child: SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text("Haptic Feedback on Keypress", style: TextStyle(color: Color(0xFFE2E8F0), fontSize: 13)),
                    subtitle: Text(
                      sound.hasHardwareVibrator
                          ? "● Physical vibration motor active"
                          : "⚠️ No physical motor detected on this tablet model",
                      style: TextStyle(
                        color: sound.hasHardwareVibrator ? const Color(0xFF00FF66) : const Color(0xFFFFB700),
                        fontSize: 10,
                      ),
                    ),
                    value: sound.hapticsEnabled,
                    activeThumbColor: theme.accentGlow,
                    onChanged: (val) {
                      setState(() {
                        sound.hapticsEnabled = val;
                        SettingsService.instance.saveHaptics(val);
                      });
                    },
                  ),
                ),

                const SizedBox(height: 16),
                const Divider(color: Color(0xFF1E293B)),

                // 2. RGB Lighting Mode Section
                _buildSectionHeader("RGB LIGHTING EFFECTS", Icons.light_mode_outlined),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildRgbChip(RgbEffectMode.reactive, "⚡ Reactive"),
                    _buildRgbChip(RgbEffectMode.ripple, "🌊 Ripple Wave"),
                    _buildRgbChip(RgbEffectMode.wave, "🌈 Horizontal Wave"),
                    _buildRgbChip(RgbEffectMode.breathing, "🫁 Breathing"),
                    _buildRgbChip(RgbEffectMode.staticGlow, "✨ Static Glow"),
                  ],
                ),

                const SizedBox(height: 16),
                const Divider(color: Color(0xFF1E293B)),

                // 3. Cyberpunk Color Themes
                _buildSectionHeader("COLOR PRESETS", Icons.palette_outlined),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: AxiomTheme.allThemes.map((t) => _buildThemeChip(t)).toList(),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    final theme = rgb.currentTheme;
    return Row(
      children: [
        Icon(icon, size: 15, color: theme.accentGlow),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            color: theme.accentGlow,
            fontWeight: FontWeight.w800,
            fontSize: 11,
            letterSpacing: 1.0,
          ),
        ),
      ],
    );
  }

  Widget _buildSoundChip(SoundProfile profile, String label) {
    final isSelected = sound.currentProfile == profile;
    final theme = rgb.currentTheme;

    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) {
        setState(() {
          sound.setProfile(profile);
          SettingsService.instance.saveSoundProfile(profile);
          sound.playKeySound(); // Sample preview!
        });
      },
      selectedColor: theme.accentGlow.withValues(alpha: 0.25),
      backgroundColor: const Color(0xFF141923),
      labelStyle: TextStyle(
        color: isSelected ? theme.accentGlow : const Color(0xFF94A3B8),
        fontSize: 11,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      side: BorderSide(
        color: isSelected ? theme.accentGlow : const Color(0xFF28364F),
      ),
    );
  }

  Widget _buildRgbChip(RgbEffectMode mode, String label) {
    final isSelected = rgb.currentMode == mode;
    final theme = rgb.currentTheme;

    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) {
        setState(() {
          rgb.setMode(mode);
          SettingsService.instance.saveRgbMode(mode);
        });
      },
      selectedColor: theme.accentGlow.withValues(alpha: 0.25),
      backgroundColor: const Color(0xFF141923),
      labelStyle: TextStyle(
        color: isSelected ? theme.accentGlow : const Color(0xFF94A3B8),
        fontSize: 11,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      side: BorderSide(
        color: isSelected ? theme.accentGlow : const Color(0xFF28364F),
      ),
    );
  }

  Widget _buildThemeChip(AxiomTheme t) {
    final isSelected = rgb.currentTheme.id == t.id;

    return ChoiceChip(
      avatar: Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(
          color: t.accentGlow,
          shape: BoxShape.circle,
        ),
      ),
      label: Text(t.name),
      selected: isSelected,
      onSelected: (_) {
        setState(() {
          rgb.setTheme(t);
          SettingsService.instance.saveTheme(t);
        });
      },
      selectedColor: t.accentGlow.withValues(alpha: 0.25),
      backgroundColor: const Color(0xFF141923),
      labelStyle: TextStyle(
        color: isSelected ? t.accentGlow : const Color(0xFF94A3B8),
        fontSize: 11,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      side: BorderSide(
        color: isSelected ? t.accentGlow : const Color(0xFF28364F),
      ),
    );
  }
}
