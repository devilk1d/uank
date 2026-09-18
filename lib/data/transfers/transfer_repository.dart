import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/config/supabase_client.dart';
import '../../domain/entities/transfer.dart';

class TransferRepository {
  static const String _bucketName = 'receipts';

  Future<List<Transfer>> getAll() async {
    final rows = await supabase
        .from('transfers')
        .select()
        .order('transfer_date', ascending: false)
        .order('created_at', ascending: false);
    return rows.map((row) => Transfer.fromJson(row)).toList();
  }

  /// Upload transfer receipt / proof image binary data to Supabase Storage 'receipts' bucket.
  /// Returns the public URL of the uploaded image.
  Future<String> uploadReceiptImage({
    required Uint8List bytes,
    required String fileExtension,
  }) async {
    final user = supabase.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final ext = fileExtension.replaceAll('.', '').toLowerCase();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final randomSuffix = (timestamp % 10000).toString().padLeft(4, '0');
    final filePath = '${user.id}/transfer_${timestamp}_$randomSuffix.$ext';

    String mimeType = 'image/jpeg';
    if (ext == 'png') {
      mimeType = 'image/png';
    } else if (ext == 'webp') {
      mimeType = 'image/webp';
    } else if (ext == 'heic') {
      mimeType = 'image/heic';
    }

    await supabase.storage.from(_bucketName).uploadBinary(
          filePath,
          bytes,
          fileOptions: FileOptions(contentType: mimeType, upsert: true),
        );

    return supabase.storage.from(_bucketName).getPublicUrl(filePath);
  }

  /// Delete transfer receipt image from Supabase Storage given its public URL or path.
  Future<void> deleteReceiptImage(String? imageUrl) async {
    if (imageUrl == null || imageUrl.isEmpty) return;
    try {
      final path = _extractStoragePath(imageUrl, _bucketName);
      if (path != null && path.isNotEmpty) {
        await supabase.storage.from(_bucketName).remove([path]);
      }
    } catch (_) {
      // Ignored if file doesn't exist or already removed
    }
  }

  String? _extractStoragePath(String url, String bucket) {
    if (!url.startsWith('http')) return url;
    final marker = '/$bucket/';
    final idx = url.indexOf(marker);
    if (idx != -1) {
      return url.substring(idx + marker.length).split('?').first;
    }
    return null;
  }

  Future<void> create(Transfer transfer) async {
    await supabase.from('transfers').insert({
      'from_account_id': transfer.fromAccountId,
      'to_account_id': transfer.toAccountId,
      'amount_from': transfer.amountFrom,
      'amount_to': transfer.amountTo,
      'exchange_rate': transfer.exchangeRate,
      'transfer_date': transfer.transferDate.toIso8601String().split('T').first,
      'notes': transfer.notes,
      'attachment_url': transfer.attachmentUrl,
    });
  }

  Future<void> update(Transfer transfer, {String? oldAttachmentUrl}) async {
    if (oldAttachmentUrl != null &&
        oldAttachmentUrl != transfer.attachmentUrl) {
      await deleteReceiptImage(oldAttachmentUrl);
    }

    await supabase.from('transfers').update({
      'from_account_id': transfer.fromAccountId,
      'to_account_id': transfer.toAccountId,
      'amount_from': transfer.amountFrom,
      'amount_to': transfer.amountTo,
      'exchange_rate': transfer.exchangeRate,
      'transfer_date': transfer.transferDate.toIso8601String().split('T').first,
      'notes': transfer.notes,
      'attachment_url': transfer.attachmentUrl,
    }).eq('id', transfer.id);
  }

  Future<void> delete(String id, {String? attachmentUrl}) async {
    if (attachmentUrl != null && attachmentUrl.isNotEmpty) {
      await deleteReceiptImage(attachmentUrl);
    }
    await supabase.from('transfers').delete().eq('id', id);
  }
}