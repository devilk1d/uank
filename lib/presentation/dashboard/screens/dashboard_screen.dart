import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_background.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/glass_card.dart';
import '../../../core/widgets/circular_progress_badge.dart';
import '../../../domain/entities/account_balance.dart';
import '../../../domain/entities/transaction.dart';
import '../../accounts/providers/account_providers.dart';
import '../../accounts/screens/accounts_screen.dart';
import '../../bills/screens/add_bill_sheet.dart';
import '../../exchange_rates/screens/exchange_rate_screen.dart';
import '../../transactions/providers/transaction_providers.dart';
import '../../transactions/screens/add_transaction_sheet.dart';
import '../../transactions/screens/transactions_screen.dart';
import '../../transfers/screens/add_transfer_sheet.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int _selectedFilterIndex = 0;
  final _filters = const ['All', 'Bank', 'E-Wallet', 'Cash'];
  String _activeHeroCurrency = 'IDR';
  bool _showBalance = true;

  @override
  Widget build(BuildContext context) {
    final balancesAsync = ref.watch(accountBalancesProvider);
    final transactionsAsync = ref.watch(transactionsProvider);
    final balances = balancesAsync.asData?.value ?? [];
    final transactions = transactionsAsync.asData?.value ?? [];
    final accountMap = {for (final b in balances) b.accountId: b};

    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 110),
            children: [
              // 1. Header (Avatar, Greeting, Currency Tag & Notification)
              _buildHeader(),
              const SizedBox(height: 20),

              // 2. Signature Electric Lime Hero Account Balance Card
              balancesAsync.when(
                data: (balances) => _buildHeroBalance(balances, transactions, accountMap),
                loading: () => const _LoadingHero(),
                error: (e, _) => _buildHeroBalance([], transactions, accountMap),
              ),
              const SizedBox(height: 20),

              // 3. Category / Account Type Filter Chips
              _buildFilterChips(),
              const SizedBox(height: 20),

              // 4. 4 Quick Action Buttons (Add, Transfer, Bills, Rates)
              _buildQuickActions(),
              const SizedBox(height: 22),

              // 5. Monthly Budget Card
              _buildBudgetCard(),
              const SizedBox(height: 22),

              // 6. Activity / Recent Transactions in Large Dark Card
              _buildRecentActivitySection(transactionsAsync, accountMap),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final now = DateTime.now();
    final hour = now.hour;
    final greeting = hour < 12
        ? 'Good Morning'
        : (hour < 17 ? 'Good Afternoon' : 'Good Evening');

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Avatar + Greeting
        Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary,
                border: Border.all(
                  color: AppColors.primaryLight,
                  width: 1.5,
                ),
              ),
              child: const Center(
                child: Icon(
                  Icons.person_rounded,
                  color: Colors.black,
                  size: 22,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Hello,',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.darkTextSecondary,
                  ),
                ),
                Text(
                  greeting,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.darkTextPrimary,
                  ),
                ),
              ],
            ),
          ],
        ),

        // Right Actions (Currency Indicator Pill + Rates Button)
        Row(
          children: [
            GestureDetector(
              onTap: () {
                setState(() {
                  _activeHeroCurrency = _activeHeroCurrency == 'IDR' ? 'MYR' : 'IDR';
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: AppColors.darkCardBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.darkCardBorder),
                ),
                child: Row(
                  children: [
                    Text(
                      _activeHeroCurrency == 'IDR' ? '\u{1F1EE}\u{1F1E9} IDR' : '\u{1F1F2}\u{1F1FE} MYR',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.darkTextPrimary),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: AppColors.darkTextSecondary),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => ExchangeRateScreen.show(context),
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.darkCardBg,
                  border: Border.all(color: AppColors.darkCardBorder),
                ),
                child: const Icon(
                  Icons.notifications_none_rounded,
                  size: 19,
                  color: AppColors.darkTextPrimary,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHeroBalance(
    List<AccountBalance> balances,
    List<Transaction> transactions,
    Map<String, AccountBalance> accountMap,
  ) {
    final filtered = _selectedFilterIndex == 0
        ? balances
        : (_selectedFilterIndex == 1
            ? balances.where((b) => b.type == 'bank').toList()
            : (_selectedFilterIndex == 2
                ? balances.where((b) => b.type == 'ewallet').toList()
                : balances.where((b) => b.type == 'cash').toList()));

    final idrBalances = filtered.where((b) => b.currency == 'IDR').toList();
    final myrBalances = filtered.where((b) => b.currency == 'MYR').toList();
    final totalIdr = idrBalances.fold<num>(0, (sum, b) => sum + b.balance);
    final totalMyr = myrBalances.fold<num>(0, (sum, b) => sum + b.balance);

    final isIdr = _activeHeroCurrency == 'IDR';
    final activeBalance = isIdr ? totalIdr : totalMyr;
    final activeSymbol = isIdr ? 'Rp' : 'RM';
    final activeAccountsCount = isIdr ? idrBalances.length : myrBalances.length;

    // Calculate Credit (Income) & Debit (Expense) for active currency
    final creditTotal = transactions
        .where((t) => t.type == 'income' && accountMap[t.accountId]?.currency == _activeHeroCurrency)
        .fold<num>(0, (sum, t) => sum + t.amount);
    final debitTotal = transactions
        .where((t) => t.type == 'expense' && accountMap[t.accountId]?.currency == _activeHeroCurrency)
        .fold<num>(0, (sum, t) => sum + t.amount);

    final formattedActiveBalance = isIdr ? _formatRupiah(activeBalance) : _formatMyr(activeBalance);
    final formattedCredit = isIdr ? 'Rp ${_formatRupiah(creditTotal)}' : 'RM ${_formatMyr(creditTotal)}';
    final formattedDebit = isIdr ? 'Rp ${_formatRupiah(debitTotal)}' : 'RM ${_formatMyr(debitTotal)}';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.limeCardBg,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.35),
            blurRadius: 28,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row inside Lime Card (Label, Multi-Currency Tabs & Eye Toggle)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text(
                    'Account balance',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E2405),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '($activeAccountsCount acc)',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF4A5610),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  // Currency Tab Switcher
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _HeroCurrencyTab(
                          label: 'IDR',
                          isActive: isIdr,
                          onTap: () => setState(() => _activeHeroCurrency = 'IDR'),
                        ),
                        _HeroCurrencyTab(
                          label: 'MYR',
                          isActive: !isIdr,
                          onTap: () => setState(() => _activeHeroCurrency = 'MYR'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Eye Toggle
                  GestureDetector(
                    onTap: () => setState(() => _showBalance = !_showBalance),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black.withValues(alpha: 0.12),
                      ),
                      child: Icon(
                        _showBalance ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                        size: 16,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Big Bold Balance Text
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  '$activeSymbol ',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1E2405),
                  ),
                ),
                Text(
                  _showBalance ? formattedActiveBalance : '\u2022\u2022\u2022\u2022\u2022\u2022',
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1.0,
                    color: Color(0xFF0E0E10),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Nested White Sub-Pills (Credit / Debit)
          Row(
            children: [
              // Credit (Income) Pill
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFF22C55E),
                        ),
                        child: const Icon(
                          Icons.arrow_outward_rounded,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Credit',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF64748B),
                              ),
                            ),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                _showBalance ? formattedCredit : '\u2022\u2022\u2022',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Debit (Expense) Pill
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFFFF453A),
                        ),
                        child: const Icon(
                          Icons.arrow_downward_rounded,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Debit',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF64748B),
                              ),
                            ),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                _showBalance ? formattedDebit : '\u2022\u2022\u2022',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                            ),
                          ],
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

  Widget _buildFilterChips() {
    return SizedBox(
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
    );
  }

  Widget _buildQuickActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _QuickActionButton(
          icon: Icons.add_rounded,
          label: 'Add',
          isHighlighted: false,
          onTap: () => AddTransactionSheet.show(context),
        ),
        _QuickActionButton(
          icon: Icons.arrow_upward_rounded,
          label: 'Transfer',
          isHighlighted: true,
          onTap: () => AddTransferSheet.show(context),
        ),
        _QuickActionButton(
          icon: Icons.receipt_long_rounded,
          label: 'Bills',
          isHighlighted: false,
          onTap: () => AddBillSheet.show(context),
        ),
        _QuickActionButton(
          icon: Icons.currency_exchange_rounded,
          label: 'Rates',
          isHighlighted: false,
          onTap: () => ExchangeRateScreen.show(context),
        ),
      ],
    );
  }

  Widget _buildBudgetCard() {
    return GlassCard(
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          const CircularProgressBadge(
            percentage: 0.56,
            size: 54,
            strokeWidth: 4.5,
            progressColor: AppColors.primary,
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Monthly Budget',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.darkTextPrimary,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Rp 1,567,000 of Rp 2,800,000 spent',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppColors.darkTextSecondary,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AccountsScreen()),
              );
            },
            child: const Text(
              'Manage',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryLight,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivitySection(
    AsyncValue<List<Transaction>> transactionsAsync,
    Map<String, AccountBalance> accountMap,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.darkCardBg,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.darkCardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row inside Card
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Activity',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.darkTextPrimary,
                ),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const TransactionsScreen()),
                  );
                },
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.darkCardElevated,
                    border: Border.all(color: AppColors.darkCardBorder),
                  ),
                  child: const Icon(Icons.tune_rounded, size: 16, color: AppColors.darkTextSecondary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          transactionsAsync.when(
            data: (transactions) {
              if (transactions.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Column(
                      children: [
                        const Icon(Icons.receipt_outlined, size: 36, color: AppColors.darkTextMuted),
                        const SizedBox(height: 8),
                        const Text(
                          'No activity recorded yet.',
                          style: TextStyle(color: AppColors.darkTextSecondary, fontSize: 12),
                        ),
                        TextButton(
                          onPressed: () => AddTransactionSheet.show(context),
                          child: const Text('Record Transaction Now', style: TextStyle(color: AppColors.primaryLight)),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return Column(
                children: transactions
                    .take(5)
                    .map((t) {
                      final acc = accountMap[t.accountId];
                      final isMyr = acc?.currency == 'MYR';
                      final formattedVal = isMyr
                          ? 'RM ${t.amount % 1 == 0 ? t.amount.toStringAsFixed(0) : t.amount.toStringAsFixed(2)}'
                          : 'Rp ${_formatRupiah(t.amount)}';

                      return _ActivityItem(
                        title: t.description?.isNotEmpty == true ? t.description! : (t.type == 'expense' ? 'Expense' : 'Income'),
                        subtitle: '${acc != null ? '${acc.name} \u00b7 ' : ''}${t.transactionDate.day}/${t.transactionDate.month}/${t.transactionDate.year}',
                        amount: '${t.type == 'expense' ? '-' : '+'}$formattedVal',
                        isNegative: t.type == 'expense',
                      );
                    })
                    .toList(),
              );
            },
            loading: () => const _LoadingBlock(),
            error: (e, _) => Text('$e', style: const TextStyle(color: AppColors.red, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  String _formatRupiah(num value) {
    final s = value.toStringAsFixed(0);
    final buffer = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buffer.write('.');
      buffer.write(s[i]);
    }
    return buffer.toString();
  }

  String _formatMyr(num value) {
    if (value % 1 == 0) {
      final s = value.toStringAsFixed(0);
      final buffer = StringBuffer();
      for (int i = 0; i < s.length; i++) {
        if (i > 0 && (s.length - i) % 3 == 0) buffer.write(',');
        buffer.write(s[i]);
      }
      return buffer.toString();
    }
    final parts = value.toStringAsFixed(2).split('.');
    final s = parts[0];
    final buffer = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buffer.write(',');
      buffer.write(s[i]);
    }
    return '${buffer.toString()}.${parts[1]}';
  }
}

class _HeroCurrencyTab extends StatelessWidget {
  const _HeroCurrencyTab({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isActive ? Colors.black : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: isActive ? AppColors.primary : const Color(0xFF2A3008),
          ),
        ),
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.isHighlighted,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isHighlighted;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isHighlighted ? AppColors.primary : AppColors.darkCardBg,
              border: Border.all(
                color: isHighlighted ? AppColors.primaryLight : AppColors.darkCardBorder,
                width: 1.2,
              ),
              boxShadow: isHighlighted
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.35),
                        blurRadius: 18,
                        offset: const Offset(0, 5),
                      ),
                    ]
                  : null,
            ),
            child: Icon(
              icon,
              size: 24,
              color: isHighlighted ? Colors.black : AppColors.darkTextPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.darkTextSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityItem extends StatelessWidget {
  const _ActivityItem({
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.isNegative,
  });

  final String title;
  final String subtitle;
  final String amount;
  final bool isNegative;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isNegative ? const Color(0xFFFF453A) : const Color(0xFF22C55E),
                ),
                child: Icon(
                  isNegative ? Icons.arrow_downward_rounded : Icons.arrow_outward_rounded,
                  size: 18,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.darkTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppColors.darkTextSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Text(
            amount,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: isNegative ? AppColors.red : AppColors.darkTextPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingHero extends StatelessWidget {
  const _LoadingHero();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 160,
      decoration: BoxDecoration(
        color: AppColors.limeCardBg.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(28),
      ),
      child: const Center(child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black)),
    );
  }
}

class _LoadingBlock extends StatelessWidget {
  const _LoadingBlock();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 80,
      child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary)),
    );
  }
}
