import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
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

    final amount = num.tryParse(_amountController.text.replaceAll(RegExp(r'[^0-9.]'), ''));
    if (amount == null || amount <= 0) {
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Recurring bill created successfully!'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create bill: $e'), backgroundColor: AppColors.red),
        );
      }
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
      decoration: const BoxDecoration(
        color: AppColors.darkCardBg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(top: BorderSide(color: AppColors.darkCardBorder, width: 1.5)),
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
                    color: AppColors.darkTextMuted,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              const Text(
                'Add Recurring Bill',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.darkTextPrimary,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Schedule recurring payments (Utilities, Internet, Rent, etc.)',
                style: TextStyle(fontSize: 12, color: AppColors.darkTextSecondary),
              ),
              const SizedBox(height: 18),

              // Name
              TextFormField(
                controller: _nameController,
                style: const TextStyle(color: AppColors.darkTextPrimary, fontSize: 14),
                decoration: InputDecoration(
                  labelText: 'Bill Name',
                  hintText: 'e.g., Fiber Internet, Electricity, Apartment Rent',
                  labelStyle: const TextStyle(color: AppColors.darkTextSecondary, fontSize: 13),
                  filled: true,
                  fillColor: Colors.black45,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppColors.darkCardBorder),
                  ),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Bill name is required' : null,
              ),
              const SizedBox(height: 14),

              // Amount & Currency
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      controller: _amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.darkTextPrimary),
                      decoration: InputDecoration(
                        labelText: 'Amount',
                        labelStyle: const TextStyle(color: AppColors.darkTextSecondary, fontSize: 13),
                        filled: true,
                        fillColor: Colors.black45,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: AppColors.darkCardBorder),
                        ),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: DropdownButtonFormField<String>(
                      initialValue: _selectedCurrency,
                      dropdownColor: AppColors.darkCardBg,
                      style: const TextStyle(color: AppColors.darkTextPrimary, fontSize: 14),
                      decoration: InputDecoration(
                        labelText: 'Currency',
                        labelStyle: const TextStyle(color: AppColors.darkTextSecondary, fontSize: 13),
                        filled: true,
                        fillColor: Colors.black45,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: AppColors.darkCardBorder),
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'IDR', child: Text('IDR')),
                        DropdownMenuItem(value: 'MYR', child: Text('MYR')),
                      ],
                      onChanged: (v) => setState(() => _selectedCurrency = v ?? 'IDR'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Due day and Reminder days
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      initialValue: _dueDay,
                      dropdownColor: AppColors.darkCardBg,
                      style: const TextStyle(color: AppColors.darkTextPrimary, fontSize: 14),
                      decoration: InputDecoration(
                        labelText: 'Due Date (Day)',
                        labelStyle: const TextStyle(color: AppColors.darkTextSecondary, fontSize: 12),
                        filled: true,
                        fillColor: Colors.black45,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: AppColors.darkCardBorder),
                        ),
                      ),
                      items: List.generate(31, (i) => i + 1).map((d) {
                        return DropdownMenuItem(value: d, child: Text('Day $d'));
                      }).toList(),
                      onChanged: (v) => setState(() => _dueDay = v ?? 10),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      initialValue: _reminderDays,
                      dropdownColor: AppColors.darkCardBg,
                      style: const TextStyle(color: AppColors.darkTextPrimary, fontSize: 14),
                      decoration: InputDecoration(
                        labelText: 'Reminder',
                        labelStyle: const TextStyle(color: AppColors.darkTextSecondary, fontSize: 12),
                        filled: true,
                        fillColor: Colors.black45,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: AppColors.darkCardBorder),
                        ),
                      ),
                      items: [1, 2, 3, 5, 7].map((d) {
                        return DropdownMenuItem(value: d, child: Text('$d days before'));
                      }).toList(),
                      onChanged: (v) => setState(() => _reminderDays = v ?? 3),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Default Account (Optional)
              accountsAsync.when(
                data: (accounts) {
                  return DropdownButtonFormField<String?>(
                    initialValue: _selectedAccountId,
                    dropdownColor: AppColors.darkCardBg,
                    style: const TextStyle(color: AppColors.darkTextPrimary, fontSize: 14),
                    decoration: InputDecoration(
                      labelText: 'Default Payment Account (Optional)',
                      labelStyle: const TextStyle(color: AppColors.darkTextSecondary, fontSize: 13),
                      filled: true,
                      fillColor: Colors.black45,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: AppColors.darkCardBorder),
                      ),
                    ),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('Select when paying')),
                      ...accounts.map((acc) => DropdownMenuItem(
                            value: acc.id,
                            child: Text('${acc.name} (${acc.currency})'),
                          )),
                    ],
                    onChanged: (val) => setState(() => _selectedAccountId = val),
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (_, _) => const SizedBox.shrink(),
              ),
              const SizedBox(height: 22),

              // Submit Button
              GestureDetector(
                onTap: _isLoading ? null : _submit,
                child: Container(
                  height: 50,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: AppColors.primary,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                          )
                        : const Text(
                            'Save Bill',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.black),
                          ),
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
