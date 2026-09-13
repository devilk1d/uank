// LOKASI: lib/data/device_tokens/device_token_repository.dart
//
// Menyimpan token FCM device ini ke database, supaya Edge Function bisa
// tahu ke mana push notification harus dikirim untuk user yang bersangkutan.

import '../../core/config/supabase_client.dart';

class DeviceTokenRepository {
  /// Dipanggil sekali setiap kali app start & user sudah login, atau setiap
  /// kali Firebase memberi token baru (token bisa berubah sewaktu-waktu).
  /// upsert supaya token yang sama tidak dobel kalau dipanggil berkali-kali.
  Future<void> registerToken({
    required String fcmToken,
    required String platform,
  }) async {
    await supabase.from('device_tokens').upsert({
      'fcm_token': fcmToken,
      'platform': platform,
    }, onConflict: 'fcm_token');
  }

  /// Dipanggil saat user logout, supaya device ini berhenti menerima
  /// notifikasi milik akun yang baru saja logout.
  Future<void> removeToken(String fcmToken) async {
    await supabase.from('device_tokens').delete().eq('fcm_token', fcmToken);
  }
}