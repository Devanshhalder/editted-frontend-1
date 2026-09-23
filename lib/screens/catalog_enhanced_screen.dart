import 'dart:io';

import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../models/product.dart';
import '../services/app_state.dart';
import '../services/business_report_service.dart';
import '../theme.dart';

class CatalogEnhancedScreen extends StatefulWidget {
  const CatalogEnhancedScreen({super.key, this.embedded = false});
  final bool embedded;

  @override
  State<CatalogEnhancedScreen> createState() => _CatalogEnhancedScreenState();
}

class _CatalogEnhancedScreenState extends State<CatalogEnhancedScreen> {
  final TextEditingController _search = TextEditingController();
  final stt.SpeechToText _speech = stt.SpeechToText();
  final Set<String> _selectedIds = <String>{};
  String _sort = 'Newest';
  bool _listening = false;

  @override
  void dispose() {
    _search.dispose();
    _speech.stop();
    super.dispose();
  }

  Future<void> _voiceSearch() async {
    if (_listening) {
      await _speech.stop();
      if (!mounted) return;
      setState(() => _listening = false);
      return;
    }
    final available = await _speech.initialize(
      // FIX #2: onStatus callback resets _listening when the engine stops
      // naturally (timeout, silence) so the mic icon doesn't stay stuck active.
      onStatus: (status) {
        if (!mounted) return;
        if (status == 'done' || status == 'notListening') {
          setState(() => _listening = false);
        }
      },
    );
    if (!available) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Voice search is not available on this device.'),
        ),
      );
      return;
    }
    setState(() => _listening = true);
    await _speech.listen(
      onResult: (result) {
        if (!mounted) return;
        _search.text = result.recognizedWords;
        setState(() {});
      },
    );
  }

  Future<void> _shareCatalog() async {
    final state = AppScope.of(context);
    try {
      final file = await BusinessReportService.createCatalogPdf(
        artisanName: state.profileName,
        businessName: state.businessName,
        pehchanId: state.pehchanId,
        products: state.products,
      );
      await BusinessReportService.shareFile(
        file,
        title: 'KarigarKart Product Catalog',
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not share catalog: $error')),
      );
    }
  }

  void _bulkDelete(List<Product> products) {
    if (_selectedIds.isEmpty) return;
    final state = AppScope.of(context);
    final deleted =
    products.where((product) => _selectedIds.contains(product.id)).toList();
    for (final product in deleted) {
      state.deleteProduct(product.id);
    }
    setState(() => _selectedIds.clear());
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${deleted.length} product(s) removed'),
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'UNDO',
          onPressed: () {
            for (final product in deleted) {
              state.restoreProduct(product);
            }
          },
        ),
      ),
    );
  }

  void _syncPrices(List<Product> products) {
    final state = AppScope.of(context);
    for (final product
    in products.where((item) => _selectedIds.contains(item.id))) {
      state.updateProduct(product.id, price: product.price);
    }
    setState(() => _selectedIds.clear());
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Selected prices queued for sync.')),
    );
  }

  // FIX #1: Collapsed the nonsensical 3-layer chain
  // _publishOnmc -> _publishOnDC -> _publishOnDCInternal (all doing the same
  // thing) plus a dead _publishOndc duplicate into one single method.
  void _publishOndc(List<Product> products) {
    final state = AppScope.of(context);
    for (final product
    in products.where((item) => _selectedIds.contains(item.id))) {
      final channels = Map<String, String>.from(product.marketplaceStatuses)
        ..['ONDC'] = 'Live';
      state.updateProduct(product.id, marketplaceStatuses: channels);
    }
    setState(() => _selectedIds.clear());
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Selected products queued for ONDC publishing.'),
      ),
    );
  }

  List<Product> _sortedProducts(List<Product> products) {
    final result = [...products];
    switch (_sort) {
      case 'Price (High to Low)':
        result.sort((a, b) => b.price.compareTo(a.price));
        break;
      case 'Price (Low to High)':
        result.sort((a, b) => a.price.compareTo(b.price));
        break;
      case 'Stock (Low to High)':
        result.sort((a, b) => a.stock.compareTo(b.stock));
        break;
      default:
        result.sort((a, b) => b.id.compareTo(a.id));
    }
    return result;
  }

  void _toggleSelection(String id) {
    if (_selectedIds.contains(id)) {
      _selectedIds.remove(id);
    } else {
      _selectedIds.add(id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final colors = Theme.of(context).colorScheme;
    final query = _search.text.trim().toLowerCase();
    final products = _sortedProducts(state.products.where((product) {
      return query.isEmpty ||
          product.title.toLowerCase().contains(query) ||
          product.category.toLowerCase().contains(query);
    }).toList());
    final drafts = state.products.where((product) => !product.published).length;
    final bulkMode = _selectedIds.isNotEmpty;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        automaticallyImplyLeading: !widget.embedded,
        title: Text(bulkMode ? '${_selectedIds.length} Selected' : 'My Catalog'),
        actions: bulkMode
            ? [
          IconButton(
            tooltip: 'Delete selected',
            onPressed: () => _bulkDelete(products),
            icon: const Icon(Icons.delete_outline_rounded),
          ),
          IconButton(
            tooltip: 'Sync prices',
            onPressed: () => _syncPrices(products),
            icon: const Icon(Icons.sync_rounded),
          ),
          IconButton(
            tooltip: 'Publish to ONDC',
            // FIX #1: was calling _publishOnmc (typo) which chained through
            // two more wrapper methods. Now calls _publishOndc directly.
            onPressed: () => _publishOndc(products),
            icon: const Icon(Icons.storefront_outlined),
          ),
        ]
            : [
          IconButton(
            tooltip: 'Share Catalog PDF',
            onPressed: _shareCatalog,
            icon: const Icon(Icons.picture_as_pdf_outlined),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 8),
              child: TextField(
                controller: _search,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Search products or categories',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: _listening
                            ? 'Stop voice search'
                            : 'Voice search',
                        onPressed: _voiceSearch,
                        icon: Icon(
                          _listening
                              ? Icons.mic_rounded
                              : Icons.mic_none_rounded,
                          color: _listening ? AppColors.clay : null,
                        ),
                      ),
                      PopupMenuButton<String>(
                        tooltip: 'Sort products',
                        icon: const Icon(Icons.tune_rounded),
                        onSelected: (value) => setState(() => _sort = value),
                        itemBuilder: (_) => const [
                          PopupMenuItem(
                            value: 'Newest',
                            child: Text('Newest'),
                          ),
                          PopupMenuItem(
                            value: 'Price (High to Low)',
                            child: Text('Price (High to Low)'),
                          ),
                          PopupMenuItem(
                            value: 'Price (Low to High)',
                            child: Text('Price (Low to High)'),
                          ),
                          PopupMenuItem(
                            value: 'Stock (Low to High)',
                            child: Text('Stock (Low to High)'),
                          ),
                        ],
                      ),
                    ],
                  ),
                  filled: true,
                  fillColor: colors.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(17),
                    borderSide:
                    BorderSide(color: colors.outline.withOpacity(.18)),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Row(
                children: [
                  _CountChip(
                    label: 'Live',
                    value: state.products.where((p) => p.published).length,
                    color: AppColors.forest,
                  ),
                  const SizedBox(width: 8),
                  _CountChip(
                    label: 'Drafts',
                    value: drafts,
                    color: AppColors.clay,
                  ),
                  const SizedBox(width: 8),
                  _CountChip(
                    label: 'Total',
                    value: state.products.length,
                    color: colors.onSurfaceVariant,
                  ),
                  const Spacer(),
                  Text(
                    _sort,
                    style: TextStyle(
                      fontSize: 10,
                      color: colors.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: products.isEmpty
                  ? _EmptyState(
                onCreate: () => Navigator.pushNamed(context, '/add'),
              )
                  : ListView.builder(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(0, 2, 0, 110),
                itemCount: products.length,
                itemBuilder: (context, index) => _CatalogProductCard(
                  product: products[index],
                  selected: _selectedIds.contains(products[index].id),
                  onLongPress: () => setState(
                        () => _toggleSelection(products[index].id),
                  ),
                  onSelect: (value) => setState(
                        () => value
                        ? _selectedIds.add(products[index].id)
                        : _selectedIds.remove(products[index].id),
                  ),
                  onTap: () {
                    if (bulkMode) {
                      setState(
                            () => _toggleSelection(products[index].id),
                      );
                    } else {
                      Navigator.pushNamed(
                        context,
                        '/product-detail',
                        arguments: products[index],
                      );
                    }
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CountChip extends StatelessWidget {
  const _CountChip(
      {required this.label, required this.value, required this.color});
  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding:
    const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
    decoration: BoxDecoration(
      color: color.withOpacity(.09),
      borderRadius: BorderRadius.circular(18),
    ),
    child: Text(
      '$label $value',
      style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w800,
        color: color,
      ),
    ),
  );
}

class _CatalogProductCard extends StatelessWidget {
  const _CatalogProductCard({
    required this.product,
    required this.selected,
    required this.onTap,
    required this.onLongPress,
    required this.onSelect,
  });
  final Product product;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final ValueChanged<bool> onSelect;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final lowStock = product.stock <= 1;
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 6, 18, 6),
      child: Material(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          onLongPress: onLongPress,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: selected
                    ? AppColors.forest
                    : colors.outline.withOpacity(.16),
              ),
            ),
            child: Row(
              children: [
                Stack(
                  children: [
                    _ProductImage(product: product),
                    if (selected)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.forest.withOpacity(.12),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Checkbox(
                            value: true,
                            onChanged: (_) => onSelect(false),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: colors.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        product.category,
                        style: TextStyle(
                          fontSize: 11,
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 7),
                      Text(
                        '₹${product.price}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: AppColors.clay,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${product.stock} in stock',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: lowStock
                              ? AppColors.clay
                              : colors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 7),
                      Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: _channelChips(product, colors),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _channelChips(Product product, ColorScheme colors) {
    final channels = product.marketplaceStatuses.keys.toList();
    if (channels.isEmpty && product.published) channels.add('ONDC');
    return channels.take(3).map((channel) {
      final color = channel.toLowerCase().contains('gem')
          ? const Color(0xFF3974B8)
          : channel.toLowerCase().contains('whatsapp')
          ? const Color(0xFF2E7D32)
          : AppColors.clay;
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: color.withOpacity(.10),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          channel,
          style: TextStyle(
            fontSize: 8,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
      );
    }).toList();
  }
}

class _ProductImage extends StatelessWidget {
  const _ProductImage({required this.product});
  final Product product;

  @override
  Widget build(BuildContext context) {
    final path = product.imagePath;
    if (path != null && path.isNotEmpty) {
      if (path.startsWith('assets/')) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: Image.asset(
            path,
            width: 78,
            height: 78,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _placeholder(),
          ),
        );
      }
      final file = File(path);
      if (file.existsSync()) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: Image.file(
            file,
            width: 78,
            height: 78,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _placeholder(),
          ),
        );
      }
    }
    return _placeholder();
  }

  Widget _placeholder() => Container(
    width: 78,
    height: 78,
    decoration: BoxDecoration(
      color: AppColors.saffron.withOpacity(.10),
      borderRadius: BorderRadius.circular(15),
      border: Border.all(color: AppColors.saffron.withOpacity(.25)),
    ),
    child: const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.camera_alt_outlined, color: AppColors.clay, size: 25),
        SizedBox(height: 3),
        Text(
          'Image Needed',
          style: TextStyle(
            fontSize: 8,
            fontWeight: FontWeight.w800,
            color: AppColors.clay,
          ),
        ),
      ],
    ),
  );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onCreate});
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 74,
            height: 74,
            decoration: BoxDecoration(
              color: AppColors.saffron.withOpacity(.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.edit_note_rounded,
              size: 34,
              color: AppColors.clay,
            ),
          ),
          const SizedBox(height: 15),
          const Text(
            'No drafts',
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          const Text(
            'Your unfinished listings will appear here',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.muted),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: onCreate,
            icon: const Icon(Icons.add_rounded),
            label: const Text(
              '+ Create New Product',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    ),
  );
}