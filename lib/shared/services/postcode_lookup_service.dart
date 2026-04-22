import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:western_malabar/app/env.dart';

class AddressLookupItem {
  final String id;
  final String rawAddress;
  final String line1;
  final String line2;
  final String city;
  final String postcode;

  const AddressLookupItem({
    required this.id,
    required this.rawAddress,
    required this.line1,
    required this.line2,
    required this.city,
    required this.postcode,
  });

  String get displayText {
    final parts = [
      if (line1.trim().isNotEmpty) line1.trim(),
      if (line2.trim().isNotEmpty) line2.trim(),
      if (city.trim().isNotEmpty) city.trim(),
      if (postcode.trim().isNotEmpty) postcode.trim(),
    ];
    return parts.join(', ');
  }
}

class PostcodeLookupService {
  static String get apiKey => Env.postcodeApiKey.trim();

  static const List<String> deliveryAreas = ['DN', 'S', 'HU'];

  static bool isDeliveryArea(String postcode) {
    final cleaned = _compactPostcode(postcode);
    return deliveryAreas.any((prefix) => cleaned.startsWith(prefix));
  }

  static String availabilityMessage(String postcode) {
    final pretty = _prettyPostcode(postcode);
    if (isDeliveryArea(postcode)) {
      return 'We deliver to $pretty • Earliest slot: Tomorrow • 6 PM - 8 PM';
    }
    return 'Sorry, we do not deliver to $pretty yet';
  }

  static String _compactPostcode(String input) {
    return input.replaceAll(RegExp(r'\s+'), '').toUpperCase().trim();
  }

  static String _prettyPostcode(String input) {
    final compact = _compactPostcode(input);
    if (compact.length <= 3) return compact;
    return '${compact.substring(0, compact.length - 3)} ${compact.substring(compact.length - 3)}';
  }

  static String _joinParts(List<String> parts) {
    return parts.where((e) => e.trim().isNotEmpty).join(', ');
  }

  static Future<List<AddressLookupItem>> findAddresses(String postcode) async {
    final compact = _compactPostcode(postcode);
    final pretty = _prettyPostcode(postcode);

    if (compact.isEmpty) return [];

    if (apiKey.isEmpty) {
      throw Exception('IDEAL_POSTCODES_API_KEY missing in .env');
    }

    final uri = Uri.parse(
      'https://api.ideal-postcodes.co.uk/v1/postcodes/'
      '${Uri.encodeComponent(compact)}?api_key=${Uri.encodeQueryComponent(apiKey)}',
    );

    final res = await http.get(
      uri,
      headers: const {
        'Accept': 'application/json',
      },
    );

    final body = res.body.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(res.body) as Map<String, dynamic>;

    if (res.statusCode == 404) {
      final suggestions = (body['suggestions'] as List?)
              ?.map((e) => e.toString())
              .where((e) => e.trim().isNotEmpty)
              .toList() ??
          const <String>[];

      if (suggestions.isNotEmpty) {
        throw Exception(
          'Postcode not found. Did you mean: ${suggestions.join(', ')}',
        );
      }

      throw Exception('Postcode not found: $pretty');
    }

    if (res.statusCode != 200) {
      throw Exception('Lookup failed (${res.statusCode}): ${res.body}');
    }

    final results = (body['result'] as List?) ?? const [];

    return results.asMap().entries.map((entry) {
      final item = (entry.value as Map).cast<String, dynamic>();

      final line1 = _joinParts([
        (item['organisation_name'] ?? '').toString(),
        _joinParts([
          (item['sub_building_name'] ?? '').toString(),
          (item['building_name'] ?? '').toString(),
          (item['building_number'] ?? '').toString(),
          (item['thoroughfare'] ?? '').toString(),
        ]),
      ]);

      final line2 = _joinParts([
        (item['dependant_locality'] ?? '').toString(),
        (item['double_dependant_locality'] ?? '').toString(),
        (item['line_2'] ?? '').toString(),
        (item['line_3'] ?? '').toString(),
      ]);

      final city = (item['post_town'] ?? '').toString();
      final postcodeValue = (item['postcode'] ?? pretty).toString();

      final rawAddress = _joinParts([
        line1,
        line2,
        city,
        postcodeValue,
      ]);

      return AddressLookupItem(
        id: (item['udprn'] ?? item['id'] ?? '${postcodeValue}_${entry.key}')
            .toString(),
        rawAddress: rawAddress,
        line1: line1,
        line2: line2,
        city: city,
        postcode: postcodeValue,
      );
    }).toList();
  }
}
