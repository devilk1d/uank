import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/app_dropdown.dart';
import '../../../domain/entities/account.dart';
import '../../../domain/entities/saving_goal.dart';
import '../../accounts/providers/account_providers.dart';
import '../providers/saving_goal_providers.dart';
import '../utils/saving_goal_ui_helpers.dart';

class DepositSavingGoalDialog extends ConsumerStatefulWidget {
  final SavingGoal goal;

  const DepositSavingGoalDialog({super.key, required this.goal});

  static Future<void> show(BuildContext context, SavingGoal goal) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DepositSavingGoalDialog(goal: goal),
    );
  }

  @override
  ConsumerState<DepositSavingGoalDialog> createState() => _DepositSavingGoalDialogState();
}

class _DepositSavingGoalDialogState extends ConsumerState<DepositSavingGoalDialog> {
  late final TextEditingController _amountController;
  String? _selectedWithdrawAccountId;
  bool _isDeposit = true; // true = Deposit, false = Withdraw
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController();
    _selectedWithdrawAccountId = widget.goal.accountId;
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _addQuickAmount(num value) {
    final currentVal = CurrencyInputFormatter.parse(_amountController.text);
    final newVal = currentVal + value;
    _amountController.text = CurrencyInputFormatter.format(newVal);
    setState(() {});
  }

  void _setMaxRemaining() {
    if (_isDeposit) {
      final remaining = (widget.goal.targetAmount - widget.goal.currentAmount).clamp(0.0, double.infinity);
      _amountController.text = CurrencyInputFormatter.format(remaining);
    } else {
      _amountController.text = CurrencyInputFormatter.format(widget.goal.currentAmount);
    }
    setState(() {});
  }

