import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

/// Centralized image upload helper for Aghinou ads.
///
/// Keeps Storage path generation and database insertion in one place so the
/// Add Ad screen can use the same behavior consistently.
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

    final urls = <String>[];
    final storage = client.storage.from(bucket);

    for (var i = 0; i < bytesList.length; i++) {
      final ext = _normalizeExtension(extensions[i]);
      final contentType = _contentType(ext);
      final path = '$userId/$adId/${DateTime.now().microsecondsSinceEpoch}_$i.$ext';

      await storage.uploadBinary(
        path,
        bytesList[i],
        fileOptions: FileOptions(contentType: contentType, upsert: false),
      );

      final url = storage.getPublicUrl(path);
      await client.from('ad_images').insert({
        'ad_id': adId,
        'image_url': url,
      });
      urls.add(url);
    }

    return urls;
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
