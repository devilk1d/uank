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
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1280),
              child: RefreshIndicator(
                color: context.isDark ? AppColors.primary : const Color(0xFF15803D),
                backgroundColor: context.cardBg,
                onRefresh: () async {
                  ref.invalidate(billsProvider);
                  ref.invalidate(billPaymentsForSelectedMonthProvider);
                  ref.invalidate(accountsProvider);
                  await Future.wait([
                    ref.read(billsProvider.future),
                    ref.read(billPaymentsForSelectedMonthProvider.future),
                    ref.read(accountsProvider.future),
                  ]);
                },
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isDesktop = constraints.maxWidth >= 900;

                    return ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: EdgeInsets.fromLTRB(
                        isDesktop ? 28 : 20,
                        isDesktop ? 24 : 16,
                        isDesktop ? 28 : 20,
                        isDesktop ? 48 : 110,
                      ),
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
                              if (isDesktop) {
                                return _buildDesktopEmptyLayout(context, selectedMonth);
                              }
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

                            final overviewCard = _MonthlyOverviewCard(
                              bills: bills,
                              paidCount: paidBills.length,
                              paidPayments: paidBills.map((e) => e.$2).toList(),
                              unpaidBills: unpaidBills.map((e) => e.$1).toList(),
                              selectedMonth: selectedMonth,
                            );

                            final unpaidSection = Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
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
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          color: context.textPrimary,
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
                                  _buildAllPaidCard(context, selectedMonth),
                                ],
                              ],
                            );

                            final paidSection = Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (paidBills.isNotEmpty) ...[
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: BoxDecoration(
                                          color: context.isDark ? AppColors.primary : const Color(0xFF15803D),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Paid This Month (${paidBills.length})',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          color: context.textPrimary,
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

                            if (isDesktop) {
                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Left Column (Overview Hero)
                                  Expanded(
                                    flex: 5,
                                    child: overviewCard,
                                  ),
                                  const SizedBox(width: 24),
                                  // Right Column (Bills list)
                                  Expanded(
                                    flex: 7,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.stretch,
                                      children: [
                                        unpaidSection,
                                        paidSection,
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            }

                            // Mobile single column
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                overviewCard,
                                const SizedBox(height: 24),
                                unpaidSection,
                                paidSection,
                              ],
                            );
                          },
                          loading: () => Center(
                            child: Padding(
                              padding: const EdgeInsets.only(top: 80),
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: context.isDark ? AppColors.primary : const Color(0xFF15803D),
                              ),
                            ),
                          ),
                          error: (e, _) => Center(
                            child: Padding(
                              padding: const EdgeInsets.only(top: 80),
                              child: Text('Error: $e', style: const TextStyle(color: AppColors.red)),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
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
            Text(
              'Monthly Bills',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
                color: context.textPrimary,
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
        color: context.cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.cardBorder),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: Icon(Icons.chevron_left_rounded, color: context.textPrimary, size: 24),
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
                Icon(Icons.calendar_month_outlined, size: 16, color: context.accentIconColor),
                const SizedBox(width: 8),
                Text(
                  '$monthName $year',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: context.textPrimary,
                  ),
                ),
                const SizedBox(width: 8),
                if (isCurrentMonth)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: context.isDark ? AppColors.primary.withValues(alpha: 0.15) : const Color(0xFFDCFCE7),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: (context.isDark ? AppColors.primary : const Color(0xFF15803D)).withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      'This Month',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: context.accentLinkColor,
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
                        color: context.inputBg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.replay_rounded, size: 11, color: context.textSecondary),
                          const SizedBox(width: 3),
                          Text(
                            'Today',
                            style: TextStyle(fontSize: 10, color: context.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.chevron_right_rounded, color: context.textPrimary, size: 24),
            visualDensity: VisualDensity.compact,
            onPressed: () => ref.read(selectedBillsMonthProvider.notifier).nextMonth(),
          ),
        ],
      ),
    );
  }

  Widget _buildAllPaidCard(BuildContext context, DateTime selectedMonth) {
    final monthName = _monthNames[selectedMonth.month - 1];
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.isDark ? AppColors.primary.withValues(alpha: 0.08) : const Color(0xFFDCFCE7),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: (context.isDark ? AppColors.primary : const Color(0xFF15803D)).withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: (context.isDark ? AppColors.primary : const Color(0xFF15803D)).withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.check_circle_rounded, color: context.accentIconColor, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'All Bills Paid!',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: context.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'All scheduled bills for $monthName ${selectedMonth.year} are completely paid.',
                  style: TextStyle(fontSize: 12, color: context.textSecondary),
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
                color: context.inputBg,
                shape: BoxShape.circle,
                border: Border.all(color: context.cardBorder),
              ),
              child: Icon(Icons.receipt_long_outlined, size: 36, color: context.textMuted),
            ),
            const SizedBox(height: 16),
            Text(
              'No bills registered yet',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: context.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Add your recurring internet, utilities, or rent\nto get reminders and track monthly payments.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: context.textSecondary, height: 1.4),
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

  Widget _buildDesktopEmptyLayout(BuildContext context, DateTime selectedMonth) {
    final monthName = _monthNames[selectedMonth.month - 1];
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left Column: Educational Overview / Feature Highlights
        Expanded(
          flex: 5,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: context.cardBg,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: context.cardBorder),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: context.isDark ? 0.25 : 0.05),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        Icons.receipt_long_rounded,
                        color: context.accentIconColor,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Recurring Bills',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: context.textPrimary,
                            ),
                          ),
                          Text(
                            'Multi-currency subscription & utility tracker',
                            style: TextStyle(fontSize: 11, color: context.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _buildGuideFeatureItem(
                  context,
                  icon: Icons.notifications_active_outlined,
                  title: 'Smart Due Date Reminders',
                  desc: 'Set custom reminder alerts before due date so you never miss a deadline.',
                ),
                const SizedBox(height: 14),
                _buildGuideFeatureItem(
                  context,
                  icon: Icons.currency_exchange_rounded,
                  title: 'Multi-Currency Support',
                  desc: 'Track and manage IDR and MYR bills seamlessly side-by-side.',
                ),
                const SizedBox(height: 14),
                _buildGuideFeatureItem(
                  context,
                  icon: Icons.account_balance_wallet_outlined,
                  title: 'Automatic Account Link',
                  desc: 'Optionally link your bills to specific wallets for one-click payment deductions.',
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 24),
        // Right Column: Action Card with Suggestions
        Expanded(
          flex: 7,
          child: Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: context.cardBg,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: context.cardBorder),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: context.isDark ? 0.25 : 0.05),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                  ),
                  child: Icon(Icons.receipt_long_outlined, size: 30, color: context.accentIconColor),
                ),
                const SizedBox(height: 16),
                Text(
                  'No bills registered yet for $monthName',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: context.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Add your recurring internet, utilities, or rent to get reminders and track monthly payments.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12.5, color: context.textSecondary, height: 1.4),
                ),
                const SizedBox(height: 18),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  onPressed: () => AddBillSheet.show(context),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Create First Bill', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                ),
                const SizedBox(height: 22),
                Divider(color: context.cardBorder, height: 1),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'POPULAR BILL CATEGORIES',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      color: context.textMuted,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildBillSuggestionChip(context, '📶 Internet & Wifi'),
                    _buildBillSuggestionChip(context, '⚡ Electricity / PLN'),
                    _buildBillSuggestionChip(context, '🏠 Rent & Housing'),
                    _buildBillSuggestionChip(context, '🎬 Netflix / Spotify'),
                    _buildBillSuggestionChip(context, '💧 Water / Utilities'),
                    _buildBillSuggestionChip(context, '💳 Credit Card'),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGuideFeatureItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String desc,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: context.inputBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: context.cardBorder),
          ),
          child: Icon(icon, size: 16, color: context.textSecondary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: context.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                desc,
                style: TextStyle(fontSize: 11, color: context.textSecondary, height: 1.3),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBillSuggestionChip(BuildContext context, String label) {
    return InkWell(
      onTap: () => AddBillSheet.show(context),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: context.inputBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: context.cardBorder),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: context.textPrimary,
          ),
        ),
      ),
    );
  }
}

