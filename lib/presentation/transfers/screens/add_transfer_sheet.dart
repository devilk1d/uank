import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/receipt_ocr_parser.dart';
import '../../../core/widgets/app_dropdown.dart';
import '../../../core/widgets/receipt_attachment_picker.dart';
import '../../../domain/entities/account.dart';
import '../../../domain/entities/transfer.dart';
import '../../accounts/providers/account_providers.dart';
import '../../repository_providers.dart';
import '../../settings/providers/receipt_ocr_provider.dart';
import '../providers/transfer_providers.dart';

class AddTransferSheet extends ConsumerStatefulWidget {
  const AddTransferSheet({super.key, this.transferToEdit});

  final Transfer? transferToEdit;

  static Future<void> show(BuildContext context, {Transfer? transferToEdit}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddTransferSheet(transferToEdit: transferToEdit),
    );
  }

  @override
  ConsumerState<AddTransferSheet> createState() => _AddTransferSheetState();
}

class _AddTransferSheetState extends ConsumerState<AddTransferSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountFromController;
  late final TextEditingController _rateController;
  late final TextEditingController _notesController;

  String? _fromAccountId;
  String? _toAccountId;
  num? _apiRate;
  bool _isCustomRate = false;
  bool _isLoading = false;
  bool _isFetchingRate = false;
  String? _rateError;
  bool _hasInitializedAccounts = false;

  // Staged Receipt Image State (In-Memory)
  Uint8List? _stagedImageBytes;
  String? _stagedImageExtension;
  String? _existingAttachmentUrl;
  bool _isExistingAttachmentRemoved = false;
  bool _isScanningOcr = false;

  bool get isEditing => widget.transferToEdit != null;

  @override
  void initState() {
    super.initState();
    final editTr = widget.transferToEdit;
    if (editTr != null) {
      _fromAccountId = editTr.fromAccountId;
      _toAccountId = editTr.toAccountId;
      _existingAttachmentUrl = editTr.attachmentUrl;
      _amountFromController = TextEditingController(
        text: CurrencyInputFormatter.format(editTr.amountFrom),
      );
      _rateController = TextEditingController(text: editTr.exchangeRate.toString());
      _notesController = TextEditingController(text: editTr.notes ?? '');
    } else {
      _amountFromController = TextEditingController();
      _rateController = TextEditingController(text: '1.0');
      _notesController = TextEditingController();
    }
    _amountFromController.addListener(() => setState(() {}));
  }

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

  Future<void> _updateExchangeRate(List<Account> accounts, {bool forceRefresh = false}) async {
    final fromAcc = _findAccount(accounts, _fromAccountId);
    final toAcc = _findAccount(accounts, _toAccountId);
    if (fromAcc == null || toAcc == null) return;

    if (fromAcc.currency == toAcc.currency) {
      if (mounted) {
        setState(() {
          _rateController.text = '1.0';
          _apiRate = 1.0;
          _isCustomRate = false;
          _rateError = null;
        });
      }
      return;
    }

    setState(() {
      _isFetchingRate = true;
      _rateError = null;
    });

    try {
      final rate = await ref
          .read(exchangeRateRepositoryProvider)
          .getLatestRate(fromAcc.currency, toAcc.currency, forceRefresh: forceRefresh);
      if (rate != null && mounted) {
        final formatted = _formatRate(rate.rate);
        setState(() {
          _apiRate = rate.rate;
          _rateController.text = formatted;
          _isCustomRate = false;
        });
      } else if (mounted) {
        setState(() {
          _rateError = 'Failed to load live rate from API. You can enter it manually.';
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _rateError = 'Network error fetching rate. You can enter it manually.';
        });
      }
    } finally {
      if (mounted) setState(() => _isFetchingRate = false);
    }
  }

  void _swapAccounts(List<Account> accounts) {
    if (_fromAccountId == null || _toAccountId == null) return;
    setState(() {
      final temp = _fromAccountId;
      _fromAccountId = _toAccountId;
      _toAccountId = temp;
    });
    _updateExchangeRate(accounts);
  }

  void _resetToApiRate() {
    if (_apiRate != null) {
      setState(() {
        _rateController.text = _formatRate(_apiRate!);
        _isCustomRate = false;
      });
    }
  }

  String _formatRate(num rate) {
    if (rate >= 100) {
      return rate % 1 == 0 ? rate.toStringAsFixed(0) : rate.toStringAsFixed(2);
    } else if (rate >= 1) {
      return rate.toStringAsFixed(4).replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
    } else {
      final s = rate.toStringAsFixed(6).replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
      return s.isEmpty ? '0' : s;
    }
  }

  String _formatAmount(num value, String currency) {
    return CurrencyInputFormatter.format(value, currency: currency);
  }

  void _handleOcrResult(OcrResult ocr, List<Account> accounts) {
    setState(() {
      _isScanningOcr = false;

      if (ocr.currency != null) {
        final currentFromAcc = _findAccount(accounts, _fromAccountId);
        if (currentFromAcc == null || currentFromAcc.currency != ocr.currency) {
          final matchingAcc = accounts.where((a) => a.currency == ocr.currency).firstOrNull;
          if (matchingAcc != null) {
            _fromAccountId = matchingAcc.id;
            if (_fromAccountId == _toAccountId) {
              _toAccountId = accounts.firstWhere((a) => a.id != matchingAcc.id).id;
            }
            _updateExchangeRate(accounts);
          }
        }
      }

      final fromAcc = _findAccount(accounts, _fromAccountId);
      final currency = fromAcc?.currency ?? ocr.currency ?? 'IDR';

      if (ocr.amount != null) {
        _amountFromController.text = CurrencyInputFormatter.format(
          ocr.amount!,
          currency: currency,
        );
      }
    });
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

    final fromAcc = _findAccount(accounts, _fromAccountId);
    final toAcc = _findAccount(accounts, _toAccountId);
    final isCrossCurrency = fromAcc != null && toAcc != null && fromAcc.currency != toAcc.currency;

    final amountFrom = CurrencyInputFormatter.parse(_amountFromController.text, currency: fromAcc?.currency);
    if (amountFrom <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid transfer amount'), backgroundColor: AppColors.red),
      );
      return;
    }

    final exchangeRate = isCrossCurrency ? (num.tryParse(_rateController.text) ?? 1.0) : 1.0;
    if (isCrossCurrency && exchangeRate <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid exchange rate greater than 0'), backgroundColor: AppColors.red),
      );
      return;
    }

    final amountTo = isCrossCurrency ? (amountFrom * exchangeRate) : amountFrom;

    setState(() => _isLoading = true);

    try {
      String? finalAttachmentUrl = _existingAttachmentUrl;
      if (_isExistingAttachmentRemoved) {
        finalAttachmentUrl = null;
      }

      // If user staged a new image in memory, upload it now upon save
      if (_stagedImageBytes != null) {
        final uploadUrl = await ref
            .read(transferRepositoryProvider)
            .uploadReceiptImage(
              bytes: _stagedImageBytes!,
              fileExtension: _stagedImageExtension ?? 'jpg',
            );
        finalAttachmentUrl = uploadUrl;
      }

      if (isEditing) {
        final updatedTr = widget.transferToEdit!.copyWith(
          fromAccountId: _fromAccountId!,
          toAccountId: _toAccountId!,
          amountFrom: amountFrom,
          amountTo: amountTo,
          exchangeRate: exchangeRate,
          notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
          attachmentUrl: finalAttachmentUrl,
        );

        await updateTransfer(
          ref,
          updatedTr,
          oldAttachmentUrl: (_isExistingAttachmentRemoved || _stagedImageBytes != null)
              ? widget.transferToEdit!.attachmentUrl
              : null,
        );

        if (mounted) {
          Navigator.pop(context);
        }
      } else {
        final transfer = Transfer(
          id: '',
          fromAccountId: _fromAccountId!,
          toAccountId: _toAccountId!,
          amountFrom: amountFrom,
          amountTo: amountTo,
          exchangeRate: exchangeRate,
          transferDate: DateTime.now(),
          notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
          attachmentUrl: finalAttachmentUrl,
        );

        await createTransfer(ref, transfer);

        if (mounted) {
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to process transfer: $e'),
            backgroundColor: AppColors.red,
          ),
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
    final isOcrEnabled = ref.watch(receiptOcrSettingProvider);

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
                'Transfer Funds',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: context.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Move money between bank accounts, e-wallets, or currencies',
                style: TextStyle(fontSize: 12, color: context.textSecondary),
              ),
              const SizedBox(height: 18),

              // Accounts dropdowns & Swap Button
              accountsAsync.when(
                data: (accounts) {
                  if (accounts.length < 2) {
                    return const Text(
                      'At least 2 accounts are required to make a transfer.',
                      style: TextStyle(color: AppColors.orange, fontSize: 13),
                    );
                  }

                  if (!_hasInitializedAccounts) {
                    _fromAccountId ??= accounts[0].id;
                    _toAccountId ??= accounts[1].id;
                    _hasInitializedAccounts = true;
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) {
                        _updateExchangeRate(accounts);
                      }
                    });
                  }

                  final fromAcc = _findAccount(accounts, _fromAccountId);
                  final toAcc = _findAccount(accounts, _toAccountId);
                  final isCrossCurrency = fromAcc != null && toAcc != null && fromAcc.currency != toAcc.currency;

                  final rawAmount = CurrencyInputFormatter.parse(_amountFromController.text, currency: fromAcc?.currency);
                  final currentRate = num.tryParse(_rateController.text) ?? 1.0;
                  final estimatedAmountTo = isCrossCurrency ? (rawAmount * currentRate) : rawAmount;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Source Account (Sender)
                      AppDropdownFormField<String>(
                        key: ValueKey('from_account_$_fromAccountId'),
                        value: _fromAccountId,
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
                              color: context.accentIconColor,
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null && val != _fromAccountId) {
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

                      // Swap Accounts Button
                      Center(
                        child: GestureDetector(
                          onTap: () => _swapAccounts(accounts),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: context.inputBg,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: context.cardBorder),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.swap_vert_rounded, size: 16, color: context.accentLinkColor),
                                const SizedBox(width: 6),
                                Text(
                                  'Swap Accounts',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: context.accentLinkColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Destination Account (Receiver)
                      AppDropdownFormField<String>(
                        key: ValueKey('to_account_$_toAccountId'),
                        value: _toAccountId,
                        labelText: 'Destination Account (Receiver)',
                        sheetTitle: 'Select Destination Account',
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
                        onChanged: (val) {
                          if (val != null && val != _toAccountId) {
                            setState(() {
                              _toAccountId = val;
                              if (_toAccountId == _fromAccountId) {
                                _fromAccountId = accounts.firstWhere((a) => a.id != val).id;
                              }
                            });
                            _updateExchangeRate(accounts);
                          }
                        },
                      ),
                      const SizedBox(height: 16),

                      // Exchange Rate Section (Cross-currency only)
                      if (isCrossCurrency) ...[
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: context.inputBg,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: (context.isDark ? AppColors.primary : const Color(0xFF15803D)).withValues(alpha: 0.3),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.currency_exchange_rounded,
                                        size: 16,
                                        color: context.accentLinkColor,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Exchange Rate',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: context.textPrimary,
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (_isFetchingRate)
                                    SizedBox(
                                      width: 14,
                                      height: 14,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: context.accentLinkColor,
                                      ),
                                    )
                                  else
                                    GestureDetector(
                                      onTap: () => _updateExchangeRate(accounts, forceRefresh: true),
                                      child: Row(
                                        children: [
                                          Icon(Icons.refresh_rounded, size: 14, color: context.accentLinkColor),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Refresh Rate',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: context.accentLinkColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              TextFormField(
                                controller: _rateController,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                onChanged: (_) {
                                  setState(() {
                                    final currentVal = num.tryParse(_rateController.text);
                                    if (_apiRate != null && currentVal != null && (currentVal - _apiRate!).abs() < 0.0001) {
                                      _isCustomRate = false;
                                    } else {
                                      _isCustomRate = true;
                                    }
                                  });
                                },
                                style: TextStyle(color: context.textPrimary, fontSize: 15, fontWeight: FontWeight.w700),
                                decoration: InputDecoration(
                                  hintText: '1.0',
                                  prefixText: '1 ${fromAcc.currency} = ',
                                  prefixStyle: TextStyle(color: context.textSecondary, fontSize: 14, fontWeight: FontWeight.w600),
                                  suffixText: toAcc.currency,
                                  suffixStyle: TextStyle(color: context.accentLinkColor, fontSize: 14, fontWeight: FontWeight.w700),
                                  filled: true,
                                  fillColor: context.inputBg,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: context.cardBorder),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: context.cardBorder),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: context.isDark ? AppColors.primary : const Color(0xFF15803D), width: 1.2),
                                  ),
                                ),
                              ),
                              if (_isCustomRate) ...[
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Custom rate applied',
                                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.orange),
                                    ),
                                    if (_apiRate != null)
                                      GestureDetector(
                                        onTap: _resetToApiRate,
                                        child: Row(
                                          children: [
                                            Icon(Icons.restore_rounded, size: 13, color: context.accentLinkColor),
                                            const SizedBox(width: 4),
                                            Text(
                                              'Reset to API (${_formatRate(_apiRate!)})',
                                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: context.accentLinkColor),
                                            ),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                              if (_rateError != null) ...[
                                const SizedBox(height: 6),
                                Text(_rateError!, style: const TextStyle(fontSize: 11, color: AppColors.red, fontWeight: FontWeight.w600)),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                      ],

                      // Transfer Amount
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Transfer Amount', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: context.textPrimary)),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _amountFromController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            inputFormatters: fromAcc?.currency == 'MYR'
                                ? [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))]
                                : [CurrencyInputFormatter()],
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: context.textPrimary),
                            decoration: InputDecoration(
                              hintText: '0',
                              prefixText: fromAcc?.currency == 'MYR' ? 'RM ' : 'Rp ',
                              prefixStyle: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: context.accentLinkColor),
                              hintStyle: TextStyle(color: context.textMuted, fontSize: 15),
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
                                borderSide: BorderSide(color: context.isDark ? AppColors.primary : const Color(0xFF15803D), width: 1.2),
                              ),
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty) ? 'Amount is required' : null,
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Real-time Estimated Destination Amount Preview
                      if (rawAmount > 0 && fromAcc != null && toAcc != null) ...[
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: context.isDark ? const Color(0xFF14161B) : context.inputBg,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isCrossCurrency
                                  ? (context.isDark ? AppColors.primary : const Color(0xFF15803D)).withValues(alpha: 0.25)
                                  : context.cardBorder,
                            ),
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Sender Deducted',
                                    style: TextStyle(fontSize: 12, color: context.textSecondary, fontWeight: FontWeight.w500),
                                  ),
                                  Text(
                                    '${fromAcc.currency == 'MYR' ? 'RM ' : 'Rp '}${_formatAmount(rawAmount, fromAcc.currency)}',
                                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: context.textPrimary),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Receiver Gets (Estimated)',
                                    style: TextStyle(fontSize: 12, color: context.textSecondary, fontWeight: FontWeight.w500),
                                  ),
                                  Text(
                                    '${toAcc.currency == 'MYR' ? 'RM ' : 'Rp '}${_formatAmount(estimatedAmountTo, toAcc.currency)}',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      color: context.isDark ? AppColors.greenLight : const Color(0xFF059669),
                                    ),
                                  ),
                                ],
                              ),
                            ],
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

              // Notes
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Notes (Optional)',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: context.textSecondary),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _notesController,
                    style: TextStyle(color: context.textPrimary, fontSize: 14, fontWeight: FontWeight.w600),
                    decoration: InputDecoration(
                      hintText: 'e.g., Transfer to savings, pocket money',
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
                        borderSide: const BorderSide(color: AppColors.primary, width: 1.2),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Receipt / Transfer Proof Attachment (Only visible if enabled in Settings)
              if (isOcrEnabled) ...[
                accountsAsync.when(
                  data: (accounts) => ReceiptAttachmentPicker(
                    stagedBytes: _stagedImageBytes,
                    stagedExtension: _stagedImageExtension,
                    existingUrl: _existingAttachmentUrl,
                    isExistingRemoved: _isExistingAttachmentRemoved,
                    isScanningOcr: _isScanningOcr,
                    isOcrEnabled: true,
                    onImageSelected: (bytes, ext, path) {
                      setState(() {
                        _stagedImageBytes = bytes;
                        _stagedImageExtension = ext;
                        _isExistingAttachmentRemoved = false;
                        _isScanningOcr = true;
                      });
                    },
                    onImageRemoved: () {
                      setState(() {
                        _stagedImageBytes = null;
                        _stagedImageExtension = null;
                        _isExistingAttachmentRemoved = true;
                        _isScanningOcr = false;
                      });
                    },
                    onOcrParsed: (ocr) => _handleOcrResult(ocr, accounts),
                  ),
                  loading: () => const SizedBox.shrink(),
                  error: (_, _) => const SizedBox.shrink(),
                ),
                const SizedBox(height: 6),
              ],
              const SizedBox(height: 22),

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
                        : Text(
                            isEditing ? 'Update Transfer' : 'Send Transfer',
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
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
