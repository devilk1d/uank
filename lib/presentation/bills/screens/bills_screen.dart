import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_background.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/app_calendar_sheet.dart';
import '../../../domain/entities/bill.dart';
import '../../../domain/entities/bill_payment.dart';
import '../../accounts/providers/account_providers.dart';
import '../providers/bill_providers.dart';
import '../widgets/pay_bill_dialog.dart';
import 'add_bill_sheet.dart';

const _monthNames = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December'
];

const _shortMonthNames = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
];

class BillsScreen extends ConsumerWidget {
  const BillsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedMonth = ref.watch(selectedBillsMonthProvider);
    final billsAsync = ref.watch(billsProvider);
    final paymentsAsync = ref.watch(billPaymentsForSelectedMonthProvider);
    final accountsAsync = ref.watch(accountsProvider);

    final now = DateTime.now();
    final isCurrentMonth = selectedMonth.year == now.year && selectedMonth.month == now.month;

    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 110),
            children: [
              // 1. Header
              _buildHeader(context),
              const SizedBox(height: 16),

              // 2. Month Switcher Bar
              _buildMonthSwitcher(context, ref, selectedMonth, isCurrentMonth),
              const SizedBox(height: 18),

              // 3. Main Bills Content
              billsAsync.when(
                data: (bills) {
                  if (bills.isEmpty) {
                    return _buildNoBillsState(context);
                  }

                  final payments = paymentsAsync.value ?? [];
                  final accounts = accountsAsync.value ?? [];

                  // Map bills to paid status for selected month
                  final paidBills = <(Bill, BillPayment)>[];
                  final unpaidBills = <(Bill, BillPayment?)>[];

                  for (final bill in bills) {
                    final payment = payments.where((p) => p.billId == bill.id).firstOrNull;
                    if (payment != null && payment.status == 'paid') {
                      paidBills.add((bill, payment));
                    } else {
                      unpaidBills.add((bill, payment));
                    }
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Overview Progress Hero Card
                      _MonthlyOverviewCard(
                        bills: bills,
                        paidCount: paidBills.length,
                        paidPayments: paidBills.map((e) => e.$2).toList(),
                        unpaidBills: unpaidBills.map((e) => e.$1).toList(),
                        selectedMonth: selectedMonth,
                      ),
                      const SizedBox(height: 24),

                      // Unpaid Bills Section
                      if (unpaidBills.isNotEmpty) ...[
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: AppColors.orange,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'To Pay (${unpaidBills.length})',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppColors.darkTextPrimary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ...unpaidBills.map((item) {
                          final bill = item.$1;
                          final account = accounts.where((a) => a.id == bill.accountId).firstOrNull;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _UnpaidBillCard(
                              bill: bill,
                              accountName: account?.name,
                              selectedMonth: selectedMonth,
                              isCurrentMonth: isCurrentMonth,
                              onPay: () => PayBillDialog.show(
                                context,
                                bill,
                                periodMonth: selectedMonth,
                              ),
                            ),
                          );
                        }),
                      ] else ...[
                        // All Paid Celebration Card
                        _buildAllPaidCard(selectedMonth),
                      ],

                      // Paid Bills Section
                      if (paidBills.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Paid This Month (${paidBills.length})',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppColors.darkTextPrimary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ...paidBills.map((item) {
                          final bill = item.$1;
                          final payment = item.$2;
                          final account = accounts.where((a) => a.id == bill.accountId).firstOrNull;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _PaidBillCard(
                              bill: bill,
                              payment: payment,
                              accountName: account?.name,
                            ),
                          );
                        }),
                      ],
                    ],
                  );
                },
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.only(top: 80),
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                  ),
                ),
                error: (e, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 40),
                    child: Text('Failed to load bills: $e', style: const TextStyle(color: AppColors.red)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Monthly Bills',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
                color: AppColors.darkTextPrimary,
              ),
            ),

          ],
        ),
        GestureDetector(
          onTap: () => AddBillSheet.show(context),
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
    );
  }

  Widget _buildMonthSwitcher(
    BuildContext context,
    WidgetRef ref,
    DateTime selectedMonth,
    bool isCurrentMonth,
  ) {
    final monthName = _monthNames[selectedMonth.month - 1];
    final year = selectedMonth.year;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.darkCardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.darkCardBorder),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left_rounded, color: AppColors.darkTextPrimary, size: 24),
            visualDensity: VisualDensity.compact,
            onPressed: () => ref.read(selectedBillsMonthProvider.notifier).prevMonth(),
          ),
          GestureDetector(
            onTap: () async {
              final picked = await AppMonthPickerSheet.show(
                context,
                initialMonth: selectedMonth,
                title: 'Select Billing Month',
              );
              if (picked != null) {
                ref.read(selectedBillsMonthProvider.notifier).setMonth(picked);
              }
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.calendar_month_outlined, size: 16, color: AppColors.primaryLight),
                const SizedBox(width: 8),
                Text(
                  '$monthName $year',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.darkTextPrimary,
                  ),
                ),
                const SizedBox(width: 8),
                if (isCurrentMonth)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                    ),
                    child: const Text(
                      'This Month',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryLight,
                      ),
                    ),
                  )
                else
                  GestureDetector(
                    onTap: () {
                      final now = DateTime.now();
                      ref.read(selectedBillsMonthProvider.notifier).setMonth(DateTime(now.year, now.month, 1));
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.replay_rounded, size: 11, color: AppColors.darkTextSecondary),
                          SizedBox(width: 3),
                          Text(
                            'Today',
                            style: TextStyle(fontSize: 10, color: AppColors.darkTextSecondary),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right_rounded, color: AppColors.darkTextPrimary, size: 24),
            visualDensity: VisualDensity.compact,
            onPressed: () => ref.read(selectedBillsMonthProvider.notifier).nextMonth(),
          ),
        ],
      ),
    );
  }

  Widget _buildAllPaidCard(DateTime selectedMonth) {
    final monthName = _monthNames[selectedMonth.month - 1];
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_circle_rounded, color: AppColors.primaryLight, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'All Bills Paid!',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.darkTextPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'All scheduled bills for $monthName ${selectedMonth.year} are completely paid.',
                  style: const TextStyle(fontSize: 12, color: AppColors.darkTextSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoBillsState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 60),
        child: Column(
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.04),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.darkCardBorder),
              ),
              child: const Icon(Icons.receipt_long_outlined, size: 36, color: AppColors.darkTextMuted),
            ),
            const SizedBox(height: 16),
            const Text(
              'No bills registered yet',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.darkTextPrimary,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Add your recurring internet, utilities, or rent\nto get reminders and track monthly payments.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppColors.darkTextSecondary, height: 1.4),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: () => AddBillSheet.show(context),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Create First Bill', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }
}

