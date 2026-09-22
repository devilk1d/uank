import 'package:flutter/services.dart';

/// Formatter that allows numeric input with flexible decimal support (comma `,` or dot `.`),
/// restricting input to at most 1 decimal separator and 2 decimal digits.
class CurrencyInputFormatter extends TextInputFormatter {
  final bool allowDecimals;

  CurrencyInputFormatter({this.allowDecimals = true});

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    final text = newValue.text;

    // Strict integer mode if decimals are explicitly disabled
    if (!allowDecimals) {
      final digitsOnly = text.replaceAll(RegExp(r'[^\d]'), '');
      if (digitsOnly.length != text.length) {
        return oldValue;
      }
      return newValue;
    }

    // Disallow negative in positive amount fields
    if (text.startsWith('-')) {
      return oldValue;
    }

    // Count decimal separators (dots or commas)
    int separatorCount = 0;
    int lastSeparatorIndex = -1;
    for (int i = 0; i < text.length; i++) {
      if (text[i] == '.' || text[i] == ',') {
        separatorCount++;
        lastSeparatorIndex = i;
      } else if (!RegExp(r'\d').hasMatch(text[i])) {
        // Disallow any non-digit, non-separator character
        return oldValue;
      }
    }

    // At most 1 decimal separator allowed when typing directly
    if (separatorCount <= 1) {
      if (lastSeparatorIndex != -1) {
        final decimals = text.substring(lastSeparatorIndex + 1);
        if (decimals.length > 2) {
          // Limit to 2 decimal places (e.g. cents/sen)
          return oldValue;
        }
      }
      return newValue;
    }

    // If multiple separators exist (e.g. pasted formatted text like 1.500.000 or 1,250.50):
    final hasBoth = text.contains('.') && text.contains(',');
    if (hasBoth) {
      final lastSepIndex = text.lastIndexOf(RegExp(r'[.,]'));
      final decimals = text.substring(lastSepIndex + 1);
      if (decimals.length <= 2) {
        return newValue;
      }
      return oldValue;
    }

    return newValue;
  }

  /// Formats a raw number into a formatted string (e.g. 20000 -> "20.000", 10.50 -> "10.50", 14.31 -> "14.31").
  static String format(num value, {String? currency, String separator = '.'}) {
    if (value % 1 != 0) {
      // Value has decimal part (e.g. 10.50, 14.31) -> ALWAYS preserve 2 decimal places
      final parts = value.abs().toStringAsFixed(2).split('.');
      final intPart = parts[0];
      final buffer = StringBuffer();
      for (int i = 0; i < intPart.length; i++) {
        if (i > 0 && (intPart.length - i) % 3 == 0) {
          buffer.write(currency == 'MYR' ? ',' : separator);
        }
        buffer.write(intPart[i]);
      }
      final decSep = currency == 'MYR' ? '.' : '.';
      return '${value < 0 ? '-' : ''}${buffer.toString()}$decSep${parts[1]}';
    }

    // Pure Integer value (e.g. 20000, 1500000)
    final s = value.abs().toStringAsFixed(0);
    final buffer = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) {
        buffer.write(currency == 'MYR' ? ',' : separator);
      }
      buffer.write(s[i]);
    }
    return '${value < 0 ? '-' : ''}${buffer.toString()}';
  }

  /// Parses a formatted string back into a numeric value (e.g., "20.000" -> 20000, "10,50" -> 10.5, "14.31" -> 14.31, "-RM 14,31" -> -14.31).
  static num parse(String text, {String? currency}) {
    if (text.trim().isEmpty) return 0;

    // 1. Clean out currency labels, spaces, and unwanted characters (preserve digits, minus, dot, comma)
    var clean = text.trim().replaceAll(RegExp(r'[^\d.,\-]'), '');
    if (clean.isEmpty || clean == '-') return 0;

    final isNegative = clean.startsWith('-');
    if (isNegative) clean = clean.substring(1);

    // 2. If both '.' and ',' exist (e.g. 1.250,50 or 1,250.50):
    if (clean.contains('.') && clean.contains(',')) {
      final lastDot = clean.lastIndexOf('.');
      final lastComma = clean.lastIndexOf(',');
      if (lastComma > lastDot) {
        // 1.250,50 -> dot is thousands separator, comma is decimal separator
        clean = clean.replaceAll('.', '').replaceAll(',', '.');
      } else {
        // 1,250.50 -> comma is thousands separator, dot is decimal separator
        clean = clean.replaceAll(',', '');
      }
      final val = num.tryParse(clean) ?? 0;
      return isNegative ? -val : val;
    }

    // 3. If only ',' exists (e.g. "10,50", "14,31", "150,000"):
    if (clean.contains(',')) {
      final firstComma = clean.indexOf(',');
      final lastComma = clean.lastIndexOf(',');

      // Multiple commas (e.g. 1,500,000) -> thousands separators
      if (firstComma != lastComma) {
        clean = clean.replaceAll(',', '');
        final val = num.tryParse(clean) ?? 0;
        return isNegative ? -val : val;
      }

      final afterComma = clean.substring(lastComma + 1);

      // 1 or 2 digits after comma (e.g. 10,50 or 14,31 or 10,5) -> decimal separator!
      if (afterComma.length == 1 || afterComma.length == 2) {
        clean = clean.replaceAll(',', '.');
        final val = num.tryParse(clean) ?? 0;
        return isNegative ? -val : val;
      }

      // Exactly 3 digits after comma (e.g. 150,000) -> thousands separator
      if (afterComma.length == 3) {
        clean = clean.replaceAll(',', '');
        final val = num.tryParse(clean) ?? 0;
        return isNegative ? -val : val;
      }

      clean = clean.replaceAll(',', '.');
      final val = num.tryParse(clean) ?? 0;
      return isNegative ? -val : val;
    }

    // 4. If only '.' exists (e.g. "10.50", "14.31", "150.000", "1.500.000"):
    if (clean.contains('.')) {
      final firstDot = clean.indexOf('.');
      final lastDot = clean.lastIndexOf('.');

      // Multiple dots (e.g. 1.500.000) -> thousands separators
      if (firstDot != lastDot) {
        clean = clean.replaceAll('.', '');
        final val = num.tryParse(clean) ?? 0;
        return isNegative ? -val : val;
      }

      final afterDot = clean.substring(lastDot + 1);

      // 1 or 2 digits after dot (e.g. 10.50, 14.31, 10.5) -> decimal point!
      if (afterDot.length == 1 || afterDot.length == 2) {
        final val = num.tryParse(clean) ?? 0;
        return isNegative ? -val : val;
      }

      // Exactly 3 digits after dot (e.g. 150.000)
      if (afterDot.length == 3) {
        clean = clean.replaceAll('.', '');
        final val = num.tryParse(clean) ?? 0;
        return isNegative ? -val : val;
      }

      final val = num.tryParse(clean) ?? 0;
      return isNegative ? -val : val;
    }

    // 5. Plain integer
    final val = num.tryParse(clean) ?? 0;
    return isNegative ? -val : val;
  }
}
