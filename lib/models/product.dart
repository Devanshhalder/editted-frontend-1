import 'package:flutter/material.dart';

class Product {
  Product({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.category,
    required this.color,
    this.published = true,
    this.stock = 1,
    this.syncStatus = 'published',
    this.syncConflict = false,
    this.syncError,
    this.imagePath,
    this.attributes = const <String>[],
    this.marketplaceStatuses = const <String, String>{},
  });

  String id;
  String title;
  String description;
  int price;
  String category;
  Color color;
  bool published;
  int stock;

  /// Local-first synchronization state: queued, processing, published, failed, delisting.
  String syncStatus;
  bool syncConflict;
  String? syncError;

  /// Original/enhanced product image stored on the device.
  String? imagePath;

  /// Generated/editable product attributes shown in the listing/detail view.
  List<String> attributes;

  /// Marketplace status by destination, for example ONDC -> Live.
  Map<String, String> marketplaceStatuses;
}
