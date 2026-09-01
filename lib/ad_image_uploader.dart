import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

/// Centralized image upload helper for Aghinou ads.
class AdImageUploader {
  const AdImageUploader({required this.client, required this.bucket});

  final SupabaseClient client;
  final String bucket;

  Future<List<String>> upload({
    required String adId,
    required String userId,
    required List<Uint8List> bytesList,
    required List<String> extensions,
  }) async {
    if (bytesList.isEmpty) return <String>[];
    if (bytesList.length != extensions.length) {
      throw ArgumentError('تعداد فایل‌ها و پسوندها یکسان نیست.');
    }

    final storage = client.storage.from(bucket);
    final uploadedPaths = <String>[];
    final urls = <String>[];

    try {
      for (var i = 0; i < bytesList.length; i++) {
        final ext = _normalizeExtension(extensions[i]);
        final contentType = _contentType(ext);
        final path = '$userId/$adId/${DateTime.now().microsecondsSinceEpoch}_$i.$ext';

        await storage.uploadBinary(
          path,
          bytesList[i],
          fileOptions: FileOptions(contentType: contentType, upsert: false),
        );
        uploadedPaths.add(path);

        final url = storage.getPublicUrl(path);
        await client.from('ad_images').insert({
          'ad_id': adId,
          'image_url': url,
        });
        urls.add(url);
      }

      return urls;
    } catch (error) {
      // Best-effort cleanup prevents orphaned Storage objects when a later
      // image or its database record fails.
      if (uploadedPaths.isNotEmpty) {
        try {
          await storage.remove(uploadedPaths);
        } catch (_) {
          // Preserve the original upload/database error.
        }
      }
      rethrow;
    }
  }

  String _normalizeExtension(String value) {
    final ext = value.toLowerCase().replaceFirst('.', '');
    switch (ext) {
      case 'png':
      case 'webp':
      case 'jpg':
      case 'jpeg':
        return ext == 'jpeg' ? 'jpg' : ext;
      default:
        return 'jpg';
    }
  }

  String _contentType(String ext) {
    switch (ext) {
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      default:
        return 'image/jpeg';
    }
  }
}
