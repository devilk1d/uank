import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/glass_card.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/spreadsheet_helper.dart';
import '../../../core/widgets/app_confirmation_sheet.dart';
import '../../../core/widgets/app_pagination.dart';
import '../../../core/widgets/receipt_image_viewer.dart';
import '../../../domain/entities/transaction.dart';
import '../../../domain/entities/transfer.dart';
import '../../accounts/providers/account_providers.dart';
import '../../categories/providers/category_providers.dart';
import '../../repository_providers.dart';
import '../../transfers/providers/transfer_providers.dart';
import '../../transfers/screens/add_transfer_sheet.dart';
import '../providers/transaction_providers.dart';
import '../screens/add_transaction_sheet.dart';
import 'import_spreadsheet_dialog.dart';

abstract class _GridActivityItem {
  DateTime get date;
  DateTime? get createdAt;
}

class _GridTxItem extends _GridActivityItem {
  final Transaction transaction;
  _GridTxItem(this.transaction);
  @override
  DateTime get date => transaction.transactionDate;
  @override
  DateTime? get createdAt => transaction.createdAt;
}

class _GridTransferItem extends _GridActivityItem {
  final Transfer transfer;
  _GridTransferItem(this.transfer);
  @override
  DateTime get date => transfer.transferDate;
  @override
  DateTime? get createdAt => transfer.createdAt;
}

class DesktopTransactionGrid extends ConsumerStatefulWidget {
  const DesktopTransactionGrid({super.key});

  @override
  ConsumerState<DesktopTransactionGrid> createState() => _DesktopTransactionGridState();
}

