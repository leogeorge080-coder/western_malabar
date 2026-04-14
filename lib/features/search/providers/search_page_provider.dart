import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:western_malabar/features/catalog/services/product_service.dart';
import 'package:western_malabar/shared/utils/debounce.dart';

/// ─────────────────────────────────────────────────────────────
/// Search Page State – Full pagination + Riverpod integration
/// ─────────────────────────────────────────────────────────────

class SearchPageState {
  final String query;
  final bool loading;
  final bool loadingMore;
  final String? error;
  final List<WmProductDto> results;
  final List<WmProductDto> suggestions;
  final bool hasMore;
  final int offset;

  const SearchPageState({
    this.query = '',
    this.loading = false,
    this.loadingMore = false,
    this.error,
    this.results = const [],
    this.suggestions = const [],
    this.hasMore = true,
    this.offset = 0,
  });

  SearchPageState copyWith({
    String? query,
    bool? loading,
    bool? loadingMore,
    String? error,
    List<WmProductDto>? results,
    List<WmProductDto>? suggestions,
    bool? hasMore,
    int? offset,
  }) {
    return SearchPageState(
      query: query ?? this.query,
      loading: loading ?? this.loading,
      loadingMore: loadingMore ?? this.loadingMore,
      error: error,
      results: results ?? this.results,
      suggestions: suggestions ?? this.suggestions,
      hasMore: hasMore ?? this.hasMore,
      offset: offset ?? this.offset,
    );
  }
}

final searchPageProvider =
    StateNotifierProvider.autoDispose<SearchPageController, SearchPageState>(
  (ref) => SearchPageController(ProductService()),
);

class SearchPageController extends StateNotifier<SearchPageState> {
  SearchPageController(this._svc) : super(const SearchPageState());

  final ProductService _svc;
  final _debouncer = SearchDebouncer(delay: const Duration(milliseconds: 280));

  static const int _suggestLimit = 8;
  static const int _pageSize = 24;

  /// Called when user types in search field
  /// Shows suggestions with 280ms debounce
  void onQueryChanged(String q) {
    state = state.copyWith(query: q, error: null);

    final trimmed = q.trim();

    if (trimmed.isEmpty) {
      state = state.copyWith(suggestions: const []);
      return;
    }

    _debouncer.run(() async {
      final results =
          await _svc.searchProductsRpc(trimmed, limit: _suggestLimit);

      // Prevent race condition: only apply if query hasn't changed
      if (state.query.trim() == trimmed) {
        state = state.copyWith(suggestions: results);
      }
    });
  }

  /// Called when user submits search (presses Enter or taps search result)
  /// Immediately loads full results (no debounce)
  Future<void> submit(String q) async {
    final trimmed = q.trim();
    if (trimmed.isEmpty) return;

    _debouncer.cancel();

    state = state.copyWith(
      query: trimmed,
      loading: true,
      suggestions: const [],
      results: const [],
      offset: 0,
      hasMore: true,
    );

    try {
      final items =
          await _svc.searchProductsRpc(trimmed, limit: _pageSize, offset: 0);

      state = state.copyWith(
        loading: false,
        results: items,
        offset: items.length,
        hasMore: items.length == _pageSize,
      );
    } catch (e) {
      state = state.copyWith(
        loading: false,
        error: 'Search failed. Please try again.',
      );
    }
  }

  /// Load next page of results (infinite scroll)
  Future<void> loadMore() async {
    if (!state.hasMore || state.loadingMore) return;

    state = state.copyWith(loadingMore: true);

    try {
      final items = await _svc.searchProductsRpc(
        state.query.trim(),
        limit: _pageSize,
        offset: state.offset,
      );

      state = state.copyWith(
        loadingMore: false,
        results: [...state.results, ...items],
        offset: state.offset + items.length,
        hasMore: items.length == _pageSize,
      );
    } catch (_) {
      state = state.copyWith(
        loadingMore: false,
        error: 'Couldn\'t load more results.',
      );
    }
  }

  @override
  void dispose() {
    _debouncer.cancel();
    super.dispose();
  }
}
