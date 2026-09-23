
import 'package:flutter/material.dart';
import '../models/product.dart';
import '../services/app_state.dart';
import '../services/app_localization.dart';
import '../theme.dart';
import '../widgets/ui.dart';
import '../services/app_transitions.dart';
import 'ai_flow_screens.dart';

String _tr(BuildContext context, String key) {
  return AppLocalization.text(
    AppScope.of(context).language,
    key,
  );
}


class CatalogScreen extends StatefulWidget {
  const CatalogScreen({
    super.key,
    this.embedded = false,
  });

  final bool embedded;

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  final TextEditingController searchController = TextEditingController();

  int selectedFilter = 0;

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  String tr(BuildContext context, String key) {
    return AppLocalization.text(
      AppScope.of(context).language,
      key,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final background = Theme.of(context).scaffoldBackgroundColor;

    final allProducts = AppScope.of(context).products;
    final searchText = searchController.text.trim().toLowerCase();

    final filteredProducts = allProducts.where((product) {
      final matchesSearch =
          searchText.isEmpty ||
              product.title.toLowerCase().contains(searchText) ||
              product.category.toLowerCase().contains(searchText);

      final matchesFilter = switch (selectedFilter) {
        1 => product.published,
        2 => !product.published,
        _ => true,
      };

      return matchesSearch && matchesFilter;
    }).toList();

    final liveCount = allProducts.where((p) => p.published).length;
    final draftCount = allProducts.where((p) => !p.published).length;

    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: Column(
          children: [
            // ================================================================
            // HEADER
            // ================================================================

            _FadeIn(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tr(context, 'myCatalog'),
                            style: TextStyle(
                              fontSize: 27,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.6,
                              color: colors.onSurface,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            tr(context, 'catalogSubtitle'),
                            style: TextStyle(
                              fontSize: 12,
                              color: colors.onSurfaceVariant,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 11,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.forest.withOpacity(.10),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.forest.withOpacity(.08),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.inventory_2_outlined,
                            size: 14,
                            color: AppColors.forest,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            '${allProducts.length}',
                            style: const TextStyle(
                              color: AppColors.forest,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 18),

            // ================================================================
            // SUMMARY STRIP
            // ================================================================

            _FadeIn(
              delay: 70,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 15,
                    vertical: 13,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: Theme.of(context).brightness == Brightness.dark
                          ? [
                        const Color(0xFF263A34),
                        const Color(0xFF352C25),
                      ]
                          : [
                        const Color(0xFFEAF3EF),
                        const Color(0xFFF6EBDD),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: colors.outline.withOpacity(.18),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _SummaryItem(
                          icon: Icons.storefront_outlined,
                          value: '$liveCount',
                          label: tr(context, 'live'),
                          color: AppColors.forest,
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 30,
                        color: colors.outline.withOpacity(.25),
                      ),
                      Expanded(
                        child: _SummaryItem(
                          icon: Icons.edit_note_rounded,
                          value: '$draftCount',
                          label: tr(context, 'drafts'),
                          color: AppColors.clay,
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 30,
                        color: colors.outline.withOpacity(.25),
                      ),
                      Expanded(
                        child: _SummaryItem(
                          icon: Icons.inventory_2_outlined,
                          value: '${allProducts.length}',
                          label: tr(context, 'total'),
                          color: colors.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 15),

            // ================================================================
            // SEARCH
            // ================================================================

            _FadeIn(
              delay: 120,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: TextField(
                  controller: searchController,
                  onChanged: (_) {
                    setState(() {});
                  },
                  decoration: InputDecoration(
                    hintText: tr(context, 'searchProducts'),
                    hintStyle: TextStyle(
                      fontSize: 13,
                      color: colors.onSurfaceVariant,
                    ),
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      color: colors.onSurfaceVariant,
                    ),
                    suffixIcon: searchController.text.isNotEmpty
                        ? IconButton(
                      tooltip: tr(context, 'clearSearch'),
                      icon: Icon(
                        Icons.close_rounded,
                        size: 19,
                        color: colors.onSurfaceVariant,
                      ),
                      onPressed: () {
                        searchController.clear();
                        setState(() {});
                      },
                    )
                        : null,
                    filled: true,
                    fillColor: colors.surface,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(17),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(17),
                      borderSide: BorderSide(
                        color: colors.outline.withOpacity(.20),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(17),
                      borderSide: const BorderSide(
                        color: AppColors.clay,
                        width: 1.3,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 13),

            // ================================================================
            // FILTERS
            // ================================================================

            _FadeIn(
              delay: 170,
              child: SizedBox(
                height: 40,
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  scrollDirection: Axis.horizontal,
                  children: [
                    _FilterChip(
                      label: tr(context, 'all'),
                      count: allProducts.length,
                      selected: selectedFilter == 0,
                      onTap: () {
                        setState(() {
                          selectedFilter = 0;
                        });
                      },
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: tr(context, 'live'),
                      count: liveCount,
                      selected: selectedFilter == 1,
                      onTap: () {
                        setState(() {
                          selectedFilter = 1;
                        });
                      },
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: tr(context, 'drafts'),
                      count: draftCount,
                      selected: selectedFilter == 2,
                      onTap: () {
                        setState(() {
                          selectedFilter = 2;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 10),

            // ================================================================
            // PRODUCT LIST
            // ================================================================

            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                child: filteredProducts.isEmpty
                    ? _EmptyCatalog(
                  key: ValueKey(
                    'empty-$selectedFilter-$searchText',
                  ),
                  hasSearch: searchText.isNotEmpty,
                  selectedFilter: selectedFilter,
                )
                    : ListView.builder(
                  key: ValueKey(
                    'products-$selectedFilter-$searchText',
                  ),
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.only(
                    top: 2,
                    bottom: 110,
                  ),
                  itemCount: filteredProducts.length,
                  itemBuilder: (context, index) {
                    return _FadeIn(
                      delay: index < 5 ? 50 + (index * 45) : 50,
                      child: ProductTile(
                        product: filteredProducts[index],
                      ),
                    );
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

// ============================================================================
// SUMMARY ITEM
// ============================================================================

class _SummaryItem extends StatelessWidget {
  const _SummaryItem({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          icon,
          size: 17,
          color: color,
        ),
        const SizedBox(width: 7),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 9,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ============================================================================
// FILTER CHIP
// ============================================================================

class _FilterChip extends StatefulWidget {
  const _FilterChip({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_FilterChip> createState() => _FilterChipState();
}

class _FilterChipState extends State<_FilterChip> {
  bool pressed = false;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return GestureDetector(
      onTapDown: (_) {
        setState(() {
          pressed = true;
        });
      },
      onTapCancel: () {
        setState(() {
          pressed = false;
        });
      },
      onTapUp: (_) {
        setState(() {
          pressed = false;
        });
        widget.onTap();
      },
      child: AnimatedScale(
        scale: pressed ? .96 : 1,
        duration: const Duration(milliseconds: 100),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsets.symmetric(
            horizontal: 15,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            color: widget.selected
                ? colors.onSurface
                : colors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: widget.selected
                  ? colors.onSurface
                  : colors.outline.withOpacity(.20),
            ),
            boxShadow: widget.selected
                ? [
              BoxShadow(
                color: colors.shadow.withOpacity(.10),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.label,
                style: TextStyle(
                  color: widget.selected
                      ? colors.surface
                      : colors.onSurface,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '${widget.count}',
                style: TextStyle(
                  color: widget.selected
                      ? colors.surface.withOpacity(.75)
                      : colors.onSurfaceVariant,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// PRODUCT IMAGE MAPPING
// ============================================================================

String? productAssetPath(Product product) {
  switch (product.id) {
    case '1':
      return 'assets/s1.png';
    case '2':
      return 'assets/s2.png';
    case '3':
      return 'assets/s3.png';
    default:
      return null;
  }
}

class _ProductImage extends StatelessWidget {
  const _ProductImage({
    required this.product,
    required this.size,
  });

  final Product product;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final assetPath = productAssetPath(product);

    if (assetPath == null) {
      return ProductVisual(
        color: product.color,
        size: size,
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(size * .18),
      child: Container(
        width: size,
        height: size,
        color: colors.surfaceVariant,
        child: Image.asset(
          assetPath,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return ProductVisual(
              color: product.color,
              size: size,
            );
          },
        ),
      ),
    );
  }
}

// ============================================================================
// PRODUCT TILE
// ============================================================================

class ProductTile extends StatelessWidget {
  const ProductTile({
    super.key,
    required this.product,
  });

  final Product product;

  String tr(BuildContext context, String key) {
    return AppLocalization.text(
      AppScope.of(context).language,
      key,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 6),
      child: Material(
        color: colors.surface,
        borderRadius: BorderRadius.circular(21),
        child: InkWell(
          borderRadius: BorderRadius.circular(21),
          onTap: () {
            Navigator.push(
              context,
              KarigarDetailRoute(
                builder: (_) => ProductDetailsScreen(
                  product: product,
                ),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(21),
              border: Border.all(
                color: colors.outline.withOpacity(.16),
              ),
              boxShadow: [
                BoxShadow(
                  color: colors.shadow.withOpacity(.035),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                Hero(
                  tag: 'product-image-${product.id}',
                  child: _ProductImage(
                    product: product,
                    size: 86,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 15,
                          height: 1.2,
                          fontWeight: FontWeight.w800,
                          color: colors.onSurface,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        product.category,
                        style: TextStyle(
                          fontSize: 12,
                          color: colors.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Text(
                            '',
                          ),
                          Text(
                            '₹${product.price}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: AppColors.clay,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            width: 3,
                            height: 3,
                            decoration: BoxDecoration(
                              color: colors.onSurfaceVariant,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Flexible(
                            child: Text(
                              '${product.stock} ${tr(context, 'inStock')}',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11,
                                color: colors.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _StatusBadge(
                      published: product.published,
                    ),
                    const SizedBox(height: 12),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: colors.onSurfaceVariant,
                      size: 20,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// STATUS BADGE
// ============================================================================

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({
    required this.published,
  });

  final bool published;

  String tr(BuildContext context, String key) {
    return AppLocalization.text(
      AppScope.of(context).language,
      key,
    );
  }

  @override
  Widget build(BuildContext context) {
    final background = published
        ? AppColors.forest.withOpacity(.10)
        : AppColors.saffron.withOpacity(.18);

    final foreground = published
        ? AppColors.forest
        : AppColors.clay;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            published
                ? Icons.check_circle_outline_rounded
                : Icons.edit_outlined,
            size: 12,
            color: foreground,
          ),
          const SizedBox(width: 4),
          Text(
            published
                ? tr(context, 'live')
                : tr(context, 'draft'),
            style: TextStyle(
              color: foreground,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// EMPTY CATALOG
// ============================================================================

class _EmptyCatalog extends StatelessWidget {
  const _EmptyCatalog({
    super.key,
    required this.hasSearch,
    required this.selectedFilter,
  });

  final bool hasSearch;
  final int selectedFilter;

  String tr(BuildContext context, String key) {
    return AppLocalization.text(
      AppScope.of(context).language,
      key,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    String title;
    String subtitle;
    IconData icon;

    if (hasSearch) {
      title = tr(context, 'noProductsFound');
      subtitle = tr(context, 'tryAnotherSearch');
      icon = Icons.search_off_rounded;
    } else if (selectedFilter == 1) {
      title = tr(context, 'noLiveProducts');
      subtitle = tr(context, 'publishedProducts');
      icon = Icons.storefront_outlined;
    } else if (selectedFilter == 2) {
      title = tr(context, 'noDrafts');
      subtitle = tr(context, 'unfinishedListings');
      icon = Icons.edit_note_rounded;
    } else {
      title = tr(context, 'catalogWaiting');
      subtitle = tr(context, 'addFirstProduct');
      icon = Icons.inventory_2_outlined;
    }

    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 78,
                height: 78,
                decoration: BoxDecoration(
                  color: AppColors.saffron.withOpacity(.15),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.saffron.withOpacity(.12),
                  ),
                ),
                child: Icon(
                  icon,
                  size: 32,
                  color: AppColors.clay,
                ),
              ),
              const SizedBox(height: 17),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: colors.onSurface,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  height: 1.45,
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// PRODUCT DETAILS
// ============================================================================

class ProductDetailsScreen extends StatelessWidget {
  const ProductDetailsScreen({
    super.key,
    required this.product,
  });

  final Product product;

  String tr(BuildContext context, String key) {
    return AppLocalization.text(
      AppScope.of(context).language,
      key,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final background = Theme.of(context).scaffoldBackgroundColor;

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        elevation: 0,
        centerTitle: false,
        title: Text(
          tr(context, 'productDetails'),
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w800,
            color: colors.onSurface,
          ),
        ),
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 30),
        children: [
          // ================================================================
          // PRODUCT PREVIEW
          // ================================================================

          _FadeIn(
            child: Container(
              height: 275,
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(26),
                border: Border.all(
                  color: colors.outline.withOpacity(.16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: colors.shadow.withOpacity(.04),
                    blurRadius: 18,
                    offset: const Offset(0, 7),
                  ),
                ],
              ),
              child: Center(
                child: Hero(
                  tag: 'product-image-${product.id}',
                  child: _ProductImage(
                    product: product,
                    size: 215,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 22),

          _FadeIn(
            delay: 70,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.title,
                        style: TextStyle(
                          fontSize: 25,
                          height: 1.15,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -.5,
                          color: colors.onSurface,
                        ),
                      ),
                      const SizedBox(height: 7),
                      Text(
                        product.category,
                        style: TextStyle(
                          fontSize: 13,
                          color: colors.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                _StatusBadge(
                  published: product.published,
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          _FadeIn(
            delay: 110,
            child: Text(
              '₹${product.price}',
              style: const TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.w800,
                color: AppColors.clay,
              ),
            ),
          ),

          const SizedBox(height: 22),

          _FadeIn(
            delay: 150,
            child: Row(
              children: [
                Expanded(
                  child: _InfoCard(
                    icon: Icons.inventory_2_outlined,
                    label: tr(context, 'stock'),
                    value:
                    '${product.stock} ${tr(context, 'available')}',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _InfoCard(
                    icon: Icons.category_outlined,
                    label: tr(context, 'category'),
                    value: product.category,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          _FadeIn(
            delay: 190,
            child: Text(
              tr(context, 'aboutCraft'),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: colors.onSurface,
              ),
            ),
          ),

          const SizedBox(height: 9),

          _FadeIn(
            delay: 220,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: colors.outline.withOpacity(.16),
                ),
              ),
              child: Text(
                product.description,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.55,
                  color: colors.onSurfaceVariant,
                ),
              ),
            ),
          ),

          const SizedBox(height: 28),

          _FadeIn(
            delay: 260,
            child: SizedBox(
              height: 55,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: colors.onSurface,
                  foregroundColor: colors.surface,
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ListingScreen(),
                    ),
                  );
                },
                icon: const Icon(
                  Icons.edit_outlined,
                  size: 19,
                ),
                label: Text(
                  tr(context, 'editListing'),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          _FadeIn(
            delay: 300,
            child: SizedBox(
              height: 50,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: colors.onSurface,
                  side: BorderSide(
                    color: colors.outline.withOpacity(.35),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text(
                  tr(context, 'backToCatalog'),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// INFORMATION CARD
// ============================================================================

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: colors.outline.withOpacity(.16),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.forest.withOpacity(.10),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(
              icon,
              size: 18,
              color: AppColors.forest,
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    color: colors.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: colors.onSurface,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// FADE + SLIDE ANIMATION
// ============================================================================

class _FadeIn extends StatefulWidget {
  const _FadeIn({
    required this.child,
    this.delay = 0,
  });

  final Widget child;
  final int delay;

  @override
  State<_FadeIn> createState() => _FadeInState();
}

class _FadeInState extends State<_FadeIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _position;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );

    _opacity = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );

    _position = Tween<Offset>(
      begin: const Offset(0, .035),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ),
    );

    Future.delayed(
      Duration(milliseconds: widget.delay),
          () {
        if (mounted) {
          _controller.forward();
        }
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(
        position: _position,
        child: widget.child,
      ),
    );
  }
}
