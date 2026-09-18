import 'dart:ui' show Size;
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class OcrResult {
  final double? amount;
  final String? currency; // 'IDR' or 'MYR'
  final String? merchant;
  final DateTime? date;
  final String rawText;

  const OcrResult({
    this.amount,
    this.currency,
    this.merchant,
    this.date,
    required this.rawText,
  });

  bool get hasData => amount != null || merchant != null || date != null;
}

class ReceiptOcrParser {
  static final _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

  /// Scan receipt or payment screenshot from file path
  static Future<OcrResult> parseReceiptFromFile(String filePath) async {
    try {
      final inputImage = InputImage.fromFilePath(filePath);
      return await _processImage(inputImage);
    } catch (e) {
      debugPrint('[ReceiptOcrParser] parseReceiptFromFile error: $e');
      return const OcrResult(rawText: '');
    }
  }

  /// Scan receipt or payment screenshot from memory bytes
  static Future<OcrResult> parseReceiptFromBytes(Uint8List bytes) async {
    try {
      final inputImage = InputImage.fromBytes(
        bytes: bytes,
        metadata: InputImageMetadata(
          size: const Size(1080, 1920),
          rotation: InputImageRotation.rotation0deg,
          format: InputImageFormat.nv21,
          bytesPerRow: 1080,
        ),
      );
      return await _processImage(inputImage);
    } catch (e) {
      debugPrint('[ReceiptOcrParser] parseReceiptFromBytes error: $e');
      return const OcrResult(rawText: '');
    }
  }

  static Future<OcrResult> _processImage(InputImage inputImage) async {
    try {
      final RecognizedText recognizedText = await _textRecognizer.processImage(inputImage);
      debugPrint('[ReceiptOcrParser] Recognized text:\n${recognizedText.text}');
      final result = parseText(recognizedText.text);
      debugPrint('[ReceiptOcrParser] Parsed: amount=${result.amount}, currency=${result.currency}, merchant=${result.merchant}, date=${result.date}');
      return result;
    } catch (e) {
      debugPrint('[ReceiptOcrParser] _processImage error: $e');
      return const OcrResult(rawText: '');
    }
  }

  /// Parse raw string from OCR
  static OcrResult parseText(String rawText) {
    if (rawText.trim().isEmpty) {
      return const OcrResult(rawText: '');
    }

    final lines = rawText
        .split(RegExp(r'[\r\n]+'))
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    final currency = _detectCurrency(rawText);
    final amount = _detectAmount(lines, currency);
    final date = _detectDate(rawText);
    final merchant = _detectMerchant(lines);

    return OcrResult(
      amount: amount,
      currency: currency,
      merchant: merchant,
      date: date,
      rawText: rawText,
    );
  }

  static void dispose() {
    _textRecognizer.close();
  }

  // --- Currency Detection ---
  static String? _detectCurrency(String text) {
    final upper = text.toUpperCase();

    int myrScore = 0;
    int idrScore = 0;

    // Malaysian bank / e-wallet / keywords
    if (RegExp(r'\bRM\b|\bMYR\b|RINGGIT|DUITNOW|TOUCH\s*N\s*GO|TNG|MAYBANK|CIMB|PUBLIC\s*BANK|RHB|AMBANK|HONG\s*LEONG|BIGPAY|GRABPAY').hasMatch(upper)) {
      myrScore += 4;
    }

    // Indonesian bank / e-wallet / keywords
    if (RegExp(r'\bRP\b|\bIDR\b|RUPIAH|BCA|MANDIRI|LIVIN|BRIMO|BRI|BNI|QRIS|GOPAY|OVO|DANA|SHOPEEPAY|LINKAJA|SEABANK|JAGO|JENIUS|BSI|FLIP').hasMatch(upper)) {
      idrScore += 4;
    }

    // Check number formatting hints
    // IDR standard dot thousands: 15.000, 150.000
    if (RegExp(r'\b\d{1,3}\.\d{3}\b').hasMatch(text)) {
      idrScore += 2;
    }
    // MYR standard 2 decimals: 15.50, 4.00, 120.00
    if (RegExp(r'\b\d+\.\d{2}\b').hasMatch(text) && !RegExp(r'\b\d+\.\d{3}\b').hasMatch(text)) {
      myrScore += 2;
    }

    if (myrScore > idrScore) return 'MYR';
    if (idrScore > myrScore) return 'IDR';
    return null;
  }

