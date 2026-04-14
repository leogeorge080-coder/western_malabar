import 'package:supabase_flutter/supabase_flutter.dart';

class SellerBarcodeLookupResult {
  final bool exists;
  final String? productId;
  final String? productName;
  final String? productSlug;
  final String? barcode;

  const SellerBarcodeLookupResult({
    required this.exists,
    this.productId,
    this.productName,
    this.productSlug,
    this.barcode,
  });

  factory SellerBarcodeLookupResult.notFound() {
    return const SellerBarcodeLookupResult(exists: false);
  }

  factory SellerBarcodeLookupResult.fromMap(Map<String, dynamic> map) {
    return SellerBarcodeLookupResult(
      exists: true,
      productId: map['id'] as String?,
      productName: map['name'] as String?,
      productSlug: map['slug'] as String?,
      barcode: map['barcode'] as String?,
    );
  }
}

class SellerBarcodeLookupService {
  SellerBarcodeLookupService(this._supabase);

  final SupabaseClient _supabase;

  Future<SellerBarcodeLookupResult> findExistingByBarcode(
      String barcode) async {
    final clean = barcode.trim();
    if (clean.isEmpty) return SellerBarcodeLookupResult.notFound();

    final rows = await _supabase
        .from('products')
        .select('id, name, slug, barcode')
        .eq('barcode', clean)
        .limit(1);

    if (rows is List && rows.isNotEmpty) {
      return SellerBarcodeLookupResult.fromMap(
        Map<String, dynamic>.from(rows.first as Map),
      );
    }

    return SellerBarcodeLookupResult.notFound();
  }
}
