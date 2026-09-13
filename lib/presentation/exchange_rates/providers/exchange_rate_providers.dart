// LOKASI: lib/presentation/exchange_rates/providers/exchange_rate_providers.dart

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../domain/entities/exchange_rate.dart';
import '../../repository_providers.dart';

part 'exchange_rate_providers.g.dart';

@riverpod
Future<ExchangeRate?> latestRate(
  Ref ref, {
  required String fromCurrency,
  required String toCurrency,
}) {
  final repo = ref.watch(exchangeRateRepositoryProvider);
  return repo.getLatestRate(fromCurrency, toCurrency);
}

/// Dipakai langsung di layar converter mata uang.
@riverpod
Future<num?> convertedAmount(
  Ref ref, {
  required num amount,
  required String fromCurrency,
  required String toCurrency,
}) {
  final repo = ref.watch(exchangeRateRepositoryProvider);
  return repo.convert(
    amount: amount,
    fromCurrency: fromCurrency,
    toCurrency: toCurrency,
  );
}
