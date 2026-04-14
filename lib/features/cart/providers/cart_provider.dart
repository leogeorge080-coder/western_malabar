import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:western_malabar/features/catalog/models/product_model.dart';

class CartItem {
  final ProductModel product;
  final int qty;

  const CartItem(this.product, this.qty);

  CartItem copyWith({ProductModel? product, int? qty}) {
    return CartItem(
      product ?? this.product,
      qty ?? this.qty,
    );
  }
}

class CartState extends StateNotifier<List<CartItem>> {
  CartState() : super(const []);

  void add(ProductModel p) {
    final i = state.indexWhere((e) => e.product.id == p.id);
    if (i == -1) {
      state = [...state, CartItem(p, 1)];
    } else {
      final list = [...state];
      list[i] = list[i].copyWith(qty: list[i].qty + 1);
      state = list;
    }
  }

  void inc(ProductModel p) => add(p);

  void dec(ProductModel p) {
    final i = state.indexWhere((e) => e.product.id == p.id);
    if (i == -1) return;

    final list = [...state];
    final newQty = list[i].qty - 1;

    if (newQty <= 0) {
      list.removeAt(i);
    } else {
      list[i] = list[i].copyWith(qty: newQty);
    }

    state = list;
  }

  void remove(ProductModel p) {
    state = state.where((e) => e.product.id != p.id).toList();
  }

  void reset() {
    state = const [];
  }

  void clear() => reset();

  int get itemCount => state.fold(0, (s, e) => s + e.qty);

  double get total {
    double sum = 0;
    for (final e in state) {
      final cents = e.product.salePriceCents ?? e.product.priceCents ?? 0;
      sum += (cents / 100.0) * e.qty;
    }
    return sum;
  }

  int get totalCents {
    int sum = 0;
    for (final e in state) {
      final cents = e.product.salePriceCents ?? e.product.priceCents ?? 0;
      sum += cents * e.qty;
    }
    return sum;
  }
}

final cartProvider =
    StateNotifierProvider<CartState, List<CartItem>>((ref) => CartState());

final addingProductIdsProvider = StateProvider<Set<String>>((ref) => {});
