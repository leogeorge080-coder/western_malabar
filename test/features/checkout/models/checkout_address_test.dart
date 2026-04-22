import 'package:flutter_test/flutter_test.dart';
import 'package:western_malabar/features/checkout/models/checkout_address.dart';

void main() {
  group('CheckoutAddress', () {
    test('isValid requires the core delivery fields', () {
      const empty = CheckoutAddress.empty();
      const valid = CheckoutAddress(
        fullName: 'Test User',
        phone: '07123456789',
        addressLine1: '1 Market Street',
        addressLine2: '',
        city: 'Manchester',
        postcode: 'M1 1AA',
      );

      expect(empty.isValid, isFalse);
      expect(valid.isValid, isTrue);
    });

    test('toMap uses backend field names', () {
      const address = CheckoutAddress(
        fullName: 'Test User',
        phone: '07123456789',
        addressLine1: '1 Market Street',
        addressLine2: 'Flat 2',
        city: 'Manchester',
        postcode: 'M1 1AA',
      );

      expect(address.toMap(), {
        'customer_name': 'Test User',
        'phone': '07123456789',
        'address_line1': '1 Market Street',
        'address_line2': 'Flat 2',
        'city': 'Manchester',
        'postcode': 'M1 1AA',
      });
    });
  });
}
