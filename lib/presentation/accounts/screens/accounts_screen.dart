import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_background.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/glass_card.dart';
import '../../../core/widgets/mini_bar_chart.dart';
import '../../../core/widgets/segmented_progress_bar.dart';
import '../../../domain/entities/account_balance.dart';
import '../../repository_providers.dart';
import '../providers/account_providers.dart';
import 'add_account_sheet.dart';

class AccountsScreen extends ConsumerStatefulWidget {
  const AccountsScreen({super.key});

  @override
  ConsumerState<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends ConsumerState<AccountsScreen> {
  String _selectedCurrency = 'ALL'; // 'ALL', 'IDR', 'MYR'

  @override
  Widget build(BuildContext context) {
    final balancesAsync = ref.watch(accountBalancesProvider);

    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 110),
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Accounts & Wallets',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.darkTextPrimary,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => AddAccountSheet.show(context),
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

              // Currency Switcher Pills (ALL / IDR / MYR)
              Row(
                children: [
                  _CurrencyFilterPill(
                    label: 'All Currencies',
                    isSelected: _selectedCurrency == 'ALL',
                    onTap: () => setState(() => _selectedCurrency = 'ALL'),
                  ),
                  const SizedBox(width: 8),
                  _CurrencyFilterPill(
                    label: 'IDR (Rp)',
                    isSelected: _selectedCurrency == 'IDR',
                    onTap: () => setState(() => _selectedCurrency = 'IDR'),
                  ),
                  const SizedBox(width: 8),
                  _CurrencyFilterPill(
                    label: 'MYR (RM)',
                    isSelected: _selectedCurrency == 'MYR',
                    onTap: () => setState(() => _selectedCurrency = 'MYR'),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Total Balance Hero & Segmented Proportion Bar
              balancesAsync.when(
                data: (balances) => _buildHeroAndProportion(balances),
                loading: () => const _LoadingBlock(),
                error: (e, _) => _buildHeroAndProportion([]),
              ),
              const SizedBox(height: 24),

              // Account Cards List
              balancesAsync.when(
                data: (balances) {
                  final filtered = balances.where((b) {
                    if (_selectedCurrency == 'IDR') return b.currency == 'IDR';
                    if (_selectedCurrency == 'MYR') return b.currency == 'MYR';
                    return true;
                  }).toList();

                  if (filtered.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 40),
                        child: Column(
                          children: [
                            const Icon(Icons.account_balance_outlined, size: 48, color: AppColors.darkTextMuted),
                            const SizedBox(height: 12),
                            const Text(
                              'No accounts registered yet.',
                              style: TextStyle(color: AppColors.darkTextSecondary),
                            ),
                            const SizedBox(height: 14),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.black,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                              onPressed: () => AddAccountSheet.show(context),
                              icon: const Icon(Icons.add_rounded, size: 18),
                              label: const Text('Add First Account', style: TextStyle(fontWeight: FontWeight.w700)),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  return Column(
                    children: filtered.map((b) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _AccountDetailCard(
                        balance: b,
                        onDeactivate: () => _confirmDeactivate(context, ref, b),
                      ),
                    )).toList(),
                  );
                },
                loading: () => const _LoadingBlock(),
                error: (e, _) => Text('$e', style: const TextStyle(color: AppColors.red)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDeactivate(BuildContext context, WidgetRef ref, AccountBalance balance) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.darkCardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Deactivate Account', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
        content: Text(
          'Are you sure you want to deactivate "${balance.name}"? It will no longer appear in your active accounts.',
          style: const TextStyle(color: AppColors.darkTextSecondary, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: AppColors.darkTextSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Deactivate', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final repo = ref.read(accountRepositoryProvider);
      await repo.deactivate(balance.accountId);
      ref.invalidate(accountsProvider);
      ref.invalidate(accountBalancesProvider);
    }
  }

  Widget _buildHeroAndProportion(List<AccountBalance> balances) {
    final idrBalances = balances.where((b) => b.currency == 'IDR').toList();
    final myrBalances = balances.where((b) => b.currency == 'MYR').toList();
    
    final idrTotal = idrBalances.fold<num>(0, (sum, b) => sum + b.balance);
    final myrTotal = myrBalances.fold<num>(0, (sum, b) => sum + b.balance);

    final segmentColors = [
      AppColors.primary,
      AppColors.teal,
      AppColors.blue,
      AppColors.orange,
      AppColors.pink,
    ];

    final relevantBalances = balances.where((b) {
      if (_selectedCurrency == 'IDR') return b.currency == 'IDR';
      if (_selectedCurrency == 'MYR') return b.currency == 'MYR';
      return true;
    }).toList();

    final segments = relevantBalances.asMap().entries.map((e) {
      final idx = e.key;
      final b = e.value;
      return SegmentItem(
        label: b.name,
        value: b.balance,
        color: segmentColors[idx % segmentColors.length],
      );
    }).toList();

    return Column(
      children: [
        if (_selectedCurrency == 'ALL' || _selectedCurrency == 'IDR') ...[
          // IDR Hero Card
          _buildBalanceHeroCard(
            currencySymbol: 'Rp',
            currencyCode: 'IDR',
            total: idrTotal,
            accountCount: idrBalances.length,
          ),
        ],
        if (_selectedCurrency == 'ALL' && myrBalances.isNotEmpty) ...[
          const SizedBox(height: 12),
        ],
        if (_selectedCurrency == 'ALL' || _selectedCurrency == 'MYR') ...[
          // MYR Hero Card
          _buildBalanceHeroCard(
            currencySymbol: 'RM',
            currencyCode: 'MYR',
            total: myrTotal,
            accountCount: myrBalances.length,
            isDecimal: true,
          ),
        ],
        const SizedBox(height: 18),

        // Multi-segment Colored Proportion Bar + Dot Legend
        if (segments.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: SegmentedProgressBar(
              height: 6,
              items: segments,
            ),
          ),
      ],
    );
  }

  Widget _buildBalanceHeroCard({
    required String currencySymbol,
    required String currencyCode,
    required num total,
    required int accountCount,
    bool isDecimal = false,
  }) {
    final formatted = isDecimal
        ? (total % 1 == 0 ? total.toStringAsFixed(0) : total.toStringAsFixed(2))
        : _formatNumber(total);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.darkCardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.darkCardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'TOTAL $currencyCode BALANCE',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: AppColors.darkTextSecondary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$accountCount Accounts',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '$currencySymbol ',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
              Text(
                formatted,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  color: AppColors.darkTextPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatNumber(num value) {
    final s = value.toStringAsFixed(0);
    final buffer = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buffer.write('.');
      buffer.write(s[i]);
    }
    return buffer.toString();
  }
}

class _CurrencyFilterPill extends StatelessWidget {
  const _CurrencyFilterPill({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.darkCardBg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.darkCardBorder,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.black : AppColors.darkTextSecondary,
          ),
        ),
      ),
    );
  }
}

class _AccountDetailCard extends StatelessWidget {
  const _AccountDetailCard({
    required this.balance,
    required this.onDeactivate,
  });

  final AccountBalance balance;
  final VoidCallback onDeactivate;

  IconData get _icon {
    switch (balance.type) {
      case 'bank':
        return Icons.account_balance_outlined;
      case 'ewallet':
        return Icons.account_balance_wallet_outlined;
      default:
        return Icons.payments_outlined;
    }
  }

  Color get _accentColor {
    switch (balance.type) {
      case 'bank':
        return AppColors.primary;
      case 'ewallet':
        return AppColors.teal;
      default:
        return AppColors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: _accentColor.withValues(alpha: 0.15),
                      border: Border.all(
                        color: _accentColor.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Icon(_icon, size: 20, color: _accentColor),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        balance.name,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.darkTextPrimary,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${balance.type.toUpperCase()} \u00b7 ${balance.currency}',
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
              Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${balance.currency} ${_formatNumber(balance.balance)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.darkTextPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 6),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert_rounded, size: 18, color: AppColors.darkTextSecondary),
                    color: AppColors.darkCardBg,
                    onSelected: (val) {
                      if (val == 'deactivate') onDeactivate();
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(
                        value: 'deactivate',
                        child: Text('Deactivate Account', style: TextStyle(color: AppColors.red, fontSize: 13)),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          MiniBarChart(
            height: 18,
            barCount: 20,
            barColor: _accentColor,
          ),
        ],
      ),
    );
  }

  String _formatNumber(num value) {
    final s = value.toStringAsFixed(0);
    final buffer = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buffer.write('.');
      buffer.write(s[i]);
    }
    return buffer.toString();
  }
}

class _LoadingBlock extends StatelessWidget {
  const _LoadingBlock();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 90,
      child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary)),
    );
  }
}
