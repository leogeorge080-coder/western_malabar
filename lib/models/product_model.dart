class ProductModel {
  final String id;
  final String name;
  final String? image;
  final int? priceCents;
  final int? salePriceCents;

  const ProductModel({
    required this.id,
    required this.name,
    this.image,
    this.priceCents,
    this.salePriceCents,
  });
}
