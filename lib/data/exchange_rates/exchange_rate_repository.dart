// LOKASI: lib/data/exchange_rates/exchange_rate_repository.dart
//
// Menangani cache kurs di tabel `exchange_rates`. Fetch dari API Wise/Flip
// yang sesungguhnya BELUM ada di sini — itu tugas Edge Function (server),
// bukan langsung dari app, supaya API key tidak tertanam di kode Flutter.
// Repository ini hanya membaca hasil cache yang sudah disimpan Edge Function.

import '../../core/config/supabase_client.dart';
import '../../domain/entities/exchange_rate.dart';

class ExchangeRateRepository {
  /// Kurs terbaru untuk 1 pasangan mata uang, misal ('MYR', 'IDR').
  /// Null kalau belum pernah ada data (misal Edge Function belum jalan sekali pun).
  Future<ExchangeRate?> getLatestRate(
      String fromCurrency,
      String toCurrency,
      ) async {
    final rows = await supabase
        .from('exchange_rates')
        .select()
        .eq('from_currency', fromCurrency)
        .eq('to_currency', toCurrency)
        .order('fetched_at', ascending: false)
        .limit(1);

    if (rows.isEmpty) return null;
    return ExchangeRate.fromJson(rows.first);
  }

  /// Helper langsung pakai di layar converter: hasil = amount * kurs terbaru.
  /// Return null kalau kursnya belum ada di cache.
  Future<num?> convert({
    required num amount,
    required String fromCurrency,
    required String toCurrency,
  }) async {
    if (fromCurrency == toCurrency) return amount;

    final rate = await getLatestRate(fromCurrency, toCurrency);
    if (rate == null) return null;

    return amount * rate.rate;
  }
}