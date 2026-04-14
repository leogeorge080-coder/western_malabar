import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/seller_request_upload_service.dart';

class SellerRequestUploadState {
  final bool uploading;
  final String? imageUrl;
  final String? error;

  const SellerRequestUploadState({
    this.uploading = false,
    this.imageUrl,
    this.error,
  });

  SellerRequestUploadState copyWith({
    bool? uploading,
    String? imageUrl,
    String? error,
    bool clearImageUrl = false,
    bool clearError = false,
  }) {
    return SellerRequestUploadState(
      uploading: uploading ?? this.uploading,
      imageUrl: clearImageUrl ? null : (imageUrl ?? this.imageUrl),
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class SellerRequestUploadNotifier
    extends StateNotifier<SellerRequestUploadState> {
  SellerRequestUploadNotifier(this._service)
      : super(const SellerRequestUploadState());

  final SellerRequestUploadService _service;

  Future<void> uploadFile(File file) async {
    state = state.copyWith(
      uploading: true,
      clearError: true,
    );

    try {
      final url = await _service.uploadProductRequestImage(file);
      state = state.copyWith(
        uploading: false,
        imageUrl: url,
      );
    } catch (e) {
      state = state.copyWith(
        uploading: false,
        error: e.toString(),
      );
    }
  }

  void clearImage() {
    state = state.copyWith(
      clearImageUrl: true,
      clearError: true,
    );
  }
}

final sellerRequestUploadServiceProvider =
    Provider<SellerRequestUploadService>((ref) {
  return SellerRequestUploadService(Supabase.instance.client);
});

final sellerRequestUploadProvider = StateNotifierProvider<
    SellerRequestUploadNotifier, SellerRequestUploadState>((ref) {
  return SellerRequestUploadNotifier(
    ref.read(sellerRequestUploadServiceProvider),
  );
});
