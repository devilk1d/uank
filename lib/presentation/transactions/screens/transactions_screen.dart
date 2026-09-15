import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_background.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/glass_card.dart';
import '../../../domain/entities/account.dart';
import '../../../domain/entities/transaction.dart';
import '../../../domain/entities/transfer.dart';
import '../../accounts/providers/account_providers.dart';
import '../../transfers/providers/transfer_providers.dart';
import '../../transfers/screens/add_transfer_sheet.dart';
import '../providers/transaction_providers.dart';
import '../widgets/transaction_calendar_sheet.dart';
import 'add_transaction_sheet.dart';

abstract class _ActivityItem {
  DateTime get date;
}

class _TxActivityItem extends _ActivityItem {
  final Transaction transaction;
  _TxActivityItem(this.transaction);
  @override
  DateTime get date => transaction.transactionDate;
}

class _TransferActivityItem extends _ActivityItem {
  final Transfer transfer;
  _TransferActivityItem(this.transfer);
  @override
  DateTime get date => transfer.transferDate;
}

class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({super.key});

  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
  int _selectedFilterIndex = 0; // 0: All, 1: Expense, 2: Income, 3: Transfer
  final _filters = const ['All', 'Expense', 'Income', 'Transfer'];
  DateTime? _startDateFilter;
  DateTime? _endDateFilter;
  DateTime? _selectedMonthFilter;

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  void _showAddOptionsModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(22, 20, 22, 32),
        decoration: const BoxDecoration(
          color: AppColors.darkCardBg,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          border: Border(top: BorderSide(color: AppColors.darkCardBorder, width: 1.5)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.darkTextMuted,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),

            const Text(
              'New Financial Entry',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.darkTextPrimary,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Choose what type of record you would like to create',
              style: TextStyle(fontSize: 12, color: AppColors.darkTextSecondary),
            ),
            const SizedBox(height: 20),

            // Option 1: Record Transaction
            _AddActionOptionTile(
              icon: Icons.receipt_long_rounded,
              iconBgColor: AppColors.primary,
              iconColor: Colors.black,
              title: 'Record Transaction',
              subtitle: 'Log income or expense with category and notes',
              onTap: () {
                Navigator.pop(ctx);
                AddTransactionSheet.show(context);
              },
            ),
            const SizedBox(height: 12),

            // Option 2: Transfer Funds
            _AddActionOptionTile(
              icon: Icons.swap_horiz_rounded,
              iconBgColor: AppColors.teal,
              iconColor: Colors.black,
              title: 'Transfer Between Accounts',
              subtitle: 'Move money between your bank, e-wallet, or cash',
              onTap: () {
                Navigator.pop(ctx);
                AddTransferSheet.show(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final transactionsAsync = ref.watch(transactionsProvider);
    final transfersAsync = ref.watch(transfersProvider);
    final accountsAsync = ref.watch(accountsProvider);

    final accounts = accountsAsync.asData?.value ?? [];
    final accountMap = {for (final a in accounts) a.id: a};

    final isLoading = transactionsAsync.isLoading || transfersAsync.isLoading;
    final hasError = transactionsAsync.hasError || transfersAsync.hasError;

    final allTransactions = transactionsAsync.asData?.value ?? [];
    final allTransfers = transfersAsync.asData?.value ?? [];

    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 110),
            children: [
              // Header with Title & "+ Add" Action Button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Transactions',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                      color: AppColors.darkTextPrimary,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _showAddOptionsModal(context),
                    child: Container(
                      height: 38,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.35),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Icon(Icons.add_rounded, size: 18, color: Colors.black),
                          SizedBox(width: 4),
                          Text(
                            'Add',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Filter Chips Row (Calendar Filter + All / Expense / Income / Transfer)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    // Calendar Filter Button
                    _buildCalendarFilterPill(
                      transactions: allTransactions,
                      transfers: allTransfers,
                      accountMap: accountMap,
                    ),
                    const SizedBox(width: 8),

                    // Filter Chips (All / Expense / Income / Transfer)
                    ...List.generate(_filters.length, (index) {
                      final isSelected = _selectedFilterIndex == index;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedFilterIndex = index),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected ? AppColors.primary : AppColors.darkCardBg,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected ? AppColors.primary : AppColors.darkCardBorder,
                              ),
                            ),
                            child: Text(
                              _filters[index],
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                                color: isSelected ? Colors.black : AppColors.darkTextSecondary,
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Combined Activity List
              if (isLoading && !transactionsAsync.hasValue)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.only(top: 80),
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                  ),
                )
              else if (hasError && !transactionsAsync.hasValue)
                Center(
                  child: Text('Error loading data', style: const TextStyle(color: AppColors.red)),
                )
              else
                _buildActivityList(
                  transactions: allTransactions,
                  transfers: allTransfers,
                  accountMap: accountMap,
                ),
            ],
          ),
        ),
      ),
    );
  }

  static const _monthNames = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];

  static const _monthShortNames = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];

  Widget _buildCalendarFilterPill({
    required List<Transaction> transactions,
    required List<Transfer> transfers,
    required Map<String, Account> accountMap,
  }) {
    final activeDates = <DateTime>{};
    for (final t in transactions) {
      activeDates.add(DateTime(t.transactionDate.year, t.transactionDate.month, t.transactionDate.day));
    }
    for (final tr in transfers) {
      activeDates.add(DateTime(tr.transferDate.year, tr.transferDate.month, tr.transferDate.day));
    }

    final dailySummaryMap = _buildDailySummaryMap(transactions, transfers);

    final hasFilter = _startDateFilter != null || _selectedMonthFilter != null;
    String filterLabel = 'Calendar';
    if (_startDateFilter != null) {
      if (_endDateFilter != null && !_isSameDay(_startDateFilter!, _endDateFilter!)) {
        final s = _startDateFilter!;
        final e = _endDateFilter!;
        if (s.month == e.month && s.year == e.year) {
          filterLabel = '${s.day} - ${e.day} ${_monthShortNames[s.month - 1]} ${s.year}';
        } else {
          filterLabel = '${s.day} ${_monthShortNames[s.month - 1]} - ${e.day} ${_monthShortNames[e.month - 1]}';
        }
      } else {
        final d = _startDateFilter!;
        filterLabel = '${d.day} ${_monthShortNames[d.month - 1]} ${d.year}';
      }
    } else if (_selectedMonthFilter != null) {
      final m = _selectedMonthFilter!;
      filterLabel = '${_monthShortNames[m.month - 1]} ${m.year}';
    }

    return GestureDetector(
      onTap: () {
        TransactionCalendarSheet.show(
          context,
          startDate: _startDateFilter,
          endDate: _endDateFilter,
          activeDates: activeDates,
          dailySummaryMap: dailySummaryMap,
          onDateRangeSelected: (start, end) {
            setState(() {
              _startDateFilter = start;
              _endDateFilter = end;
              _selectedMonthFilter = null;
            });
          },
          onMonthSelected: (month) {
            setState(() {
              _selectedMonthFilter = month;
              _startDateFilter = null;
              _endDateFilter = null;
            });
          },
          onClearFilter: () {
            setState(() {
              _startDateFilter = null;
              _endDateFilter = null;
              _selectedMonthFilter = null;
            });
          },
        );
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: EdgeInsets.symmetric(horizontal: hasFilter ? 12 : 14, vertical: 8),
        decoration: BoxDecoration(
          color: hasFilter ? AppColors.primary : AppColors.darkCardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: hasFilter ? AppColors.primary : AppColors.darkCardBorder,
          ),
          boxShadow: hasFilter
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.calendar_month_rounded,
              size: 15,
              color: hasFilter ? Colors.black : AppColors.primary,
            ),
            const SizedBox(width: 6),
            Text(
              filterLabel,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: hasFilter ? FontWeight.w700 : FontWeight.w600,
                color: hasFilter ? Colors.black : AppColors.darkTextPrimary,
              ),
            ),
            if (hasFilter) ...[
              const SizedBox(width: 6),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _startDateFilter = null;
                    _endDateFilter = null;
                    _selectedMonthFilter = null;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: Colors.black26,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close_rounded, size: 12, color: Colors.black),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Map<DateTime, String> _buildDailySummaryMap(
    List<Transaction> transactions,
    List<Transfer> transfers,
  ) {
    final map = <DateTime, List<_ActivityItem>>{};
    for (final t in transactions) {
      final d = DateTime(t.transactionDate.year, t.transactionDate.month, t.transactionDate.day);
      map.putIfAbsent(d, () => []).add(_TxActivityItem(t));
    }
    for (final tr in transfers) {
      final d = DateTime(tr.transferDate.year, tr.transferDate.month, tr.transferDate.day);
      map.putIfAbsent(d, () => []).add(_TransferActivityItem(tr));
    }

    final result = <DateTime, String>{};
    for (final entry in map.entries) {
      final count = entry.value.length;
      result[entry.key] = '$count ${count == 1 ? 'transaction' : 'transactions'} recorded';
    }
    return result;
  }

  String _computeDaySummary(List<_ActivityItem> dayItems) {
    final count = dayItems.length;
    return '$count ${count == 1 ? 'Transaction' : 'Transactions'}';
  }

  Widget _buildActivityList({
    required List<Transaction> transactions,
    required List<Transfer> transfers,
    required Map<String, Account> accountMap,
  }) {
    List<_ActivityItem> items = [];

    if (_selectedFilterIndex == 0) {
      // All (Transactions + Transfers)
      items = [
        ...transactions.map((t) => _TxActivityItem(t)),
        ...transfers.map((t) => _TransferActivityItem(t)),
      ]..sort((a, b) => b.date.compareTo(a.date));
    } else if (_selectedFilterIndex == 1) {
      // Expense
      items = transactions
          .where((t) => t.type == 'expense')
          .map((t) => _TxActivityItem(t))
          .toList()
        ..sort((a, b) => b.date.compareTo(a.date));
    } else if (_selectedFilterIndex == 2) {
      // Income
      items = transactions
          .where((t) => t.type == 'income')
          .map((t) => _TxActivityItem(t))
          .toList()
        ..sort((a, b) => b.date.compareTo(a.date));
    } else if (_selectedFilterIndex == 3) {
      // Transfer
      items = transfers
          .map((t) => _TransferActivityItem(t))
          .toList()
        ..sort((a, b) => b.date.compareTo(a.date));
    }

    // Apply Calendar / Date Range / Month Filter
    if (_startDateFilter != null) {
      final startDay = DateTime(_startDateFilter!.year, _startDateFilter!.month, _startDateFilter!.day);
      final endDay = _endDateFilter != null
          ? DateTime(_endDateFilter!.year, _endDateFilter!.month, _endDateFilter!.day, 23, 59, 59, 999)
          : DateTime(_startDateFilter!.year, _startDateFilter!.month, _startDateFilter!.day, 23, 59, 59, 999);

      items = items.where((item) {
        return (item.date.isAfter(startDay) || item.date.isAtSameMomentAs(startDay)) &&
            (item.date.isBefore(endDay) || item.date.isAtSameMomentAs(endDay));
      }).toList();
    } else if (_selectedMonthFilter != null) {
      final m = _selectedMonthFilter!;
      items = items
          .where((item) =>
              item.date.year == m.year &&
              item.date.month == m.month)
          .toList();
    }

    if (items.isEmpty) {
      String emptyMessage = 'No records found';
      if (_startDateFilter != null) {
        if (_endDateFilter != null && !_isSameDay(_startDateFilter!, _endDateFilter!)) {
          final s = _startDateFilter!;
          final e = _endDateFilter!;
          emptyMessage = 'No transactions between ${s.day} ${_monthShortNames[s.month - 1]} and ${e.day} ${_monthShortNames[e.month - 1]} ${e.year}';
        } else {
          final d = _startDateFilter!;
          emptyMessage = 'No transactions on ${d.day} ${_monthShortNames[d.month - 1]} ${d.year}';
        }
      } else if (_selectedMonthFilter != null) {
        final m = _selectedMonthFilter!;
        emptyMessage = 'No transactions in ${_monthNames[m.month - 1]} ${m.year}';
      } else if (_selectedFilterIndex == 1) {
        emptyMessage = 'No expense transactions found';
      } else if (_selectedFilterIndex == 2) {
        emptyMessage = 'No income transactions found';
      } else if (_selectedFilterIndex == 3) {
        emptyMessage = 'No transfer logs found';
      }

      final hasDateFilter = _startDateFilter != null || _selectedMonthFilter != null;

      return Center(
        child: Padding(
          padding: const EdgeInsets.only(top: 60),
          child: Column(
            children: [
              Icon(
                hasDateFilter
                    ? Icons.event_busy_rounded
                    : _selectedFilterIndex == 3
                        ? Icons.swap_horiz_rounded
                        : Icons.receipt_long_outlined,
                size: 48,
                color: AppColors.darkTextMuted,
              ),
              const SizedBox(height: 12),
              Text(
                emptyMessage,
                style: const TextStyle(color: AppColors.darkTextSecondary, fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              if (hasDateFilter)
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF22242D),
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.darkCardBorder),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () {
                    setState(() {
                      _startDateFilter = null;
                      _endDateFilter = null;
                      _selectedMonthFilter = null;
                    });
                  },
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text(
                    'Clear Date Filter',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                )
              else
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () {
                    if (_selectedFilterIndex == 3) {
                      AddTransferSheet.show(context);
                    } else {
                      _showAddOptionsModal(context);
                    }
                  },
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: Text(
                    _selectedFilterIndex == 3 ? 'Make First Transfer' : 'Record New Entry',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
            ],
          ),
        ),
      );
    }

    // Group items chronologically by date
    final Map<DateTime, List<_ActivityItem>> groupedByDay = {};
    for (final item in items) {
      final dayKey = DateTime(item.date.year, item.date.month, item.date.day);
      groupedByDay.putIfAbsent(dayKey, () => []).add(item);
    }
    final sortedDays = groupedByDay.keys.toList()..sort((a, b) => b.compareTo(a));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: sortedDays.expand((day) {
        final dayItems = groupedByDay[day]!;
        final summary = _computeDaySummary(dayItems);

        return [
          _DateSectionHeader(date: day, summaryText: summary),
          ...dayItems.map((item) {
            if (item is _TxActivityItem) {
              final t = item.transaction;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _TransactionCard(
                  transaction: t,
                  account: accountMap[t.accountId],
                  onTap: () => _showTransactionActionsModal(context, ref, t, accountMap[t.accountId]),
                ),
              );
            } else if (item is _TransferActivityItem) {
              final tr = item.transfer;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _TransferCard(
                  transfer: tr,
                  fromAccount: accountMap[tr.fromAccountId],
                  toAccount: accountMap[tr.toAccountId],
                  onTap: () => _showTransferActionsModal(
                    context,
                    ref,
                    tr,
                    accountMap[tr.fromAccountId],
                    accountMap[tr.toAccountId],
                  ),
                ),
              );
            }
            return const SizedBox.shrink();
          }),
        ];
      }).toList(),
    );
  }

  void _showTransactionActionsModal(
    BuildContext context,
    WidgetRef ref,
    Transaction transaction,
    Account? account,
  ) {
    final isExpense = transaction.type == 'expense';
    final isMyr = account?.currency == 'MYR';
    final date = transaction.transactionDate;
    final formattedAmount = isMyr
        ? 'RM ${transaction.amount % 1 == 0 ? transaction.amount.toStringAsFixed(0) : transaction.amount.toStringAsFixed(2)}'
        : 'Rp ${_formatNumber(transaction.amount)}';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: AppColors.darkCardBg,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          border: Border(
            top: BorderSide(color: AppColors.darkCardBorder, width: 1.5),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.darkTextMuted,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Transaction Overview Header Card
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.black38,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.darkCardBorder),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: (isExpense ? AppColors.red : AppColors.primary).withValues(alpha: 0.15),
                      border: Border.all(
                        color: (isExpense ? AppColors.red : AppColors.primary).withValues(alpha: 0.3),
                      ),
                    ),
                    child: Icon(
                      isExpense ? Icons.arrow_outward_rounded : Icons.arrow_downward_rounded,
                      size: 20,
                      color: isExpense ? AppColors.red : AppColors.primaryLight,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          transaction.description?.isNotEmpty == true
                              ? transaction.description!
                              : (isExpense ? 'Expense' : 'Income'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.darkTextPrimary,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${account != null ? '${account.name} \u00b7 ' : ''}${isExpense ? 'Expense' : 'Income'} \u00b7 ${date.day}/${date.month}/${date.year}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.darkTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${isExpense ? '-' : '+'}$formattedAmount',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: isExpense ? AppColors.red : AppColors.green,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Option 1: Edit Transaction
            _AddActionOptionTile(
              icon: Icons.edit_rounded,
              iconBgColor: AppColors.primary,
              iconColor: Colors.black,
              title: 'Edit Transaction',
              subtitle: 'Change amount, category, account, or notes',
              onTap: () {
                Navigator.pop(ctx);
                AddTransactionSheet.show(context, transactionToEdit: transaction);
              },
            ),
            const SizedBox(height: 12),

            // Option 2: Delete Transaction
            _AddActionOptionTile(
              icon: Icons.delete_outline_rounded,
              iconBgColor: AppColors.red.withValues(alpha: 0.15),
              iconColor: AppColors.red,
              title: 'Delete Transaction',
              subtitle: 'Permanently remove this transaction record',
              onTap: () {
                Navigator.pop(ctx);
                _confirmDeleteTransaction(context, ref, transaction, account);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showTransferActionsModal(
    BuildContext context,
    WidgetRef ref,
    Transfer transfer,
    Account? fromAccount,
    Account? toAccount,
  ) {
    final date = transfer.transferDate;
    final fromName = fromAccount?.name ?? 'Account';
    final toName = toAccount?.name ?? 'Account';
    final fromCurrency = fromAccount?.currency ?? 'IDR';
    final fromAmountStr = fromCurrency == 'MYR'
        ? 'RM ${transfer.amountFrom % 1 == 0 ? transfer.amountFrom.toStringAsFixed(0) : transfer.amountFrom.toStringAsFixed(2)}'
        : 'Rp ${_formatNumber(transfer.amountFrom)}';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: AppColors.darkCardBg,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          border: Border(
            top: BorderSide(color: AppColors.darkCardBorder, width: 1.5),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.darkTextMuted,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Transfer Overview Header Card
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.black38,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.darkCardBorder),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.teal.withValues(alpha: 0.15),
                      border: Border.all(
                        color: AppColors.teal.withValues(alpha: 0.3),
                      ),
                    ),
                    child: const Icon(
                      Icons.swap_horiz_rounded,
                      size: 22,
                      color: AppColors.teal,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$fromName \u2192 $toName',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.darkTextPrimary,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Transfer \u00b7 ${date.day}/${date.month}/${date.year}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.darkTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    fromAmountStr,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.teal,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Option: Delete Transfer Log
            _AddActionOptionTile(
              icon: Icons.delete_outline_rounded,
              iconBgColor: AppColors.red.withValues(alpha: 0.15),
              iconColor: AppColors.red,
              title: 'Delete Transfer Log',
              subtitle: 'Permanently remove this transfer record',
              onTap: () {
                Navigator.pop(ctx);
                _confirmDeleteTransfer(context, ref, transfer, fromAccount, toAccount);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDeleteTransaction(BuildContext context, WidgetRef ref, Transaction transaction, Account? account) async {
    final isMyr = account?.currency == 'MYR';
    final formattedAmount = isMyr
        ? 'RM ${transaction.amount % 1 == 0 ? transaction.amount.toStringAsFixed(0) : transaction.amount.toStringAsFixed(2)}'
        : 'Rp ${_formatNumber(transaction.amount)}';

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.darkCardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Delete Transaction', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
        content: Text(
          'Are you sure you want to delete this ${transaction.type} transaction of $formattedAmount?',
          style: const TextStyle(color: AppColors.darkTextSecondary, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: AppColors.darkTextSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await deleteTransaction(ref, transaction.id);
    }
  }

  Future<void> _confirmDeleteTransfer(
    BuildContext context,
    WidgetRef ref,
    Transfer transfer,
    Account? fromAcc,
    Account? toAcc,
  ) async {
    final fromName = fromAcc?.name ?? 'Account';
    final toName = toAcc?.name ?? 'Account';
    final fromCurrency = fromAcc?.currency ?? 'IDR';
    final formattedAmount = fromCurrency == 'MYR'
        ? 'RM ${transfer.amountFrom % 1 == 0 ? transfer.amountFrom.toStringAsFixed(0) : transfer.amountFrom.toStringAsFixed(2)}'
        : 'Rp ${_formatNumber(transfer.amountFrom)}';

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.darkCardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Delete Transfer Log', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
        content: Text(
          'Are you sure you want to delete this transfer of $formattedAmount from $fromName to $toName?',
          style: const TextStyle(color: AppColors.darkTextSecondary, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: AppColors.darkTextSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await deleteTransfer(ref, transfer.id);
    }
  }

  static String _formatNumber(num val) {
    final s = val.toStringAsFixed(0);
    final buffer = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buffer.write('.');
      buffer.write(s[i]);
    }
    return buffer.toString();
  }
}

class _AddActionOptionTile extends StatelessWidget {
  const _AddActionOptionTile({
    required this.icon,
    required this.iconBgColor,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color iconBgColor;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.black45,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.darkCardBorder),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: iconBgColor,
              ),
              child: Icon(icon, size: 22, color: iconColor),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.darkTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.darkTextSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.darkTextSecondary, size: 20),
          ],
        ),
      ),
    );
  }
}

class _TransactionCard extends StatelessWidget {
  const _TransactionCard({
    required this.transaction,
    this.account,
    required this.onTap,
  });

  final Transaction transaction;
  final Account? account;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isExpense = transaction.type == 'expense';
    final isMyr = account?.currency == 'MYR';
    final date = transaction.transactionDate;
    final formattedAmount = isMyr
        ? 'RM ${transaction.amount % 1 == 0 ? transaction.amount.toStringAsFixed(0) : transaction.amount.toStringAsFixed(2)}'
        : 'Rp ${_formatNumber(transaction.amount)}';

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: (isExpense ? AppColors.red : AppColors.primary).withValues(alpha: 0.15),
                      border: Border.all(
                        color: (isExpense ? AppColors.red : AppColors.primary).withValues(alpha: 0.3),
                      ),
                    ),
                    child: Icon(
                      isExpense ? Icons.arrow_outward_rounded : Icons.arrow_downward_rounded,
                      size: 18,
                      color: isExpense ? AppColors.red : AppColors.primaryLight,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          transaction.description?.isNotEmpty == true
                              ? transaction.description!
                              : (isExpense ? 'Expense' : 'Income'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.darkTextPrimary,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${account != null ? '${account!.name} \u00b7 ' : ''}${isExpense ? 'Expense' : 'Income'} \u00b7 ${date.day}/${date.month}/${date.year}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: AppColors.darkTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${isExpense ? '-' : '+'}$formattedAmount',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: isExpense ? AppColors.red : AppColors.green,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _formatNumber(num val) {
    final s = val.toStringAsFixed(0);
    final buffer = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buffer.write('.');
      buffer.write(s[i]);
    }
    return buffer.toString();
  }
}

