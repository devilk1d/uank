import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/app_calendar_sheet.dart';
import '../../../core/widgets/app_dropdown.dart';
import '../../../domain/entities/bill.dart';
import '../../accounts/providers/account_providers.dart';
import '../providers/bill_providers.dart';

class PayBillDialog extends ConsumerStatefulWidget {
  const PayBillDialog({super.key, required this.bill, this.periodMonth});

  final Bill bill;
  final DateTime? periodMonth;

  static Future<void> show(BuildContext context, Bill bill, {DateTime? periodMonth}) {
    return showDialog(
      context: context,
      builder: (_) => PayBillDialog(bill: bill, periodMonth: periodMonth),
    );
  }

  @override
  ConsumerState<PayBillDialog> createState() => _PayBillDialogState();
}

class _PayBillDialogState extends ConsumerState<PayBillDialog> {
  late final TextEditingController _amountController;
  String? _selectedAccountId;
  DateTime _selectedPaidDate = DateTime.now();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(text: CurrencyInputFormatter.format(widget.bill.amount));
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

    final amount = CurrencyInputFormatter.parse(_amountController.text);
    if (amount <= 0) {
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
        periodMonth: widget.periodMonth,
        paidDate: _selectedPaidDate,
      );

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (_) {
      // Failed silently / handled
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
            const Text(
              'Amount to Pay',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.darkTextSecondary,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              inputFormatters: [CurrencyInputFormatter()],
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              decoration: InputDecoration(
                hintText: '0',
                hintStyle: const TextStyle(
                  color: AppColors.darkTextMuted,
                  fontSize: 14,
                ),
                prefixText: widget.bill.currency == 'IDR' ? 'Rp  ' : 'RM  ',
                prefixStyle: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
                filled: true,
                fillColor: AppColors.darkCardBg,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppColors.darkCardBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppColors.darkCardBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(
                    color: AppColors.primary,
                    width: 1.2,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Account selection
            accountsAsync.when(
              data: (accounts) {
                if (accounts.isEmpty) {
                  return const Text(
                    'No active accounts available',
                    style: TextStyle(color: AppColors.orange, fontSize: 12),
                  );
                }
                _selectedAccountId ??= accounts.first.id;

                return AppDropdownFormField<String>(
                  initialValue: _selectedAccountId,
                  labelText: 'Pay from Account',
                  sheetTitle: 'Select Payment Account',
                  items: accounts.map((acc) {
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
                        color: AppColors.primary,
                      ),
                    );
                  }).toList(),
                  onChanged: (val) => setState(() => _selectedAccountId = val),
                );
              },
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => Text('$e', style: const TextStyle(color: AppColors.red, fontSize: 12)),
            ),
            const SizedBox(height: 16),

            // Payment Date Picker
            const Text(
              'Payment Date',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.darkTextSecondary,
              ),
            ),
            const SizedBox(height: 8),
            InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () async {
                final picked = await AppDatePickerSheet.show(
                  context,
                  initialDate: _selectedPaidDate,
                  title: 'Select Payment Date',
                );
                if (picked != null) {
                  setState(() => _selectedPaidDate = picked);
                }
              },
              child: Container(
                height: 50,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: AppColors.darkCardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.darkCardBorder),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_today_rounded,
                          size: 18,
                          color: AppColors.primaryLight,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '${_selectedPaidDate.day}/${_selectedPaidDate.month}/${_selectedPaidDate.year}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      size: 20,
                      color: AppColors.darkTextSecondary,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(
            'Cancel',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.darkTextSecondary,
            ),
          ),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          ),
          onPressed: _isLoading ? null : _pay,
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                )
              : const Text(
                  'Confirm Payment',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
        ),
      ],
    );
  }
}
