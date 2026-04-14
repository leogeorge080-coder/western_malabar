import 'dart:io';

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SellerRequestUploadService {
  final SupabaseClient supabase;

  SellerRequestUploadService(this.supabase);

  Future<String> uploadProductRequestImage(File file) async {
    final compressedFile = await _compressProductImage(file);

    final userId = supabase.auth.currentUser?.id;
    if (userId == null || userId.isEmpty) {
      throw Exception('User not signed in');
    }

    final fileName =
        'seller_request_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final storagePath = 'seller_requests/$userId/$fileName';

    await supabase.storage.from('product-images').upload(
          storagePath,
          compressedFile,
          fileOptions: const FileOptions(
            contentType: 'image/jpeg',
            upsert: false,
          ),
        );

    return supabase.storage.from('product-images').getPublicUrl(storagePath);
  }

  Future<File> _compressProductImage(File file) async {
    final tempDir = await getTemporaryDirectory();
    final targetPath = p.join(
      tempDir.path,
      'wm_seller_req_${DateTime.now().millisecondsSinceEpoch}.jpg',
    );

    final result = await FlutterImageCompress.compressAndGetFile(
      file.absolute.path,
      targetPath,
      quality: 72,
      minWidth: 1200,
      minHeight: 1200,
      format: CompressFormat.jpeg,
    );

    if (result == null) {
      return file;
    }

    return File(result.path);
  }
}
