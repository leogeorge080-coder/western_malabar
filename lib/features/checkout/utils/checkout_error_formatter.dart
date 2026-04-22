import 'dart:convert';

String stripCheckoutExceptionPrefix(String value) {
  final trimmed = value.trim();
  if (trimmed.startsWith('Exception: ')) {
    return trimmed.substring('Exception: '.length).trim();
  }
  return trimmed;
}

String extractCheckoutBackendErrorText(String raw) {
  final normalized = stripCheckoutExceptionPrefix(raw);

  if (normalized.startsWith('{') || normalized.startsWith('[')) {
    try {
      final decoded = jsonDecode(normalized);
      if (decoded is Map<String, dynamic>) {
        for (final key in ['error', 'message', 'msg']) {
          final value = decoded[key]?.toString().trim();
          if (value != null && value.isNotEmpty) return value;
        }
      }
    } catch (_) {}
  }

  final failedIndex = normalized.indexOf('failed:');
  if (failedIndex >= 0) {
    final trailing =
        normalized.substring(failedIndex + 'failed:'.length).trim();
    if (trailing.isNotEmpty) {
      return extractCheckoutBackendErrorText(trailing);
    }
  }

  return normalized;
}

String friendlyCheckoutError(Object error) {
  final raw = extractCheckoutBackendErrorText(error.toString());
  final lower = raw.toLowerCase();

  String suffixAfter(String prefix) {
    final match = RegExp(
      '^${RegExp.escape(prefix)}\\s*(.+)\$',
      caseSensitive: false,
    ).firstMatch(raw);
    return match?.group(1)?.trim() ?? '';
  }

  if (lower == 'cart is empty' ||
      lower == 'cannot place order with empty cart' ||
      lower == 'your cart is empty') {
    return 'Your basket is empty. Add an item before placing the order.';
  }

  if (lower == 'not authenticated' ||
      lower.contains('user session lost') ||
      lower.contains('user session not available')) {
    return 'Your session expired. Please sign in again and retry checkout.';
  }

  if (lower == 'invalid delivery type') {
    return 'Choose a delivery option before placing the order.';
  }

  if (lower == 'invalid payment method') {
    return 'Choose a valid payment method before placing the order.';
  }

  if (lower == 'missing product_id in cart' ||
      lower.startsWith('invalid product in cart:')) {
    return 'One item in your basket is no longer valid. Remove it and try again.';
  }

  if (lower == 'invalid quantity in cart' ||
      lower.startsWith('invalid quantity for product')) {
    return 'One item has an invalid quantity. Update your basket and try again.';
  }

  if (lower.startsWith('inactive product in cart:')) {
    final productName = suffixAfter('Inactive product in cart:');
    return productName.isEmpty
        ? 'One item is no longer active. Remove it to continue.'
        : '$productName is no longer active. Remove it to continue.';
  }

  if (lower.startsWith('unavailable product in cart:')) {
    final productName = suffixAfter('Unavailable product in cart:');
    return productName.isEmpty
        ? 'One item is unavailable right now. Remove it to continue.'
        : '$productName is unavailable right now. Remove it to continue.';
  }

  if (lower.startsWith('invalid product price for:')) {
    final productName = suffixAfter('Invalid product price for:');
    return productName.isEmpty
        ? 'One item has a pricing issue. Remove it or try again later.'
        : '$productName has a pricing issue. Remove it or try again later.';
  }

  if (lower.startsWith('insufficient stock for:')) {
    final productName = suffixAfter('Insufficient stock for:');
    return productName.isEmpty
        ? 'One item is no longer available in the requested quantity. Reduce the quantity and try again.'
        : '$productName is no longer available in the requested quantity. Reduce the quantity and try again.';
  }

  if (lower.startsWith('insufficient available quantity for:')) {
    final productName = suffixAfter('Insufficient available quantity for:');
    return productName.isEmpty
        ? 'One item exceeds the currently available quantity. Reduce the quantity and try again.'
        : '$productName exceeds the currently available quantity. Reduce the quantity and try again.';
  }

  if (lower.contains('payment init failed')) {
    return 'Payment could not be started. Check your basket details and try again.';
  }

  if (lower.contains('invalid payment intent response')) {
    return 'Payment could not be confirmed right now. Try again in a moment.';
  }

  if (lower.contains('could not confirm latest checkout total')) {
    return 'We could not confirm your latest basket total. Review your basket and try again.';
  }

  return raw.isEmpty
      ? 'Could not place your order right now. Please try again.'
      : raw;
}
