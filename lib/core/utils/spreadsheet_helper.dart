import 'dart:convert';
import 'package:intl/intl.dart';

import '../../domain/entities/transaction.dart';
import '../../domain/entities/transfer.dart';

class ParsedSpreadsheetRow {
  final DateTime? date;
  final String rawDate;
  final String type; // 'income', 'expense', 'transfer'
  final String description;
  final String accountName;
  final String currency;
  final double amount;
  final String categoryName;
  final double? amountIdr;

  ParsedSpreadsheetRow({
    required this.date,
    required this.rawDate,
    required this.type,
    required this.description,
    required this.accountName,
    required this.currency,
    required this.amount,
    required this.categoryName,
    this.amountIdr,
  });
}

class SpreadsheetHelper {
  SpreadsheetHelper._();

  static String generateCsv({
    required List<Transaction> transactions,
    List<Transfer> transfers = const [],
    Map<String, String> accountNames = const {},
    Map<String, String> categoryNames = const {},
  }) {
    final buffer = StringBuffer();
    final dateFormat = DateFormat('yyyy-MM-dd');

    // CSV Header
    buffer.writeln('Tanggal,Tipe,Kategori,Keterangan,Akun / Sumber,Mata Uang,Nominal,Setara IDR');

    // 1. Transactions
    for (final tx in transactions) {
      final dateStr = dateFormat.format(tx.transactionDate);
      final typeStr = tx.type == 'income' ? 'Pemasukan (Income)' : 'Pengeluaran (Expense)';
      final catStr = tx.categoryId != null ? (categoryNames[tx.categoryId] ?? tx.categoryId!) : '-';
      final descStr = _escapeCsv(tx.description ?? '');
      final accStr = _escapeCsv(accountNames[tx.accountId] ?? tx.accountId);
      final currStr = tx.amountIdr != null && tx.amountIdr != tx.amount ? 'MYR' : 'IDR';
      final amountStr = tx.amount.toStringAsFixed(2);
      final idrStr = tx.amountIdr != null ? tx.amountIdr!.toStringAsFixed(2) : amountStr;

      buffer.writeln('$dateStr,$typeStr,$catStr,$descStr,$accStr,$currStr,$amountStr,$idrStr');
    }

    // 2. Transfers
    for (final tf in transfers) {
      final dateStr = dateFormat.format(tf.transferDate);
      const typeStr = 'Transfer Antar Akun';
      const catStr = 'Transfer';
      final fromAcc = accountNames[tf.fromAccountId] ?? tf.fromAccountId;
      final toAcc = accountNames[tf.toAccountId] ?? tf.toAccountId;
      final descStr = _escapeCsv(tf.notes?.isNotEmpty == true ? tf.notes! : 'Transfer: $fromAcc -> $toAcc');
      final accStr = _escapeCsv('$fromAcc -> $toAcc');
      final amountStr = tf.amountFrom.toStringAsFixed(2);

      buffer.writeln('$dateStr,$typeStr,$catStr,$descStr,$accStr,Valas,$amountStr,-');
    }

    return buffer.toString();
  }

