import 'package:flutter/services.dart';

/// Formatter that automatically inserts thousands separators (e.g., `20000` -> `20.000`)
/// and strictly restricts input to digits only.
class CurrencyInputFormatter extends TextInputFormatter {
  final String separator;

  CurrencyInputFormatter({this.separator = '.'});

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    String text = newValue.text;
    int cursorPosition = newValue.selection.end;

    // Handle backspacing a separator (e.g. backspacing the dot in "200.000")
    if (oldValue.text.length == newValue.text.length + 1 &&
        oldValue.selection.end > 0 &&
        oldValue.selection.isCollapsed &&
        oldValue.text[oldValue.selection.end - 1] == separator) {
      final deleteIndex = oldValue.selection.end - 2;
      if (deleteIndex >= 0) {
        text = oldValue.text.substring(0, deleteIndex) +
            oldValue.text.substring(oldValue.selection.end);
        cursorPosition = deleteIndex;
      }
    }

    // Strip everything except digits
    String digitsOnly = text.replaceAll(RegExp(r'[^\d]'), '');

    if (digitsOnly.isEmpty) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }

    // Format with thousands separator
    final buffer = StringBuffer();
    for (int i = 0; i < digitsOnly.length; i++) {
      if (i > 0 && (digitsOnly.length - i) % 3 == 0) {
        buffer.write(separator);
      }
      buffer.write(digitsOnly[i]);
    }

    final formattedText = buffer.toString();

    // Calculate how many digits were before the cursor
    int digitsBeforeCursor = 0;
    for (int i = 0; i < cursorPosition && i < text.length; i++) {
      if (RegExp(r'\d').hasMatch(text[i])) {
        digitsBeforeCursor++;
      }
    }

    // Map to corresponding position in formattedText
    int newCursorOffset = 0;
    int digitCount = 0;
    for (int i = 0; i < formattedText.length; i++) {
      if (digitCount == digitsBeforeCursor) {
        newCursorOffset = i;
        break;
      }
      if (formattedText[i] != separator) {
        digitCount++;
      }
      newCursorOffset = i + 1;
    }

    return TextEditingValue(
      text: formattedText,
      selection: TextSelection.collapsed(offset: newCursorOffset.clamp(0, formattedText.length)),
    );
  }

  /// Formats a raw number into a formatted string (e.g. 20000 -> "20.000", 6.39 -> "6.39").
  static String format(num value, {String? currency, String separator = '.'}) {
    if (currency == 'MYR' || value % 1 != 0) {
      if (value % 1 == 0) {
        final s = value.toStringAsFixed(0);
        final buffer = StringBuffer();
        for (int i = 0; i < s.length; i++) {
          if (i > 0 && (s.length - i) % 3 == 0) buffer.write(',');
          buffer.write(s[i]);
        }
        return buffer.toString();
      }
      final parts = value.toStringAsFixed(2).split('.');
      final s = parts[0];
      final buffer = StringBuffer();
      for (int i = 0; i < s.length; i++) {
        if (i > 0 && (s.length - i) % 3 == 0) buffer.write(',');
        buffer.write(s[i]);
      }
      // Trim trailing zero if .x0 or keep 2 decimals
      return '${buffer.toString()}.${parts[1]}';
    }

    final s = value.toStringAsFixed(0);
    final buffer = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) {
        buffer.write(separator);
      }
      buffer.write(s[i]);
    }
    return buffer.toString();
  }

  /// Parses a formatted string back into a numeric value (e.g., "20.000" -> 20000, "6.39" -> 6.39).
  static num parse(String text, {String? currency}) {
    if (text.trim().isEmpty) return 0;

    final trimmed = text.trim();

    // 1. Explicit IDR handling: dot is thousands, comma is decimal
    if (currency == 'IDR') {
      if (RegExp(r',\d{1,2}$').hasMatch(trimmed)) {
        final clean = trimmed.replaceAll('.', '').replaceAll(',', '.');
        return num.tryParse(clean) ?? 0;
      }
      final clean = trimmed.replaceAll('.', '').replaceAll(',', '');
      return num.tryParse(clean) ?? 0;
    }

    // 2. Explicit MYR handling: comma is thousands, dot is decimal
    if (currency == 'MYR') {
      final clean = trimmed.replaceAll(',', '');
      return num.tryParse(clean) ?? 0;
    }

    // 3. Heuristic when currency is null/unknown:
    // Indonesian pattern: multiple dots (1.500.000) or comma decimal with dots (150.000,50)
    if (RegExp(r'\.\d{3}\.').hasMatch(trimmed) || RegExp(r'\.\d{3},\d{1,2}$').hasMatch(trimmed)) {
      final clean = trimmed.replaceAll('.', '').replaceAll(',', '.');
      return num.tryParse(clean) ?? 0;
    }

    // Standard English decimal: e.g. 6.39, 1,250.50, 10.5
    if (RegExp(r'^\d{1,3}(,\d{3})*\.\d{1,2}$|^\d+\.\d{1,2}$').hasMatch(trimmed)) {
      final clean = trimmed.replaceAll(',', '');
      return num.tryParse(clean) ?? 0;
    }

    // Indonesian 3-digit thousand dot at end without decimal: 150.000
    if (RegExp(r'^\d{1,3}\.\d{3}$').hasMatch(trimmed)) {
      final clean = trimmed.replaceAll('.', '');
      return num.tryParse(clean) ?? 0;
    }

    // Fallback
    final clean = trimmed.replaceAll(',', '');
    return num.tryParse(clean) ?? 0;
  }
}
