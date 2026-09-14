import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
                      fontWeight: FontWeight.w700,
                      color: AppColors.darkTextPrimary,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _showAddOptionsModal(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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

              // Filter Chips (All / Expense / Income / Transfer)
              SizedBox(
                height: 36,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _filters.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final isSelected = _selectedFilterIndex == index;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedFilterIndex = index),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primary : AppColors.darkCardBg,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected ? AppColors.primary : AppColors.darkCardBorder,
                          ),
                        ),
                        child: Text(
                          _filters[index],
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected ? Colors.black : AppColors.darkTextSecondary,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),

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
                  transactions: transactionsAsync.asData?.value ?? [],
                  transfers: transfersAsync.asData?.value ?? [],
                  accountMap: accountMap,
                ),
            ],
          ),
        ),
      ),
    );
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

    if (items.isEmpty) {
      String emptyMessage = 'No records found';
      if (_selectedFilterIndex == 1) emptyMessage = 'No expense transactions found';
      if (_selectedFilterIndex == 2) emptyMessage = 'No income transactions found';
      if (_selectedFilterIndex == 3) emptyMessage = 'No transfer logs found';

      return Center(
        child: Padding(
          padding: const EdgeInsets.only(top: 60),
          child: Column(
            children: [
              Icon(
                _selectedFilterIndex == 3 ? Icons.swap_horiz_rounded : Icons.receipt_long_outlined,
                size: 48,
                color: AppColors.darkTextMuted,
              ),
              const SizedBox(height: 12),
              Text(
                emptyMessage,
                style: const TextStyle(color: AppColors.darkTextSecondary, fontSize: 14),
              ),
              const SizedBox(height: 16),
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

    return Column(
      children: items.map((item) {
        if (item is _TxActivityItem) {
          final t = item.transaction;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _TransactionCard(
              transaction: t,
              account: accountMap[t.accountId],
              onEdit: () => AddTransactionSheet.show(context, transactionToEdit: t),
              onDelete: () => _confirmDeleteTransaction(context, ref, t, accountMap[t.accountId]),
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
              onDelete: () => _confirmDeleteTransfer(
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
      }).toList(),
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
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Transaction deleted successfully'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
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
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Transfer log deleted successfully'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
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
    required this.onEdit,
    required this.onDelete,
  });

  final Transaction transaction;
  final Account? account;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final isExpense = transaction.type == 'expense';
    final isMyr = account?.currency == 'MYR';
    final date = transaction.transactionDate;
    final formattedAmount = isMyr
        ? 'RM ${transaction.amount % 1 == 0 ? transaction.amount.toStringAsFixed(0) : transaction.amount.toStringAsFixed(2)}'
        : 'Rp ${_formatNumber(transaction.amount)}';

    return GlassCard(
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
          Row(
            children: [
              Text(
                '${isExpense ? '-' : '+'}$formattedAmount',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isExpense ? AppColors.red : AppColors.green,
                ),
              ),
              const SizedBox(width: 4),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded, size: 18, color: AppColors.darkTextSecondary),
                color: AppColors.darkCardBg,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                onSelected: (val) {
                  if (val == 'edit') {
                    onEdit();
                  } else if (val == 'delete') {
                    onDelete();
                  }
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit_outlined, size: 16, color: AppColors.primaryLight),
                        SizedBox(width: 8),
                        Text('Edit', style: TextStyle(color: Colors.white, fontSize: 13)),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline_rounded, size: 16, color: AppColors.red),
                        SizedBox(width: 8),
                        Text('Delete', style: TextStyle(color: AppColors.red, fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
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
    required this.onDelete,
  });

  final Transfer transfer;
  final Account? fromAccount;
  final Account? toAccount;
  final VoidCallback onDelete;

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

    return GlassCard(
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
          Row(
            children: [
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
              const SizedBox(width: 4),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded, size: 18, color: AppColors.darkTextSecondary),
                color: AppColors.darkCardBg,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                onSelected: (val) {
                  if (val == 'delete') {
                    onDelete();
                  }
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline_rounded, size: 16, color: AppColors.red),
                        SizedBox(width: 8),
                        Text('Delete', style: TextStyle(color: AppColors.red, fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
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
