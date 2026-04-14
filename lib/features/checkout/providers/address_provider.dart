import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:western_malabar/features/checkout/models/address_model.dart';
import 'package:western_malabar/features/checkout/services/address_service.dart';

final addressServiceProvider = Provider<AddressService>((ref) {
  return AddressService();
});

final addressesProvider =
    FutureProvider.autoDispose<List<AddressModel>>((ref) async {
  final service = ref.read(addressServiceProvider);
  return service.fetchAddresses();
});

final defaultAddressProvider =
    FutureProvider.autoDispose<AddressModel?>((ref) async {
  final service = ref.read(addressServiceProvider);
  return service.fetchDefaultAddress();
});