class _MonthlyOverviewCard extends StatelessWidget {
  const _MonthlyOverviewCard({
    required this.bills,
    required this.paidCount,
    required this.paidPayments,
    required this.unpaidBills,
    required this.selectedMonth,
  });

  final List<Bill> bills;
  final int paidCount;
  final List<BillPayment> paidPayments;
  final List<Bill> unpaidBills;
  final DateTime selectedMonth;

  @override
  Widget build(BuildContext context) {
    final totalCount = bills.length;
    final progress = totalCount > 0 ? (paidCount / totalCount).clamp(0.0, 1.0) : 0.0;

    // Calculate Paid vs Remaining summary strings
    final paidTotals = <String, num>{};
    for (final p in paidPayments) {
      final bill = bills.where((b) => b.id == p.billId).firstOrNull;
      final currency = bill?.currency ?? 'IDR';
      final amount = p.amountPaid ?? bill?.amount ?? 0;
      paidTotals[currency] = (paidTotals[currency] ?? 0) + amount;
    }

    final remainingTotals = <String, num>{};
    for (final b in unpaidBills) {
      remainingTotals[b.currency] = (remainingTotals[b.currency] ?? 0) + b.amount;
    }

    String formatGrouped(Map<String, num> map, {String emptyText = '0'}) {
      if (map.isEmpty) return emptyText;
      return map.entries
          .map((e) => '${e.key} ${CurrencyInputFormatter.format(e.value)}')
          .join(' + ');
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.darkCardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.darkCardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Progress Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'MONTHLY PROGRESS',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.0,
                      color: AppColors.darkTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$paidCount of $totalCount Bills Paid',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.darkTextPrimary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: progress == 1.0
                      ? AppColors.primary.withValues(alpha: 0.2)
                      : Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: progress == 1.0
                        ? AppColors.primary
                        : Colors.white.withValues(alpha: 0.12),
                  ),
                ),
                child: Text(
                  '${(progress * 100).toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: progress == 1.0 ? AppColors.primaryLight : AppColors.darkTextPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              height: 8,
              child: Stack(
                children: [
                  Container(color: Colors.white.withValues(alpha: 0.08)),
                  FractionallySizedBox(
                    widthFactor: progress,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.primaryLight, AppColors.primary],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.5),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),

          // 2-Column Summary Cards
          Row(
            children: [
              // Paid Col
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.check_circle_outline_rounded, size: 14, color: AppColors.primaryLight),
                          SizedBox(width: 5),
                          Text(
                            'Paid So Far',
                            style: TextStyle(fontSize: 11, color: AppColors.darkTextSecondary, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        formatGrouped(paidTotals),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryLight,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Remaining Col
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.pending_actions_rounded, size: 14, color: AppColors.orange),
                          SizedBox(width: 5),
                          Text(
                            'Remaining Due',
                            style: TextStyle(fontSize: 11, color: AppColors.darkTextSecondary, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        formatGrouped(remainingTotals),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: remainingTotals.isNotEmpty ? AppColors.orange : AppColors.darkTextMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _UnpaidBillCard extends StatelessWidget {
  const _UnpaidBillCard({
    required this.bill,
    this.accountName,
    required this.selectedMonth,
    required this.isCurrentMonth,
    required this.onPay,
  });

  final Bill bill;
  final String? accountName;
  final DateTime selectedMonth;
  final bool isCurrentMonth;
  final VoidCallback onPay;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = now.day;
    final isOverdue = isCurrentMonth && (today > bill.dueDay);
    final isDueToday = isCurrentMonth && (today == bill.dueDay);
    final daysLeft = bill.dueDay - today;

    String statusBadgeText;
    Color statusBadgeColor;
    Color statusBadgeTextColor;

    if (isCurrentMonth) {
      if (isDueToday) {
        statusBadgeText = 'DUE TODAY';
        statusBadgeColor = AppColors.orange.withValues(alpha: 0.2);
        statusBadgeTextColor = AppColors.orange;
      } else if (isOverdue) {
        final overdueDays = today - bill.dueDay;
        statusBadgeText = 'OVERDUE ($overdueDays ${overdueDays == 1 ? 'day' : 'days'})';
        statusBadgeColor = AppColors.red.withValues(alpha: 0.2);
        statusBadgeTextColor = AppColors.red;
      } else {
        statusBadgeText = 'Due in $daysLeft ${daysLeft == 1 ? 'day' : 'days'}';
        statusBadgeColor = Colors.white.withValues(alpha: 0.08);
        statusBadgeTextColor = AppColors.darkTextSecondary;
      }
    } else {
      statusBadgeText = 'Due on ${bill.dueDay}th';
      statusBadgeColor = Colors.white.withValues(alpha: 0.08);
      statusBadgeTextColor = AppColors.darkTextSecondary;
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.darkCardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isOverdue ? AppColors.red.withValues(alpha: 0.5) : AppColors.darkCardBorder,
          width: isOverdue ? 1.5 : 1.0,
        ),
        boxShadow: [
          if (isOverdue)
            BoxShadow(
              color: AppColors.red.withValues(alpha: 0.1),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: Icon + Name + Status Tag
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: isOverdue
                      ? AppColors.red.withValues(alpha: 0.15)
                      : AppColors.primary.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.receipt_long_rounded,
                  color: isOverdue ? AppColors.red : AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      bill.name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.darkTextPrimary,
                      ),
                    ),
                    if (accountName != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Account: $accountName',
                        style: const TextStyle(fontSize: 11, color: AppColors.darkTextSecondary),
                      ),
                    ],
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: statusBadgeColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isOverdue
                        ? AppColors.red
                        : isDueToday
                            ? AppColors.orange
                            : AppColors.darkCardBorder,
                  ),
                ),
                child: Text(
                  statusBadgeText,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.4,
                    color: statusBadgeTextColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Bottom row: Amount & Pay Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Bill Amount',
                    style: TextStyle(fontSize: 11, color: AppColors.darkTextMuted),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${bill.currency} ${CurrencyInputFormatter.format(bill.amount)}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                      color: AppColors.darkTextPrimary,
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: onPay,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.35),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.payment_rounded, size: 15, color: Colors.black),
                      SizedBox(width: 6),
                      Text(
                        'Pay Now',
                        style: TextStyle(
                          fontSize: 12,
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
        ],
      ),
    );
  }
}

class _PaidBillCard extends StatelessWidget {
  const _PaidBillCard({
    required this.bill,
    required this.payment,
    this.accountName,
  });

  final Bill bill;
  final BillPayment payment;
  final String? accountName;

  @override
  Widget build(BuildContext context) {
    final paidDate = payment.paidDate;
    String paidDateText = 'Paid this month';
    if (paidDate != null) {
      paidDateText = 'Paid on ${paidDate.day} ${_shortMonthNames[paidDate.month - 1]} ${paidDate.year}';
    }

    final amountPaid = payment.amountPaid ?? bill.amount;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.darkCardBg.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_rounded, color: AppColors.primaryLight, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  bill.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.darkTextPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Text(
                      paidDateText,
                      style: const TextStyle(fontSize: 11, color: AppColors.darkTextSecondary),
                    ),
                    if (accountName != null) ...[
                      const Text(' \u00b7 ', style: TextStyle(fontSize: 11, color: AppColors.darkTextMuted)),
                      Text(
                        accountName!,
                        style: const TextStyle(fontSize: 11, color: AppColors.darkTextSecondary),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'PAID \u2713',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryLight,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${bill.currency} ${CurrencyInputFormatter.format(amountPaid)}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.darkTextPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