class _TransferCard extends StatelessWidget {
  const _TransferCard({
    required this.transfer,
    this.fromAccount,
    this.toAccount,
    required this.onTap,
  });

  final Transfer transfer;
  final Account? fromAccount;
  final Account? toAccount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final date = transfer.transferDate;
    final fromName = fromAccount?.name ?? 'Account';
    final toName = toAccount?.name ?? 'Account';
    final fromCurrency = fromAccount?.currency ?? 'IDR';
    final toCurrency = toAccount?.currency ?? 'IDR';
    final isSameCurrency = fromCurrency == toCurrency;

    final fromAmountStr = fromCurrency == 'MYR'
        ? 'RM ${transfer.amountFrom % 1 == 0 ? transfer.amountFrom.toStringAsFixed(0) : transfer.amountFrom.toStringAsFixed(2)}'
        : 'Rp ${_formatNumber(transfer.amountFrom)}';

    final toAmountStr = toCurrency == 'MYR'
        ? 'RM ${transfer.amountTo % 1 == 0 ? transfer.amountTo.toStringAsFixed(0) : transfer.amountTo.toStringAsFixed(2)}'
        : 'Rp ${_formatNumber(transfer.amountTo)}';

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.teal.withValues(alpha: 0.15),
                      border: Border.all(
                        color: AppColors.teal.withValues(alpha: 0.3),
                      ),
                    ),
                    child: const Icon(
                      Icons.swap_horiz_rounded,
                      size: 20,
                      color: AppColors.teal,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$fromName \u2192 $toName',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.darkTextPrimary,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Transfer \u00b7 ${date.day}/${date.month}/${date.year}${transfer.notes != null && transfer.notes!.isNotEmpty ? ' \u00b7 ${transfer.notes}' : ''}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: AppColors.darkTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  fromAmountStr,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.teal,
                  ),
                ),
                if (!isSameCurrency)
                  Text(
                    '\u2192 $toAmountStr',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.darkTextSecondary,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static String _formatNumber(num val) {
    final s = val.toStringAsFixed(0);
    final buffer = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buffer.write('.');
      buffer.write(s[i]);
    }
    return buffer.toString();
  }
}

class _DateSectionHeader extends StatelessWidget {
  const _DateSectionHeader({
    required this.date,
    required this.summaryText,
  });

  final DateTime date;
  final String summaryText;

  static const _weekdays = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
  ];

  static const _monthShortNames = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];

  String _formatDateTitle(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final target = DateTime(date.year, date.month, date.day);

    final weekdayName = _weekdays[date.weekday - 1];
    final monthName = _monthShortNames[date.month - 1];

    if (target == today) {
      return 'Today, ${date.day} $monthName';
    } else if (target == yesterday) {
      return 'Yesterday, ${date.day} $monthName';
    } else {
      return '$weekdayName, ${date.day} $monthName ${date.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 14, bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _formatDateTitle(date),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.darkTextPrimary,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
          if (summaryText.isNotEmpty)
            Flexible(
              child: Container(
                margin: const EdgeInsets.only(left: 8),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E2028),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.darkCardBorder),
                ),
                child: Text(
                  summaryText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.darkTextSecondary,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

