import 'package:flutter/material.dart';

import '../theme.dart';

class DraftProductsScreen extends StatefulWidget {
  const DraftProductsScreen({
    super.key,
    this.initialDraftCount = 2,
  });

  final int initialDraftCount;

  @override
  State<DraftProductsScreen> createState() => _DraftProductsScreenState();
}

class _DraftProductsScreenState extends State<DraftProductsScreen> {
  late List<_DraftProduct> drafts;

  @override
  void initState() {
    super.initState();

    drafts = [
      _DraftProduct(
        id: 'draft_flower_vase',
        title: 'Handcrafted Flower Vase',
        category: 'Home Decor',
        description:
        'A handcrafted decorative flower vase made by skilled artisans. '
            'Suitable for home decoration, gifting and traditional interiors.',
        price: 799,
        stock: 5,
        icon: Icons.local_florist_rounded,
      ),
      _DraftProduct(
        id: 'draft_wooden_box',
        title: 'Handcrafted Wooden Box',
        category: 'Woodcraft',
        description:
        'A beautifully handcrafted wooden storage box designed for '
            'keeping jewellery, accessories and other small items.',
        price: 999,
        stock: 4,
        icon: Icons.inventory_2_rounded,
      ),
    ];
  }

  Future<void> _openDraft(_DraftProduct draft) async {
    final published = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => DraftProductDetailsScreen(
          draft: draft,
        ),
      ),
    );

    if (published == true && mounted) {
      setState(() {
        drafts.removeWhere((item) => item.id == draft.id);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Product published successfully.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        centerTitle: false,
        title: const Text(
          'Draft Products',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            Navigator.pop(context, drafts.length);
          },
        ),
      ),
      body: drafts.isEmpty
          ? _buildEmptyState(colors)
          : ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 30),
        children: [
          _buildHeader(colors),

          const SizedBox(height: 18),

          ...drafts.map(
                (draft) => _DraftTile(
              draft: draft,
              onTap: () => _openDraft(draft),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(ColorScheme colors) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.clay.withOpacity(.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.clay.withOpacity(.16),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.clay.withOpacity(.14),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.edit_note_rounded,
              color: AppColors.clay,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${drafts.length} Draft${drafts.length == 1 ? '' : 's'}',
                  style: TextStyle(
                    color: colors.onSurface,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Complete your product details before publishing.',
                  style: TextStyle(
                    color: colors.onSurfaceVariant,
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ColorScheme colors) {
    return Center(
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
              ),
              child: const Icon(
                Icons.check_circle_outline_rounded,
                size: 38,
                color: AppColors.forest,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'No Drafts',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: colors.onSurface,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              'All your products have been published.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


// ============================================================================
// DRAFT PRODUCT
// ============================================================================

class _DraftProduct {
  _DraftProduct({
    required this.id,
    required this.title,
    required this.category,
    required this.description,
    required this.price,
    required this.stock,
    required this.icon,
  });

  final String id;

  String title;
  String category;
  String description;
  double price;
  int stock;

  final IconData icon;
}


// ============================================================================
// DRAFT TILE
// ============================================================================

class _DraftTile extends StatelessWidget {
  const _DraftTile({
    required this.draft,
    required this.onTap,
  });

  final _DraftProduct draft;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: colors.surface,
        borderRadius: BorderRadius.circular(21),
        child: InkWell(
          borderRadius: BorderRadius.circular(21),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(21),
              border: Border.all(
                color: colors.outline.withOpacity(.16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 78,
                  height: 78,
                  decoration: BoxDecoration(
                    color: AppColors.saffron.withOpacity(.13),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    draft.icon,
                    size: 38,
                    color: AppColors.clay,
                  ),
                ),

                const SizedBox(width: 14),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        draft.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: colors.onSurface,
                        ),
                      ),

                      const SizedBox(height: 5),

                      Text(
                        draft.category,
                        style: TextStyle(
                          fontSize: 12,
                          color: colors.onSurfaceVariant,
                        ),
                      ),

                      const SizedBox(height: 9),

                      Row(
                        children: [
                          const Icon(
                            Icons.edit_note_rounded,
                            size: 15,
                            color: AppColors.clay,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            'Draft',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.clay,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const Icon(
                  Icons.chevron_right_rounded,
                  size: 23,
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
// DRAFT DETAILS
// ============================================================================

class DraftProductDetailsScreen extends StatefulWidget {
  const DraftProductDetailsScreen({
    super.key,
    required this.draft,
  });

  final _DraftProduct draft;

  @override
  State<DraftProductDetailsScreen> createState() =>
      _DraftProductDetailsScreenState();
}

class _DraftProductDetailsScreenState
    extends State<DraftProductDetailsScreen> {
  Future<void> _editDraft() async {
    final titleController = TextEditingController(
      text: widget.draft.title,
    );

    final categoryController = TextEditingController(
      text: widget.draft.category,
    );

    final priceController = TextEditingController(
      text: widget.draft.price.toStringAsFixed(0),
    );

    final stockController = TextEditingController(
      text: widget.draft.stock.toString(),
    );

    final descriptionController = TextEditingController(
      text: widget.draft.description,
    );

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(25),
        ),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade400,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                const Text(
                  'Edit Draft',
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                  ),
                ),

                const SizedBox(height: 18),

                _EditField(
                  controller: titleController,
                  label: 'Product name',
                  icon: Icons.inventory_2_outlined,
                ),

                const SizedBox(height: 12),

                _EditField(
                  controller: categoryController,
                  label: 'Category',
                  icon: Icons.category_outlined,
                ),

                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: _EditField(
                        controller: priceController,
                        label: 'Price',
                        icon: Icons.currency_rupee_rounded,
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _EditField(
                        controller: stockController,
                        label: 'Stock',
                        icon: Icons.inventory_2_outlined,
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                _EditField(
                  controller: descriptionController,
                  label: 'Description',
                  icon: Icons.description_outlined,
                  maxLines: 4,
                ),

                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.forest,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    onPressed: () {
                      final price =
                      double.tryParse(priceController.text.trim());

                      final stock =
                      int.tryParse(stockController.text.trim());

                      if (titleController.text.trim().isEmpty ||
                          categoryController.text.trim().isEmpty ||
                          price == null ||
                          stock == null) {
                        ScaffoldMessenger.of(sheetContext).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Please enter valid product details.',
                            ),
                          ),
                        );
                        return;
                      }

                      widget.draft.title =
                          titleController.text.trim();

                      widget.draft.category =
                          categoryController.text.trim();

                      widget.draft.price = price;

                      widget.draft.stock = stock;

                      widget.draft.description =
                          descriptionController.text.trim();

                      Navigator.pop(sheetContext, true);
                    },
                    child: const Text(
                      'Save Changes',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    titleController.dispose();
    categoryController.dispose();
    priceController.dispose();
    stockController.dispose();
    descriptionController.dispose();

    if (saved == true && mounted) {
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Draft updated successfully.'),
        ),
      );
    }
  }

  Future<void> _publishDraft() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Publish product?'),
          content: Text(
            'Are you sure you want to publish "${widget.draft.title}"?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.forest,
              ),
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Publish'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        title: const Text(
          'Draft Details',
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              children: [
                Container(
                  height: 250,
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(
                      color: colors.outline.withOpacity(.16),
                    ),
                  ),
                  child: Center(
                    child: Container(
                      width: 155,
                      height: 155,
                      decoration: BoxDecoration(
                        color: AppColors.saffron.withOpacity(.13),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Icon(
                        widget.draft.icon,
                        size: 80,
                        color: AppColors.clay,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 22),

                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        widget.draft.title,
                        style: TextStyle(
                          fontSize: 24,
                          height: 1.15,
                          fontWeight: FontWeight.w800,
                          color: colors.onSurface,
                        ),
                      ),
                    ),

                    const SizedBox(width: 10),

                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.saffron.withOpacity(.18),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'DRAFT',
                        style: TextStyle(
                          color: AppColors.clay,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 7),

                Text(
                  widget.draft.category,
                  style: TextStyle(
                    fontSize: 13,
                    color: colors.onSurfaceVariant,
                  ),
                ),

                const SizedBox(height: 15),

                Text(
                  '₹${widget.draft.price.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.w800,
                    color: AppColors.clay,
                  ),
                ),

                const SizedBox(height: 20),

                Row(
                  children: [
                    Expanded(
                      child: _InfoBox(
                        icon: Icons.inventory_2_outlined,
                        label: 'Stock',
                        value: '${widget.draft.stock}',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _InfoBox(
                        icon: Icons.category_outlined,
                        label: 'Category',
                        value: widget.draft.category,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 25),

                Text(
                  'About this product',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: colors.onSurface,
                  ),
                ),

                const SizedBox(height: 10),

                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: colors.outline.withOpacity(.16),
                    ),
                  ),
                  child: Text(
                    widget.draft.description,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.55,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),

          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
              decoration: BoxDecoration(
                color: colors.surface,
                border: Border(
                  top: BorderSide(
                    color: colors.outline.withOpacity(.14),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _editDraft,
                      icon: const Icon(
                        Icons.edit_outlined,
                        size: 18,
                      ),
                      label: const Text('Edit'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 52),
                        foregroundColor: colors.onSurface,
                        side: BorderSide(
                          color: colors.outline.withOpacity(.35),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _publishDraft,
                      icon: const Icon(
                        Icons.publish_rounded,
                        size: 18,
                      ),
                      label: const Text('Publish'),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(0, 52),
                        backgroundColor: AppColors.forest,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}


// ============================================================================
// EDIT FIELD
// ============================================================================

class _EditField extends StatelessWidget {
  const _EditField({
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboardType,
    this.maxLines = 1,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType? keyboardType;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: Theme.of(context)
                .colorScheme
                .outline
                .withOpacity(.18),
          ),
        ),
      ),
    );
  }
}


// ============================================================================
// INFO BOX
// ============================================================================

class _InfoBox extends StatelessWidget {
  const _InfoBox({
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
          Icon(
            icon,
            size: 19,
            color: AppColors.forest,
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
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: colors.onSurface,
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