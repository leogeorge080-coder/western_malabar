import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/admin_product_request_model.dart';
import '../services/admin_product_requests_service.dart';
import '../../seller_requests/models/duplicate_candidate_model.dart';

final adminProductRequestsServiceProvider =
    Provider<AdminProductRequestsService>((ref) {
  return AdminProductRequestsService(Supabase.instance.client);
});

final adminAuthUserIdProvider = Provider<String?>((ref) {
  return Supabase.instance.client.auth.currentUser?.id;
});

final adminPendingProductRequestsProvider =
    FutureProvider<List<AdminProductRequestModel>>((ref) async {
  final authUserId = ref.watch(adminAuthUserIdProvider);

  if (authUserId == null || authUserId.isEmpty) {
    return const <AdminProductRequestModel>[];
  }

  final service = ref.read(adminProductRequestsServiceProvider);
  return service.fetchPendingRequests();
});

final duplicateCandidatesProvider = FutureProvider.family
    .autoDispose<List<DuplicateCandidateModel>, String>((ref, requestId) async {
  final authUserId = ref.watch(adminAuthUserIdProvider);

  if (authUserId == null || authUserId.isEmpty) {
    return const <DuplicateCandidateModel>[];
  }

  return ref
      .read(adminProductRequestsServiceProvider)
      .fetchDuplicateCandidates(requestId);
});
