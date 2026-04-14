import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/seller_barcode_lookup_service.dart';

class SellerBarcodeLookupState {
  final bool checking;
  final SellerBarcodeLookupResult? result;
  final String? error;
  final String checkedBarcode;

  const SellerBarcodeLookupState({
    this.checking = false,
    this.result,
    this.error,
    this.checkedBarcode = '',
  });

  SellerBarcodeLookupState copyWith({
    bool? checking,
    SellerBarcodeLookupResult? result,
    String? error,
    String? checkedBarcode,
    bool clearResult = false,
    bool clearError = false,
  }) {
    return SellerBarcodeLookupState(
      checking: checking ?? this.checking,
      result: clearResult ? null : (result ?? this.result),
      error: clearError ? null : (error ?? this.error),
      checkedBarcode: checkedBarcode ?? this.checkedBarcode,
    );
  }
}

class SellerBarcodeLookupNotifier
    extends StateNotifier<SellerBarcodeLookupState> {
  SellerBarcodeLookupNotifier(this._service)
      : super(const SellerBarcodeLookupState());

  final SellerBarcodeLookupService _service;

  Future<void> checkBarcode(String barcode) async {
    final clean = barcode.trim();

    if (clean.isEmpty) {
      state = state.copyWith(
        checkedBarcode: '',
        clearResult: true,
        clearError: true,
        checking: false,
      );
      return;
    }

    state = state.copyWith(
      checking: true,
      checkedBarcode: clean,
      clearError: true,
    );

    try {
      final result = await _service.findExistingByBarcode(clean);
      state = state.copyWith(
        checking: false,
        result: result,
      );
    } catch (e) {
      state = state.copyWith(
        checking: false,
        error: e.toString(),
        clearResult: true,
      );
    }
  }

  void clear() {
    state = const SellerBarcodeLookupState();
  }
}

final sellerBarcodeLookupServiceProvider =
    Provider<SellerBarcodeLookupService>((ref) {
  return SellerBarcodeLookupService(Supabase.instance.client);
});

final sellerBarcodeLookupProvider = StateNotifierProvider<
    SellerBarcodeLookupNotifier, SellerBarcodeLookupState>((ref) {
  return SellerBarcodeLookupNotifier(
    ref.read(sellerBarcodeLookupServiceProvider),
  );
});
