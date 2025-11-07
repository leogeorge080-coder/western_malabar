import '../models/product_model.dart';

class ProductService {
  static Future<List<ProductModel>> fetchFeatured() async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    return const [
      ProductModel(id: '1', name: 'Kerala Matta Rice 5kg', priceCents: 1299),
      ProductModel(id: '2', name: 'Sambar Powder 200g', priceCents: 249),
      ProductModel(id: '3', name: 'Mango Pickle 400g', priceCents: 349),
      ProductModel(id: '4', name: 'Ghee 500ml', priceCents: 899),
    ];
  }

  static Future<List<ProductModel>> fetchByCategory(String categorySlug) async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    return List.generate(
      12,
      (i) => ProductModel(
        id: '$categorySlug-$i',
        name: '$categorySlug Item ${i + 1}',
        priceCents: 199 + i * 10,
      ),
    );
  }
}
