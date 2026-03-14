import 'package:flutter/material.dart';

class AppColors {
  // ─── Backgrounds ────────────────────────────────────────────────────────
  static const Color primaryBackground = Color(0xFF050A05);   // Deep black-green
  static const Color cardBackground    = Color(0xFF0D150D);   // Dark card

  // ─── Greens ─────────────────────────────────────────────────────────────
  static const Color primaryAccent   = Color(0xFF00E040);   // Bright neon green
  static const Color secondaryGreen  = Color(0xFF1A6B1A);   // Forest / mid-tone
  static const Color dimGreen        = Color(0xFF0A3A0A);   // Dark green tint
  static const Color gridLine        = Color(0xFF0F3A0F);   // Notebook line green

  // ─── Reds ───────────────────────────────────────────────────────────────
  static const Color dangerRed       = Color(0xFFFF2233);   // Alert red
  static const Color dimRed          = Color(0xFF7A0010);   // Muted/dark red

  // ─── Grayscale on black ─────────────────────────────────────────────────
  static const Color textPrimary     = Color(0xFFEEFFEE);   // Near white w/ green tint
  static const Color textSecondary   = Color(0xFF7AB87A);   // Muted green-grey

  // ─── Legacy aliases so existing code compiles ───────────────────────────
  static const Color secondaryAccent1 = secondaryGreen;
  static const Color secondaryAccent2 = primaryAccent;
  static const Color goldAccent       = Color(0xFF00E040); // remapped → green
  static const Color softPurple       = dangerRed;          // remapped → red
}
