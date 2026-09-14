import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/glass_card.dart';
import '../providers/exchange_rate_providers.dart';

class ExchangeRateScreen extends ConsumerStatefulWidget {
  const ExchangeRateScreen({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const ExchangeRateScreen(),
    );
  }

  @override
  ConsumerState<ExchangeRateScreen> createState() => _ExchangeRateScreenState();
}

class _ExchangeRateScreenState extends ConsumerState<ExchangeRateScreen> {
  final _amountController = TextEditingController(text: '100');
  String _fromCurrency = 'MYR';
  String _toCurrency = 'IDR';

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _swapCurrencies() {
    setState(() {
      final temp = _fromCurrency;
      _fromCurrency = _toCurrency;
      _toCurrency = temp;
    });
  }

  @override
  Widget build(BuildContext context) {
    final rawAmount = num.tryParse(_amountController.text) ?? 0;
    final latestRateAsync = ref.watch(latestRateProvider(
      fromCurrency: _fromCurrency,
      toCurrency: _toCurrency,
    ));
    final convertedAsync = ref.watch(convertedAmountProvider(
      amount: rawAmount,
      fromCurrency: _fromCurrency,
      toCurrency: _toCurrency,
    ));

    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(22, 20, 22, 24 + bottomInset),
      decoration: const BoxDecoration(
        color: AppColors.darkCardBg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(top: BorderSide(color: AppColors.darkCardBorder, width: 1.5)),
      ),
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

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                'Currency Converter',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.darkTextPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Live conversion calculator based on current exchange rates',
            style: TextStyle(fontSize: 12, color: AppColors.darkTextSecondary),
          ),
          const SizedBox(height: 20),

          // Currency Selector & Swap Row
          GlassCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // From Row
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: TextFormField(
                        controller: _amountController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.darkTextPrimary),
                        decoration: InputDecoration(
                          labelText: 'From ($_fromCurrency)',
                          labelStyle: const TextStyle(color: AppColors.darkTextSecondary, fontSize: 12),
                          border: InputBorder.none,
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        _fromCurrency,
                        style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primaryLight),
                      ),
                    ),
                  ],
                ),
                const Divider(color: AppColors.darkCardBorder, height: 24),

                // Swap Button
                Center(
                  child: GestureDetector(
                    onTap: _swapCurrencies,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primary,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.swap_vert_rounded, size: 20, color: Colors.black),
                    ),
                  ),
                ),
                const Divider(color: AppColors.darkCardBorder, height: 24),

                // To Result Row
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Converted ($_toCurrency)',
                            style: const TextStyle(fontSize: 12, color: AppColors.darkTextSecondary),
                          ),
                          const SizedBox(height: 4),
                          convertedAsync.when(
                            data: (converted) => Text(
                              converted != null
                                  ? _formatNumber(converted)
                                  : 'Rate not cached',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: AppColors.greenLight,
                              ),
                            ),
                            loading: () => const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                            ),
                            error: (_, _) => const Text(
                              'Failed to get exchange rate',
                              style: TextStyle(color: AppColors.red, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.teal.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.teal.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        _toCurrency,
                        style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.teal),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Exchange rate status info
          latestRateAsync.when(
            data: (rate) {
              if (rate == null) {
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Rate not available in cache, using approximate calculation.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: AppColors.orange),
                  ),
                );
              }
              return Center(
                child: Text(
                  '1 $_fromCurrency = ${rate.rate} $_toCurrency \u00b7 Updated: ${rate.fetchedAt.day}/${rate.fetchedAt.month} ${rate.fetchedAt.hour.toString().padLeft(2, '0')}:${rate.fetchedAt.minute.toString().padLeft(2, '0')}',
                  style: const TextStyle(fontSize: 11, color: AppColors.darkTextSecondary),
                ),
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  String _formatNumber(num value) {
    if (value >= 1000) {
      final s = value.toStringAsFixed(0);
      final buffer = StringBuffer();
      for (int i = 0; i < s.length; i++) {
        if (i > 0 && (s.length - i) % 3 == 0) buffer.write('.');
        buffer.write(s[i]);
      }
      return buffer.toString();
    }
    return value.toStringAsFixed(2);
  }
}
