import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:western_malabar/features/catalog/models/category_model.dart';
import 'package:western_malabar/features/catalog/services/category_service.dart';
import 'package:western_malabar/features/catalog/services/product_service.dart';
import 'package:western_malabar/shared/utils/debounce.dart';

class SearchSuggestionsState {
  final String query;
  final bool isLoading;
  final List<WmProductDto> products;
  final List<CategoryModel> categories;

  const SearchSuggestionsState({
    required this.query,
    required this.isLoading,
    required this.products,
    required this.categories,
  });

  factory SearchSuggestionsState.initial() {
    return const SearchSuggestionsState(
      query: '',
      isLoading: false,
      products: [],
      categories: [],
    );
  }

  bool get isEmpty =>
      query.trim().isEmpty || (products.isEmpty && categories.isEmpty);

  SearchSuggestionsState copyWith({
    String? query,
    bool? isLoading,
    List<WmProductDto>? products,
    List<CategoryModel>? categories,
  }) {
    return SearchSuggestionsState(
      query: query ?? this.query,
      isLoading: isLoading ?? this.isLoading,
      products: products ?? this.products,
      categories: categories ?? this.categories,
    );
  }
}

final searchQueryProvider = StateProvider<String>((ref) => '');

final searchProvider =
    StateNotifierProvider<SearchController, SearchSuggestionsState>(
  (ref) => SearchController(ref),
);

class SearchController extends StateNotifier<SearchSuggestionsState> {
  SearchController(this.ref) : super(SearchSuggestionsState.initial());

  final Ref ref;
  final _productSvc = ProductService();
  final _debouncer = SearchDebouncer(delay: const Duration(milliseconds: 250));

  void search(String q) {
    final trimmed = q.trim();
    ref.read(searchQueryProvider.notifier).state = trimmed;

    if (trimmed.isEmpty || trimmed.length < 2) {
      state = SearchSuggestionsState.initial();
      return;
    }

    state = state.copyWith(
      query: trimmed,
      isLoading: true,
      products: const [],
      categories: const [],
    );

    _debouncer.run(() async {
      try {
        final results = await Future.wait([
          _productSvc.searchProductsRpc(trimmed, limit: 6),
          CategoryService.searchByName(trimmed, limit: 4),
        ]);

        final products = results[0] as List<WmProductDto>;
        final categories = results[1] as List<CategoryModel>;

        state = SearchSuggestionsState(
          query: trimmed,
          isLoading: false,
          products: products,
          categories: categories,
        );
      } catch (_) {
        state = SearchSuggestionsState(
          query: trimmed,
          isLoading: false,
          products: const [],
          categories: const [],
        );
      }
    });
  }

  void clear() {
    _debouncer.cancel();
    ref.read(searchQueryProvider.notifier).state = '';
    state = SearchSuggestionsState.initial();
  }

  @override
  void dispose() {
    _debouncer.cancel();
    super.dispose();
  }
}




