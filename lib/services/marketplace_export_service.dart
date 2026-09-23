import 'dart:convert';

import '../models/product.dart';

class MarketplaceExportService {
  static String buildCatalogJson({
    required String marketplace,
    required String sellerName,
    required String businessName,
    required List<Product> products,
  }) {
    final payload = <String, dynamic>{
      'schema_version': '1.0',
      'marketplace': marketplace,
      'seller': {
        'name': sellerName,
        'business_name': businessName,
      },
      'catalog': {
        'generated_at': DateTime.now().toUtc().toIso8601String(),
        'currency': 'INR',
        'products': products.map(_product).toList(),
      },
    };

    return const JsonEncoder.withIndent('  ').convert(payload);
  }

  static Map<String, dynamic> _product(Product product) {
    return {
      'product_id': product.id,
      'name': product.title,
      'description': product.description,
      'category': product.category,
      'price_inr': product.price,
      'available_stock': product.stock,
      'status': product.published ? 'published' : 'draft',
    };
  }
}