  // --- Amount Detection ---
  static double? _detectAmount(List<String> lines, String? currency) {
    final candidates = <_AmountCandidate>[];

    // Ultra high score keywords for screenshots and receipts
    final grandTotalRegex = RegExp(
      r'(TOTAL\s*PEMBAYARAN|TOTAL\s*TRANSAKSI|TOTAL\s*TRANSFER|TOTAL\s*TAGIHAN|TOTAL\s*BAYAR|TOTAL\s*AMOUNT|TOTAL\s*HARGA|GRAND\s*TOTAL|NOMINAL\s*TRANSFER|NOMINAL\s*TRANSAKSI|JUMLAH\s*TRANSFER|JUMLAH\s*PEMBAYARAN|JUMLAH\s*DITRANSFER|NILAI\s*TRANSAKSI|AMOUNT\s*TRANSFERRED|TRANSFER\s*AMOUNT|TOTAL\s*DIBAYAR|BERHASIL\s*DITRANSFER|PEMBAYARAN\s*SUKSES|TRANSAKSI\s*BERHASIL|PEMBAYARAN\s*BERHASIL|STATUS\s*BERHASIL|TRANSFER\s*BERHASIL|TOTAL\s*BELANJA|TOTAL\s*PURCHASE)',
      caseSensitive: false,
    );

    // Standard total keywords
    final totalRegex = RegExp(
      r'(^|\s)(TOTAL|JUMLAH|NOMINAL|AMOUNT|BAYAR|TAGIHAN|HARGA|NET|SUBTOTAL)(\s|$|:)',
      caseSensitive: false,
    );

    // Negative keywords: items that are NOT the main transaction amount
    final negativeRegex = RegExp(
      r'(KEMBALI|CHANGE|CASH\s*RECEIVED|TUNAI\s*DITERIMA|BAYAR\s*TUNAI|UANG\s*DITERIMA|RECEIVED|TENDERED|SISA\s*SALDO|SALDO\s*AWAL|SALDO\s*AKHIR|ENDING\s*BALANCE|AVAILABLE\s*BALANCE|SALDO\s*REKENING|PPN|TAX|PAJAK|DISKON|DISCOUNT|PROMO|POTONGAN|VOUCHER|CASHBACK|BIAYA\s*ADMIN|ADMIN\s*FEE|FEE|BIAYA\s*LAYANAN|BIAYA\s*TRANSAKSI)',
      caseSensitive: false,
    );

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      final lineUpper = line.toUpperCase();

      // Determine line weight
      int baseScore = 0;
      if (grandTotalRegex.hasMatch(lineUpper)) {
        baseScore += 120;
      } else if (totalRegex.hasMatch(lineUpper)) {
        baseScore += 70;
      }

      if (negativeRegex.hasMatch(lineUpper)) {
        baseScore -= 100;
      }

      // If line contains currency symbols, boost score
      if (RegExp(r'\bRP\b|\bIDR\b|\bRM\b|\bMYR\b', caseSensitive: false).hasMatch(lineUpper)) {
        baseScore += 35;
      }

      // Extract numbers on this line
      final numbersOnLine = _extractNumbersFromLine(line, currency);
      for (final numVal in numbersOnLine) {
        if (numVal > 0) {
          candidates.add(_AmountCandidate(
            value: numVal,
            score: baseScore + (i <= 10 ? 15 : 5), // Mobile bank screenshots display amount in top/middle
            lineIndex: i,
          ));
        }
      }

      // If this line had a total keyword but the number was on the NEXT line (common in mobile apps)
      if (baseScore > 0 && numbersOnLine.isEmpty && i + 1 < lines.length) {
        final nextLineNumbers = _extractNumbersFromLine(lines[i + 1], currency);
        for (final numVal in nextLineNumbers) {
          if (numVal > 0) {
            candidates.add(_AmountCandidate(
              value: numVal,
              score: baseScore - 5,
              lineIndex: i + 1,
            ));
          }
        }
      }
    }

    if (candidates.isEmpty) return null;

    // Sort by score descending, then by value
    candidates.sort((a, b) {
      final scoreCompare = b.score.compareTo(a.score);
      if (scoreCompare != 0) return scoreCompare;
      return b.value.compareTo(a.value);
    });

    final best = candidates.first;
    if (best.value > 0) {
      return best.value;
    }

