import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/spreadsheet_helper.dart';
import '../../../domain/entities/account.dart';
import '../../../domain/entities/category.dart';
import '../../../domain/entities/transaction.dart';
import '../../accounts/providers/account_providers.dart';
import '../../categories/providers/category_providers.dart';
import '../../repository_providers.dart';
import '../providers/transaction_providers.dart';

class ImportSpreadsheetDialog extends ConsumerStatefulWidget {
  const ImportSpreadsheetDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (_) => const ImportSpreadsheetDialog(),
    );
  }

  @override
  ConsumerState<ImportSpreadsheetDialog> createState() => _ImportSpreadsheetDialogState();
}

class _ImportSpreadsheetDialogState extends ConsumerState<ImportSpreadsheetDialog> {
  final _textController = TextEditingController();
  List<ParsedSpreadsheetRow> _parsedRows = [];
  bool _isImporting = false;
  String? _statusMessage;
  bool _isSuccess = false;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _parseInput(String text) {
    if (text.trim().isEmpty) {
      setState(() {
        _parsedRows = [];
        _statusMessage = null;
      });
      return;
    }

    final rows = SpreadsheetHelper.parseSpreadsheetContent(text);
    setState(() {
      _parsedRows = rows;
      if (rows.isEmpty) {
        _statusMessage = 'No valid transaction rows found. Check column headers.';
      } else {
        _statusMessage = 'Found ${rows.length} valid transaction rows ready for import.';
      }
    });
  }

  void _loadSampleData() {
    const sample = '''Tanggal,Keterangan,Masuk ke,Mata Uang,Nominal,Kategori,Setara IDR
01/09/2026,Transfer dari Mba Una,Tabungan Pribadi,IDR,1000000.00,Transfer,1000000
05/09/2026,Transfer dari Orang Tua,Uang Malay,IDR,2000000.00,Transfer,2000000
08/09/2026,Cash dari Hani,Cash RM,RM,100.00,Kebutuhan,431700
11/09/2026,Topup TNG,Touch 'n Go Wallet,RM,231.39,Kebutuhan,998911
12/09/2026,Tuker Cash sama TNG (Asan),Touch 'n Go Wallet,RM,50.00,Kebutuhan,215850
12/09/2026,Bayar Beras (Celiboy),Touch 'n Go Wallet,RM,12.00,Belanja,51804
18/09/2026,Card Holder,Touch 'n Go Wallet,RM,6.39,Belanja,27586''';

    _textController.text = sample;
    _parseInput(sample);
  }

