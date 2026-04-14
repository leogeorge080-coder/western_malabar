import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/seller_product_model.dart';
import '../models/seller_session_model.dart';

class SellerService {
  SellerService(this._supabase);

  final SupabaseClient _supabase;

  User? get currentUser => _supabase.auth.currentUser;

  Future<SellerSessionModel> getSellerSession() async {
    final user = currentUser;
    if (user == null) {
      return const SellerSessionModel.loggedOut();
    }

    final row = await _supabase
        .from('seller_permissions')
        .select('user_id, is_active')
        .eq('user_id', user.id)
        .maybeSingle();

    if (row == null) {
      return SellerSessionModel.noSellerAccess(userId: user.id);
    }

    return SellerSessionModel.seller(
      userId: user.id,
      isActive: row['is_active'] == true,
    );
  }

  Future<List<SellerProductModel>> fetchMyProducts() async {
    final user = currentUser;
    if (user == null) {
      throw Exception('Not signed in');
    }

    final rows = await _supabase.from('products').select('''
          id,
          seller_id,
          name,
          slug,
          barcode,
          images,
          is_available,
          available_qty,
          seller_notes,
          price_change_locked,
          product_variants (
            id,
            sku,
            price_cents,
            sale_price_cents,
            stock_qty
          )
        ''').eq('seller_id', user.id).order('name');

    return (rows as List)
        .map((e) => SellerProductModel.fromMap(
              Map<String, dynamic>.from(e as Map),
            ))
        .toList();
  }

  Future<void> updateProductOps({
    required String productId,
    required bool isAvailable,
    required int availableQty,
    String? sellerNotes,
  }) async {
    await _supabase.rpc(
      'seller_update_product_ops',
      params: {
        '_product_id': productId,
        '_is_available': isAvailable,
        '_available_qty': availableQty,
        '_seller_notes': sellerNotes,
      },
    );
  }

  Future<void> requestPriceChange({
    required String productId,
    required String variantId,
    required int requestedPriceCents,
    String? sellerReason,
  }) async {
    await _supabase.rpc(
      'seller_request_price_change',
      params: {
        '_product_id': productId,
        '_variant_id': variantId,
        '_requested_price_cents': requestedPriceCents,
        '_seller_reason': sellerReason,
      },
    );
  }
}
