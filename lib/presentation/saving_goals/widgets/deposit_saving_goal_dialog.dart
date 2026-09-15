import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../domain/entities/saving_goal.dart';
import '../providers/saving_goal_providers.dart';

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
  final _amountController = TextEditingController();
  bool _isDeposit = true; // true = deposit, false = withdraw
  bool _isLoading = false;

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
    final remaining = (widget.goal.targetAmount - widget.goal.currentAmount).clamp(0, double.infinity);
    if (_isDeposit) {
      _amountController.text = CurrencyInputFormatter.format(remaining);
    } else {
      _amountController.text = CurrencyInputFormatter.format(widget.goal.currentAmount);
    }
    setState(() {});
  }

  Future<void> _submit() async {
    final inputAmount = CurrencyInputFormatter.parse(_amountController.text);
    if (inputAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount')),
      );
      return;
    }

    if (!_isDeposit && inputAmount > widget.goal.currentAmount) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Withdrawal amount cannot exceed current balance')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final delta = _isDeposit ? inputAmount : -inputAmount;
      await adjustSavingGoalAmount(ref, id: widget.goal.id, deltaAmount: delta);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isDeposit
                  ? 'Successfully saved to ${widget.goal.name}!'
                  : 'Successfully withdrawn from ${widget.goal.name}!',
            ),
            backgroundColor: AppColors.teal,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update: $e'), backgroundColor: AppColors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final isIdr = widget.goal.currency == 'IDR';
    final symbol = isIdr ? 'Rp' : 'RM';

    final inputAmount = CurrencyInputFormatter.parse(_amountController.text);
    final estimatedNewAmount = _isDeposit
        ? widget.goal.currentAmount + inputAmount
        : (widget.goal.currentAmount - inputAmount).clamp(0, double.infinity);
    final progress = widget.goal.targetAmount > 0
        ? (estimatedNewAmount / widget.goal.targetAmount).clamp(0.0, 1.0)
        : 0.0;

    final quickPills = isIdr
        ? [50000, 100000, 500000, 1000000]
        : [10, 50, 100, 500];

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
      child: Container(
        padding: EdgeInsets.fromLTRB(24, 20, 24, 24 + bottomInset),
        decoration: BoxDecoration(
          color: const Color(0xFF141418).withValues(alpha: 0.96),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.1),
            width: 1.2,
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
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isDeposit ? 'Add Savings' : 'Withdraw Savings',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.goal.name,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.darkTextSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  // Segmented Switcher (Deposit / Withdraw)
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: AppColors.darkCardBg,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.darkCardBorder),
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
                                color: _isDeposit ? Colors.black : AppColors.darkTextSecondary,
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
                                color: !_isDeposit ? Colors.white : AppColors.darkTextSecondary,
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
                  color: AppColors.darkCardBg,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.darkCardBorder),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Current: $symbol ${CurrencyInputFormatter.format(widget.goal.currentAmount)}',
                          style: const TextStyle(fontSize: 12, color: AppColors.darkTextSecondary),
                        ),
                        Text(
                          'Target: $symbol ${CurrencyInputFormatter.format(widget.goal.targetAmount)}',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 8,
                        backgroundColor: Colors.white.withValues(alpha: 0.08),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _isDeposit ? AppColors.primary : AppColors.orange,
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
                            color: _isDeposit ? AppColors.primaryLight : AppColors.orange,
                          ),
                        ),
                        Text(
                          '${(progress * 100).toStringAsFixed(1)}%',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Amount Input Field
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.darkCardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _isDeposit ? AppColors.primary.withValues(alpha: 0.6) : AppColors.red.withValues(alpha: 0.6),
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
                        color: _isDeposit ? AppColors.primary : AppColors.red,
                      ),
                    ),
                    Expanded(
                      child: TextField(
                        controller: _amountController,
                        keyboardType: TextInputType.number,
                        autofocus: true,
                        inputFormatters: [CurrencyInputFormatter()],
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                        decoration: const InputDecoration(
                          hintText: '0',
                          hintStyle: TextStyle(color: AppColors.darkTextMuted, fontSize: 14),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 14),
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
                          backgroundColor: AppColors.darkCardBg,
                          side: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
                          label: Text(
                            '+$symbol ${CurrencyInputFormatter.format(val)}',
                            style: const TextStyle(fontSize: 11, color: AppColors.darkTextPrimary),
                          ),
                          onPressed: () => _addQuickAmount(val),
                        ),
                      );
                    }),
                    ActionChip(
                      backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                      side: const BorderSide(color: AppColors.primary),
                      label: Text(
                        _isDeposit ? 'Max Target' : 'All Balance',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primaryLight),
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
                  onPressed: _isLoading ? null : _submit,
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
      ),
    );
  }
}
