import 'package:flutter/material.dart';
import 'package:hive_ce/hive.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

import '../models/product.dart';

class CatalogLocalDb {
  CatalogLocalDb._();

  static const String _boxName = 'karigarkart_catalog';
  static const String _productsKey = 'products';
  static Box<dynamic>? _box;

  static Future<void> initialize() async {
    if (_box?.isOpen == true) return;
    await Hive.initFlutter();
    _box = await Hive.openBox<dynamic>(_boxName);
  }

  static Future<List<Product>> loadProducts() async {
    await initialize();
    final raw = _box!.get(_productsKey);
    if (raw is! List) return <Product>[];

    return raw.whereType<Map>().map((item) {
      final map = Map<String, dynamic>.from(item);
      final rawAttributes = map['attributes'];
      final rawMarketplace = map['marketplaceStatuses'];

      return Product(
        id: map['id']?.toString() ?? '',
        title: map['title']?.toString() ?? '',
        description: map['description']?.toString() ?? '',
        price: int.tryParse(map['price']?.toString() ?? '') ?? 0,
        category: map['category']?.toString() ?? 'Other',
        color: Color(
          int.tryParse(map['color']?.toString() ?? '') ?? 0xFF8B5E3C,
        ),
        published: map['published'] == true,
        stock: int.tryParse(map['stock']?.toString() ?? '') ?? 1,
        syncStatus: map['syncStatus']?.toString() ?? 'published',
        syncConflict: map['syncConflict'] == true,
        syncError: map['syncError']?.toString(),
        imagePath: map['imagePath']?.toString(),
        attributes: rawAttributes is List
            ? rawAttributes.map((item) => item.toString()).toList()
            : const <String>[],
        marketplaceStatuses: rawMarketplace is Map
            ? rawMarketplace.map(
                (key, value) => MapEntry(key.toString(), value.toString()),
              )
            : const <String, String>{},
      );
    }).where((product) => product.id.isNotEmpty).toList();
  }

  static Future<void> saveProducts(Iterable<Product> products) async {
    await initialize();
    await _box!.put(
      _productsKey,
      products
          .map(
            (product) => <String, dynamic>{
              'id': product.id,
              'title': product.title,
              'description': product.description,
              'price': product.price,
              'category': product.category,
              'color': product.color.value,
              'published': product.published,
              'stock': product.stock,
              'syncStatus': product.syncStatus,
              'syncConflict': product.syncConflict,
              'syncError': product.syncError,
              'imagePath': product.imagePath,
              'attributes': product.attributes,
              'marketplaceStatuses': product.marketplaceStatuses,
            },
          )
          .toList(),
    );
  }

  static Future<void> upsert(Product product) async {
    final products = await loadProducts();
    final index = products.indexWhere((item) => item.id == product.id);
    if (index >= 0) {
      products[index] = product;
    } else {
      products.insert(0, product);
    }
    await saveProducts(products);
  }

  static Future<void> delete(String id) async {
    final products = await loadProducts();
    products.removeWhere((item) => item.id == id);
    await saveProducts(products);
  }

  static Future<void> clear() async {
    await initialize();
    await _box!.delete(_productsKey);
  }
}
