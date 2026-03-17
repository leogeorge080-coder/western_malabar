import 'dart:async';
import 'package:flutter/foundation.dart';

/// ─────────────────────────────────────────────────────────────────
/// Debounce Utility – For search, filter, and user input
/// ─────────────────────────────────────────────────────────────────
///
/// Why debounce?
/// - Prevents firing a query on every keystroke
/// - Reduces DB load
/// - Eliminates UI flicker
/// - Mimics Amazon-style search behavior
///
/// Example (in a StatefulWidget):
/// ```dart
/// late SearchDebouncer _debouncer;
///
/// @override
/// void initState() {
///   super.initState();
///   _debouncer = SearchDebouncer(delay: Duration(milliseconds: 300));
/// }
///
/// void _onSearchChanged(String query) {
///   _debouncer.run(() async {
///     final results = await productService.searchProductsRpc(query);
///     setState(() => products = results);
///   });
/// }
///
/// @override
/// void dispose() {
///   _debouncer.cancel();
///   super.dispose();
/// }
/// ```
/// ─────────────────────────────────────────────────────────────────

class SearchDebouncer {
  final Duration delay;
  Timer? _timer;

  SearchDebouncer({this.delay = const Duration(milliseconds: 300)});

  /// Cancel any pending operation
  void cancel() {
    _timer?.cancel();
    _timer = null;
  }

  /// Schedule a callback to run after <delay> with debounce
  void run(VoidCallback callback) {
    cancel(); // Cancel previous timer
    _timer = Timer(delay, callback);
  }

  /// Async version: schedule a future to run after <delay>
  Future<T> runAsync<T>(Future<T> Function() callback) async {
    cancel();
    final completer = Completer<T>();

    _timer = Timer(delay, () async {
      try {
        final result = await callback();
        if (!completer.isCompleted) {
          completer.complete(result);
        }
      } catch (e) {
        if (!completer.isCompleted) {
          completer.completeError(e);
        }
      }
    });

    return completer.future;
  }
}
