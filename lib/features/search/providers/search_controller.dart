import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:western_malabar/features/catalog/models/category_model.dart';
import 'package:western_malabar/features/catalog/models/product_model.dart';
import 'package:western_malabar/features/catalog/services/category_service.dart';
import 'package:western_malabar/features/catalog/services/product_service.dart';
import 'package:western_malabar/shared/utils/debounce.dart';

const _recentSearchesKey = 'wm_recent_searches_v1';
const _synonymMap = <String, String>{
  'mathi': 'sardine',
  'chala': 'sardine',
  'kappa': 'tapioca',
  'aval': 'rice flakes',
};

class SearchSessionState {
  final bool isHydrated;

  final String query;
  final String committedQuery;

  final bool isOverlayVisible;
  final bool shouldRequestFocus;

  final bool isSuggesting;
  final bool isSearchingResults;

  final List<String> recentQueries;
  final List<WmProductDto> suggestionProducts;
  final List<CategoryModel> suggestionCategories;

  final List<ProductModel> resultItems;

  final String sort;
  final String selectedCategorySlug;
  final double resultScrollOffset;

  final String? errorMessage;

  const SearchSessionState({
    required this.isHydrated,
    required this.query,
    required this.committedQuery,
    required this.isOverlayVisible,
    required this.shouldRequestFocus,
    required this.isSuggesting,
    required this.isSearchingResults,
    required this.recentQueries,
    required this.suggestionProducts,
    required this.suggestionCategories,
    required this.resultItems,
    required this.sort,
    required this.selectedCategorySlug,
    required this.resultScrollOffset,
    required this.errorMessage,
  });

  factory SearchSessionState.initial() {
    return const SearchSessionState(
      isHydrated: false,
      query: '',
      committedQuery: '',
      isOverlayVisible: false,
      shouldRequestFocus: false,
      isSuggesting: false,
      isSearchingResults: false,
      recentQueries: [],
      suggestionProducts: [],
      suggestionCategories: [],
      resultItems: [],
      sort: 'relevance',
      selectedCategorySlug: '',
      resultScrollOffset: 0,
      errorMessage: null,
    );
  }

  SearchSessionState copyWith({
    bool? isHydrated,
    String? query,
    String? committedQuery,
    bool? isOverlayVisible,
    bool? shouldRequestFocus,
    bool? isSuggesting,
    bool? isSearchingResults,
    List<String>? recentQueries,
    List<WmProductDto>? suggestionProducts,
    List<CategoryModel>? suggestionCategories,
    List<ProductModel>? resultItems,
    String? sort,
    String? selectedCategorySlug,
    double? resultScrollOffset,
    String? errorMessage,
    bool clearErrorMessage = false,
  }) {
    return SearchSessionState(
      isHydrated: isHydrated ?? this.isHydrated,
      query: query ?? this.query,
      committedQuery: committedQuery ?? this.committedQuery,
      isOverlayVisible: isOverlayVisible ?? this.isOverlayVisible,
      shouldRequestFocus: shouldRequestFocus ?? this.shouldRequestFocus,
      isSuggesting: isSuggesting ?? this.isSuggesting,
      isSearchingResults: isSearchingResults ?? this.isSearchingResults,
      recentQueries: recentQueries ?? this.recentQueries,
      suggestionProducts: suggestionProducts ?? this.suggestionProducts,
      suggestionCategories: suggestionCategories ?? this.suggestionCategories,
      resultItems: resultItems ?? this.resultItems,
      sort: sort ?? this.sort,
      selectedCategorySlug: selectedCategorySlug ?? this.selectedCategorySlug,
      resultScrollOffset: resultScrollOffset ?? this.resultScrollOffset,
      errorMessage:
          clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
    );
  }

  bool get hasSuggestionContent =>
      suggestionProducts.isNotEmpty || suggestionCategories.isNotEmpty;

  bool get hasRecentContent => recentQueries.isNotEmpty;

  List<ProductModel> get visibleResults {
    var list = [...resultItems];

    if (selectedCategorySlug.isNotEmpty) {
      list = list
          .where((p) => (p.categorySlug ?? '').trim() == selectedCategorySlug)
          .toList();
    }

    switch (sort) {
      case 'price_low':
        list.sort(
          (a, b) => ((a.salePriceCents ?? a.priceCents ?? 0))
              .compareTo((b.salePriceCents ?? b.priceCents ?? 0)),
        );
        break;
      case 'price_high':
        list.sort(
          (a, b) => ((b.salePriceCents ?? b.priceCents ?? 0))
              .compareTo((a.salePriceCents ?? a.priceCents ?? 0)),
        );
        break;
      case 'name':
        list.sort(
          (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
        );
        break;
      case 'relevance':
      default:
        break;
    }

    return list;
  }
}

final searchProvider =
    StateNotifierProvider<SearchController, SearchSessionState>(
  (ref) => SearchController(ref),
);

class SearchController extends StateNotifier<SearchSessionState> {
  SearchController(this.ref) : super(SearchSessionState.initial());

