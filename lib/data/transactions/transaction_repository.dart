import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/config/supabase_client.dart';
import '../../domain/entities/transaction.dart';

class TransactionRepository {
  static const String _bucketName = 'receipts';

  Future<List<Transaction>> getAll() async {
    final rows = await supabase
        .from('transactions')
        .select()
        .order('transaction_date', ascending: false)
        .order('created_at', ascending: false);
    return rows.map((row) => Transaction.fromJson(row)).toList();
  }

  Future<List<Transaction>> getByAccount(String accountId) async {
    final rows = await supabase
        .from('transactions')
        .select()
        .eq('account_id', accountId)
        .order('transaction_date', ascending: false)
        .order('created_at', ascending: false);
    return rows.map((row) => Transaction.fromJson(row)).toList();
  }

  /// Upload receipt image binary data to Supabase Storage 'receipts' bucket.
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
    final filePath = '${user.id}/${timestamp}_$randomSuffix.$ext';

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

  /// Delete receipt image from Supabase Storage given its public URL or path.
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

  /// amount_idr TIDAK dikirim dari sini — sudah diisi otomatis oleh
  /// trigger `fill_amount_idr` di database (lihat db.sql).
  Future<void> create(Transaction transaction) async {
    await supabase.from('transactions').insert({
      'account_id': transaction.accountId,
      'category_id': transaction.categoryId,
      'type': transaction.type,
      'amount': transaction.amount,
      'description': transaction.description,
      'attachment_url': transaction.attachmentUrl,
      'transaction_date':
          transaction.transactionDate.toIso8601String().split('T').first,
    });
  }

  Future<void> update(Transaction transaction, {String? oldAttachmentUrl}) async {
    // If attachment was removed or changed, delete the old image
    if (oldAttachmentUrl != null &&
        oldAttachmentUrl != transaction.attachmentUrl) {
      await deleteReceiptImage(oldAttachmentUrl);
    }

    await supabase.from('transactions').update({
      'account_id': transaction.accountId,
      'category_id': transaction.categoryId,
      'type': transaction.type,
      'amount': transaction.amount,
      'description': transaction.description,
      'attachment_url': transaction.attachmentUrl,
      'transaction_date':
          transaction.transactionDate.toIso8601String().split('T').first,
    }).eq('id', transaction.id);
  }

  Future<void> delete(String transactionId, {String? attachmentUrl}) async {
    if (attachmentUrl != null && attachmentUrl.isNotEmpty) {
      await deleteReceiptImage(attachmentUrl);
    }
    await supabase.from('transactions').delete().eq('id', transactionId);
  }
}