  Future<void> _executeImport() async {
    if (_parsedRows.isEmpty) return;

    setState(() {
      _isImporting = true;
      _statusMessage = 'Matching accounts and categories...';
    });

    try {
      final accounts = ref.read(accountsProvider).asData?.value ?? [];
      final categories = ref.read(categoriesProvider).asData?.value ?? [];
      final txRepo = ref.read(transactionRepositoryProvider);

      int successCount = 0;

      for (final row in _parsedRows) {
        // 1. Resolve Account ID
        Account? matchedAccount;
        if (row.accountName.isNotEmpty) {
          final query = row.accountName.toLowerCase();
          for (final acc in accounts) {
            if (acc.name.toLowerCase().contains(query) || query.contains(acc.name.toLowerCase())) {
              matchedAccount = acc;
              break;
            }
          }
        }
        matchedAccount ??= accounts.isNotEmpty ? accounts.first : null;

        if (matchedAccount == null) continue;

        // 2. Resolve Category ID
        Category? matchedCat;
        if (row.categoryName.isNotEmpty) {
          final query = row.categoryName.toLowerCase();
          for (final cat in categories) {
            if (cat.name.toLowerCase().contains(query) || query.contains(cat.name.toLowerCase())) {
              matchedCat = cat;
              break;
            }
          }
        }

        final tx = Transaction(
          id: '',
          accountId: matchedAccount.id,
          categoryId: matchedCat?.id,
          type: row.type == 'income' ? 'income' : 'expense',
          amount: row.amount,
          amountIdr: row.amountIdr,
          description: row.description.isNotEmpty ? row.description : null,
          transactionDate: row.date ?? DateTime.now(),
        );

        await txRepo.create(tx);
        successCount++;
      }

      ref.invalidate(transactionsProvider);
      ref.invalidate(accountBalancesProvider);

      setState(() {
        _isImporting = false;
        _isSuccess = true;
        _statusMessage = 'Successfully imported $successCount transactions!';
      });
    } catch (e) {
      setState(() {
        _isImporting = false;
        _statusMessage = 'Import error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final primaryAccent = isDark ? AppColors.primary : const Color(0xFF15803D);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        width: 720,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF14161E) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isDark ? Colors.white.withValues(alpha: 0.12) : const Color(0xFFE2E8F0),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.6 : 0.15),
              blurRadius: 36,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Modal Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 20, 16),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: primaryAccent.withValues(alpha: isDark ? 0.2 : 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.table_chart_rounded,
                      color: primaryAccent,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Import Spreadsheet Data',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: context.textPrimary,
                          ),
                        ),
                        Text(
                          'Paste CSV content from Google Sheets or Excel',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12.5,
                            color: context.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(Icons.close_rounded, color: context.textMuted),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // 2. Modal Body (Scrollable)
            Flexible(
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'CSV DATA CONTENT',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.0,
                          color: context.textMuted,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _loadSampleData,
                        icon: const Icon(Icons.auto_fix_high_rounded, size: 14),
                        label: const Text('Load Sample Data'),
                        style: TextButton.styleFrom(
                          foregroundColor: primaryAccent,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Text Area Input
                  TextField(
                    controller: _textController,
                    maxLines: 6,
                    onChanged: _parseInput,
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 12,
                      color: context.textPrimary,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Paste comma-separated (CSV) or tab-separated text here...\ne.g. 01/09/2026,Belanja Makan,Cash RM,RM,15.50,Makanan',
                      hintStyle: GoogleFonts.jetBrainsMono(
                        fontSize: 12,
                        color: context.textMuted,
                      ),
                      filled: true,
                      fillColor: isDark ? const Color(0xFF0F1015) : const Color(0xFFF8FAFC),
                      contentPadding: const EdgeInsets.all(14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: context.cardBorder),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Live Preview Section
                  if (_parsedRows.isNotEmpty) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'PARSED PREVIEW (${_parsedRows.length} ROWS)',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.0,
                            color: context.textMuted,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: primaryAccent.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Ready to import',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: primaryAccent,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Preview Table Card
                    Container(
                      height: 180,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0F1015) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: context.cardBorder),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.vertical,
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: DataTable(
                              headingRowHeight: 34,
                              dataRowMinHeight: 32,
                              dataRowMaxHeight: 34,
                              horizontalMargin: 12,
                              columnSpacing: 16,
                              headingTextStyle: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: context.textMuted,
                              ),
                              columns: const [
                                DataColumn(label: Text('Date')),
                                DataColumn(label: Text('Type')),
                                DataColumn(label: Text('Description')),
                                DataColumn(label: Text('Account')),
                                DataColumn(label: Text('Nominal')),
                                DataColumn(label: Text('Category')),
                              ],
                              rows: _parsedRows.take(50).map((row) {
                                final isIncome = row.type == 'income';
                                return DataRow(
                                  cells: [
                                    DataCell(Text(
                                      row.rawDate,
                                      style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: context.textPrimary),
                                    )),
                                    DataCell(
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: isIncome
                                              ? (isDark ? AppColors.primary.withValues(alpha: 0.2) : const Color(0xFFDCFCE7))
                                              : (isDark ? AppColors.red.withValues(alpha: 0.2) : const Color(0xFFFFE4E6)),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          isIncome ? 'Income' : 'Expense',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                            color: isIncome
                                                ? (isDark ? AppColors.primary : const Color(0xFF15803D))
                                                : (isDark ? AppColors.red : const Color(0xFFBE123C)),
                                          ),
                                        ),
                                      ),
                                    ),
                                    DataCell(Text(
                                      row.description.isNotEmpty ? row.description : '-',
                                      style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: context.textPrimary),
                                    )),
                                    DataCell(Text(
                                      row.accountName.isNotEmpty ? row.accountName : '-',
                                      style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: context.textPrimary),
                                    )),
                                    DataCell(Text(
                                      '${row.currency} ${CurrencyInputFormatter.format(row.amount, currency: row.currency)}',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w700,
                                        color: isIncome
                                            ? (isDark ? AppColors.primary : const Color(0xFF15803D))
                                            : context.textPrimary,
                                      ),
                                    )),
                                    DataCell(Text(
                                      row.categoryName.isNotEmpty ? row.categoryName : '-',
                                      style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: context.textPrimary),
                                    )),
                                  ],
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],

                  if (_statusMessage != null) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: _isSuccess
                            ? (isDark ? AppColors.primary.withValues(alpha: 0.15) : const Color(0xFFDCFCE7))
                            : (isDark ? Colors.amber.withValues(alpha: 0.15) : const Color(0xFFFEF3C7)),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _isSuccess ? Icons.check_circle_rounded : Icons.info_outline_rounded,
                            size: 16,
                            color: _isSuccess
                                ? (isDark ? AppColors.primary : const Color(0xFF15803D))
                                : (isDark ? Colors.amber : const Color(0xFFB45309)),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _statusMessage!,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: _isSuccess
                                    ? (isDark ? AppColors.primary : const Color(0xFF15803D))
                                    : (isDark ? Colors.amber : const Color(0xFFB45309)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // 3. Modal Actions Footer
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: _isImporting ? null : () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      side: BorderSide(color: context.cardBorder),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      _isSuccess ? 'Close' : 'Cancel',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w700,
                        color: context.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  if (!_isSuccess)
                    FilledButton.icon(
                      onPressed: _parsedRows.isEmpty || _isImporting ? null : _executeImport,
                      style: FilledButton.styleFrom(
                        backgroundColor: primaryAccent,
                        foregroundColor: isDark ? Colors.black : Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: _isImporting
                          ? SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: isDark ? Colors.black : Colors.white,
                              ),
                            )
                          : const Icon(Icons.file_download_done_rounded, size: 18),
                      label: Text(
                        _isImporting ? 'Importing...' : 'Import ${_parsedRows.length} Rows',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w800,
                          fontSize: 13.5,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
