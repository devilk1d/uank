import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/config/supabase_client.dart';

const String _kReceiptOcrEnabledKey = 'uank_enable_receipt_ocr';

class ReceiptOcrSettingNotifier extends Notifier<bool> {
  @override
  bool build() {
    _loadFromStorage();
    return true; // Default to true
  }

  Future<void> _loadFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final localVal = prefs.getBool(_kReceiptOcrEnabledKey);
      if (localVal != null) {
        state = localVal;
        return;
      }

      final user = supabase.auth.currentUser;
      final cloudVal = user?.userMetadata?['enable_receipt_ocr'];
      if (cloudVal is bool) {
        state = cloudVal;
        await prefs.setBool(_kReceiptOcrEnabledKey, cloudVal);
      }
    } catch (_) {}
  }

  Future<void> toggle() async {
    final next = !state;
    state = next;
    await _persist(next);
  }

  Future<void> setEnabled(bool value) async {
    if (state == value) return;
    state = value;
    await _persist(value);
  }

  Future<void> _persist(bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kReceiptOcrEnabledKey, value);
    } catch (_) {}

    try {
      if (supabase.auth.currentUser != null) {
        await supabase.auth.updateUser(
          UserAttributes(
            data: {'enable_receipt_ocr': value},
          ),
        );
      }
    } catch (_) {}
  }
}

final receiptOcrSettingProvider =
    NotifierProvider<ReceiptOcrSettingNotifier, bool>(
  ReceiptOcrSettingNotifier.new,
);
