import 'package:flutter/material.dart';

class AppColors {
  // Brand / Serie A inspired palette
  static const Color primary = Color(0xFF0F52BA); // Sapphire Blue
  static const Color primaryLight = Color(0xFF3B82F6);
  static const Color primaryDark = Color(0xFF0A367A);
  
  static const Color accent = Color(0xFF00A86B); // Serie A Jade Green
  static const Color accentLight = Color(0xFF10B981);
  
  // Role Colors (Classic Italian Fantacalcio)
  static const Color roleP = Color(0xFFF59E0B); // Amber / Orange for Portiere
  static const Color roleD = Color(0xFF10B981); // Emerald Green for Difensore
  static const Color roleC = Color(0xFF3B82F6); // Blue for Centrocampista
  static const Color roleA = Color(0xFFEF4444); // Red for Attaccante

  // Role Backgrounds (Soft tints for light theme badges)
  static const Color rolePBgLight = Color(0xFFFEF3C7);
  static const Color roleDBgLight = Color(0xFFD1FAE5);
  static const Color roleCBgLight = Color(0xFFDBEAFE);
  static const Color roleABgLight = Color(0xFFFEE2E2);

  // Status Colors
  static const Color statusAvailable = Color(0xFF64748B); // Slate
  static const Color statusMine = Color(0xFF10B981);      // Green (Won by me)
  static const Color statusOthers = Color(0xFFEF4444);    // Red (Taken by others)

  // Star Favorite
  static const Color starActive = Color(0xFFFBBF24); // Warm Gold

  // Surface & Neutrals Light
  static const Color lightBg = Color(0xFFF8FAFC);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightBorder = Color(0xFFE2E8F0);
  static const Color lightTextPrimary = Color(0xFF0F172A);
  static const Color lightTextSecondary = Color(0xFF64748B);

  // Surface & Neutrals Dark
  static const Color darkBg = Color(0xFF0B0F19);
  static const Color darkSurface = Color(0xFF111827);
  static const Color darkCard = Color(0xFF1F2937);
  static const Color darkBorder = Color(0xFF374151);
  static const Color darkTextPrimary = Color(0xFFF9FAFB);
  static const Color darkTextSecondary = Color(0xFF9CA3AF);

  static Color getRoleColor(String role) {
    final r = role.toUpperCase().trim();
    if (r.startsWith('P')) return roleP;
    if (r.startsWith('D')) return roleD;
    if (r.startsWith('C')) return roleC;
    if (r.startsWith('A')) return roleA;
    return primary;
  }

  static Color getRoleBgColor(String role, bool isDark) {
    final r = role.toUpperCase().trim();
    if (isDark) {
      if (r.startsWith('P')) return const Color(0xFF451A03);
      if (r.startsWith('D')) return const Color(0xFF064E3B);
      if (r.startsWith('C')) return const Color(0xFF1E3A8A);
      if (r.startsWith('A')) return const Color(0xFF450A0A);
      return const Color(0xFF1E293B);
    } else {
      if (r.startsWith('P')) return rolePBgLight;
      if (r.startsWith('D')) return roleDBgLight;
      if (r.startsWith('C')) return roleCBgLight;
      if (r.startsWith('A')) return roleABgLight;
      return const Color(0xFFF1F5F9);
    }
  }
}
