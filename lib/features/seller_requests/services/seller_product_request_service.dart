import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:western_malabar/features/seller_requests/models/seller_product_request_model.dart';

class SellerProductRequestService {
  SellerProductRequestService(this._supabase);

  final SupabaseClient _supabase;

  Future<List<SellerProductRequestModel>> fetchMyRequests() async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('Not signed in');

    final rows = await _supabase.from('seller_product_requests').select('''
          id,
          seller_id,
          product_name,
          normalized_name,
          slug,
          category_id,
          brand_id,
          description,
          barcode,
          requested_images,
          requested_image_url,
          requested_price_cents,
          status,
          duplicate_status,
          duplicate_confidence,
          suggested_product_id,
          issue_flags,
          review_summary,
          admin_note,
          created_at,
          reviewed_at
        ''').eq('seller_id', user.id).order('created_at', ascending: false);

    return (rows as List)
        .map((e) => SellerProductRequestModel.fromMap(
              Map<String, dynamic>.from(e as Map),
            ))
        .toList();
  }

  Future<void> submitRequest({
    required String productName,
    String? slug,
    String? categoryId,
    String? brandId,
    String? description,
    String? barcode,
    List<String> requestedImages = const [],
    String? requestedImageUrl,
    required int requestedPriceCents,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('Not signed in');

    final cleanedImages = [
      ...requestedImages,
      if ((requestedImageUrl ?? '').trim().isNotEmpty)
        requestedImageUrl!.trim(),
    ].map((e) => e.trim()).where((e) => e.isNotEmpty).take(2).toList();

    await _supabase.from('seller_product_requests').insert({
      'seller_id': user.id,
      'product_name': productName.trim(),
      'normalized_name': productName.trim().toLowerCase(),
      'slug': (slug ?? '').trim().isEmpty ? null : slug!.trim(),
      'category_id': categoryId,
      'brand_id': brandId,
      'barcode': barcode?.trim().isEmpty == true ? null : barcode?.trim(),
      'requested_price_cents': requestedPriceCents,
      'description':
          description?.trim().isEmpty == true ? null : description?.trim(),
      'requested_images': cleanedImages,
      'requested_image_url':
          cleanedImages.isNotEmpty ? cleanedImages.first : null,
      'status': 'pending',
      'duplicate_status': 'unchecked',
      'duplicate_confidence': 0,
      'issue_flags': const <String>[],
    });
  }
}
