import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/seller_session_model.dart';
import '../services/seller_service.dart';

final sellerServiceProvider = Provider<SellerService>((ref) {
  return SellerService(Supabase.instance.client);
});

final sellerSessionProvider = FutureProvider<SellerSessionModel>((ref) async {
  return ref.read(sellerServiceProvider).getSellerSession();
});
