import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/glass_card.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../domain/entities/account.dart';
import '../../repository_providers.dart';

class _AccountDraft {
  final String name;
  final String type;
  final String currency;
  final num initialBalance;

  const _AccountDraft({
    required this.name,
    required this.type,
    required this.currency,
    required this.initialBalance,
  });
}

class StepPrimaryAccount extends ConsumerStatefulWidget {
  const StepPrimaryAccount({
    super.key,
    required this.onNext,
    required this.onSkip,
  });

  final VoidCallback onNext;
  final VoidCallback onSkip;

  @override
  ConsumerState<StepPrimaryAccount> createState() => _StepPrimaryAccountState();
}

class _StepPrimaryAccountState extends ConsumerState<StepPrimaryAccount> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController(text: 'Bank BCA');
  final _balanceController = TextEditingController(text: '0');
  String _selectedType = 'bank';
  String _selectedCurrency = 'IDR';
  bool _isSaving = false;

  final List<_AccountDraft> _addedAccounts = [];

  final List<Map<String, String>> _templates = const [
    {'name': 'Bank BCA', 'type': 'bank', 'currency': 'IDR'},
    {'name': 'Bank Mandiri', 'type': 'bank', 'currency': 'IDR'},
    {'name': 'Cash Wallet', 'type': 'cash', 'currency': 'IDR'},
    {'name': 'GoPay', 'type': 'ewallet', 'currency': 'IDR'},
    {'name': 'OVO', 'type': 'ewallet', 'currency': 'IDR'},
    {'name': 'Maybank', 'type': 'bank', 'currency': 'MYR'},
    {'name': 'Touch \'n Go', 'type': 'ewallet', 'currency': 'MYR'},
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();
    super.dispose();
  }

  void _applyTemplate(Map<String, String> template) {
    setState(() {
      _nameController.text = template['name']!;
      _selectedType = template['type']!;
      if (template.containsKey('currency')) {
        _selectedCurrency = template['currency']!;
      }
    });
  }

  void _addCurrentAccountToList() {
    if (!_formKey.currentState!.validate()) return;
    final name = _nameController.text.trim();
    final balance = CurrencyInputFormatter.parse(_balanceController.text);

    setState(() {
      _addedAccounts.add(_AccountDraft(
        name: name,
        type: _selectedType,
        currency: _selectedCurrency,
        initialBalance: balance,
      ));
      _nameController.clear();
      _balanceController.text = '0';
      _selectedType = 'bank';
    });
    HapticFeedback.lightImpact();
  }

  Future<void> _handleSave() async {
    final name = _nameController.text.trim();
    final currentFormFilled = name.isNotEmpty;

    if (_addedAccounts.isEmpty && !currentFormFilled) {
      if (!_formKey.currentState!.validate()) return;
    }

    final List<_AccountDraft> accountsToSave = List<_AccountDraft>.from(_addedAccounts);

    if (currentFormFilled) {
      final balance = CurrencyInputFormatter.parse(_balanceController.text);
      accountsToSave.add(_AccountDraft(
        name: name,
        type: _selectedType,
        currency: _selectedCurrency,
        initialBalance: balance,
      ));
    }

    if (accountsToSave.isEmpty) {
      widget.onNext();
      return;
    }

    setState(() => _isSaving = true);
    try {
      final repo = ref.read(accountRepositoryProvider);
      for (final draft in accountsToSave) {
        final account = Account(
          id: '',
          name: draft.name,
          type: draft.type,
          currency: draft.currency,
          isActive: true,
        );
        await repo.create(account, initialBalance: draft.initialBalance);
      }
      widget.onNext();
    } catch (_) {
      widget.onNext();
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final textPrimary = context.textPrimary;
    final textSecondary = context.textSecondary;
    final cardBorder = context.cardBorder;
    final isCurrentFormFilled = _nameController.text.trim().isNotEmpty;
    final totalAccountsCount = _addedAccounts.length + (isCurrentFormFilled ? 1 : 0);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Step 2 of 4',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.0,
                color: isDark ? AppColors.primary : const Color(0xFF15803D),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Add Accounts & Wallets',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.6,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Set up one or more bank accounts, cash wallets, or e-wallets to start tracking your balances.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                height: 1.4,
                color: textSecondary,
              ),
            ),
            const SizedBox(height: 20),

            // Added Accounts Section (if any accounts added)
            if (_addedAccounts.isNotEmpty) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'ADDED ACCOUNTS (${_addedAccounts.length})',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.0,
                      color: isDark ? AppColors.primaryLight : const Color(0xFF15803D),
                    ),
                  ),
                  Text(
                    '${_addedAccounts.length} ready to save',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                      color: textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ..._addedAccounts.asMap().entries.map((entry) {
                final idx = entry.key;
                final acc = entry.value;
                final isIdr = acc.currency == 'IDR';
                final formattedBal = isIdr
                    ? 'Rp ${CurrencyInputFormatter.format(acc.initialBalance)}'
                    : 'RM ${CurrencyInputFormatter.format(acc.initialBalance)}';

                IconData iconData;
                switch (acc.type) {
                  case 'cash':
                    iconData = Icons.account_balance_wallet_rounded;
                    break;
                  case 'ewallet':
                    iconData = Icons.phone_android_rounded;
                    break;
                  case 'bank':
                  default:
                    iconData = Icons.account_balance_rounded;
                    break;
                }

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: (isDark ? AppColors.primary : const Color(0xFF15803D)).withValues(alpha: 0.25),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: (isDark ? AppColors.primary : const Color(0xFF15803D)).withValues(alpha: 0.15),
                        ),
                        child: Icon(iconData, size: 18, color: isDark ? AppColors.primaryLight : const Color(0xFF15803D)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              acc.name,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: textPrimary,
                              ),
                            ),
                            Text(
                              '${acc.type.toUpperCase()} • $formattedBal',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w500,
                                color: textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() => _addedAccounts.removeAt(idx));
                        },
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.red.withValues(alpha: 0.1),
                          ),
                          child: const Icon(Icons.close_rounded, size: 16, color: AppColors.red),
                        ),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 16),
            ],

            // Quick templates
            Text(
              'Quick Templates',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                color: textSecondary,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _templates.map((tpl) {
                final isSelected = _nameController.text == tpl['name'];
                return GestureDetector(
                  onTap: () => _applyTemplate(tpl),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? (isDark ? AppColors.primary : const Color(0xFF15803D))
                          : (isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF1F5F9)),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? (isDark ? AppColors.primary : const Color(0xFF15803D))
                            : cardBorder,
                      ),
                    ),
                    child: Text(
                      tpl['name']!,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: isSelected
                            ? (isDark ? Colors.black : Colors.white)
                            : textPrimary,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // Account Details Card
            GlassCard(
              borderRadius: 20,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _addedAccounts.isEmpty ? 'Account Details' : 'Add Another Account',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: textPrimary,
                        ),
                      ),
                      if (_addedAccounts.isNotEmpty && isCurrentFormFilled)
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _nameController.clear();
                              _balanceController.text = '0';
                            });
                          },
                          child: Text(
                            'Clear',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: textSecondary,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  Text(
                    'Account Name',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _nameController,
                    onChanged: (_) => setState(() {}),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: textPrimary,
                    ),
                    decoration: InputDecoration(
                      hintText: 'e.g. Bank BCA, GoPay, Cash',
                      prefixIcon: Icon(Icons.account_balance_rounded, color: textSecondary, size: 20),
                      filled: true,
                      fillColor: isDark ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFF1F5F9),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: cardBorder),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                      ),
                    ),
                    validator: (val) {
                      if (_addedAccounts.isEmpty && (val == null || val.trim().isEmpty)) {
                        return 'Please enter an account name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 18),

                  Text(
                    'Account Type',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildTypeOption('bank', 'Bank', Icons.account_balance_rounded),
                      const SizedBox(width: 8),
                      _buildTypeOption('cash', 'Cash', Icons.account_balance_wallet_rounded),
                      const SizedBox(width: 8),
                      _buildTypeOption('ewallet', 'E-Wallet', Icons.phone_android_rounded),
                    ],
                  ),
                  const SizedBox(height: 18),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Balance input (flex 3)
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Initial Balance',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: textSecondary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _balanceController,
                              keyboardType: TextInputType.number,
                              inputFormatters: [CurrencyInputFormatter()],
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: textPrimary,
                              ),
                              decoration: InputDecoration(
                                hintText: '0',
                                prefixIcon: Padding(
                                  padding: const EdgeInsets.only(left: 14, right: 8),
                                  child: Center(
                                    widthFactor: 0.0,
                                    child: Text(
                                      _selectedCurrency == 'IDR' ? 'Rp' : 'RM',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: isDark ? AppColors.primaryLight : const Color(0xFF15803D),
                                      ),
                                    ),
                                  ),
                                ),
                                filled: true,
                                fillColor: isDark ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFF1F5F9),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide(color: cardBorder),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide(
                                    color: isDark ? AppColors.primary : const Color(0xFF15803D),
                                    width: 1.5,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Currency Switcher (flex 2)
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Currency',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: textSecondary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              height: 52,
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: isDark ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: cardBorder),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () => setState(() => _selectedCurrency = 'IDR'),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: _selectedCurrency == 'IDR'
                                              ? (isDark ? AppColors.primary : const Color(0xFF15803D))
                                              : Colors.transparent,
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        alignment: Alignment.center,
                                        child: Text(
                                          'IDR',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.w800,
                                            color: _selectedCurrency == 'IDR'
                                                ? (isDark ? Colors.black : Colors.white)
                                                : textSecondary,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () => setState(() => _selectedCurrency = 'MYR'),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: _selectedCurrency == 'MYR'
                                              ? (isDark ? AppColors.primary : const Color(0xFF15803D))
                                              : Colors.transparent,
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        alignment: Alignment.center,
                                        child: Text(
                                          'RM',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.w800,
                                            color: _selectedCurrency == 'MYR'
                                                ? (isDark ? Colors.black : Colors.white)
                                                : textSecondary,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Add to list button
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: OutlinedButton.icon(
                      onPressed: isCurrentFormFilled ? _addCurrentAccountToList : null,
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: Text(
                        'Add to Account List',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: isDark ? AppColors.primaryLight : const Color(0xFF15803D),
                        disabledForegroundColor: textSecondary.withValues(alpha: 0.4),
                        side: BorderSide(
                          color: isCurrentFormFilled
                              ? (isDark ? AppColors.primary : const Color(0xFF15803D)).withValues(alpha: 0.4)
                              : cardBorder,
                        ),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Actions
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.black,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: _isSaving ? null : _handleSave,
                child: _isSaving
                    ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                    : Text(
                        totalAccountsCount > 1
                            ? 'Save $totalAccountsCount Accounts & Continue'
                            : 'Save Account & Continue',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.2,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: TextButton(
                onPressed: widget.onSkip,
                child: Text(
                  'Set Up Later',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: textSecondary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeOption(String typeKey, String label, IconData icon) {
    final isSelected = _selectedType == typeKey;
    final isDark = context.isDark;
    final cardBorder = context.cardBorder;
    final textPrimary = context.textPrimary;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedType = typeKey),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark ? AppColors.primary.withValues(alpha: 0.15) : const Color(0xFF15803D).withValues(alpha: 0.12))
                : (isDark ? Colors.white.withValues(alpha: 0.03) : const Color(0xFFF1F5F9)),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? (isDark ? AppColors.primary : const Color(0xFF15803D))
                  : cardBorder,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 20,
                color: isSelected
                    ? (isDark ? AppColors.primaryLight : const Color(0xFF15803D))
                    : textPrimary.withValues(alpha: 0.7),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  color: isSelected
                      ? (isDark ? AppColors.primaryLight : const Color(0xFF15803D))
                      : textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
