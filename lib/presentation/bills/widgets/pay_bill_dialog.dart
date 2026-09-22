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
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.65),
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
    _amountController = TextEditingController(
      text: CurrencyInputFormatter.format(widget.bill.amount, currency: widget.bill.currency),
    );
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
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(22, 16, 22, 24 + bottomInset + bottomPadding),
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
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: context.textMuted.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Header Row: Icon + Title
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: (context.isDark ? AppColors.primary : const Color(0xFF15803D)).withValues(alpha: 0.15),
                    border: Border.all(
                      color: (context.isDark ? AppColors.primary : const Color(0xFF15803D)).withValues(alpha: 0.3),
                      width: 1.2,
                    ),
                  ),
                  child: Icon(Icons.receipt_long_rounded, color: context.accentIconColor, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pay Bill',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                          color: context.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.bill.name,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: context.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Amount to Pay
            Text(
              'Amount to Pay',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: context.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              inputFormatters: [CurrencyInputFormatter()],
              style: TextStyle(
                color: context.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
              decoration: InputDecoration(
                hintText: '0',
                hintStyle: TextStyle(
                  color: context.textMuted,
                  fontSize: 14,
                ),
                prefixText: widget.bill.currency == 'IDR' ? 'Rp  ' : 'RM  ',
                prefixStyle: TextStyle(
                  color: context.accentLinkColor,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
                filled: true,
                fillColor: context.inputBg,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: context.cardBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: context.cardBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: context.isDark ? AppColors.primary : const Color(0xFF15803D),
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
                        color: context.accentIconColor,
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
            Text(
              'Payment Date',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: context.textSecondary,
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
                  color: context.inputBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: context.cardBorder),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today_rounded,
                          size: 18,
                          color: context.accentIconColor,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '${_selectedPaidDate.day}/${_selectedPaidDate.month}/${_selectedPaidDate.year}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: context.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 20,
                      color: context.textSecondary,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Action Buttons
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.black,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: _isLoading ? null : _pay,
                child: _isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                      )
                    : const Text(
                        'Confirm Payment',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: context.textSecondary,
                  backgroundColor: context.inputBg,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: context.cardBorder,
                    ),
                  ),
                ),
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: context.textPrimary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
