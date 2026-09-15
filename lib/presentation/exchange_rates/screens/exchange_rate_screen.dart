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
      decoration: const BoxDecoration(
        color: AppColors.darkCardBg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(
          top: BorderSide(color: AppColors.darkCardBorder, width: 1.5),
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
                color: AppColors.darkTextMuted,
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
                  color: AppColors.primary.withValues(alpha: 0.15),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                ),
                child: const Icon(Icons.currency_exchange_rounded, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Currency Converter',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppColors.darkTextPrimary,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Real-time conversion calculator',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.darkTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh_rounded, color: AppColors.primaryLight, size: 20),
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
                icon: const Icon(Icons.close_rounded, color: AppColors.darkTextSecondary, size: 22),
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
                      color: const Color(0xFF181A20),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.darkCardBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'You Send',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.darkTextSecondary,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                              ),
                              child: Text(
                                _fromCurrency,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                  color: AppColors.primaryLight,
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
                            cursorColor: AppColors.primary,
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              color: AppColors.darkTextPrimary,
                              letterSpacing: -0.5,
                            ),
                            decoration: const InputDecoration(
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
                                color: AppColors.darkTextMuted,
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
                      color: const Color(0xFF181A20),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.darkCardBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'You Get (Estimated)',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.darkTextSecondary,
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
                              style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                                color: AppColors.greenLight,
                                letterSpacing: -0.5,
                              ),
                            ),
                            loading: () => const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: AppColors.primary,
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
                    border: Border.all(color: AppColors.darkCardBg, width: 3),
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
              final sourceLabel = rate.source == 'open_er' ? 'ExchangeRate-API' : rate.source.toUpperCase();
              final isIdr = _fromCurrency == 'IDR';
              final baseUnit = isIdr ? '1.000' : '1';
              final rateValue = isIdr ? rate.rate * 1000 : rate.rate;
              final rateFormatted = _formatRate(rateValue);

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                decoration: BoxDecoration(
                  color: const Color(0xFF14161B),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.darkCardBorder),
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
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.darkTextPrimary,
                        ),
                      ),
                    ),
                    Text(
                      sourceLabel,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: AppColors.darkTextMuted,
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
