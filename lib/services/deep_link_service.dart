import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';

import '../models/product.dart';
import 'app_state.dart';

class DeepLinkService {
  static StreamSubscription<Uri>? _subscription;

  static Future<void> initialize({
    required GlobalKey<NavigatorState> navigatorKey,
    required AppState state,
  }) async {
    final links = AppLinks();

    Future<void> handle(Uri uri) async {
      final segments = uri.pathSegments;
      if (segments.length < 2 || segments.first != 'product') return;
      final id = segments[1];
      Product? product;
      for (final item in state.products) {
        if (item.id == id) {
          product = item;
          break;
        }
      }
      if (product == null) return;
      await Future<void>.delayed(const Duration(milliseconds: 250));
      navigatorKey.currentState?.pushNamed('/product-detail', arguments: product);
    }

    try {
      final initial = await links.getInitialLink();
      if (initial != null) await handle(initial);
    } catch (_) {
      // Ignore malformed or unavailable initial links.
    }

    await _subscription?.cancel();
    _subscription = links.uriLinkStream.listen(
      (uri) => handle(uri),
      onError: (_) {},
    );
  }

  static Future<void> dispose() async {
    await _subscription?.cancel();
    _subscription = null;
  }
}
