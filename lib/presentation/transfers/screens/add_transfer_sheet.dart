import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/account.dart';
import '../../../domain/entities/transfer.dart';
import '../../accounts/providers/account_providers.dart';
import '../providers/transfer_providers.dart';

class AddTransferSheet extends ConsumerStatefulWidget {
  const AddTransferSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AddTransferSheet(),
    );
  }

  @override
  ConsumerState<AddTransferSheet> createState() => _AddTransferSheetState();
}

class _AddTransferSheetState extends ConsumerState<AddTransferSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amountFromController = TextEditingController();
  final _rateController = TextEditingController(text: '1.0');
  final _notesController = TextEditingController();

  String? _fromAccountId;
  String? _toAccountId;
  bool _isLoading = false;

  @override
  void dispose() {
    _amountFromController.dispose();
    _rateController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Account? _findAccount(List<Account> accounts, String? id) {
    if (id == null) return null;
    return accounts.where((a) => a.id == id).firstOrNull;
  }

  Future<void> _submit(List<Account> accounts) async {
    if (!_formKey.currentState!.validate()) return;

    if (_fromAccountId == null || _toAccountId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select source and destination accounts'), backgroundColor: AppColors.red),
      );
      return;
    }

    if (_fromAccountId == _toAccountId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Source and destination accounts cannot be the same'), backgroundColor: AppColors.red),
      );
      return;
    }

    final amountFrom = num.tryParse(_amountFromController.text.replaceAll(RegExp(r'[^0-9.]'), ''));
    if (amountFrom == null || amountFrom <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid transfer amount'), backgroundColor: AppColors.red),
      );
      return;
    }

    final exchangeRate = num.tryParse(_rateController.text) ?? 1.0;
    final amountTo = amountFrom * exchangeRate;

    setState(() => _isLoading = true);

    try {
      final transfer = Transfer(
        id: '',
        fromAccountId: _fromAccountId!,
        toAccountId: _toAccountId!,
        amountFrom: amountFrom,
        amountTo: amountTo,
        exchangeRate: exchangeRate,
        transferDate: DateTime.now(),
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      );

      await createTransfer(ref, transfer);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Transfer completed successfully!'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to process transfer: $e'), backgroundColor: AppColors.red),
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
                'Transfer Funds',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.darkTextPrimary,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Move money between bank accounts, e-wallets, or currencies',
                style: TextStyle(fontSize: 12, color: AppColors.darkTextSecondary),
              ),
              const SizedBox(height: 18),

              // Accounts dropdowns
              accountsAsync.when(
                data: (accounts) {
                  if (accounts.length < 2) {
                    return const Text(
                      'At least 2 accounts are required to make a transfer.',
                      style: TextStyle(color: AppColors.orange, fontSize: 13),
                    );
                  }

                  _fromAccountId ??= accounts[0].id;
                  _toAccountId ??= accounts[1].id;

                  final fromAcc = _findAccount(accounts, _fromAccountId);
                  final toAcc = _findAccount(accounts, _toAccountId);
                  final isCrossCurrency = fromAcc != null && toAcc != null && fromAcc.currency != toAcc.currency;

                  return Column(
                    children: [
                      // From Account
                      DropdownButtonFormField<String>(
                        initialValue: _fromAccountId,
                        dropdownColor: AppColors.darkCardBg,
                        style: const TextStyle(color: AppColors.darkTextPrimary, fontSize: 14),
                        decoration: InputDecoration(
                          labelText: 'Source Account (Sender)',
                          labelStyle: const TextStyle(color: AppColors.darkTextSecondary, fontSize: 13),
                          filled: true,
                          fillColor: Colors.black45,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: AppColors.darkCardBorder),
                          ),
                        ),
                        items: accounts.map((acc) {
                          return DropdownMenuItem(
                            value: acc.id,
                            child: Text('${acc.name} (${acc.currency})'),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setState(() {
                            _fromAccountId = val;
                            if (_fromAccountId == _toAccountId) {
                              _toAccountId = accounts.firstWhere((a) => a.id != val).id;
                            }
                          });
                        },
                      ),
                      const SizedBox(height: 12),

                      // To Account
                      DropdownButtonFormField<String>(
                        initialValue: _toAccountId,
                        dropdownColor: AppColors.darkCardBg,
                        style: const TextStyle(color: AppColors.darkTextPrimary, fontSize: 14),
                        decoration: InputDecoration(
                          labelText: 'Destination Account (Receiver)',
                          labelStyle: const TextStyle(color: AppColors.darkTextSecondary, fontSize: 13),
                          filled: true,
                          fillColor: Colors.black45,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: AppColors.darkCardBorder),
                          ),
                        ),
                        items: accounts.where((a) => a.id != _fromAccountId).map((acc) {
                          return DropdownMenuItem(
                            value: acc.id,
                            child: Text('${acc.name} (${acc.currency})'),
                          );
                        }).toList(),
                        onChanged: (val) => setState(() => _toAccountId = val),
                      ),
                      const SizedBox(height: 14),

                      // Cross currency notice & rate
                      if (isCrossCurrency) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.currency_exchange_rounded, size: 20, color: AppColors.primaryLight),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Cross-currency transfer (${fromAcc.currency} \u2192 ${toAcc.currency})',
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primaryLight),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _rateController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          style: const TextStyle(color: AppColors.darkTextPrimary, fontSize: 14),
                          decoration: InputDecoration(
                            labelText: 'Exchange Rate (1 ${fromAcc.currency} = ... ${toAcc.currency})',
                            labelStyle: const TextStyle(color: AppColors.darkTextSecondary, fontSize: 12),
                            filled: true,
                            fillColor: Colors.black45,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: AppColors.darkCardBorder),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                      ],
                    ],
                  );
                },
                loading: () => const LinearProgressIndicator(),
                error: (e, _) => Text('$e', style: const TextStyle(color: AppColors.red)),
              ),

              // Amount From
              TextFormField(
                controller: _amountFromController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.darkTextPrimary),
                decoration: InputDecoration(
                  labelText: 'Transfer Amount',
                  labelStyle: const TextStyle(color: AppColors.darkTextSecondary, fontSize: 13),
                  filled: true,
                  fillColor: Colors.black45,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppColors.darkCardBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                  ),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Amount is required' : null,
              ),
              const SizedBox(height: 14),

              // Notes
              TextFormField(
                controller: _notesController,
                style: const TextStyle(color: AppColors.darkTextPrimary, fontSize: 14),
                decoration: InputDecoration(
                  labelText: 'Notes (Optional)',
                  labelStyle: const TextStyle(color: AppColors.darkTextSecondary, fontSize: 13),
                  filled: true,
                  fillColor: Colors.black45,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppColors.darkCardBorder),
                  ),
                ),
              ),
              const SizedBox(height: 22),

              // Submit Button
              accountsAsync.when(
                data: (accounts) => GestureDetector(
                  onTap: _isLoading ? null : () => _submit(accounts),
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
                              'Send Transfer',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.black),
                            ),
                    ),
                  ),
                ),
                loading: () => const SizedBox.shrink(),
                error: (_, _) => const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