    return null;
  }

  static List<double> _extractNumbersFromLine(String line, String? currency) {
    final results = <double>[];

    // Clean OCR artifacts
    var cleaned = line
        .replaceAll(RegExp(r'(?<=\d)[oO](?=\d)'), '0')
        .replaceAll(RegExp(r'(?<=\d)[lI](?=\d)'), '1')
        .replaceAll(RegExp(r',\s*-'), '') // Remove trailing ,- or .-
        .replaceAll(RegExp(r'\.\s*-'), '');

    // 1. Indonesian style: Rp 150.000 or 150.000,00 or Rp. 15.000 or 15.000
    final idrMatches = RegExp(r'(?:Rp\.?|IDR)?\s*([0-9]{1,3}(?:\.[0-9]{3})+(?:,[0-9]{2})?)').allMatches(cleaned);
    for (final m in idrMatches) {
      final str = m.group(1);
      if (str != null) {
        final normalized = str.replaceAll('.', '').replaceAll(',', '.');
        final val = double.tryParse(normalized);
        if (val != null && val > 0) results.add(val);
      }
    }

    // 2. Comma thousands style: Rp 150,000 or IDR 150,000 or 150,000.00
    final commaThousands = RegExp(r'(?:Rp\.?|IDR)?\s*([0-9]{1,3}(?:,[0-9]{3})+(?:\.[0-9]{2})?)').allMatches(cleaned);
    for (final m in commaThousands) {
      final str = m.group(1);
      if (str != null) {
        final normalized = str.replaceAll(',', '');
        final val = double.tryParse(normalized);
        if (val != null && val > 0 && !results.contains(val)) results.add(val);
      }
    }

    // 3. Malaysian / standard decimal style: RM 45.50 or RM45.50 or 45.50
    final myrMatches = RegExp(r'(?:RM|MYR)?\s*([0-9]{1,3}(?:,[0-9]{3})*\.[0-9]{2})\b').allMatches(cleaned);
    for (final m in myrMatches) {
      final str = m.group(1);
      if (str != null) {
        final normalized = str.replaceAll(',', '');
        final val = double.tryParse(normalized);
        if (val != null && val > 0 && !results.contains(val)) results.add(val);
      }
    }

    // 4. Standalone plain number with currency prefix: Rp 50000 or IDR 50000 or RM 50
    final prefixedMatches = RegExp(r'(?:Rp\.?|IDR|RM|MYR)\s*([0-9]+(?:\.[0-9]{2})?)\b', caseSensitive: false).allMatches(cleaned);
    for (final m in prefixedMatches) {
      final str = m.group(1);
      if (str != null) {
        final val = double.tryParse(str);
        if (val != null && val > 0 && !results.contains(val)) results.add(val);
      }
    }

    // 5. Fallback: plain integers if 4+ digits
    if (results.isEmpty) {
      final plainMatches = RegExp(r'\b([1-9][0-9]{2,8})\b').allMatches(cleaned);
      for (final m in plainMatches) {
        final str = m.group(1);
        if (str != null) {
          final val = double.tryParse(str);
          if (val != null && val > 0) {
            // Filter out phone numbers or years (2020-2030) unless on amount line
            if (val >= 2020 && val <= 2030 && !line.toUpperCase().contains('RP') && !line.toUpperCase().contains('TOTAL') && !line.toUpperCase().contains('NOMINAL')) {
              continue;
            }
            results.add(val);
          }
        }
      }
    }

    return results;
  }

  // --- Date Detection ---
  static DateTime? _detectDate(String text) {
    // 1. DD/MM/YYYY or DD-MM-YYYY or DD.MM.YYYY
    final dmyMatch = RegExp(r'\b(\d{1,2})[\/\.-](\d{1,2})[\/\.-](\d{4})\b').firstMatch(text);
    if (dmyMatch != null) {
      final day = int.tryParse(dmyMatch.group(1)!);
      final month = int.tryParse(dmyMatch.group(2)!);
      final year = int.tryParse(dmyMatch.group(3)!);
      if (day != null && month != null && year != null) {
        if (year >= 2020 && year <= 2030 && month >= 1 && month <= 12 && day >= 1 && day <= 31) {
          return DateTime(year, month, day);
        }
      }
    }

    // 2. YYYY-MM-DD or YYYY/MM/DD
    final ymdMatch = RegExp(r'\b(\d{4})[\/\.-](\d{1,2})[\/\.-](\d{1,2})\b').firstMatch(text);
    if (ymdMatch != null) {
      final year = int.tryParse(ymdMatch.group(1)!);
      final month = int.tryParse(ymdMatch.group(2)!);
      final day = int.tryParse(ymdMatch.group(3)!);
      if (day != null && month != null && year != null) {
        if (year >= 2020 && year <= 2030 && month >= 1 && month <= 12 && day >= 1 && day <= 31) {
          return DateTime(year, month, day);
        }
      }
    }

    // 3. DD Mon YYYY / DD Month YYYY (Indonesian, English, Malay)
    final monthNames = {
      'JAN': 1, 'FEB': 2, 'MAR': 3, 'APR': 4, 'MEI': 5, 'MAY': 5, 'JUN': 6,
      'JUL': 7, 'AGU': 8, 'AUG': 8, 'SEP': 9, 'OKT': 10, 'OCT': 10, 'NOV': 11, 'DES': 12, 'DEC': 12,
      'MAC': 3, 'OGOS': 8,
    };
    final textMonthMatch = RegExp(
      r'\b(\d{1,2})\s+([A-Za-z]{3,10})\s+(\d{4})\b',
    ).firstMatch(text);

    if (textMonthMatch != null) {
      final day = int.tryParse(textMonthMatch.group(1)!);
      final rawMonth = textMonthMatch.group(2)!.toUpperCase();
      final monthPrefix = rawMonth.substring(0, rawMonth.length >= 3 ? 3 : rawMonth.length);
      final year = int.tryParse(textMonthMatch.group(3)!);
      final month = monthNames[monthPrefix];
      if (day != null && month != null && year != null) {
        if (year >= 2020 && year <= 2030 && day >= 1 && day <= 31) {
          return DateTime(year, month, day);
        }
      }
    }

    return null;
  }

  // --- Merchant / Receiver / Note Detection ---
  static String? _detectMerchant(List<String> lines) {
    // 1. Look for explicit recipient / destination labels in screenshots
    final labelPattern = RegExp(
      r'^(PENERIMA|TRANSFER\s*KE|KE|KEPADA|TUJUAN|MERCHANT|NAMA\s*PENERIMA|BAYAR\s*KE|TO|RECIPIENT|PAID\s*TO|BENEFICIARY\s*NAME|BENEFICIARY)\s*[:\s-]+\s*(.+)$',
      caseSensitive: false,
    );

    for (final line in lines) {
      final match = labelPattern.firstMatch(line.trim());
      if (match != null) {
        final extracted = match.group(2)?.trim();
        if (extracted != null && extracted.length >= 2 && !RegExp(r'^\d+$').hasMatch(extracted)) {
          // Clean up account numbers (4+ digits) or symbols
          final cleaned = extracted.replaceAll(RegExp(r'^\d{4,}\s*[-/]?\s*'), '').trim();
          if (cleaned.isNotEmpty) return cleaned;
        }
      }
    }

    // 2. Look for Notes / Reference labels in screenshots
    final notesPattern = RegExp(
      r'^(CATATAN|KETERANGAN|NOTES|NOTE|BERITA|REFERENCE|REF)\s*[:\s-]+\s*(.+)$',
      caseSensitive: false,
    );
    for (final line in lines) {
      final match = notesPattern.firstMatch(line.trim());
      if (match != null) {
        final extracted = match.group(2)?.trim();
        if (extracted != null && extracted.length >= 2) {
          return extracted;
        }
      }
    }

    // 3. Fallback: inspect top 5 lines of physical receipts
    final noiseKeywords = RegExp(
      r'(STRUK|RECEIPT|NOTA|SALINAN|BUKTI|TRANSFER\s*BERHASIL|TRANSAKSI\s*BERHASIL|TRANSAKSI\s*SUKSES|PEMBAYARAN\s*BERHASIL|PEMBAYARAN\s*SUKSES|SUCCESSFUL|SUCCESS|BERHASIL|PAYMENT\s*RECEIPT|TAX\s*INVOICE|INVOICE|WELCOME|TERIMA\s*KASIH|THANK\s*YOU|CUSTOMER\s*COPY|MERCHANT\s*COPY|TANGGAL|DATE|TIME|JAM|WAKTU|RINCIAN|DETAIL|STATUS)',
      caseSensitive: false,
    );

    for (int i = 0; i < lines.length && i < 6; i++) {
      final line = lines[i].trim();
      if (line.length >= 3 && line.length <= 40 && !noiseKeywords.hasMatch(line) && !RegExp(r'^\d+$').hasMatch(line)) {
        final cleaned = line.replaceAll(RegExp(r'[^\w\s\.\&\-]'), '').trim();
        if (cleaned.length >= 3) {
          return cleaned;
        }
      }
    }

    return null;
  }
}

class _AmountCandidate {
  final double value;
  final int score;
  final int lineIndex;

  _AmountCandidate({
    required this.value,
    required this.score,
    required this.lineIndex,
  });
}