  final Ref ref;
  final _productSvc = ProductService();
  final _debouncer = SearchDebouncer(delay: const Duration(milliseconds: 150));
  final Map<String, List<WmProductDto>> _suggestionProductCache = {};
  final Map<String, List<CategoryModel>> _suggestionCategoryCache = {};
  final Map<String, List<ProductModel>> _resultCache = {};

  int _suggestionRequestId = 0;
  int _resultRequestId = 0;
  bool _hydrating = false;

  String _normalizeQuery(String q) {
    return q.toLowerCase().trim().replaceAll(RegExp(r'\s+'), ' ');
  }

  String _searchKey(String q) {
    final normalized = _normalizeQuery(q);
    return _synonymMap[normalized] ?? normalized;
  }

  void _rememberSuggestionCache(
    String key,
    List<WmProductDto> products,
    List<CategoryModel> categories,
  ) {
    _suggestionProductCache.remove(key);
    _suggestionCategoryCache.remove(key);
    _suggestionProductCache[key] = List<WmProductDto>.from(products);
    _suggestionCategoryCache[key] = List<CategoryModel>.from(categories);

    while (_suggestionProductCache.length > 24) {
      final oldestKey = _suggestionProductCache.keys.first;
      _suggestionProductCache.remove(oldestKey);
      _suggestionCategoryCache.remove(oldestKey);
    }
  }

  void _rememberResultCache(String key, List<ProductModel> items) {
    _resultCache.remove(key);
    _resultCache[key] = List<ProductModel>.from(items);

    while (_resultCache.length > 24) {
      _resultCache.remove(_resultCache.keys.first);
    }
  }

  Future<void> hydrate() async {
    if (_hydrating || state.isHydrated) return;
    _hydrating = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final recent =
          prefs.getStringList(_recentSearchesKey) ?? const <String>[];

      state = state.copyWith(
        isHydrated: true,
        recentQueries: recent,
      );
    } finally {
      _hydrating = false;
    }
  }

