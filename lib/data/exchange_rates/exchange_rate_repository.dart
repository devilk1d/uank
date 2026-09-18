// LOKASI: lib/data/exchange_rates/exchange_rate_repository.dart

import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../core/config/supabase_client.dart';
import '../../domain/entities/exchange_rate.dart';

class ExchangeRateRepository {
  static const _openErBaseUrl = 'https://open.er-api.com/v6/latest';

  /// Kurs terbaru untuk 1 pasangan mata uang, misal ('MYR', 'IDR').
  /// Mengambil dari cache database Supabase; jika belum ada atau sudah usang (> 12 jam),
  /// otomatis mengambil data live terbaru dari Open ExchangeRate API (open.er-api.com)
  /// dan menyimpannya kembali ke cache Supabase.
  Future<ExchangeRate?> getLatestRate(
    String fromCurrency,
    String toCurrency, {
    bool forceRefresh = false,
  }) async {
    if (fromCurrency == toCurrency) {
      return ExchangeRate(
        id: 'self',
        fromCurrency: fromCurrency,
        toCurrency: toCurrency,
        rate: 1.0,
        source: 'manual',
        fetchedAt: DateTime.now(),
      );
    }

    ExchangeRate? cachedRate;
    try {
      final rows = await supabase
          .from('exchange_rates')
          .select()
          .eq('from_currency', fromCurrency)
          .eq('to_currency', toCurrency)
          .order('fetched_at', ascending: false)
          .limit(1);

      if (rows.isNotEmpty) {
        cachedRate = ExchangeRate.fromJson(rows.first);
      }
    } catch (_) {
      // Supabase cache lookup failure, proceed to live fetch
    }

    final isExpired = cachedRate == null ||
        DateTime.now().difference(cachedRate.fetchedAt).inHours >= 12;

    if (!forceRefresh && cachedRate != null && !isExpired) {
      return cachedRate;
    }

    // Fetch live from open.er-api.com
    try {
      final freshRate = await _fetchFromApi(fromCurrency, toCurrency);
      if (freshRate != null) {
        // Save to Supabase cache asynchronously
        _saveToCache(freshRate);
        return freshRate;
      }
    } catch (_) {
      // Network fetch error, return existing cached rate if any
    }

    return cachedRate;
  }

  Future<ExchangeRate?> _fetchFromApi(String fromCurrency, String toCurrency) async {
    final uri = Uri.parse('$_openErBaseUrl/$fromCurrency');
    final response = await http.get(uri).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (data['result'] == 'success' && data['rates'] is Map) {
        final rates = data['rates'] as Map<String, dynamic>;
        final rateValue = rates[toCurrency];
        if (rateValue != null && rateValue is num) {
          return ExchangeRate(
            id: '',
            fromCurrency: fromCurrency,
            toCurrency: toCurrency,
            rate: rateValue,
            source: 'open_er',
            fetchedAt: DateTime.now(),
          );
        }
      }
    }
    return null;
  }

  Future<void> _saveToCache(ExchangeRate rate) async {
    try {
      await supabase.from('exchange_rates').insert({
        'from_currency': rate.fromCurrency,
        'to_currency': rate.toCurrency,
        'rate': rate.rate,
        'source': 'open_er',
        'fetched_at': rate.fetchedAt.toIso8601String(),
      });
    } catch (_) {
      // Ignore cache save error
    }
  }

  /// Helper langsung pakai di layar converter: hasil = amount * kurs terbaru.
  Future<num?> convert({
    required num amount,
    required String fromCurrency,
    required String toCurrency,
    bool forceRefresh = false,
  }) async {
    if (fromCurrency == toCurrency) return amount;

    final rate = await getLatestRate(fromCurrency, toCurrency, forceRefresh: forceRefresh);
    if (rate == null) return null;

    return amount * rate.rate;
  }
}