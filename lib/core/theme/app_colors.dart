import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // --- Brand Accents (Electric Lime & Neo-FinTech) ---
  static const primary = Color(0xFFD8FF3F); // Electric Neon Lime
  static const primaryLight = Color(0xFFE8FF70);
  static const primaryDark = Color(0xFFBCE600);
  static const primaryNeon = Color(0xFFD4FF00);

  // Signature Hero Card (Electric Lime)
  static const limeCardBg = Color(0xFFD8FF3F);
  static const limeCardText = Color(0xFF0E0E10);
  static const limeCardMuted = Color(0xFF424A10);

  // Status & Category Accents
  static const green = Color(0xFF22C55E); // Credit / Income
  static const greenLight = Color(0xFF86EFAC);
  static const red = Color(0xFFFF453A); // Debit / Expense
  static const redLight = Color(0xFFFCA5A5);
  static const blue = Color(0xFF3B82F6); // Digital / Cards
  static const teal = Color(0xFF14B8A6); // Growth / Wallets
  static const orange = Color(0xFFFB923C); // Amber / Bills
  static const purple = Color(0xFFA855F7);
  static const pink = Color(0xFFF472B6);
  static const yellow = Color(0xFFFBBF24);

  // --- Dark mode (Deep Obsidian & Charcoal Surface) ---
  static const darkBackground = Color(0xFF0E0E10);
  static const darkBgStart = Color(0xFF1A2208); // Subtle top electric lime ambient glow
  static const darkBgMid = Color(0xFF10120A);
  static const darkBgEnd = Color(0xFF0E0E10); // Solid Deep Obsidian base
  
  static const darkCardBg = Color(0xFF18181C); // Solid Dark Charcoal card
  static const darkCardBorder = Color(0xFF282830); // Clean subtle divider border
  static const darkCardElevated = Color(0xFF222228);
  static const darkInputBg = Color(0xFF121216);
  
  static const darkTextPrimary = Colors.white;
  static const darkTextSecondary = Color(0xFF9E9EA8); // Clean cool grey
  static const darkTextMuted = Color(0xFF62626E);

  static const darkGlassFill = Color(0x1AD8FF3F);
  static const darkGlassFillStrong = Color(0xFF18181C);
  static const darkGlassBorder = Color(0x2BD8FF3F);

  // --- Light mode (Clean Mint / Slate Surface) ---
  static const lightBackground = Color(0xFFF4F7EE);
  static const lightBgStart = Color(0xFFFAFDF5);
  static const lightBgMid = Color(0xFFF4F7EE);
  static const lightBgEnd = Color(0xFFECF1E4);

  static const lightCardBg = Colors.white;
  static const lightCardBorder = Color(0xFFE2E8F0);
  static const lightCardElevated = Color(0xFFF8FAFC);
  static const lightInputBg = Color(0xFFF1F5F9);

  static const lightTextPrimary = Color(0xFF0F172A); // Deep Slate 900
  static const lightTextSecondary = Color(0xFF475569); // Slate 600
  static const lightTextMuted = Color(0xFF94A3B8); // Slate 400

  static const lightGlassFill = Color(0xE6FFFFFF);
  static const lightGlassFillStrong = Colors.white;
  static const lightGlassBorder = Color(0xFFE2E8F0);

  // High-contrast Light Mode Accents (Forest Emerald & Deep Teal)
  static const lightAccentGreen = Color(0xFF15803D); // Deep Forest Green (WCAG AAA)
  static const lightAccentTeal = Color(0xFF0D9488);
  static const lightIncomeGreen = Color(0xFF059669); // Crisp Emerald
  static const lightExpenseRed = Color(0xFFDC2626);

  // --- Adaptive Helpers ---
  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static Color textPrimary(BuildContext context) =>
      isDark(context) ? darkTextPrimary : lightTextPrimary;

  static Color textSecondary(BuildContext context) =>
      isDark(context) ? darkTextSecondary : lightTextSecondary;

  static Color textMuted(BuildContext context) =>
      isDark(context) ? darkTextMuted : lightTextMuted;

  static Color cardBg(BuildContext context) =>
      isDark(context) ? darkCardBg : lightCardBg;

  static Color cardBorder(BuildContext context) =>
      isDark(context) ? darkCardBorder : lightCardBorder;

  static Color cardElevated(BuildContext context) =>
      isDark(context) ? darkCardElevated : lightCardElevated;

  static Color inputBg(BuildContext context) =>
      isDark(context) ? darkInputBg : lightInputBg;

  static Color background(BuildContext context) =>
      isDark(context) ? darkBackground : lightBackground;

  static Color incomeColor(BuildContext context) =>
      isDark(context) ? green : lightIncomeGreen;

  static Color expenseColor(BuildContext context) =>
      isDark(context) ? red : lightExpenseRed;

  static Color accentLinkColor(BuildContext context) =>
      isDark(context) ? primary : lightAccentGreen;

  static Color accentIconColor(BuildContext context) =>
      isDark(context) ? primaryLight : lightAccentGreen;

  /// Ensures that bright neon colors (like electric lime #CCFF00 / #D8FF3F)
  /// are converted to a deep legible emerald green in light mode.
  static Color ensureContrast(Color color, BuildContext context) {
    if (isDark(context)) return color;
    final lum = color.computeLuminance();
    if (lum > 0.55) {
      return lightAccentGreen;
    }
    return color;
  }
}

/// Handy extension on [BuildContext] for ergonomic theme-aware styling
extension AppThemeContextExtension on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
  Color get textPrimary => AppColors.textPrimary(this);
  Color get textSecondary => AppColors.textSecondary(this);
  Color get textMuted => AppColors.textMuted(this);
  Color get cardBg => AppColors.cardBg(this);
  Color get cardBorder => AppColors.cardBorder(this);
  Color get cardElevated => AppColors.cardElevated(this);
  Color get inputBg => AppColors.inputBg(this);
  Color get appBg => AppColors.background(this);
  Color get background => appBg;
  Color get incomeColor => AppColors.incomeColor(this);
  Color get expenseColor => AppColors.expenseColor(this);
  Color get accentLinkColor => AppColors.accentLinkColor(this);
  Color get accentIconColor => AppColors.accentIconColor(this);
  Color adaptiveContrast(Color color) => AppColors.ensureContrast(color, this);
}
