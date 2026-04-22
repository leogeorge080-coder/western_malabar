import 'package:flutter_test/flutter_test.dart';
import 'package:western_malabar/features/checkout/utils/checkout_error_formatter.dart';

void main() {
  group('friendlyCheckoutError', () {
    test('extracts JSON message payloads', () {
      expect(
        friendlyCheckoutError(Exception('{"message":"Cart is empty"}')),
        'Your basket is empty. Add an item before placing the order.',
      );
    });

    test('maps insufficient stock errors to user-friendly copy', () {
      expect(
        friendlyCheckoutError(Exception('Insufficient stock for: Appam Batter')),
        'Appam Batter is no longer available in the requested quantity. Reduce the quantity and try again.',
      );
    });

    test('maps invalid payment intent response', () {
      expect(
        friendlyCheckoutError(Exception('invalid payment intent response')),
        'Payment could not be confirmed right now. Try again in a moment.',
      );
    });

    test('unwraps nested function failure prefixes', () {
      expect(
        friendlyCheckoutError(
          Exception('FunctionsHttpException failed: Exception: unavailable product in cart: Banana Chips'),
        ),
        'Banana Chips is unavailable right now. Remove it to continue.',
      );
    });

    test('falls back to cleaned raw message when no mapping exists', () {
      expect(
        friendlyCheckoutError(Exception('Something unexpected happened')),
        'Something unexpected happened',
      );
    });
  });
}
