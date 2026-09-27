import 'package:flutter/material.dart';

/// AgriTrack color palette — dark theme with purple/pink gradient accents.
class AppColors {
  AppColors._();

  // ---------- Background ----------
  static const Color background = Color(0xFF0A0A0F);
  static const Color surface = Color(0xFF14141C);
  static const Color surfaceElevated = Color(0xFF1C1C26);
  static const Color inputFill = Color(0xFF1A1A22);

  // ---------- Brand Gradient (purple -> pink) ----------
  static const Color gradientStart = Color(0xFF7B2FF7);
  static const Color gradientEnd = Color(0xFFE8117F);

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [gradientStart, gradientEnd],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFF8A2BE2), Color(0xFFE8117F)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ---------- Text ----------
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFA0A0AC);
  static const Color textMuted = Color(0xFF6B6B76);
  static const Color textOnGradient = Color(0xFFFFFFFF);

  // ---------- Status ----------
  static const Color success = Color(0xFF2ECC71);
  static const Color successBg = Color(0xFF16321F);
  static const Color warning = Color(0xFFF5A623);
  static const Color warningBg = Color(0xFF332616);
  static const Color danger = Color(0xFFFF4D6D);
  static const Color dangerBg = Color(0xFF331A1F);
  static const Color pending = Color(0xFFE8117F);

  // ---------- Accent (icons, badges) ----------
  static const Color accentPurple = Color(0xFF7B2FF7);
  static const Color accentPink = Color(0xFFE8117F);
  static const Color accentGreen = Color(0xFF2ECC71);

  // ---------- Border / Divider ----------
  static const Color border = Color(0xFF262631);
  static const Color divider = Color(0xFF1E1E28);

  // ---------- Bottom Nav ----------
  static const Color navBackground = Color(0xFF14141C);
  static const Color navActive = Color(0xFFE8117F);
  static const Color navInactive = Color(0xFF6B6B76);
}
