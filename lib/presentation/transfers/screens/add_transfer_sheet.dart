import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/app_dropdown.dart';
import '../../../domain/entities/account.dart';
import '../../../domain/entities/transfer.dart';
import '../../accounts/providers/account_providers.dart';
import '../../repository_providers.dart';
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
  bool _isFetchingRate = false;

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

  Future<void> _updateExchangeRate(List<Account> accounts) async {
    final fromAcc = _findAccount(accounts, _fromAccountId);
    final toAcc = _findAccount(accounts, _toAccountId);
    if (fromAcc == null || toAcc == null) return;
    if (fromAcc.currency == toAcc.currency) {
      _rateController.text = '1.0';
      return;
    }

    setState(() => _isFetchingRate = true);
    try {
      final rate = await ref
          .read(exchangeRateRepositoryProvider)
          .getLatestRate(fromAcc.currency, toAcc.currency);
      if (rate != null && mounted) {
        setState(() {
          _rateController.text = rate.rate.toString();
        });
      }
    } catch (_) {
      // Ignored
    } finally {
      if (mounted) setState(() => _isFetchingRate = false);
    }
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

    final amountFrom = CurrencyInputFormatter.parse(_amountFromController.text);
    if (amountFrom <= 0) {
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
                      AppDropdownFormField<String>(
                        initialValue: _fromAccountId,
                        labelText: 'Source Account (Sender)',
                        sheetTitle: 'Select Source Account',
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
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _fromAccountId = val;
                              if (_fromAccountId == _toAccountId) {
                                _toAccountId = accounts.firstWhere((a) => a.id != val).id;
                              }
                            });
                            _updateExchangeRate(accounts);
                          }
                        },
                      ),
                      const SizedBox(height: 12),

                      // To Account
                      AppDropdownFormField<String>(
                        initialValue: _toAccountId,
                        labelText: 'Destination Account (Receiver)',
                        sheetTitle: 'Select Destination Account',
                        items: accounts.where((a) => a.id != _fromAccountId).map((acc) {
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
                              color: AppColors.teal,
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setState(() => _toAccountId = val);
                          _updateExchangeRate(accounts);
                        },
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
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Exchange Rate (1 ${fromAcc.currency} = ... ${toAcc.currency})',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.darkTextSecondary),
                            ),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _rateController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                              ],
                              style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                              decoration: InputDecoration(
                                hintText: '1.0',
                                hintStyle: const TextStyle(color: AppColors.darkTextMuted, fontSize: 14),
                                filled: true,
                                fillColor: AppColors.darkCardBg,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                suffixIcon: _isFetchingRate
                                    ? const Padding(
                                        padding: EdgeInsets.all(14),
                                        child: SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                                        ),
                                      )
                                    : null,
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
                                  borderSide: const BorderSide(color: AppColors.primary, width: 1.2),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                      ],
                    ],
                  );
                },
                loading: () => const LinearProgressIndicator(),
                error: (e, _) => Text('$e', style: const TextStyle(color: AppColors.red)),
              ),

              // Amount From
              accountsAsync.when(
                data: (accounts) {
                  final fromAcc = _findAccount(accounts, _fromAccountId);
                  final symbol = fromAcc?.currency == 'MYR' ? 'RM ' : 'Rp ';
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Transfer Amount',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.darkTextSecondary),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _amountFromController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [CurrencyInputFormatter()],
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
                        decoration: InputDecoration(
                          hintText: '0',
                          prefixText: symbol,
                          prefixStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.primary),
                          hintStyle: const TextStyle(color: AppColors.darkTextMuted, fontSize: 14),
                          filled: true,
                          fillColor: AppColors.darkCardBg,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                            borderSide: const BorderSide(color: AppColors.primary, width: 1.2),
                          ),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Amount is required' : null,
                      ),
                    ],
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (_, _) => const SizedBox.shrink(),
              ),
              const SizedBox(height: 16),

              // Notes
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Notes (Optional)',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.darkTextSecondary),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _notesController,
                    style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                    decoration: InputDecoration(
                      hintText: 'e.g., Transfer to savings, pocket money',
                      hintStyle: const TextStyle(color: AppColors.darkTextMuted, fontSize: 14),
                      filled: true,
                      fillColor: AppColors.darkCardBg,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                        borderSide: const BorderSide(color: AppColors.primary, width: 1.2),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Submit Button
              accountsAsync.when(
                data: (accounts) => SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    onPressed: _isLoading ? null : () => _submit(accounts),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                          )
                        : const Text(
                            'Send Transfer',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
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
