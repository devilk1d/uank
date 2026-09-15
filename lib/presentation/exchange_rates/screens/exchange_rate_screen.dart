import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
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
    final rawAmount = CurrencyInputFormatter.parse(_amountController.text);
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
      padding: EdgeInsets.fromLTRB(20, 16, 20, 24 + bottomInset),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(
          top: BorderSide(color: context.cardBorder, width: 1.5),
        ),
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
                color: context.textMuted.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: (context.isDark ? AppColors.primary : const Color(0xFF0D9488)).withValues(alpha: 0.15),
                  border: Border.all(color: (context.isDark ? AppColors.primary : const Color(0xFF0D9488)).withValues(alpha: 0.3)),
                ),
                child: Icon(Icons.currency_exchange_rounded, color: context.isDark ? AppColors.primary : const Color(0xFF0D9488), size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Currency Converter',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: context.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Real-time conversion calculator',
                      style: TextStyle(
                        fontSize: 12,
                        color: context.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.refresh_rounded, color: context.textSecondary, size: 20),
                tooltip: 'Refresh Rate',
                onPressed: () {
                  ref.invalidate(latestRateProvider(fromCurrency: _fromCurrency, toCurrency: _toCurrency));
                  ref.invalidate(convertedAmountProvider(
                    amount: rawAmount,
                    fromCurrency: _fromCurrency,
                    toCurrency: _toCurrency,
                  ));
                },
              ),
              IconButton(
                icon: Icon(Icons.close_rounded, color: context.textSecondary, size: 22),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Unified Conversion Card Section
          Stack(
            alignment: Alignment.center,
            children: [
              Column(
                children: [
                  // FROM CARD
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: context.inputBg,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: context.cardBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'You Send',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: context.textSecondary,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: (context.isDark ? AppColors.primary : const Color(0xFF15803D)).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: (context.isDark ? AppColors.primary : const Color(0xFF15803D)).withValues(alpha: 0.3)),
                              ),
                              child: Text(
                                _fromCurrency,
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                  color: context.isDark ? AppColors.primaryLight : const Color(0xFF15803D),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          height: 36,
                          child: TextFormField(
                            controller: _amountController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [CurrencyInputFormatter()],
                            cursorColor: context.isDark ? AppColors.primary : const Color(0xFF15803D),
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              color: context.textPrimary,
                              letterSpacing: -0.5,
                            ),
                            decoration: InputDecoration(
                              isDense: true,
                              filled: false,
                              fillColor: Colors.transparent,
                              contentPadding: EdgeInsets.zero,
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              errorBorder: InputBorder.none,
                              disabledBorder: InputBorder.none,
                              hintText: '0',
                              hintStyle: TextStyle(
                                color: context.textMuted,
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // TO CARD
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: context.inputBg,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: context.cardBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'You Get (Estimated)',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: context.textSecondary,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.teal.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppColors.teal.withValues(alpha: 0.3)),
                              ),
                              child: Text(
                                _toCurrency,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                  color: AppColors.teal,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Container(
                          height: 36,
                          alignment: Alignment.centerLeft,
                          child: convertedAsync.when(
                            data: (converted) => Text(
                              converted != null
                                  ? _formatNumber(converted)
                                  : 'Rate unavailable',
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                                color: context.isDark ? AppColors.greenLight : const Color(0xFF059669),
                                letterSpacing: -0.5,
                              ),
                            ),
                            loading: () => SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: context.isDark ? AppColors.primary : const Color(0xFF15803D),
                              ),
                            ),
                            error: (_, _) => const Text(
                              'Failed to load rate',
                              style: TextStyle(
                                color: AppColors.red,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // Floating Swap Button
              GestureDetector(
                onTap: _swapCurrencies,
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary,
                    border: Border.all(color: context.cardBg, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.swap_vert_rounded,
                    size: 20,
                    color: Colors.black,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Exchange Rate Live Info Pill
          latestRateAsync.when(
            data: (rate) {
              if (rate == null) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.orange.withValues(alpha: 0.2)),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.info_outline_rounded, color: AppColors.orange, size: 16),
                      SizedBox(width: 8),
                      Text(
                        'Rate not available in cache',
                        style: TextStyle(fontSize: 12, color: AppColors.orange, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                );
              }
              final isIdr = _fromCurrency == 'IDR';
              final baseUnit = isIdr ? '1.000' : '1';
              final rateValue = isIdr ? rate.rate * 1000 : rate.rate;
              final rateFormatted = _formatRate(rateValue);

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                decoration: BoxDecoration(
                  color: context.inputBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: context.cardBorder),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.green,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '$baseUnit $_fromCurrency = $rateFormatted $_toCurrency',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: context.textPrimary,
                        ),
                      ),
                    ),
                  ],
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

  String _formatRate(num rate) {
    if (rate >= 100) {
      return _formatNumber(rate);
    } else if (rate >= 1) {
      return rate % 1 == 0
          ? rate.toStringAsFixed(0)
          : rate.toStringAsFixed(4).replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
    } else {
      final s = rate.toStringAsFixed(4).replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
      return s.isEmpty ? '0' : s;
    }
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
