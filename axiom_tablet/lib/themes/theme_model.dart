import 'package:flutter/material.dart';

class AxiomTheme {
  final String id;
  final String name;
  final Color bgPrimary;
  final Color bgSurface;
  final Color keyBase;
  final Color keyModifier;
  final Color accentGlow;
  final Color accentPressed;
  final Color textPrimary;
  final Color textSecondary;
  final Color borderColor;

  const AxiomTheme({
    required this.id,
    required this.name,
    required this.bgPrimary,
    required this.bgSurface,
    required this.keyBase,
    required this.keyModifier,
    required this.accentGlow,
    required this.accentPressed,
    required this.textPrimary,
    required this.textSecondary,
    required this.borderColor,
  });

  static const AxiomTheme cyberBlue = AxiomTheme(
    id: "cyber_blue",
    name: "Cyber Blue",
    bgPrimary: Color(0xFF070A10),
    bgSurface: Color(0xFF0B0F19),
    keyBase: Color(0xFF141B2D),
    keyModifier: Color(0xFF0E1422),
    accentGlow: Color(0xFF00E5FF),
    accentPressed: Color(0xFF00E5FF),
    textPrimary: Color(0xFFE2E8F0),
    textSecondary: Color(0xFF64748B),
    borderColor: Color(0xFF1E293B),
  );

  static const AxiomTheme neonPurple = AxiomTheme(
    id: "neon_purple",
    name: "Neon Purple",
    bgPrimary: Color(0xFF090611),
    bgSurface: Color(0xFF120C22),
    keyBase: Color(0xFF1E1338),
    keyModifier: Color(0xFF160D2A),
    accentGlow: Color(0xFFD946EF),
    accentPressed: Color(0xFFE879F9),
    textPrimary: Color(0xFFF5D0FE),
    textSecondary: Color(0xFF86198F),
    borderColor: Color(0xFF3B185F),
  );

  static const AxiomTheme matrixGreen = AxiomTheme(
    id: "matrix_green",
    name: "Matrix Green",
    bgPrimary: Color(0xFF040A06),
    bgSurface: Color(0xFF08140C),
    keyBase: Color(0xFF0E2415),
    keyModifier: Color(0xFF091A0E),
    accentGlow: Color(0xFF00FF66),
    accentPressed: Color(0xFF22C55E),
    textPrimary: Color(0xFFDCFCE7),
    textSecondary: Color(0xFF15803D),
    borderColor: Color(0xFF14532D),
  );

  static const AxiomTheme crimson = AxiomTheme(
    id: "crimson",
    name: "Crimson",
    bgPrimary: Color(0xFF0A0507),
    bgSurface: Color(0xFF140A0E),
    keyBase: Color(0xFF241017),
    keyModifier: Color(0xFF1A0B10),
    accentGlow: Color(0xFFFF2A55),
    accentPressed: Color(0xFFF43F5E),
    textPrimary: Color(0xFFFFE4E6),
    textSecondary: Color(0xFF9F1239),
    borderColor: Color(0xFF4C0519),
  );

  static const AxiomTheme amber = AxiomTheme(
    id: "amber",
    name: "Amber",
    bgPrimary: Color(0xFF0A0804),
    bgSurface: Color(0xFF141008),
    keyBase: Color(0xFF241C0E),
    keyModifier: Color(0xFF1A140A),
    accentGlow: Color(0xFFFFB700),
    accentPressed: Color(0xFFF59E0B),
    textPrimary: Color(0xFFFEF3C7),
    textSecondary: Color(0xFF92400E),
    borderColor: Color(0xFF451A03),
  );

  static const AxiomTheme arctic = AxiomTheme(
    id: "arctic",
    name: "Arctic",
    bgPrimary: Color(0xFF06090E),
    bgSurface: Color(0xFF0C121C),
    keyBase: Color(0xFF162030),
    keyModifier: Color(0xFF101724),
    accentGlow: Color(0xFF38BDF8),
    accentPressed: Color(0xFFE0F2FE),
    textPrimary: Color(0xFFF0F9FF),
    textSecondary: Color(0xFF64748B),
    borderColor: Color(0xFF1E293B),
  );

  static const AxiomTheme stealth = AxiomTheme(
    id: "stealth",
    name: "Stealth",
    bgPrimary: Color(0xFF050505),
    bgSurface: Color(0xFF0D0D0D),
    keyBase: Color(0xFF171717),
    keyModifier: Color(0xFF121212),
    accentGlow: Color(0xFF737373),
    accentPressed: Color(0xFFA3A3A3),
    textPrimary: Color(0xFFE5E5E5),
    textSecondary: Color(0xFF525252),
    borderColor: Color(0xFF262626),
  );

  static const List<AxiomTheme> allThemes = [
    cyberBlue,
    neonPurple,
    matrixGreen,
    crimson,
    amber,
    arctic,
    stealth,
  ];
}
