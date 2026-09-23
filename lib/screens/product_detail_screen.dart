import 'dart:io';

import 'package:flutter/material.dart';

import '../models/product.dart';
import '../services/app_state.dart';
import '../services/offline_request_queue.dart';
import '../theme.dart';

class ProductDetailScreen extends StatelessWidget {
  const ProductDetailScreen({super.key, required this.product});

  final Product product;

  Future<void> _edit(BuildContext context) async {
    final state = AppScope.of(context);
    state.beginEditProduct(product.id);
    if (!context.mounted) return;
    Navigator.pushNamed(context, '/listing');
  }

  Future<void> _delete(BuildContext context) async {
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Remove craft?',
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                  color: Theme.of(sheetContext).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Are you sure you want to remove this craft from your catalog?',
                style: TextStyle(
                  fontSize: 13,
                  height: 1.4,
                  color: Theme.of(sheetContext).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(sheetContext, false),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.red.shade700,
                      ),
                      onPressed: () => Navigator.pop(sheetContext, true),
                      child: const Text('Delete'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed != true || !context.mounted) return;

    final state = AppScope.of(context);
    final deleted = _copyProduct(product);
    final wasLive = product.published ||
        product.marketplaceStatuses.values.any(
          (status) => status.toLowerCase() == 'live',
        );

    if (wasLive) {
      deleted.syncStatus = 'delisting';
      await OfflineRequestQueue.enqueue(
        type: 'delist_product',
        payload: {
          'product_id': product.id,
          'title': product.title,
          'marketplaces': product.marketplaceStatuses,
        },
      );
    }

    state.deleteProduct(product.id);
    Navigator.pop(context);

    var restored = false;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 5),
        content: Text(
          wasLive ? 'Product removed; delisting queued.' : 'Product removed from catalog.',
        ),
        action: SnackBarAction(
          label: 'UNDO',
          onPressed: () {
            restored = true;
            state.restoreProduct(deleted);
          },
        ),
      ),
    );

    Future<void>.delayed(const Duration(seconds: 5), () {
      if (restored) return;
    });
  }

  Product _copyProduct(Product source) {
    return Product(
      id: source.id,
      title: source.title,
      description: source.description,
      price: source.price,
      category: source.category,
      color: source.color,
      published: source.published,
      stock: source.stock,
      syncStatus: source.syncStatus,
      syncConflict: source.syncConflict,
      syncError: source.syncError,
      imagePath: source.imagePath,
      attributes: List<String>.from(source.attributes),
      marketplaceStatuses: Map<String, String>.from(source.marketplaceStatuses),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Product details'),
        actions: [
          IconButton(
            tooltip: 'Edit product',
            onPressed: () => _edit(context),
            icon: const Icon(Icons.edit_outlined),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 30),
          children: [
            _ProductHeroImage(product: product),
            const SizedBox(height: 18),
            Text(
              product.title.isEmpty ? 'Untitled craft' : product.title,
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                letterSpacing: -.5,
                color: colors.onSurface,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              product.category,
              style: const TextStyle(
                color: AppColors.clay,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              product.description.isEmpty ? 'No description added yet.' : product.description,
              style: TextStyle(
                color: colors.onSurfaceVariant,
                fontSize: 13,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            _InfoCard(
              title: 'Price & inventory',
              children: [
                _InfoRow(label: 'Selling price', value: '₹${product.price}'),
                _InfoRow(label: 'Stock', value: '${product.stock} units'),
                _InfoRow(label: 'Sync status', value: product.syncStatus),
              ],
            ),
            const SizedBox(height: 12),
            _InfoCard(
              title: 'Generated attributes',
              children: [
                if (product.attributes.isEmpty)
                  Text(
                    'No attributes saved yet.',
                    style: TextStyle(color: colors.onSurfaceVariant, fontSize: 12),
                  )
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: product.attributes
                        .map((tag) => Chip(label: Text(tag)))
                        .toList(),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            _InfoCard(
              title: 'Marketplace status',
              children: [
                if (product.marketplaceStatuses.isEmpty)
                  const _StatusPill(label: 'Not published'),
                ...product.marketplaceStatuses.entries.map(
                  (entry) => _MarketplaceRow(
                    marketplace: entry.key,
                    status: entry.value,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            SizedBox(
              height: 52,
              child: FilledButton.icon(
                onPressed: () => _edit(context),
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Edit product'),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 52,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red.shade700,
                  side: BorderSide(color: Colors.red.shade200),
                ),
                onPressed: () => _delete(context),
                icon: const Icon(Icons.delete_outline_rounded),
                label: const Text('Delete product'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductHeroImage extends StatelessWidget {
  const _ProductHeroImage({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final path = product.imagePath;
    final fallback = Container(
      color: product.color.withOpacity(.14),
      alignment: Alignment.center,
      child: Icon(
        Icons.handyman_outlined,
        size: 48,
        color: product.color,
      ),
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: AspectRatio(
        aspectRatio: 1.15,
        child: path == null || path.isEmpty
            ? fallback
            : path.startsWith('assets/')
                ? Image.asset(
                    path,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => fallback,
                  )
                : Image.file(
                    File(path),
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => fallback,
                  ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.outline.withOpacity(.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: colors.onSurface,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(color: colors.onSurfaceVariant, fontSize: 12),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: colors.onSurface,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _MarketplaceRow extends StatelessWidget {
  const _MarketplaceRow({required this.marketplace, required this.status});

  final String marketplace;
  final String status;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(child: Text(marketplace)),
          _StatusPill(label: status),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.forest.withOpacity(.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.forest,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
