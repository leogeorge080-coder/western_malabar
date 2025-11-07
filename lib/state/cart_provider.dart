import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:western_malabar/models/product_model.dart';

class CartItem {
  final ProductModel product;
  final int qty;
  const CartItem(this.product, this.qty);

  CartItem copyWith({ProductModel? product, int? qty}) =>
      CartItem(product ?? this.product, qty ?? this.qty);
}

class CartState extends StateNotifier<List<CartItem>> {
  CartState() : super(const []);

  // add 1 (or insert new)
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

  // increment quantity
  void inc(ProductModel p) => add(p);

  // decrement quantity (remove if hits 0)
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

  // remove item completely
  void remove(ProductModel p) {
    state = state.where((e) => e.product.id != p.id).toList();
  }

  // clear cart
  void clear() => state = const [];

  // derived values
  int get itemCount => state.fold(0, (s, e) => s + e.qty);

  double get total {
    double sum = 0;
    for (final e in state) {
      final cents = e.product.salePriceCents ?? e.product.priceCents ?? 0;
      sum += (cents / 100.0) * e.qty;
    }
    return sum;
  }
}

// Provider
final cartProvider =
    StateNotifierProvider<CartState, List<CartItem>>((ref) => CartState());
