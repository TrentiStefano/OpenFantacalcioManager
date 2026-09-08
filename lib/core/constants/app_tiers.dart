import 'package:flutter/material.dart';

class AppTiers {
  static const String top = 'TOP';
  static const String semiTop = 'SEMITOP';
  static const String terzoSlot = 'TERZO-SLOT';
  static const String quartoSlot = 'QUARTO-SLOT';
  static const String titolari = 'TITOLARI';
  static const String scommesse = 'SCOMMESSE';
  static const String altri = 'ALTRI';

  static const List<String> defaultTiers = [
    top,
    semiTop,
    terzoSlot,
    quartoSlot,
    titolari,
    scommesse,
    altri,
  ];

  static const List<String> goalkeeperTiers = [
    top,
    semiTop,
    terzoSlot,
    altri,
  ];

  static int getPriority(String? tier) {
    if (tier == null || tier.isEmpty) return 999;
    final t = tier.toUpperCase().trim();
    switch (t) {
      case top:
        return 1;
      case semiTop:
        return 2;
      case terzoSlot:
        return 3;
      case quartoSlot:
        return 4;
      case titolari:
        return 5;
      case scommesse:
        return 6;
      case altri:
        return 7;
      default:
        return 50;
    }
  }

  static Color getTierColor(String? tier) {
    if (tier == null || tier.isEmpty) return Colors.grey;
    final t = tier.toUpperCase().trim();
    switch (t) {
      case top:
        return const Color(0xFFE11D48); // Rose / Ruby
      case semiTop:
        return const Color(0xFFF97316); // Orange
      case terzoSlot:
        return const Color(0xFFF59E0B); // Amber
      case quartoSlot:
        return const Color(0xFF10B981); // Emerald
      case titolari:
        return const Color(0xFF06B6D4); // Cyan
      case scommesse:
        return const Color(0xFF8B5CF6); // Purple
      case altri:
        return const Color(0xFF64748B); // Slate
      default:
        return Colors.blueGrey;
    }
  }
}
