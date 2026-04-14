import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:western_malabar/features/seller_requests/models/seller_product_request_model.dart';
import 'package:western_malabar/features/seller_requests/services/seller_product_request_service.dart';

final sellerProductRequestServiceProvider =
    Provider<SellerProductRequestService>((ref) {
  return SellerProductRequestService(Supabase.instance.client);
});

final sellerProductRequestsProvider =
    FutureProvider<List<SellerProductRequestModel>>((ref) {
  return ref.read(sellerProductRequestServiceProvider).fetchMyRequests();
});
