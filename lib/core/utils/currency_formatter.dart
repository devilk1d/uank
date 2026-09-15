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

  /// Formats a raw number or string into a thousands-separated string (e.g., 20000 -> "20.000").
  static String format(num value, {String separator = '.'}) {
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

  /// Parses a formatted string back into a numeric value (e.g., "20.000" -> 20000).
  static num parse(String text) {
    final clean = text.replaceAll(RegExp(r'[^\d]'), '');
    return num.tryParse(clean) ?? 0;
  }
}
