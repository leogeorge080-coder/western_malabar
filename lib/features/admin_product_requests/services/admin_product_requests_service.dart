import 'package:supabase_flutter/supabase_flutter.dart';
import '../../seller_requests/models/duplicate_candidate_model.dart';
import '../models/admin_product_request_model.dart';

class AdminProductRequestsService {
  AdminProductRequestsService(this._supabase);

  final SupabaseClient _supabase;

  Future<List<AdminProductRequestModel>> fetchPendingRequests() async {
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
          reviewed_at,
          seller_profile:profiles!seller_id(
            full_name,
            email
          )
        ''').eq('status', 'pending').order('created_at', ascending: false);

    return (rows as List)
        .map((e) => AdminProductRequestModel.fromMap(
              Map<String, dynamic>.from(e as Map),
            ))
        .toList();
  }

  Future<List<DuplicateCandidateModel>> fetchDuplicateCandidates(
      String requestId) async {
    final rows = await _supabase.rpc(
      'get_seller_request_duplicate_candidates',
      params: {'_request_id': requestId},
    );

    return (rows as List)
        .map((e) => DuplicateCandidateModel.fromMap(
              Map<String, dynamic>.from(e as Map),
            ))
        .toList();
  }

  Future<void> approveAsNew({
    required String requestId,
    required String finalName,
    required String finalSlug,
    String? finalCategoryId,
    String? finalBrandId,
    required int variantPriceCents,
    int? variantSalePriceCents,
    String? variantSku,
  }) async {
    await _supabase.rpc(
      'admin_approve_seller_product_request',
      params: {
        '_request_id': requestId,
        '_final_name': finalName,
        '_final_slug': finalSlug,
        '_final_category_id': finalCategoryId,
        '_final_brand_id': finalBrandId,
        '_variant_price_cents': variantPriceCents,
        '_variant_sale_price_cents': variantSalePriceCents,
        '_variant_sku': variantSku,
      },
    );
  }

  Future<void> mergeIntoExisting({
    required String requestId,
    required String existingProductId,
    String? adminNote,
  }) async {
    await _supabase.rpc(
      'admin_merge_seller_product_request_into_existing',
      params: {
        '_request_id': requestId,
        '_existing_product_id': existingProductId,
        '_admin_note': adminNote,
      },
    );
  }

  Future<void> reject({
    required String requestId,
    required String adminNote,
  }) async {
    await _supabase.rpc(
      'admin_reject_seller_product_request',
      params: {
        '_request_id': requestId,
        '_admin_note': adminNote,
      },
    );
  }
}