class _MonthlyOverviewCard extends StatefulWidget {
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
  State<_MonthlyOverviewCard> createState() => _MonthlyOverviewCardState();
}

class _MonthlyOverviewCardState extends State<_MonthlyOverviewCard> {
  String? _selectedCurrency;

  @override
  Widget build(BuildContext context) {
    // Determine available currencies
    final availableCurrencies = widget.bills.map((b) => b.currency).toSet().toList();
    availableCurrencies.sort((a, b) => a == 'IDR' ? -1 : b == 'IDR' ? 1 : a.compareTo(b));

    final activeCurrency = _selectedCurrency != null && availableCurrencies.contains(_selectedCurrency)
        ? _selectedCurrency!
        : (availableCurrencies.isNotEmpty ? availableCurrencies.first : 'IDR');

    // Filter bills and payments for active currency
    final currencyBills = widget.bills.where((b) => b.currency == activeCurrency).toList();
    final currencyPaidPayments = widget.paidPayments.where((p) {
      final bill = widget.bills.where((b) => b.id == p.billId).firstOrNull;
      return bill != null && bill.currency == activeCurrency;
    }).toList();
    final currencyUnpaidBills = widget.unpaidBills.where((b) => b.currency == activeCurrency).toList();

    final currencyTotalCount = currencyBills.length;
    final currencyPaidCount = currencyPaidPayments.length;
    final progress = currencyTotalCount > 0 ? (currencyPaidCount / currencyTotalCount).clamp(0.0, 1.0) : 0.0;

    // Calculate Paid total
    num paidTotal = 0;
    for (final p in currencyPaidPayments) {
      final bill = widget.bills.where((b) => b.id == p.billId).firstOrNull;
      paidTotal += p.amountPaid ?? bill?.amount ?? 0;
    }

    // Calculate Remaining total
    num remainingTotal = 0;
    for (final b in currencyUnpaidBills) {
      remainingTotal += b.amount;
    }

    final symbol = activeCurrency == 'IDR'
        ? 'Rp'
        : activeCurrency == 'MYR'
            ? 'RM'
            : activeCurrency;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: context.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: context.isDark ? 0.25 : 0.05),
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
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'MONTHLY PROGRESS',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.0,
                      color: context.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$currencyPaidCount of $currencyTotalCount Bills Paid',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: context.textPrimary,
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Currency Switcher Pills (shown if multiple currencies exist)
                  if (availableCurrencies.length > 1) ...[
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: context.inputBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: context.cardBorder),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: availableCurrencies.map((cur) {
                          final isSelected = cur == activeCurrency;
                          return GestureDetector(
                            onTap: () => setState(() => _selectedCurrency = cur),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                              decoration: BoxDecoration(
                                color: isSelected ? AppColors.primary : Colors.transparent,
                                borderRadius: BorderRadius.circular(9),
                              ),
                              child: Text(
                                cur,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: isSelected ? Colors.black : context.textSecondary,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  // Percentage Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: progress == 1.0
                          ? AppColors.primary.withValues(alpha: 0.2)
                          : context.inputBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: progress == 1.0
                            ? AppColors.primary
                            : context.cardBorder,
                      ),
                    ),
                    child: Text(
                      '${(progress * 100).toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: progress == 1.0
                            ? (context.isDark ? AppColors.primaryLight : const Color(0xFF15803D))
                            : context.textPrimary,
                      ),
                    ),
                  ),
                ],
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
                  Container(color: context.cardBorder),
                  FractionallySizedBox(
                    widthFactor: progress,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: context.isDark
                              ? const [AppColors.primaryLight, AppColors.primary]
                              : const [Color(0xFF059669), Color(0xFF15803D)],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: (context.isDark ? AppColors.primary : const Color(0xFF15803D)).withValues(alpha: 0.4),
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

          // 2-Column Symmetrical Summary Cards
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Paid Col
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: context.isDark ? Colors.white.withValues(alpha: 0.04) : context.inputBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: context.cardBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: (context.isDark ? AppColors.primary : const Color(0xFF15803D)).withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.check_circle_outline_rounded,
                                size: 13,
                                color: context.accentIconColor,
                              ),
                            ),
                            const SizedBox(width: 7),
                            Text(
                              'Paid So Far',
                              style: TextStyle(
                                fontSize: 11,
                                color: context.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            '$symbol ${CurrencyInputFormatter.format(paidTotal)}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.2,
                              color: context.isDark ? AppColors.primaryLight : const Color(0xFF15803D),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Remaining Col
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: context.isDark ? Colors.white.withValues(alpha: 0.04) : context.inputBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: context.cardBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: AppColors.orange.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.pending_actions_rounded,
                                size: 13,
                                color: AppColors.orange,
                              ),
                            ),
                            const SizedBox(width: 7),
                            Text(
                              'Remaining Due',
                              style: TextStyle(
                                fontSize: 11,
                                color: context.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            '$symbol ${CurrencyInputFormatter.format(remainingTotal)}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.2,
                              color: remainingTotal > 0 ? AppColors.orange : context.textMuted,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
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
        statusBadgeColor = context.inputBg;
        statusBadgeTextColor = context.textSecondary;
      }
    } else {
      statusBadgeText = 'Due on ${bill.dueDay}th';
      statusBadgeColor = context.inputBg;
      statusBadgeTextColor = context.textSecondary;
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isOverdue ? AppColors.red.withValues(alpha: 0.5) : context.cardBorder,
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
                      : (context.isDark ? AppColors.primary : const Color(0xFF15803D)).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.receipt_long_rounded,
                  color: isOverdue ? AppColors.red : (context.isDark ? AppColors.primary : const Color(0xFF15803D)),
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
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: context.textPrimary,
                      ),
                    ),
                    if (accountName != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Account: $accountName',
                        style: TextStyle(fontSize: 11, color: context.textSecondary),
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
                            : context.cardBorder,
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
                  Text(
                    'Bill Amount',
                    style: TextStyle(fontSize: 11, color: context.textMuted),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${bill.currency} ${CurrencyInputFormatter.format(bill.amount)}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                      color: context.textPrimary,
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
        color: context.cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.cardBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: (context.isDark ? AppColors.primary : const Color(0xFF15803D)).withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.check_rounded, color: context.isDark ? AppColors.primaryLight : const Color(0xFF15803D), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  bill.name,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: context.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Text(
                      paidDateText,
                      style: TextStyle(fontSize: 11, color: context.textSecondary),
                    ),
                    if (accountName != null) ...[
                      Text(' \u00b7 ', style: TextStyle(fontSize: 11, color: context.textMuted)),
                      Text(
                        accountName!,
                        style: TextStyle(fontSize: 11, color: context.textSecondary),
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
                  color: (context.isDark ? AppColors.primary : const Color(0xFF15803D)).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'PAID \u2713',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: context.isDark ? AppColors.primaryLight : const Color(0xFF15803D),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${bill.currency} ${CurrencyInputFormatter.format(amountPaid)}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: context.textPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
