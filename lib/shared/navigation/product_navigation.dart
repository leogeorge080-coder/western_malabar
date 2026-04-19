import 'package:flutter/material.dart';
import 'package:western_malabar/features/catalog/models/product_model.dart';
import 'package:western_malabar/features/catalog/screens/product_detail_screen.dart';

class ProductNavigation {
  static Future<void> open(
    BuildContext context, {
    required String productId,
    ProductModel? initialProduct,
  }) {
    return Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => ProductDetailScreen(
          productId: productId,
          initialProduct: initialProduct,
        ),
      ),
    );
  }
}

// Legacy function name for backwards compatibility
Future<void> openProductDetail(
  BuildContext context, {
  required String productId,
  ProductModel? initialProduct,
}) {
  return ProductNavigation.open(context,
      productId: productId, initialProduct: initialProduct);
}
