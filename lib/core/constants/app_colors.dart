import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static bool isDarkMode = false;

  // Primary
  static Color get primary => isDarkMode ? const Color(0xFF27AE60) : const Color(0xFF006D37);
  static Color get primaryDim => isDarkMode ? const Color(0xFF1E8449) : const Color(0xFF00602F);
  static Color get primaryContainer => isDarkMode ? const Color(0xFF114A29) : const Color(0xFF7EFBA4);
  static Color get onPrimary => const Color(0xFFE3FFE4);
  static Color get onPrimaryContainer => isDarkMode ? const Color(0xFF7EFBA4) : const Color(0xFF005F2F);

  // Accent
  static Color get accent => const Color(0xFF27AE60);

  // Surface / Background
  static Color get surface => isDarkMode ? const Color(0xFF121212) : const Color(0xFFF9F9F9);
  static Color get surfaceContainerLow => isDarkMode ? const Color(0xFF1E1E1E) : const Color(0xFFF2F4F4);
  static Color get surfaceContainer => isDarkMode ? const Color(0xFF242424) : const Color(0xFFEBEEEF);
  static Color get surfaceContainerHigh => isDarkMode ? const Color(0xFF2A2A2A) : const Color(0xFFE4E9EA);
  static Color get surfaceContainerHighest => isDarkMode ? const Color(0xFF323232) : const Color(0xFFDDE4E5);

  // On-Surface
  static Color get onSurface => isDarkMode ? const Color(0xFFE1E1E1) : const Color(0xFF2D3435);
  static Color get onSurfaceVariant => isDarkMode ? const Color(0xFFAAAAAA) : const Color(0xFF596061);

  // Outline
  static Color get outline => const Color(0xFF757C7D);
  static Color get outlineVariant => isDarkMode ? const Color(0xFF4A4A4A) : const Color(0xFFACB3B4);

  // Error
  static Color get error => isDarkMode ? const Color(0xFFCF6679) : const Color(0xFF9F403D);

  // Tertiary
  static Color get tertiaryContainer => isDarkMode ? const Color(0xFF2A3D32) : const Color(0xFFDAFCE6);
  static Color get onTertiaryContainer => isDarkMode ? const Color(0xFF81BCA0) : const Color(0xFF446252);

  // Misc
  static Color get white => const Color(0xFFFFFFFF);
  static Color get black => const Color(0xFF000000);
  static Color get chipBackground => isDarkMode ? const Color(0xFFE1E1E1) : const Color(0xFF2D3435);
  static Color get chipText => isDarkMode ? const Color(0xFF121212) : const Color(0xFFF9F9F9);
}
