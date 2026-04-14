import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:western_malabar/features/checkout/models/address_model.dart';

class AddressService {
  final SupabaseClient _supabase = Supabase.instance.client;

  User? get _user => _supabase.auth.currentUser;

  Future<List<AddressModel>> fetchAddresses() async {
    final user = _user;
    if (user == null) return const [];

    final data = await _supabase
        .from('addresses')
        .select()
        .eq('user_id', user.id)
        .order('is_default', ascending: false)
        .order('created_at', ascending: false);

    return (data as List<dynamic>)
        .map((e) => AddressModel.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  Future<AddressModel?> fetchDefaultAddress() async {
    final user = _user;
    if (user == null) return null;

    final data = await _supabase
        .from('addresses')
        .select()
        .eq('user_id', user.id)
        .eq('is_default', true)
        .maybeSingle();

    if (data == null) return null;
    return AddressModel.fromMap(data);
  }

  Future<AddressModel> addAddress(AddressModel address) async {
    final user = _user;
    if (user == null) {
      throw Exception('User not signed in');
    }

    if (address.isDefault) {
      await _clearDefault(user.id);
    }

    final payload = {
      ...address.toInsertMap(),
      'user_id': user.id,
    };

    final inserted =
        await _supabase.from('addresses').insert(payload).select().single();

    await _refreshSavedAddressCount(user.id);

    return AddressModel.fromMap(inserted);
  }

  Future<AddressModel> updateAddress(AddressModel address) async {
    final user = _user;
    if (user == null) {
      throw Exception('User not signed in');
    }

    if (address.id.isEmpty) {
      throw Exception('Address id is missing');
    }

    if (address.isDefault) {
      await _clearDefault(user.id, exceptId: address.id);
    }

    final updated = await _supabase
        .from('addresses')
        .update({
          'label': address.label,
          'full_name': address.fullName,
          'phone': address.phone,
          'postcode': address.postcode,
          'address_line1': address.addressLine1,
          'address_line2': address.addressLine2,
          'city': address.city,
          'county': address.county,
          'delivery_note': address.deliveryNote,
          'is_default': address.isDefault,
          'latitude': address.latitude,
          'longitude': address.longitude,
        })
        .eq('id', address.id)
        .eq('user_id', user.id)
        .select()
        .single();

    return AddressModel.fromMap(updated);
  }

  Future<void> deleteAddress(String addressId) async {
    final user = _user;
    if (user == null) {
      throw Exception('User not signed in');
    }

    final existing = await _supabase
        .from('addresses')
        .select('id,is_default')
        .eq('id', addressId)
        .eq('user_id', user.id)
        .maybeSingle();

    if (existing == null) {
      return;
    }

    final wasDefault = existing['is_default'] == true;

    await _supabase
        .from('addresses')
        .delete()
        .eq('id', addressId)
        .eq('user_id', user.id);

    if (wasDefault) {
      final next = await _supabase
          .from('addresses')
          .select('id')
          .eq('user_id', user.id)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (next != null) {
        final nextId = next['id'] as String?;
        if (nextId != null && nextId.isNotEmpty) {
          await _supabase
              .from('addresses')
              .update({'is_default': true})
              .eq('id', nextId)
              .eq('user_id', user.id);
        }
      }
    }

    await _refreshSavedAddressCount(user.id);
  }

  Future<void> setDefaultAddress(String addressId) async {
    final user = _user;
    if (user == null) {
      throw Exception('User not signed in');
    }

    await _clearDefault(user.id, exceptId: addressId);

    await _supabase
        .from('addresses')
        .update({'is_default': true})
        .eq('id', addressId)
        .eq('user_id', user.id);
  }

  Future<AddressModel?> saveAddressFromCheckout({
    required String fullName,
    required String phone,
    required String postcode,
    required String addressLine1,
    required String addressLine2,
    required String city,
    String? county,
    String? label,
    String? deliveryNote,
    double? latitude,
    double? longitude,
  }) async {
    final user = _user;
    if (user == null) {
      return null;
    }

    final cleanPostcode = postcode.trim().toUpperCase();
    final cleanAddressLine1 = addressLine1.trim();
    final cleanAddressLine2 = addressLine2.trim();
    final cleanCity = city.trim();

    if (cleanPostcode.isEmpty ||
        cleanAddressLine1.isEmpty ||
        cleanCity.isEmpty ||
        fullName.trim().isEmpty ||
        phone.trim().isEmpty) {
      return null;
    }

    final existingRows = await _supabase
        .from('addresses')
        .select()
        .eq('user_id', user.id)
        .eq('postcode', cleanPostcode)
        .eq('address_line1', cleanAddressLine1);

    final existingList = existingRows as List<dynamic>;
    if (existingList.isNotEmpty) {
      final first = existingList.first as Map<String, dynamic>;
      return AddressModel.fromMap(first);
    }

    final currentRows = await _supabase
        .from('addresses')
        .select('id')
        .eq('user_id', user.id)
        .limit(1);

    final isFirstAddress = (currentRows as List).isEmpty;

    final address = AddressModel(
      id: '',
      userId: user.id,
      label: (label == null || label.trim().isEmpty) ? 'Home' : label.trim(),
      fullName: fullName.trim(),
      phone: phone.trim(),
      postcode: cleanPostcode,
      addressLine1: cleanAddressLine1,
      addressLine2: cleanAddressLine2,
      city: cleanCity,
      county: county?.trim(),
      deliveryNote: deliveryNote?.trim(),
      isDefault: isFirstAddress,
      latitude: latitude,
      longitude: longitude,
    );

    return addAddress(address);
  }

  Future<void> _clearDefault(String userId, {String? exceptId}) async {
    var query = _supabase
        .from('addresses')
        .update({'is_default': false})
        .eq('user_id', userId)
        .eq('is_default', true);

    if (exceptId != null && exceptId.isNotEmpty) {
      query = query.neq('id', exceptId);
    }

    await query;
  }

  Future<void> _refreshSavedAddressCount(String userId) async {
    final rows =
        await _supabase.from('addresses').select('id').eq('user_id', userId);

    final count = (rows as List).length;

    await _supabase.from('profiles').update({
      'saved_addresses': count,
    }).eq('id', userId);
  }
}