  Future<void> _submit(List<Account> accounts) async {
    final amount = CurrencyInputFormatter.parse(_amountController.text);
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount'), backgroundColor: AppColors.red),
      );
      return;
    }

    if (!_isDeposit && amount > widget.goal.currentAmount) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Withdrawal amount cannot exceed current saved balance'),
          backgroundColor: AppColors.red,
        ),
      );
      return;
    }

    final targetAccountId = _isDeposit
        ? (widget.goal.accountId ?? _selectedWithdrawAccountId ?? accounts.firstOrNull?.id)
        : (_selectedWithdrawAccountId ?? widget.goal.accountId ?? accounts.firstOrNull?.id);

    if (targetAccountId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an account'), backgroundColor: AppColors.red),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await depositOrWithdrawSavingGoal(
        ref,
        goal: widget.goal,
        accountId: targetAccountId,
        amount: amount,
        isDeposit: _isDeposit,
      );

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (_) {
      // Handled silently consistent with other dialogs
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final isIdr = widget.goal.currency == 'IDR';
    final symbol = isIdr ? 'Rp' : 'RM';

    final accountsAsync = ref.watch(accountsProvider);
    final accountsList = accountsAsync.asData?.value ?? [];
    final matchingAccounts = accountsList.where((a) => a.currency == widget.goal.currency).toList();
    final displayAccounts = matchingAccounts.isNotEmpty ? matchingAccounts : accountsList;

    if (_selectedWithdrawAccountId == null || !displayAccounts.any((a) => a.id == _selectedWithdrawAccountId)) {
      if (widget.goal.accountId != null && displayAccounts.any((a) => a.id == widget.goal.accountId)) {
        _selectedWithdrawAccountId = widget.goal.accountId;
      } else if (displayAccounts.isNotEmpty) {
        _selectedWithdrawAccountId = displayAccounts.first.id;
      }
    }

    final linkedDepositAccount = accountsList.where((a) => a.id == widget.goal.accountId).firstOrNull;

    final enteredAmount = CurrencyInputFormatter.parse(_amountController.text);
    final estimatedNewAmount = _isDeposit
        ? (widget.goal.currentAmount + enteredAmount)
        : (widget.goal.currentAmount - enteredAmount).clamp(0.0, double.infinity);
    final progress = widget.goal.targetAmount > 0
        ? (estimatedNewAmount / widget.goal.targetAmount).clamp(0.0, 1.0)
        : 0.0;

    final quickPills = isIdr
        ? [50000, 100000, 500000, 1000000]
        : [10, 50, 100, 500];

    return Container(
      padding: EdgeInsets.fromLTRB(22, 20, 22, 24 + bottomInset),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(
          top: BorderSide(color: context.cardBorder, width: 1.5),
        ),
      ),
      child: SingleChildScrollView(
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
                  color: context.textMuted.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Title & Goal Name
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: SavingGoalUIHelper.parseColor(widget.goal.color).withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: SavingGoalUIHelper.parseColor(widget.goal.color).withValues(alpha: 0.4),
                          ),
                        ),
                        child: Icon(
                          SavingGoalUIHelper.getIconData(widget.goal.icon),
                          size: 19,
                          color: SavingGoalUIHelper.getContrastColor(
                            SavingGoalUIHelper.parseColor(widget.goal.color),
                            context,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _isDeposit ? 'Add Savings' : 'Withdraw Savings',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: context.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              widget.goal.name,
                              style: TextStyle(
                                fontSize: 13,
                                color: context.textSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Segmented Switcher (Deposit / Withdraw)
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: context.inputBg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: context.cardBorder),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onTap: () => setState(() => _isDeposit = true),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: _isDeposit ? AppColors.primary : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            'Deposit',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: _isDeposit ? Colors.black : context.textSecondary,
                            ),
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => setState(() => _isDeposit = false),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: !_isDeposit ? AppColors.red : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            'Withdraw',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: !_isDeposit ? Colors.white : context.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Current Goal Status Card
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: context.inputBg,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: context.cardBorder),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Current: $symbol ${CurrencyInputFormatter.format(widget.goal.currentAmount)}',
                        style: TextStyle(fontSize: 12, color: context.textSecondary),
                      ),
                      Text(
                        'Target: $symbol ${CurrencyInputFormatter.format(widget.goal.targetAmount)}',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: context.textPrimary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 8,
                      backgroundColor: context.cardBorder,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _isDeposit ? (context.isDark ? AppColors.primary : const Color(0xFF15803D)) : AppColors.orange,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Estimated: $symbol ${CurrencyInputFormatter.format(estimatedNewAmount)}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _isDeposit ? (context.isDark ? AppColors.primaryLight : const Color(0xFF15803D)) : AppColors.orange,
                        ),
                      ),
                      Text(
                        '${(progress * 100).toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: context.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Account Indicator / Selector
            if (_isDeposit) ...[
              if (linkedDepositAccount != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: context.isDark ? AppColors.primary.withValues(alpha: 0.08) : const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: (context.isDark ? AppColors.primary : const Color(0xFF15803D)).withValues(alpha: 0.25)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: (context.isDark ? AppColors.primary : const Color(0xFF15803D)).withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          linkedDepositAccount.type == 'bank'
                              ? Icons.account_balance_outlined
                              : linkedDepositAccount.type == 'ewallet'
                                  ? Icons.account_balance_wallet_outlined
                                  : Icons.payments_outlined,
                          size: 16,
                          color: context.accentIconColor,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Funding Source (Auto-Linked)',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: context.textSecondary,
                              ),
                            ),
                            Text(
                              '${linkedDepositAccount.name} (${linkedDepositAccount.currency})',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: context.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.check_circle_outline_rounded, size: 16, color: context.accentIconColor),
                    ],
                  ),
                )
              else if (displayAccounts.isNotEmpty)
                AppDropdownFormField<String>(
                  key: ValueKey('deposit_account_$_selectedWithdrawAccountId'),
                  initialValue: _selectedWithdrawAccountId,
                  labelText: 'Funding Source Account',
                  hintText: 'Select funding source account',
                  sheetTitle: 'Select Funding Account',
                  items: displayAccounts.map((acc) {
                    return AppDropdownItem<String>(
                      value: acc.id,
                      label: '${acc.name} (${acc.currency})',
                      subtitle: 'Type: ${acc.type.toUpperCase()}',
                      icon: Icon(
                        acc.type == 'bank'
                            ? Icons.account_balance_outlined
                            : acc.type == 'ewallet'
                                ? Icons.account_balance_wallet_outlined
                                : Icons.payments_outlined,
                        size: 20,
                        color: context.accentIconColor,
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _selectedWithdrawAccountId = val);
                    }
                  },
                ),
            ] else ...[
              // Withdraw Destination Account Selector
              if (displayAccounts.isNotEmpty)
                AppDropdownFormField<String>(
                  key: ValueKey('withdraw_account_$_selectedWithdrawAccountId'),
                  initialValue: _selectedWithdrawAccountId,
                  labelText: 'Withdraw To Account',
                  hintText: 'Select destination account',
                  sheetTitle: 'Select Destination Account',
                  items: displayAccounts.map((acc) {
                    return AppDropdownItem<String>(
                      value: acc.id,
                      label: '${acc.name} (${acc.currency})',
                      subtitle: 'Type: ${acc.type.toUpperCase()}',
                      icon: Icon(
                        acc.type == 'bank'
                            ? Icons.account_balance_outlined
                            : acc.type == 'ewallet'
                                ? Icons.account_balance_wallet_outlined
                                : Icons.payments_outlined,
                        size: 20,
                        color: AppColors.red,
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _selectedWithdrawAccountId = val);
                    }
                  },
                ),
            ],
            const SizedBox(height: 16),

            // Amount Input Field
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
              decoration: BoxDecoration(
                color: context.inputBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _isDeposit
                      ? (context.isDark ? AppColors.primary.withValues(alpha: 0.6) : const Color(0xFF15803D).withValues(alpha: 0.6))
                      : AppColors.red.withValues(alpha: 0.6),
                  width: 1.2,
                ),
              ),
              child: Row(
                children: [
                  Text(
                    '$symbol ',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: _isDeposit ? context.accentLinkColor : AppColors.red,
                    ),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                      autofocus: true,
                      cursorColor: _isDeposit
                          ? (context.isDark ? AppColors.primary : const Color(0xFF15803D))
                          : AppColors.red,
                      inputFormatters: [CurrencyInputFormatter()],
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: context.textPrimary,
                      ),
                      decoration: InputDecoration(
                        hintText: '0',
                        hintStyle: TextStyle(color: context.textMuted, fontSize: 14),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        errorBorder: InputBorder.none,
                        disabledBorder: InputBorder.none,
                        filled: false,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Quick Amount Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ...quickPills.map((val) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ActionChip(
                        backgroundColor: context.inputBg,
                        side: BorderSide(color: context.cardBorder),
                        label: Text(
                          '+$symbol ${CurrencyInputFormatter.format(val)}',
                          style: TextStyle(fontSize: 11, color: context.textPrimary),
                        ),
                        onPressed: () => _addQuickAmount(val),
                      ),
                    );
                  }),
                  ActionChip(
                    backgroundColor: context.isDark ? AppColors.primary.withValues(alpha: 0.15) : const Color(0xFFDCFCE7),
                    side: BorderSide(color: context.isDark ? AppColors.primary : const Color(0xFF15803D)),
                    label: Text(
                      'Max Target',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: context.isDark ? AppColors.primaryLight : const Color(0xFF15803D),
                      ),
                    ),
                    onPressed: _setMaxRemaining,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isDeposit ? AppColors.primary : AppColors.red,
                  foregroundColor: _isDeposit ? Colors.black : Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                onPressed: _isLoading ? null : () => _submit(displayAccounts),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        _isDeposit ? 'Add to Goal' : 'Withdraw from Goal',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
