import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/seller_product_model.dart';
import '../providers/seller_session_provider.dart';

final sellerProductsProvider = FutureProvider<List<SellerProductModel>>((ref) {
  return ref.read(sellerServiceProvider).fetchMyProducts();
});
