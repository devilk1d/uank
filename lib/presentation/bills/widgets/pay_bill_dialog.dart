import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/bill.dart';
import '../../accounts/providers/account_providers.dart';
import '../providers/bill_providers.dart';

class PayBillDialog extends ConsumerStatefulWidget {
  const PayBillDialog({super.key, required this.bill});

  final Bill bill;

  static Future<void> show(BuildContext context, Bill bill) {
    return showDialog(
      context: context,
      builder: (_) => PayBillDialog(bill: bill),
    );
  }

  @override
  ConsumerState<PayBillDialog> createState() => _PayBillDialogState();
}

class _PayBillDialogState extends ConsumerState<PayBillDialog> {
  late final TextEditingController _amountController;
  String? _selectedAccountId;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(text: widget.bill.amount.toStringAsFixed(0));
    _selectedAccountId = widget.bill.accountId;
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _pay() async {
    if (_selectedAccountId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an account to pay from'), backgroundColor: AppColors.red),
      );
      return;
    }

    final amount = num.tryParse(_amountController.text.replaceAll(RegExp(r'[^0-9.]'), ''));
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount'), backgroundColor: AppColors.red),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await payBill(
        ref,
        billId: widget.bill.id,
        accountId: _selectedAccountId!,
        amount: amount,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Bill "${widget.bill.name}" paid successfully!'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Payment failed: $e'), backgroundColor: AppColors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final accountsAsync = ref.watch(accountsProvider);

    return AlertDialog(
      backgroundColor: AppColors.darkCardBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: const BorderSide(color: AppColors.darkCardBorder),
      ),
      title: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withValues(alpha: 0.15),
            ),
            child: const Icon(Icons.receipt_long_rounded, color: AppColors.primaryLight, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Pay Bill',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.darkTextPrimary),
                ),
                Text(
                  widget.bill.name,
                  style: const TextStyle(fontSize: 12, color: AppColors.darkTextSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Amount
            TextFormField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.darkTextPrimary),
              decoration: InputDecoration(
                labelText: 'Amount to Pay (${widget.bill.currency})',
                labelStyle: const TextStyle(color: AppColors.darkTextSecondary, fontSize: 12),
                filled: true,
                fillColor: Colors.black45,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.darkCardBorder),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Account selection
            accountsAsync.when(
              data: (accounts) {
                if (accounts.isEmpty) {
                  return const Text('No active accounts available', style: TextStyle(color: AppColors.orange, fontSize: 12));
                }
                _selectedAccountId ??= accounts.first.id;

                return DropdownButtonFormField<String>(
                  initialValue: _selectedAccountId,
                  dropdownColor: AppColors.darkCardBg,
                  style: const TextStyle(color: AppColors.darkTextPrimary, fontSize: 13),
                  decoration: InputDecoration(
                    labelText: 'Pay from Account',
                    labelStyle: const TextStyle(color: AppColors.darkTextSecondary, fontSize: 12),
                    filled: true,
                    fillColor: Colors.black45,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.darkCardBorder),
                    ),
                  ),
                  items: accounts.map((acc) {
                    return DropdownMenuItem(
                      value: acc.id,
                      child: Text('${acc.name} (${acc.currency})'),
                    );
                  }).toList(),
                  onChanged: (val) => setState(() => _selectedAccountId = val),
                );
              },
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => Text('$e', style: const TextStyle(color: AppColors.red, fontSize: 12)),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(color: AppColors.darkTextSecondary)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: _isLoading ? null : _pay,
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                )
              : const Text('Confirm Payment', style: TextStyle(fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }
}