class _DesktopTransactionGridState extends ConsumerState<DesktopTransactionGrid> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  int _selectedTypeIndex = 0; // 0: All, 1: Expense, 2: Income, 3: Transfer
  String? _selectedAccountId;
  String? _selectedCategoryId;
  String _selectedDateRange = 'All Time'; // 'All Time', 'This Month', 'Last Month'
  
  // Pagination State
  int _currentPage = 1;
  int _itemsPerPage = 25;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String val) {
    setState(() {
      _searchQuery = val.trim().toLowerCase();
      _currentPage = 1; // Reset to page 1 on filter
    });
  }

  void _exportCsv(
    List<Transaction> transactions,
    List<Transfer> transfers,
    Map<String, String> accountNames,
    Map<String, String> categoryNames,
  ) {
    final csv = SpreadsheetHelper.generateCsv(
      transactions: transactions,
      transfers: transfers,
      accountNames: accountNames,
      categoryNames: categoryNames,
    );

    Clipboard.setData(ClipboardData(text: csv));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            const Expanded(
              child: Text('CSV copied to clipboard! You can paste it directly into Excel or Google Sheets.'),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF15803D),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _deleteTransaction(Transaction tx) async {
    final confirmed = await AppConfirmationSheet.show(
      context,
      title: 'Delete Transaction?',
      message: 'Are you sure you want to delete "${tx.description ?? 'this transaction'}"? This action cannot be undone.',
      confirmLabel: 'Delete',
      isDestructive: true,
      icon: Icons.delete_outline_rounded,
    );

    if (confirmed == true) {
      await ref.read(transactionRepositoryProvider).delete(tx.id, attachmentUrl: tx.attachmentUrl);
      ref.invalidate(transactionsProvider);
      ref.invalidate(accountBalancesProvider);
    }
  }

  void _deleteTransfer(Transfer tf) async {
    final confirmed = await AppConfirmationSheet.show(
      context,
      title: 'Delete Transfer?',
      message: 'Are you sure you want to delete this transfer? Balances of both accounts will be restored.',
      confirmLabel: 'Delete',
      isDestructive: true,
      icon: Icons.delete_outline_rounded,
    );

    if (confirmed == true) {
      await ref.read(transferRepositoryProvider).delete(tf.id, attachmentUrl: tf.attachmentUrl);
      ref.invalidate(transfersProvider);
      ref.invalidate(accountBalancesProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final primaryAccent = isDark ? AppColors.primary : const Color(0xFF15803D);

    final transactionsAsync = ref.watch(transactionsProvider);
    final transfersAsync = ref.watch(transfersProvider);
    final accountsAsync = ref.watch(accountsProvider);
    final categoriesAsync = ref.watch(categoriesProvider);

    final transactions = transactionsAsync.asData?.value ?? [];
    final transfers = transfersAsync.asData?.value ?? [];
    final accounts = accountsAsync.asData?.value ?? [];
    final categories = categoriesAsync.asData?.value ?? [];

    final accountMap = {for (final a in accounts) a.id: a};
    final categoryMap = {for (final c in categories) c.id: c};
    final accountNames = {for (final a in accounts) a.id: a.name};
    final categoryNames = {for (final c in categories) c.id: c.name};

    // 1. Build Unified Activity List
    final allItems = <_GridActivityItem>[];
    for (final tx in transactions) {
      allItems.add(_GridTxItem(tx));
    }
    for (final tf in transfers) {
      allItems.add(_GridTransferItem(tf));
    }

    // Sort by Date Descending
    allItems.sort((a, b) {
      final dateComp = b.date.compareTo(a.date);
      if (dateComp != 0) return dateComp;
      if (a.createdAt != null && b.createdAt != null) {
        return b.createdAt!.compareTo(a.createdAt!);
      }
      return 0;
    });

    // 2. Filter Items
    final now = DateTime.now();
    final filteredItems = allItems.where((item) {
      // Type Filter
      if (_selectedTypeIndex == 1) {
        if (item is! _GridTxItem || item.transaction.type != 'expense') return false;
      } else if (_selectedTypeIndex == 2) {
        if (item is! _GridTxItem || item.transaction.type != 'income') return false;
      } else if (_selectedTypeIndex == 3) {
        if (item is! _GridTransferItem) return false;
      }

      // Account Filter
      if (_selectedAccountId != null) {
        if (item is _GridTxItem && item.transaction.accountId != _selectedAccountId) return false;
        if (item is _GridTransferItem &&
            item.transfer.fromAccountId != _selectedAccountId &&
            item.transfer.toAccountId != _selectedAccountId) {
          return false;
        }
      }

      // Category Filter
      if (_selectedCategoryId != null) {
        if (item is! _GridTxItem || item.transaction.categoryId != _selectedCategoryId) return false;
      }

      // Date Range Filter
      if (_selectedDateRange == 'This Month') {
        if (item.date.year != now.year || item.date.month != now.month) return false;
      } else if (_selectedDateRange == 'Last Month') {
        final lastMonth = DateTime(now.year, now.month - 1, 1);
        if (item.date.year != lastMonth.year || item.date.month != lastMonth.month) return false;
      }

      // Search Query Filter
      if (_searchQuery.isNotEmpty) {
        if (item is _GridTxItem) {
          final tx = item.transaction;
          final desc = (tx.description ?? '').toLowerCase();
          final accName = (accountNames[tx.accountId] ?? '').toLowerCase();
          final catName = (categoryNames[tx.categoryId] ?? '').toLowerCase();
          final amountStr = tx.amount.toString();
          if (!desc.contains(_searchQuery) &&
              !accName.contains(_searchQuery) &&
              !catName.contains(_searchQuery) &&
              !amountStr.contains(_searchQuery)) {
            return false;
          }
        } else if (item is _GridTransferItem) {
          final tf = item.transfer;
          final notes = (tf.notes ?? '').toLowerCase();
          final fromAcc = (accountNames[tf.fromAccountId] ?? '').toLowerCase();
          final toAcc = (accountNames[tf.toAccountId] ?? '').toLowerCase();
          if (!notes.contains(_searchQuery) &&
              !fromAcc.contains(_searchQuery) &&
              !toAcc.contains(_searchQuery)) {
            return false;
          }
        }
      }

      return true;
    }).toList();

    // 3. Compute Summary Metrics from ALL unfiltered transactions
    double totalIncomeIdr = 0;
    double totalIncomeMyr = 0;
    double totalExpenseIdr = 0;
    double totalExpenseMyr = 0;

    for (final tx in transactions) {
      final acc = accountMap[tx.accountId];
      final isMyr = acc?.currency == 'MYR';

      if (tx.type == 'income') {
        if (isMyr) {
          totalIncomeMyr += tx.amount;
        } else {
          totalIncomeIdr += tx.amount;
        }
      } else if (tx.type == 'expense') {
        if (isMyr) {
          totalExpenseMyr += tx.amount;
        } else {
          totalExpenseIdr += tx.amount;
        }
      }
    }

    // 4. Pagination Slice
    final totalItems = filteredItems.length;
    final totalPages = (totalItems / _itemsPerPage).ceil().clamp(1, 999999);
    final safeCurrentPage = _currentPage.clamp(1, totalPages);
    final startIndex = (safeCurrentPage - 1) * _itemsPerPage;
    final endIndex = (startIndex + _itemsPerPage).clamp(0, totalItems);
    final pageItems = totalItems == 0 ? <_GridActivityItem>[] : filteredItems.sublist(startIndex, endIndex);

    return ListView(
      padding: const EdgeInsets.fromLTRB(28, 24, 28, 48),
      children: [
        // 1. TOP FINANCIAL SUMMARY CARDS (3-Columns Bento - Stable unfiltered metrics)
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                title: 'TOTAL INCOME',
                primaryAmount: 'Rp ${CurrencyInputFormatter.format(totalIncomeIdr, currency: 'IDR')}',
                secondaryAmount: totalIncomeMyr > 0 ? 'RM ${CurrencyInputFormatter.format(totalIncomeMyr, currency: 'MYR')}' : null,
                icon: Icons.arrow_downward_rounded,
                accentColor: isDark ? AppColors.primary : const Color(0xFF15803D),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _MetricCard(
                title: 'TOTAL EXPENSE',
                primaryAmount: 'Rp ${CurrencyInputFormatter.format(totalExpenseIdr, currency: 'IDR')}',
                secondaryAmount: totalExpenseMyr > 0 ? 'RM ${CurrencyInputFormatter.format(totalExpenseMyr, currency: 'MYR')}' : null,
                icon: Icons.arrow_upward_rounded,
                accentColor: isDark ? AppColors.red : const Color(0xFFBE123C),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _MetricCard(
                title: 'NET BALANCE (IDR)',
                primaryAmount: 'Rp ${CurrencyInputFormatter.format(totalIncomeIdr - totalExpenseIdr, currency: 'IDR')}',
                secondaryAmount: totalIncomeMyr - totalExpenseMyr != 0
                    ? 'RM ${CurrencyInputFormatter.format(totalIncomeMyr - totalExpenseMyr, currency: 'MYR')}'
                    : null,
                icon: Icons.account_balance_rounded,
                accentColor: const Color(0xFF38BDF8),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // 2. SPREADSHEET TOOLBAR (Filter, Search & Action Buttons)
        GlassCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  // Search Bar
                  Expanded(
                    flex: 3,
                    child: Container(
                      height: 42,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF14161F) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: context.cardBorder),
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: _onSearchChanged,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          color: context.textPrimary,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Search description, account, category, or amount...',
                          hintStyle: GoogleFonts.plusJakartaSans(
                            fontSize: 12.5,
                            color: context.textMuted,
                          ),
                          prefixIcon: Icon(
                            Icons.search_rounded,
                            size: 18,
                            color: context.textMuted,
                          ),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.close_rounded, size: 16),
                                  onPressed: () {
                                    _searchController.clear();
                                    _onSearchChanged('');
                                  },
                                )
                              : null,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Account Selector
                  Container(
                    height: 42,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF14161F) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: context.cardBorder),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String?>(
                        value: _selectedAccountId,
                        dropdownColor: isDark ? const Color(0xFF181B24) : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        hint: Text(
                          'All Accounts',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: context.textMuted,
                          ),
                        ),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: context.textPrimary,
                        ),
                        items: [
                          const DropdownMenuItem<String?>(
                            value: null,
                            child: Text('All Accounts'),
                          ),
                          ...accounts.map((a) => DropdownMenuItem<String?>(
                                value: a.id,
                                child: Text('${a.name} (${a.currency})'),
                              )),
                        ],
                        onChanged: (val) {
                          setState(() {
                            _selectedAccountId = val;
                            _currentPage = 1;
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Date Range Selector
                  Container(
                    height: 42,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF14161F) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: context.cardBorder),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedDateRange,
                        dropdownColor: isDark ? const Color(0xFF181B24) : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: context.textPrimary,
                        ),
                        items: const [
                          DropdownMenuItem(value: 'All Time', child: Text('All Time')),
                          DropdownMenuItem(value: 'This Month', child: Text('This Month')),
                          DropdownMenuItem(value: 'Last Month', child: Text('Last Month')),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _selectedDateRange = val;
                              _currentPage = 1;
                            });
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),

                  // Import Spreadsheet Button
                  OutlinedButton.icon(
                    onPressed: () => ImportSpreadsheetDialog.show(context),
                    icon: const Icon(Icons.file_upload_outlined, size: 16),
                    label: const Text('Import'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      side: BorderSide(color: context.cardBorder),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      foregroundColor: context.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Export CSV Button
                  OutlinedButton.icon(
                    onPressed: () => _exportCsv(transactions, transfers, accountNames, categoryNames),
                    icon: const Icon(Icons.file_download_outlined, size: 16),
                    label: const Text('Export CSV'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      side: BorderSide(color: context.cardBorder),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      foregroundColor: context.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 12),

                  // + Add Transaction
                  FilledButton.icon(
                    onPressed: () => AddTransactionSheet.show(context),
                    icon: const Icon(Icons.add_rounded, size: 16),
                    label: const Text('New Transaction'),
                    style: FilledButton.styleFrom(
                      backgroundColor: primaryAccent,
                      foregroundColor: isDark ? Colors.black : Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Filter Type Tabs (All, Expense, Income, Transfer)
              Row(
                children: [
                  _FilterPill(
                    label: 'All Activity (${allItems.length})',
                    isSelected: _selectedTypeIndex == 0,
                    onTap: () => setState(() {
                      _selectedTypeIndex = 0;
                      _currentPage = 1;
                    }),
                  ),
                  const SizedBox(width: 8),
                  _FilterPill(
                    label: 'Expenses',
                    isSelected: _selectedTypeIndex == 1,
                    badgeColor: isDark ? AppColors.red : const Color(0xFFBE123C),
                    onTap: () => setState(() {
                      _selectedTypeIndex = 1;
                      _currentPage = 1;
                    }),
                  ),
                  const SizedBox(width: 8),
                  _FilterPill(
                    label: 'Income',
                    isSelected: _selectedTypeIndex == 2,
                    badgeColor: isDark ? AppColors.primary : const Color(0xFF15803D),
                    onTap: () => setState(() {
                      _selectedTypeIndex = 2;
                      _currentPage = 1;
                    }),
                  ),
                  const SizedBox(width: 8),
                  _FilterPill(
                    label: 'Transfers',
                    isSelected: _selectedTypeIndex == 3,
                    badgeColor: const Color(0xFF38BDF8),
                    onTap: () => setState(() {
                      _selectedTypeIndex = 3;
                      _currentPage = 1;
                    }),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 3. RESPONSIVE FULL-WIDTH DATA TABLE
        GlassCard(
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (pageItems.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 20),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.search_off_rounded,
                          size: 48,
                          color: context.textMuted,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No transactions match your filter criteria',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: context.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Try clearing your search query or changing the filter options.',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            color: context.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final tableWidth = constraints.maxWidth > 1050 ? constraints.maxWidth : 1050.0;

                      return SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: SizedBox(
                          width: tableWidth,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // 3A. Header Row
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF13151D) : const Color(0xFFF1F5F9),
                                  border: Border(
                                    bottom: BorderSide(
                                      color: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE2E8F0),
                                    ),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      flex: 12,
                                      child: Text(
                                        'DATE',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 0.5,
                                          color: context.textMuted,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 11,
                                      child: Text(
                                        'TYPE',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 0.5,
                                          color: context.textMuted,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 22,
                                      child: Text(
                                        'DESCRIPTION / NOTES',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 0.5,
                                          color: context.textMuted,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 14,
                                      child: Text(
                                        'CATEGORY',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 0.5,
                                          color: context.textMuted,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 15,
                                      child: Text(
                                        'ACCOUNT / ROUTE',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 0.5,
                                          color: context.textMuted,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 15,
                                      child: Text(
                                        'AMOUNT (ORIGINAL)',
                                        textAlign: TextAlign.right,
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 0.5,
                                          color: context.textMuted,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 14,
                                      child: Text(
                                        'SETARA (IDR)',
                                        textAlign: TextAlign.right,
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 0.5,
                                          color: context.textMuted,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 8,
                                      child: Text(
                                        'PROOF',
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 0.5,
                                          color: context.textMuted,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 9,
                                      child: Text(
                                        'ACTIONS',
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 0.5,
                                          color: context.textMuted,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // 3B. Data Rows
                              ...pageItems.asMap().entries.map((entry) {
                                final idx = entry.key;
                                final item = entry.value;
                                final isLast = idx == pageItems.length - 1;

                                if (item is _GridTxItem) {
                                  final tx = item.transaction;
                                  final isIncome = tx.type == 'income';
                                  final acc = accountMap[tx.accountId];
                                  final cat = tx.categoryId != null ? categoryMap[tx.categoryId] : null;
                                  final isMyr = acc?.currency == 'MYR';

                                  return Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                    decoration: BoxDecoration(
                                      border: isLast
                                          ? null
                                          : Border(
                                              bottom: BorderSide(
                                                color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF1F5F9),
                                              ),
                                            ),
                                    ),
                                    child: Row(
                                      children: [
                                        // Date
                                        Expanded(
                                          flex: 12,
                                          child: Text(
                                            DateFormat('dd MMM yyyy').format(tx.transactionDate),
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 12.5,
                                              fontWeight: FontWeight.w600,
                                              color: context.textPrimary,
                                            ),
                                          ),
                                        ),

                                        // Type Badge
                                        Expanded(
                                          flex: 11,
                                          child: Align(
                                            alignment: Alignment.centerLeft,
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                              decoration: BoxDecoration(
                                                color: isIncome
                                                    ? (isDark ? AppColors.primary.withValues(alpha: 0.18) : const Color(0xFFDCFCE7))
                                                    : (isDark ? AppColors.red.withValues(alpha: 0.18) : const Color(0xFFFFE4E6)),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    isIncome ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                                                    size: 11,
                                                    color: isIncome
                                                        ? (isDark ? AppColors.primary : const Color(0xFF15803D))
                                                        : (isDark ? AppColors.red : const Color(0xFFBE123C)),
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    isIncome ? 'Income' : 'Expense',
                                                    style: GoogleFonts.plusJakartaSans(
                                                      fontSize: 11,
                                                      fontWeight: FontWeight.w700,
                                                      color: isIncome
                                                          ? (isDark ? AppColors.primary : const Color(0xFF15803D))
                                                          : (isDark ? AppColors.red : const Color(0xFFBE123C)),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),

                                        // Description
                                        Expanded(
                                          flex: 22,
                                          child: Padding(
                                            padding: const EdgeInsets.only(right: 8),
                                            child: Text(
                                              tx.description?.isNotEmpty == true ? tx.description! : 'No description',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: GoogleFonts.plusJakartaSans(
                                                fontSize: 12.5,
                                                fontWeight: FontWeight.w600,
                                                color: tx.description?.isNotEmpty == true ? context.textPrimary : context.textMuted,
                                              ),
                                            ),
                                          ),
                                        ),

                                        // Category
                                        Expanded(
                                          flex: 14,
                                          child: Row(
                                            children: [
                                              Container(
                                                width: 24,
                                                height: 24,
                                                decoration: BoxDecoration(
                                                  color: isDark ? const Color(0xFF1E212B) : const Color(0xFFF1F5F9),
                                                  shape: BoxShape.circle,
                                                ),
                                                child: Center(
                                                  child: Icon(
                                                    _resolveCategoryIcon(cat?.icon),
                                                    size: 13,
                                                    color: isDark ? Colors.white70 : const Color(0xFF475569),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  cat?.name ?? 'Uncategorized',
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: GoogleFonts.plusJakartaSans(
                                                    fontSize: 12,
                                                    color: context.textPrimary,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),

                                        // Account
                                        Expanded(
                                          flex: 15,
                                          child: Align(
                                            alignment: Alignment.centerLeft,
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                              decoration: BoxDecoration(
                                                color: isDark ? const Color(0xFF181B24) : const Color(0xFFF1F5F9),
                                                borderRadius: BorderRadius.circular(6),
                                                border: Border.all(color: context.cardBorder),
                                              ),
                                              child: Text(
                                                acc?.name ?? 'Unknown',
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: GoogleFonts.plusJakartaSans(
                                                  fontSize: 11.5,
                                                  fontWeight: FontWeight.w600,
                                                  color: context.textPrimary,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),

                                        // Amount (Original)
                                        Expanded(
                                          flex: 15,
                                          child: Text(
                                            '${isIncome ? '+' : '-'}${isMyr ? 'RM' : 'Rp'} ${CurrencyInputFormatter.format(tx.amount, currency: isMyr ? 'MYR' : 'IDR')}',
                                            textAlign: TextAlign.right,
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w800,
                                              color: isIncome
                                                  ? (isDark ? AppColors.primary : const Color(0xFF15803D))
                                                  : context.textPrimary,
                                            ),
                                          ),
                                        ),

                                        // Setara IDR
                                        Expanded(
                                          flex: 14,
                                          child: Text(
                                            tx.amountIdr != null
                                                ? 'Rp ${CurrencyInputFormatter.format(tx.amountIdr!, currency: 'IDR')}'
                                                : '-',
                                            textAlign: TextAlign.right,
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 12,
                                              color: context.textSecondary,
                                            ),
                                          ),
                                        ),

                                        // Proof
                                        Expanded(
                                          flex: 8,
                                          child: Center(
                                            child: tx.attachmentUrl != null && tx.attachmentUrl!.isNotEmpty
                                                ? InkWell(
                                                    onTap: () => ReceiptImageViewer.show(context, imageUrl: tx.attachmentUrl!),
                                                    borderRadius: BorderRadius.circular(6),
                                                    child: Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                                      decoration: BoxDecoration(
                                                        color: (isDark ? AppColors.primary : const Color(0xFF15803D)).withValues(alpha: 0.15),
                                                        borderRadius: BorderRadius.circular(6),
                                                      ),
                                                      child: Row(
                                                        mainAxisSize: MainAxisSize.min,
                                                        children: [
                                                          Icon(
                                                            Icons.image_outlined,
                                                            size: 13,
                                                            color: isDark ? AppColors.primary : const Color(0xFF15803D),
                                                          ),
                                                          const SizedBox(width: 4),
                                                          Text(
                                                            'View',
                                                            style: GoogleFonts.plusJakartaSans(
                                                              fontSize: 11,
                                                              fontWeight: FontWeight.w700,
                                                              color: isDark ? AppColors.primary : const Color(0xFF15803D),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  )
                                                : Text('-', style: TextStyle(color: context.textMuted)),
                                          ),
                                        ),

                                        // Actions
                                        Expanded(
                                          flex: 9,
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              IconButton(
                                                icon: const Icon(Icons.edit_outlined, size: 16),
                                                tooltip: 'Edit Transaction',
                                                visualDensity: VisualDensity.compact,
                                                padding: EdgeInsets.zero,
                                                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                                                onPressed: () => AddTransactionSheet.show(context, transactionToEdit: tx),
                                              ),
                                              const SizedBox(width: 4),
                                              IconButton(
                                                icon: Icon(Icons.delete_outline_rounded, size: 16, color: AppColors.red),
                                                tooltip: 'Delete',
                                                visualDensity: VisualDensity.compact,
                                                padding: EdgeInsets.zero,
                                                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                                                onPressed: () => _deleteTransaction(tx),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                } else {
                                  final tf = (item as _GridTransferItem).transfer;
                                  final fromAcc = accountMap[tf.fromAccountId];
                                  final toAcc = accountMap[tf.toAccountId];

                                  return Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                    decoration: BoxDecoration(
                                      border: isLast
                                          ? null
                                          : Border(
                                              bottom: BorderSide(
                                                color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF1F5F9),
                                              ),
                                            ),
                                    ),
                                    child: Row(
                                      children: [
                                        // Date
                                        Expanded(
                                          flex: 12,
                                          child: Text(
                                            DateFormat('dd MMM yyyy').format(tf.transferDate),
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 12.5,
                                              fontWeight: FontWeight.w600,
                                              color: context.textPrimary,
                                            ),
                                          ),
                                        ),

                                        // Type
                                        Expanded(
                                          flex: 11,
                                          child: Align(
                                            alignment: Alignment.centerLeft,
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF38BDF8).withValues(alpha: 0.18),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  const Icon(Icons.swap_horiz_rounded, size: 12, color: Color(0xFF0284C7)),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    'Transfer',
                                                    style: GoogleFonts.plusJakartaSans(
                                                      fontSize: 11,
                                                      fontWeight: FontWeight.w700,
                                                      color: const Color(0xFF0284C7),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),

                                        // Description
                                        Expanded(
                                          flex: 22,
                                          child: Padding(
                                            padding: const EdgeInsets.only(right: 8),
                                            child: Text(
                                              tf.notes?.isNotEmpty == true ? tf.notes! : 'Transfer Antar Akun',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: GoogleFonts.plusJakartaSans(
                                                fontSize: 12.5,
                                                fontWeight: FontWeight.w600,
                                                color: context.textPrimary,
                                              ),
                                            ),
                                          ),
                                        ),

                                        // Category
                                        Expanded(
                                          flex: 14,
                                          child: Text(
                                            'Transfer',
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 12,
                                              color: context.textPrimary,
                                            ),
                                          ),
                                        ),

                                        // Route
                                        Expanded(
                                          flex: 15,
                                          child: Text(
                                            '${fromAcc?.name ?? 'Unknown'} -> ${toAcc?.name ?? 'Unknown'}',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: context.textPrimary,
                                            ),
                                          ),
                                        ),

                                        // Amount
                                        Expanded(
                                          flex: 15,
                                          child: Text(
                                            '${fromAcc?.currency ?? 'IDR'} ${CurrencyInputFormatter.format(tf.amountFrom, currency: fromAcc?.currency ?? 'IDR')}',
                                            textAlign: TextAlign.right,
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w800,
                                              color: const Color(0xFF38BDF8),
                                            ),
                                          ),
                                        ),

                                        // Setara IDR
                                        Expanded(
                                          flex: 14,
                                          child: Text(
                                            toAcc?.currency == 'IDR'
                                                ? 'Rp ${CurrencyInputFormatter.format(tf.amountTo, currency: 'IDR')}'
                                                : '-',
                                            textAlign: TextAlign.right,
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 12,
                                              color: context.textSecondary,
                                            ),
                                          ),
                                        ),

                                        // Proof
                                        Expanded(
                                          flex: 8,
                                          child: Center(
                                            child: tf.attachmentUrl != null && tf.attachmentUrl!.isNotEmpty
                                                ? InkWell(
                                                    onTap: () => ReceiptImageViewer.show(context, imageUrl: tf.attachmentUrl!),
                                                    borderRadius: BorderRadius.circular(6),
                                                    child: Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                                      decoration: BoxDecoration(
                                                        color: (isDark ? AppColors.primary : const Color(0xFF15803D)).withValues(alpha: 0.15),
                                                        borderRadius: BorderRadius.circular(6),
                                                      ),
                                                      child: Row(
                                                        mainAxisSize: MainAxisSize.min,
                                                        children: [
                                                          Icon(
                                                            Icons.image_outlined,
                                                            size: 13,
                                                            color: isDark ? AppColors.primary : const Color(0xFF15803D),
                                                          ),
                                                          const SizedBox(width: 4),
                                                          Text(
                                                            'View',
                                                            style: GoogleFonts.plusJakartaSans(
                                                              fontSize: 11,
                                                              fontWeight: FontWeight.w700,
                                                              color: isDark ? AppColors.primary : const Color(0xFF15803D),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  )
                                                : Text('-', style: TextStyle(color: context.textMuted)),
                                          ),
                                        ),

                                        // Actions
                                        Expanded(
                                          flex: 9,
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              IconButton(
                                                icon: const Icon(Icons.edit_outlined, size: 16),
                                                tooltip: 'Edit Transfer',
                                                visualDensity: VisualDensity.compact,
                                                padding: EdgeInsets.zero,
                                                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                                                onPressed: () => AddTransferSheet.show(context, transferToEdit: tf),
                                              ),
                                              const SizedBox(width: 4),
                                              IconButton(
                                                icon: Icon(Icons.delete_outline_rounded, size: 16, color: AppColors.red),
                                                tooltip: 'Delete',
                                                visualDensity: VisualDensity.compact,
                                                padding: EdgeInsets.zero,
                                                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                                                onPressed: () => _deleteTransfer(tf),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }
                              }),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

              // 4. BOTTOM PAGINATION BAR
              if (filteredItems.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  child: AppPagination(
                    currentPage: safeCurrentPage,
                    totalItems: totalItems,
                    itemsPerPage: _itemsPerPage,
                    onPageChanged: (newPage) {
                      setState(() {
                        _currentPage = newPage;
                      });
                    },
                    onItemsPerPageChanged: (newSize) {
                      setState(() {
                        _itemsPerPage = newSize;
                        _currentPage = 1;
                      });
                    },
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  IconData _resolveCategoryIcon(String? iconName) {
    if (iconName == null) return Icons.category_rounded;
    switch (iconName.toLowerCase()) {
      case 'restaurant':
      case 'food':
      case 'makanan':
        return Icons.restaurant_rounded;
      case 'shopping_bag':
      case 'shopping':
      case 'belanja':
        return Icons.shopping_bag_rounded;
      case 'directions_car':
      case 'transport':
      case 'transportasi':
        return Icons.directions_car_rounded;
      case 'medical_services':
      case 'health':
      case 'kesehatan':
        return Icons.medical_services_rounded;
      case 'work':
      case 'salary':
      case 'gaji':
        return Icons.work_rounded;
      case 'swap_horiz':
      case 'transfer':
        return Icons.swap_horiz_rounded;
      case 'bolt':
      case 'bills':
      case 'listrik':
        return Icons.bolt_rounded;
      default:
        return Icons.category_rounded;
    }
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.primaryAmount,
    this.secondaryAmount,
    required this.icon,
    required this.accentColor,
  });

  final String title;
  final String primaryAmount;
  final String? secondaryAmount;
  final IconData icon;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;

    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: context.textMuted,
                ),
              ),
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: isDark ? 0.2 : 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Icon(icon, size: 15, color: accentColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            primaryAmount,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: context.textPrimary,
            ),
          ),
          if (secondaryAmount != null) ...[
            const SizedBox(height: 2),
            Text(
              secondaryAmount!,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: context.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _FilterPill extends StatelessWidget {
  const _FilterPill({
    required this.label,
    required this.isSelected,
    this.badgeColor,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final Color? badgeColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final primaryAccent = isDark ? AppColors.primary : const Color(0xFF15803D);

    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? (badgeColor ?? primaryAccent).withValues(alpha: isDark ? 0.22 : 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? (badgeColor ?? primaryAccent)
                : context.cardBorder,
            width: 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (badgeColor != null) ...[
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: badgeColor,
                ),
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected
                    ? (badgeColor ?? (isDark ? AppColors.primary : const Color(0xFF15803D)))
                    : context.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
