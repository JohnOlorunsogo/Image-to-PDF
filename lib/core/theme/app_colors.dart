import 'package:flutter/material.dart';

class AppColors {
  // ─── Primary Palette ───
  // More vibrant and energetic Indigo / Purple tones
  static const Color primaryLight = Color(0xFF818CF8); // Indigo 400
  static const Color primary = Color(0xFF6366F1); // Indigo 500
  static const Color primaryDark = Color(0xFF4F46E5); // Indigo 600

  // ─── Accent / Teal ───
  static const Color accent = Color(0xFF06B6D4); // Cyan 500
  static const Color accentLight = Color(0xFF22D3EE); // Cyan 400
  static const Color accentDark = Color(0xFF0891B2); // Cyan 600

  // ─── Surface (Light) ───
  static const Color surfaceLight = Color(0xFFF8FAFC);
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color subtleBorderLight = Color(0xFFE2E8F0);

  // ─── Surface (Dark) ───
  static const Color scaffoldDark = Color(0xFF0F172A); // Slate 900
  static const Color surfaceDark = Color(0xFF1E293B); // Slate 800
  static const Color cardDark = Color(0xFF334155); // Slate 700
  static const Color subtleBorderDark = Color(0xFF475569); // Slate 600

  // ─── Text ───
  static const Color textPrimaryLight = Color(0xFF0F172A);
  static const Color textSecondaryLight = Color(0xFF64748B);
  static const Color textPrimaryDark = Color(0xFFF1F5F9);
  static const Color textSecondaryDark = Color(0xFF94A3B8);

  // ─── Semantic ───
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);

  // ─── Gradients ───
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryLight, primaryDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [accentLight, accentDark],
    begin: Alignment.bottomLeft,
    end: Alignment.topRight,
  );

  static const LinearGradient coolMeshGradient = LinearGradient(
    colors: [Color(0xFF818CF8), Color(0xFFC084FC), Color(0xFF38BDF8)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkMeshGradient = LinearGradient(
    colors: [Color(0xFF1E1B4B), Color(0xFF312E81), Color(0xFF1E293B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkCardGradient = LinearGradient(
    colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient shimmerGradient = LinearGradient(
    colors: [Color(0x00FFFFFF), Color(0x33FFFFFF), Color(0x00FFFFFF)],
    stops: [0.0, 0.5, 1.0],
    begin: Alignment(-1.0, -0.3),
    end: Alignment(1.0, 0.3),
  );
}
