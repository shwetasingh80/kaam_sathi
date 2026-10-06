import 'package:flutter/material.dart';

/// KaamSaathi brand palette (logo ke rang).
///
/// Rule: Yellow ke upar hamesha [charcoal] text — kabhi white nahi
/// (white-on-yellow contrast bahut kam hota hai).
class AppColors {
  AppColors._();

  // Brand
  static const yellow = Color(0xFFFFB800); // Primary Yellow (Peela)
  static const charcoal = Color(0xFF1F2937); // Gahra Kaala/Neela
  static const cream = Color(0xFFFFF9EE); // Halka Cream Background

  // Accents
  static const orange = Color(0xFFFF8A00);
  static const green = Color(0xFF16A34A);
  static const red = Color(0xFFEF4444);

  // Tints (soft backgrounds for cards / chips)
  static const yellowTint = Color(0xFFFFF1C7);
  static const yellowSoft = Color(0xFFFFE08A);
  static const orangeTint = Color(0xFFFFEBD3);
  static const greenTint = Color(0xFFDCF5E3);
  static const redTint = Color(0xFFFDE3E3);
  static const blueTint = Color(0xFFE3ECF7);

  // Darker variants for *text* on tints (keeps contrast >= 4.5:1)
  static const greenDark = Color(0xFF15803D);
  static const redDark = Color(0xFFB91C1C);
  static const orangeDark = Color(0xFFB45309);
  static const blueDark = Color(0xFF1E40AF);

  // Neutrals
  static const white = Color(0xFFFFFFFF);
  static const surface = Color(0xFFFFFFFF);
  static const charcoalSoft = Color(0xFF374151);
  static const muted = Color(0xFF5B6472);
  static const border = Color(0xFFF0E4C8);
  static const divider = Color(0xFFEDE5D3);
  static const disabled = Color(0xFFD9D4C7);
}