  Future<void> _persistRecentQueries(List<String> queries) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_recentSearchesKey, queries);
  }

  Future<void> _saveRecentQuery(String q) async {
    final trimmed = q.trim();
    if (trimmed.isEmpty) return;

    final next = <String>[
      trimmed,
      ...state.recentQueries.where(
        (e) => e.toLowerCase() != trimmed.toLowerCase(),
      ),
    ].take(10).toList();

    state = state.copyWith(recentQueries: next);
    await _persistRecentQueries(next);
  }

  Future<void> removeRecentQuery(String q) async {
    final next = state.recentQueries
        .where((e) => e.toLowerCase() != q.toLowerCase())
        .toList();
    state = state.copyWith(recentQueries: next);
    await _persistRecentQueries(next);
  }

  void openHomeOverlay() {
    state = state.copyWith(
      isOverlayVisible: true,
      shouldRequestFocus: true,
      clearErrorMessage: true,
    );
  }

  void collapseForHome() {
    state = state.copyWith(
      isOverlayVisible: false,
      shouldRequestFocus: false,
      isSuggesting: false,
    );
  }

  void clearQuery({bool keepOverlay = true, bool clearResults = false}) {
    _debouncer.cancel();
    _suggestionRequestId++;
    _resultRequestId++;

    state = state.copyWith(
      query: '',
      committedQuery: clearResults ? '' : state.committedQuery,
      suggestionProducts: const [],
      suggestionCategories: const [],
      isSuggesting: false,
      isSearchingResults: false,
      isOverlayVisible: keepOverlay && state.hasRecentContent,
      shouldRequestFocus: keepOverlay,
      resultItems: clearResults ? const [] : state.resultItems,
      selectedCategorySlug: '',
      sort: 'relevance',
      clearErrorMessage: true,
    );
  }

  void setSort(String value) {
    state = state.copyWith(sort: value);
  }

  void setCategory(String slug) {
    state = state.copyWith(selectedCategorySlug: slug);
  }

  void setResultScrollOffset(double value) {
    state = state.copyWith(resultScrollOffset: value);
  }

  void enterSearchScreen({String initialQuery = ''}) {
    final trimmed = initialQuery.trim();

    if (trimmed.isEmpty) {
      state = state.copyWith(
        query: '',
        committedQuery: '',
        suggestionProducts: const [],
        suggestionCategories: const [],
        resultItems: const [],
        isOverlayVisible: false,
        shouldRequestFocus: true,
        isSuggesting: false,
        isSearchingResults: false,
        selectedCategorySlug: '',
        sort: 'relevance',
        resultScrollOffset: 0,
        clearErrorMessage: true,
      );
      return;
    }

    if (state.committedQuery != trimmed || state.query != trimmed) {
      unawaited(commitQuery(trimmed));
      return;
    }

    state = state.copyWith(
      isOverlayVisible: false,
      shouldRequestFocus: false,
    );
  }

  void updateQuery(
    String raw, {
    bool fetchResultsToo = false,
    bool showOverlay = true,
  }) {
    final q = raw.trim();
    final searchKey = _searchKey(q);

    if (q.isEmpty) {
      _debouncer.cancel();

      // Critical fix:
      // invalidate any in-flight suggestion/result response so stale async
      // callbacks cannot write "a", "r", etc. back into the field.
      _suggestionRequestId++;
      _resultRequestId++;

      state = state.copyWith(
        query: '',
        suggestionProducts: const [],
        suggestionCategories: const [],
        isSuggesting: false,
        isOverlayVisible: showOverlay && state.hasRecentContent,
        shouldRequestFocus: showOverlay,
        clearErrorMessage: true,
        selectedCategorySlug: '',
        committedQuery: fetchResultsToo ? '' : state.committedQuery,
        resultItems: fetchResultsToo ? const [] : state.resultItems,
        isSearchingResults: false,
        resultScrollOffset: 0,
      );
      return;
    }

    final cachedSuggestionProducts = _suggestionProductCache[searchKey];
    final cachedSuggestionCategories = _suggestionCategoryCache[searchKey];

    state = state.copyWith(
      query: q,
      isOverlayVisible: showOverlay,
      shouldRequestFocus: showOverlay,
      isSuggesting: q.length >= 1 && cachedSuggestionProducts == null,
      clearErrorMessage: true,
      selectedCategorySlug: '',
      suggestionProducts: cachedSuggestionProducts ?? state.suggestionProducts,
      suggestionCategories:
          cachedSuggestionCategories ?? state.suggestionCategories,
    );

    final suggestionReq = ++_suggestionRequestId;

    _debouncer.run(() async {
      try {
        final results = await Future.wait([
          _productSvc.searchProductsRpc(searchKey, limit: 8),
          CategoryService.searchByName(searchKey, limit: 4),
        ]);

        if (suggestionReq != _suggestionRequestId) return;

        final products = results[0] as List<WmProductDto>;
        final categories = results[1] as List<CategoryModel>;
        _rememberSuggestionCache(searchKey, products, categories);

        state = state.copyWith(
          query: q,
          isSuggesting: false,
          suggestionProducts: products,
          suggestionCategories: categories,
        );
      } catch (_) {
        if (suggestionReq != _suggestionRequestId) return;

        state = state.copyWith(
          query: q,
          isSuggesting: false,
          suggestionProducts: const [],
          suggestionCategories: const [],
        );
      }
    });

    if (fetchResultsToo && q.length >= 3) {
      final cachedResults = _resultCache[searchKey];
      if (cachedResults != null && cachedResults.isNotEmpty) {
        state = state.copyWith(
          committedQuery: q,
          resultItems: List<ProductModel>.from(cachedResults),
          isSearchingResults: false,
          selectedCategorySlug: '',
        );
      }

      unawaited(
        commitQuery(
          q,
          closeOverlay: false,
          requestFocus: true,
        ),
      );
    }
  }

  Future<void> commitQuery(
    String raw, {
    bool closeOverlay = true,
    bool requestFocus = false,
  }) async {
    final q = raw.trim();
    final searchKey = _searchKey(q);

    if (q.isEmpty) {
      _resultRequestId++;
      _suggestionRequestId++;

      state = state.copyWith(
        query: '',
        committedQuery: '',
        resultItems: const [],
        isSearchingResults: false,
        isOverlayVisible: false,
        shouldRequestFocus: requestFocus,
        selectedCategorySlug: '',
        suggestionProducts: const [],
        suggestionCategories: const [],
        isSuggesting: false,
        clearErrorMessage: true,
      );
      return;
    }

    final req = ++_resultRequestId;
    final cachedResults = _resultCache[searchKey];

    state = state.copyWith(
      query: q,
      committedQuery: q,
      resultItems: cachedResults != null && cachedResults.isNotEmpty
          ? List<ProductModel>.from(cachedResults)
          : state.resultItems,
      isSearchingResults: true,
      isSuggesting: false,
      suggestionProducts: const [],
      suggestionCategories: const [],
      isOverlayVisible: closeOverlay ? false : state.isOverlayVisible,
      shouldRequestFocus: requestFocus,
      selectedCategorySlug: '',
      clearErrorMessage: true,
    );

    try {
      final results = await _productSvc.fetchProductModelsByQuery(
        searchKey,
        limit: 30,
      );

      if (req != _resultRequestId) return;

      _rememberResultCache(searchKey, results);
      await _saveRecentQuery(q);

      state = state.copyWith(
        query: q,
        committedQuery: q,
        resultItems: results,
        isSearchingResults: false,
        isSuggesting: false,
        suggestionProducts: const [],
        suggestionCategories: const [],
        isOverlayVisible: false,
        shouldRequestFocus: requestFocus,
        selectedCategorySlug: '',
      );
    } catch (e) {
      if (req != _resultRequestId) return;

      state = state.copyWith(
        isSearchingResults: false,
        isSuggesting: false,
        suggestionProducts: const [],
        suggestionCategories: const [],
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> selectSuggestionProduct(WmProductDto dto) async {
    await commitQuery(
      dto.name,
      closeOverlay: true,
      requestFocus: false,
    );
  }

  Future<void> rerunRecent(String q) async {
    await commitQuery(q);
  }

  @override
  void dispose() {
    _debouncer.cancel();
    super.dispose();
  }
}
