import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/app_dropdown.dart';
import '../../../domain/entities/bill.dart';
import '../../accounts/providers/account_providers.dart';
import '../providers/bill_providers.dart';

class AddBillSheet extends ConsumerStatefulWidget {
  const AddBillSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AddBillSheet(),
    );
  }

  @override
  ConsumerState<AddBillSheet> createState() => _AddBillSheetState();
}

class _AddBillSheetState extends ConsumerState<AddBillSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();

  String _selectedCurrency = 'IDR';
  int _dueDay = 10;
  int _reminderDays = 3;
  String? _selectedAccountId;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final amount = CurrencyInputFormatter.parse(_amountController.text);
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid bill amount'), backgroundColor: AppColors.red),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final bill = Bill(
        id: '',
        name: _nameController.text.trim(),
        amount: amount,
        currency: _selectedCurrency,
        dueDay: _dueDay,
        accountId: _selectedAccountId,
        reminderDaysBefore: _reminderDays,
        isActive: true,
      );

      await createBill(ref, bill);

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
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final accountsAsync = ref.watch(accountsProvider);

    return Container(
      padding: EdgeInsets.fromLTRB(22, 20, 22, 20 + bottomInset),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(top: BorderSide(color: context.cardBorder, width: 1.5)),
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Drag handle
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
              const SizedBox(height: 16),

              Text(
                'Add Recurring Bill',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: context.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Schedule recurring payments (Utilities, Internet, Rent, etc.)',
                style: TextStyle(fontSize: 12, color: context.textSecondary),
              ),
              const SizedBox(height: 18),

              // Name
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Bill Name',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: context.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _nameController,
                    style: TextStyle(color: context.textPrimary, fontSize: 14, fontWeight: FontWeight.w600),
                    decoration: InputDecoration(
                      hintText: 'e.g., Fiber Internet, Electricity, Rent',
                      hintStyle: TextStyle(color: context.textMuted, fontSize: 14),
                      filled: true,
                      fillColor: context.inputBg,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Bill name is required' : null,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Amount & Currency
              accountsAsync.when(
                data: (accounts) => Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Amount',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: context.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _amountController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [CurrencyInputFormatter()],
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: context.textPrimary,
                            ),
                            decoration: InputDecoration(
                              hintText: '0',
                              prefixText: _selectedCurrency == 'IDR' ? 'Rp ' : 'RM ',
                              prefixStyle: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: context.accentLinkColor,
                              ),
                              hintStyle: TextStyle(
                                color: context.textMuted,
                                fontSize: 14,
                              ),
                              filled: true,
                              fillColor: context.inputBg,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                            validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Currency',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: context.textSecondary),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            height: 50,
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: context.inputBg,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: context.cardBorder),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _selectedCurrency = 'IDR';
                                        if (_selectedAccountId != null) {
                                          final acc = accounts.where((a) => a.id == _selectedAccountId).firstOrNull;
                                          if (acc == null || acc.currency != 'IDR') {
                                            _selectedAccountId = null;
                                          }
                                        }
                                      });
                                    },
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: _selectedCurrency == 'IDR' ? AppColors.primary : Colors.transparent,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        'IDR',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: _selectedCurrency == 'IDR' ? Colors.black : context.textSecondary,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _selectedCurrency = 'MYR';
                                        if (_selectedAccountId != null) {
                                          final acc = accounts.where((a) => a.id == _selectedAccountId).firstOrNull;
                                          if (acc == null || acc.currency != 'MYR') {
                                            _selectedAccountId = null;
                                          }
                                        }
                                      });
                                    },
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: _selectedCurrency == 'MYR' ? AppColors.primary : Colors.transparent,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        'MYR',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: _selectedCurrency == 'MYR' ? Colors.black : context.textSecondary,
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
                loading: () => const SizedBox.shrink(),
                error: (_, _) => const SizedBox.shrink(),
              ),
              const SizedBox(height: 16),

              // Due day and Reminder days
              Row(
                children: [
                  Expanded(
                    child: AppDropdownFormField<int>(
                      initialValue: _dueDay,
                      labelText: 'Due Date (Day)',
                      enableSearch: true,
                      sheetTitle: 'Select Due Date',
                      items: List.generate(31, (i) => i + 1).map((d) {
                        return AppDropdownItem<int>(
                          value: d,
                          label: 'Day $d',
                          subtitle: 'Every month on the ${d}th',
                          icon: Icon(Icons.calendar_today_rounded, size: 18, color: context.accentIconColor),
                        );
                      }).toList(),
                      onChanged: (v) => setState(() => _dueDay = v ?? 10),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: AppDropdownFormField<int>(
                      initialValue: _reminderDays,
                      labelText: 'Reminder',
                      sheetTitle: 'Select Reminder Time',
                      items: [1, 2, 3, 5, 7].map((d) {
                        return AppDropdownItem<int>(
                          value: d,
                          label: '$d days before',
                          subtitle: 'Notify $d days ahead of due date',
                          icon: const Icon(Icons.notifications_active_outlined, size: 18, color: AppColors.orange),
                        );
                      }).toList(),
                      onChanged: (v) => setState(() => _reminderDays = v ?? 3),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Default Account (Optional) - Filtered by selected currency
              accountsAsync.when(
                data: (accounts) {
                  final matchingAccounts = accounts.where((a) => a.currency == _selectedCurrency).toList();
                  if (_selectedAccountId != null && !matchingAccounts.any((a) => a.id == _selectedAccountId)) {
                    _selectedAccountId = null;
                  }

                  return AppDropdownFormField<String?>(
                    key: ValueKey('bill_default_account_${_selectedCurrency}_$_selectedAccountId'),
                    value: _selectedAccountId,
                    labelText: 'Default Payment Account (Optional)',
                    sheetTitle: 'Select Default Account',
                    items: [
                      AppDropdownItem<String?>(
                        value: null,
                        label: 'None (Select when paying)',
                        icon: Icon(Icons.help_outline_rounded, size: 20, color: context.textSecondary),
                      ),
                      ...matchingAccounts.map((acc) => AppDropdownItem<String?>(
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
                              color: AppColors.teal,
                            ),
                          )),
                    ],
                    onChanged: (val) => setState(() => _selectedAccountId = val),
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (_, _) => const SizedBox.shrink(),
              ),
              const SizedBox(height: 24),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  onPressed: _isLoading ? null : _submit,
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                        )
                      : const Text(
                          'Save Bill',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
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