  static List<ParsedSpreadsheetRow> parseSpreadsheetContent(String rawContent) {
    final lines = const LineSplitter().convert(rawContent);
    if (lines.isEmpty) return [];

    final result = <ParsedSpreadsheetRow>[];
    int headerIndex = -1;
    String separator = ',';

    // Auto-detect separator (comma vs semicolon vs tab)
    for (int i = 0; i < lines.length && i < 10; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;
      if (line.contains(';') && line.split(';').length >= 4) {
        separator = ';';
        headerIndex = i;
        break;
      } else if (line.contains('\t') && line.split('\t').length >= 4) {
        separator = '\t';
        headerIndex = i;
        break;
      } else if (line.contains(',') && line.split(',').length >= 4) {
        separator = ',';
        headerIndex = i;
        break;
      }
    }

    if (headerIndex == -1) headerIndex = 0;

    // Detect column indexes from header line
    final headerTokens = _splitCsvLine(lines[headerIndex], separator)
        .map((t) => t.toLowerCase().trim())
        .toList();

    int dateCol = -1;
    int descCol = -1;
    int accountCol = -1;
    int currCol = -1;
    int amountCol = -1;
    int catCol = -1;
    int idrCol = -1;
    int typeCol = -1;

    for (int i = 0; i < headerTokens.length; i++) {
      final h = headerTokens[i];
      if (h.contains('tgl') || h.contains('tanggal') || h.contains('date')) {
        dateCol = i;
      } else if (h.contains('ket') || h.contains('deskripsi') || h.contains('sumber /') || h.contains('keterangan') || h.contains('desc')) {
        descCol = i;
      } else if (h.contains('masuk ke') || h.contains('sumber uang') || h.contains('akun') || h.contains('account')) {
        accountCol = i;
      } else if (h.contains('mata uang') || h.contains('currency') || h.contains('curr')) {
        currCol = i;
      } else if (h.contains('nominal') || h.contains('jumlah') || h.contains('amount')) {
        amountCol = i;
      } else if (h.contains('kategori') || h.contains('category')) {
        catCol = i;
      } else if (h.contains('setara idr') || h.contains('idr')) {
        idrCol = i;
      } else if (h.contains('tipe') || h.contains('type')) {
        typeCol = i;
      }
    }

    // Default column fallbacks if headers weren't named standardly
    if (dateCol == -1) dateCol = 0;
    if (descCol == -1) descCol = 1.clamp(0, headerTokens.length - 1);
    if (accountCol == -1) accountCol = 2.clamp(0, headerTokens.length - 1);
    if (currCol == -1) currCol = 3.clamp(0, headerTokens.length - 1);
    if (amountCol == -1) amountCol = 4.clamp(0, headerTokens.length - 1);
    if (catCol == -1) catCol = 5.clamp(0, headerTokens.length - 1);

    for (int i = headerIndex + 1; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;

      final tokens = _splitCsvLine(line, separator);
      if (tokens.isEmpty || tokens.length < 3) continue;

      final rawDate = _safeGet(tokens, dateCol);
      final rawDesc = _safeGet(tokens, descCol);
      final rawAccount = _safeGet(tokens, accountCol);
      final rawCurr = _safeGet(tokens, currCol);
      final rawAmount = _safeGet(tokens, amountCol);
      final rawCat = _safeGet(tokens, catCol);
      final rawIdr = idrCol != -1 ? _safeGet(tokens, idrCol) : '';
      final rawType = typeCol != -1 ? _safeGet(tokens, typeCol) : '';

      final amount = _parseNumeric(rawAmount);
      if (amount == null || amount <= 0) continue;

      final parsedDate = _parseDate(rawDate);

      String inferredType = 'expense';
      if (rawType.toLowerCase().contains('income') || rawType.toLowerCase().contains('masuk')) {
        inferredType = 'income';
      } else if (rawType.toLowerCase().contains('transfer')) {
        inferredType = 'transfer';
      } else if (rawDesc.toLowerCase().contains('transfer dari') || rawDesc.toLowerCase().contains('gaji') || rawCat.toLowerCase().contains('income')) {
        inferredType = 'income';
      }

      String normalizedCurrency = 'IDR';
      if (rawCurr.toUpperCase().contains('RM') || rawCurr.toUpperCase().contains('MYR')) {
        normalizedCurrency = 'MYR';
      } else if (rawCurr.toUpperCase().contains('IDR') || rawCurr.toUpperCase().contains('RP')) {
        normalizedCurrency = 'IDR';
      } else if (rawAccount.toUpperCase().contains('RM') || rawAccount.toUpperCase().contains('TNG') || rawAccount.toUpperCase().contains('MALAY')) {
        normalizedCurrency = 'MYR';
      }

      result.add(ParsedSpreadsheetRow(
        date: parsedDate,
        rawDate: rawDate,
        type: inferredType,
        description: rawDesc,
        accountName: rawAccount,
        currency: normalizedCurrency,
        amount: amount,
        categoryName: rawCat,
        amountIdr: _parseNumeric(rawIdr),
      ));
    }

    return result;
  }

  static String _escapeCsv(String field) {
    if (field.contains(',') || field.contains('"') || field.contains('\n')) {
      return '"${field.replaceAll('"', '""')}"';
    }
    return field;
  }

  static List<String> _splitCsvLine(String line, String separator) {
    final result = <String>[];
    final buffer = StringBuffer();
    bool inQuotes = false;

    for (int i = 0; i < line.length; i++) {
      final char = line[i];
      if (char == '"') {
        if (inQuotes && i + 1 < line.length && line[i + 1] == '"') {
          buffer.write('"');
          i++; // Skip escaped quote
        } else {
          inQuotes = !inQuotes;
        }
      } else if (char == separator && !inQuotes) {
        result.add(buffer.toString().trim());
        buffer.clear();
      } else {
        buffer.write(char);
      }
    }
    result.add(buffer.toString().trim());
    return result;
  }

  static String _safeGet(List<String> list, int index) {
    if (index >= 0 && index < list.length) {
      return list[index].trim();
    }
    return '';
  }

  static double? _parseNumeric(String raw) {
    if (raw.isEmpty) return null;
    var cleaned = raw
        .replaceAll('Rp', '')
        .replaceAll('RP', '')
        .replaceAll('RM', '')
        .replaceAll('rm', '')
        .replaceAll(' ', '')
        .trim();

    // Handle 1.000.000,00 vs 1,000,000.00
    if (cleaned.contains(',') && cleaned.contains('.')) {
      if (cleaned.lastIndexOf('.') > cleaned.lastIndexOf(',')) {
        // 1,000,000.00
        cleaned = cleaned.replaceAll(',', '');
      } else {
        // 1.000.000,00
        cleaned = cleaned.replaceAll('.', '').replaceAll(',', '.');
      }
    } else if (cleaned.contains(',')) {
      // Check if comma is decimal or thousands
      final parts = cleaned.split(',');
      if (parts.length == 2 && parts[1].length <= 2) {
        cleaned = '${parts[0]}.${parts[1]}';
      } else {
        cleaned = cleaned.replaceAll(',', '');
      }
    }

    return double.tryParse(cleaned);
  }

  static DateTime? _parseDate(String raw) {
    if (raw.isEmpty) return null;
    final clean = raw.trim();

    final patterns = [
      'dd/MM/yyyy',
      'd/M/yyyy',
      'yyyy-MM-dd',
      'dd-MM-yyyy',
      'MM/dd/yyyy',
      'd/M/yy',
      'dd/MM/yy',
    ];

    for (final p in patterns) {
      try {
        return DateFormat(p).parseStrict(clean);
      } catch (_) {}
    }

    return DateTime.tryParse(clean);
  }
}
