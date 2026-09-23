import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../models/product.dart';
import '../services/app_state.dart';
import '../services/app_transitions.dart';
import '../services/marketplace_export_service.dart';
import '../theme.dart';

class MarketLinkageScreen extends StatefulWidget {
  const MarketLinkageScreen({super.key});

  @override
  State<MarketLinkageScreen> createState() => _MarketLinkageScreenState();
}

class _MarketLinkageScreenState extends State<MarketLinkageScreen>
    with SingleTickerProviderStateMixin {
  final FlutterTts _tts = FlutterTts();
  late final AnimationController _successController;

  String? _busyMarketplace;
  String? _successMarketplace;
  Timer? _successTimer;

  @override
  void initState() {
    super.initState();
    _successController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _configureTts();
  }

  Future<void> _configureTts() async {
    try {
      await _tts.setLanguage('en-IN');
      await _tts.setSpeechRate(.46);
      await _tts.setVolume(.9);
      await _tts.setPitch(1.0);
    } catch (_) {
      // Voice guidance is an accessibility enhancement. The screen remains
      // fully usable if the device has no configured TTS engine.
    }
  }

  Future<void> _speak(String message) async {
    try {
      await _tts.stop();
      await _tts.speak(message);
    } catch (_) {}
  }

  @override
  void dispose() {
    _successTimer?.cancel();
    _successController.dispose();
    _tts.stop();
    super.dispose();
  }

  List<Product> get _products => AppScope.of(context).products;

  int get _stock => _products.fold<int>(0, (sum, p) => sum + p.stock);

  int get _published => _products.where((p) => p.published).length;

  int get _drafts => _products.where((p) => !p.published).length;

  Future<void> _export(String marketplace) async {
    if (_busyMarketplace != null) return;

    final state = AppScope.of(context);
    setState(() {
      _busyMarketplace = marketplace;
      _successMarketplace = null;
    });
    _successController.reset();

    await _speak('Preparing your $marketplace catalog. Please wait.');
    await Future.delayed(const Duration(milliseconds: 650));

    try {
      final json = MarketplaceExportService.buildCatalogJson(
        marketplace: marketplace,
        sellerName: state.profileName,
        businessName: state.businessName,
        products: List<Product>.from(state.products),
      );

      await Clipboard.setData(ClipboardData(text: json));
      if (!mounted) return;

      setState(() {
        _busyMarketplace = null;
        _successMarketplace = marketplace;
      });
      _successController.forward();
      _successTimer?.cancel();
      _successTimer = Timer(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() => _successMarketplace = null);
        }
      });

      await _speak('$marketplace catalog is ready. The structured catalog is copied.');

      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text('$marketplace catalog copied to clipboard'),
          ),
        );
    } catch (_) {
      if (!mounted) return;
      setState(() => _busyMarketplace = null);
      await _speak('Export could not be completed. Please try again.');
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text('Export could not be completed. Please try again.'),
          ),
        );
    }
  }

  Future<void> _publishDraft(Product product) async {
    if (product.published) return;

    final confirmed = await _confirm(
      title: 'Publish product?',
      message: 'This will move the draft into your published catalog.',
      confirmLabel: 'Publish',
      icon: Icons.publish_rounded,
    );
    if (!confirmed || !mounted) return;

    await _speak('Publishing ${product.title}.');
    product.published = true;
    AppScope.of(context).notifyListeners();

    if (!mounted) return;
    setState(() {});
    await Future.delayed(const Duration(milliseconds: 180));
    await _speak('${product.title} is now published.');
  }

  Future<void> _deleteDraft(Product product) async {
    if (product.published) return;

    final confirmed = await _confirm(
      title: 'Delete draft?',
      message: 'This draft will be removed from your catalog.',
      confirmLabel: 'Delete',
      icon: Icons.delete_outline_rounded,
      destructive: true,
    );
    if (!confirmed || !mounted) return;

    await _speak('Deleting draft ${product.title}.');
    final state = AppScope.of(context);
    state.products.removeWhere((item) => identical(item, product));
    state.notifyListeners();

    if (!mounted) return;
    await _speak('Draft deleted.');
    setState(() {});
  }

  Future<bool> _confirm({
    required String title,
    required String message,
    required String confirmLabel,
    required IconData icon,
    bool destructive = false,
  }) async {
    await _speak('$title $message');
    if (!mounted) return false;

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final colors = Theme.of(dialogContext).colorScheme;
        return AlertDialog(
          icon: Icon(icon, size: 34),
          title: Text(title),
          content: Text(message),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          actions: [
            SizedBox(
              height: 50,
              child: TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Cancel'),
              ),
            ),
            SizedBox(
              height: 50,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: destructive ? colors.error : colors.onSurface,
                  foregroundColor: destructive ? colors.onError : colors.surface,
                ),
                onPressed: () => Navigator.pop(dialogContext, true),
                child: Text(confirmLabel),
              ),
            ),
          ],
        );
      },
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final state = AppScope.of(context);
    final products = state.products;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        titleSpacing: 20,
        title: const Text(
          'Market Linkage',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
        ),
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          _IntroCard(colors: colors, onListen: () => _speak('Market Linkage helps you manage inventory and prepare your catalog for GeM, ONDC and e-Haat.')),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _MetricCard(icon: Icons.inventory_2_outlined, value: '$_stock', label: 'Stock')),
              const SizedBox(width: 10),
              Expanded(child: _MetricCard(icon: Icons.storefront_outlined, value: '$_published', label: 'Published')),
              const SizedBox(width: 10),
              Expanded(child: _MetricCard(icon: Icons.edit_note_rounded, value: '$_drafts', label: 'Drafts')),
            ],
          ),
          const SizedBox(height: 24),
          const _SectionTitle(icon: Icons.inventory_2_outlined, title: 'Digital Inventory'),
          const SizedBox(height: 10),
          if (products.isEmpty)
            _EmptyState(colors: colors)
          else
            ...products.map((product) => _InventoryCard(
                  product: product,
                  onPublish: product.published ? null : () => _publishDraft(product),
                  onDelete: product.published ? null : () => _deleteDraft(product),
                )),
          const SizedBox(height: 24),
          const _SectionTitle(icon: Icons.public_rounded, title: 'Marketplace Export'),
          const SizedBox(height: 6),
          Text(
            'Prepare a structured catalog package. It is copied to the clipboard for the marketplace onboarding/import step.',
            style: TextStyle(fontSize: 12, height: 1.45, color: colors.onSurfaceVariant),
          ),
          const SizedBox(height: 12),
          _MarketplaceButton(
            name: 'GeM',
            subtitle: 'Government e-Marketplace catalog',
            icon: Icons.account_balance_outlined,
            busy: _busyMarketplace == 'GeM',
            success: _successMarketplace == 'GeM',
            onTap: () => _export('GeM'),
          ),
          _MarketplaceButton(
            name: 'ONDC',
            subtitle: 'Open Network for Digital Commerce catalog',
            icon: Icons.hub_outlined,
            busy: _busyMarketplace == 'ONDC',
            success: _successMarketplace == 'ONDC',
            onTap: () => _export('ONDC'),
          ),
          _MarketplaceButton(
            name: 'e-Haat',
            subtitle: 'Digital artisan marketplace catalog',
            icon: Icons.language_rounded,
            busy: _busyMarketplace == 'e-Haat',
            success: _successMarketplace == 'e-Haat',
            onTap: () => _export('e-Haat'),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: colors.surfaceVariant.withOpacity(.45),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline_rounded, size: 18, color: colors.onSurfaceVariant),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    'The export is a structured catalog payload; it does not claim direct API submission to these marketplaces.',
                    style: TextStyle(fontSize: 11, height: 1.4, color: colors.onSurfaceVariant),
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

class _IntroCard extends StatelessWidget {
  const _IntroCard({required this.colors, required this.onListen});

  final ColorScheme colors;
  final VoidCallback onListen;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.forest.withOpacity(.12), AppColors.saffron.withOpacity(.12)],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: colors.outline.withOpacity(.16)),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.forest.withOpacity(.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.link_rounded, color: AppColors.forest, size: 28),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Text(
              'Manage stock, publish drafts and prepare marketplace catalogs in one place.',
              style: TextStyle(fontSize: 13, height: 1.4, color: colors.onSurface, fontWeight: FontWeight.w700),
            ),
          ),
          IconButton(
            tooltip: 'Listen',
            onPressed: onListen,
            icon: const Icon(Icons.volume_up_rounded),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.icon, required this.value, required this.label});

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 13),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: colors.outline.withOpacity(.16)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 21, color: AppColors.forest),
          const SizedBox(height: 7),
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: colors.onSurface)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: colors.onSurfaceVariant)),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 21, color: AppColors.clay),
        const SizedBox(width: 8),
        Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: colors.onSurface)),
      ],
    );
  }
}

class _InventoryCard extends StatefulWidget {
  const _InventoryCard({required this.product, this.onPublish, this.onDelete});

  final Product product;
  final VoidCallback? onPublish;
  final VoidCallback? onDelete;

  @override
  State<_InventoryCard> createState() => _InventoryCardState();
}

class _InventoryCardState extends State<_InventoryCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final published = widget.product.published;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: colors.surface,
        borderRadius: BorderRadius.circular(19),
        child: InkWell(
          borderRadius: BorderRadius.circular(19),
          onTapDown: (_) => setState(() => _pressed = true),
          onTapCancel: () => setState(() => _pressed = false),
          onTapUp: (_) => setState(() => _pressed = false),
          child: AnimatedScale(
            scale: _pressed ? .985 : 1,
            duration: const Duration(milliseconds: 100),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(19),
                border: Border.all(color: colors.outline.withOpacity(.16)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: widget.product.color.withOpacity(.13),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(Icons.inventory_2_outlined, color: widget.product.color),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.product.title.isEmpty ? 'Untitled draft' : widget.product.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: colors.onSurface)),
                        const SizedBox(height: 4),
                        Text('${widget.product.stock} in stock  •  ₹${widget.product.price}', style: TextStyle(fontSize: 11, color: colors.onSurfaceVariant)),
                        const SizedBox(height: 7),
                        _StatusPill(published: published),
                      ],
                    ),
                  ),
                  if (!published) ...[
                    IconButton(
                      tooltip: 'Publish draft',
                      onPressed: widget.onPublish,
                      icon: const Icon(Icons.publish_rounded),
                    ),
                    IconButton(
                      tooltip: 'Delete draft',
                      onPressed: widget.onDelete,
                      icon: Icon(Icons.delete_outline_rounded, color: colors.error),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.published});

  final bool published;

  @override
  Widget build(BuildContext context) {
    final color = published ? AppColors.forest : AppColors.clay;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(color: color.withOpacity(.10), borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(published ? Icons.check_circle_outline_rounded : Icons.edit_outlined, size: 13, color: color),
          const SizedBox(width: 4),
          Text(published ? 'Published' : 'Draft', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: color)),
        ],
      ),
    );
  }
}

class _MarketplaceButton extends StatefulWidget {
  const _MarketplaceButton({required this.name, required this.subtitle, required this.icon, required this.busy, required this.success, required this.onTap});

  final String name;
  final String subtitle;
  final IconData icon;
  final bool busy;
  final bool success;
  final VoidCallback onTap;

  @override
  State<_MarketplaceButton> createState() => _MarketplaceButtonState();
}

class _MarketplaceButtonState extends State<_MarketplaceButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapCancel: () => setState(() => _pressed = false),
        onTapUp: (_) {
          setState(() => _pressed = false);
          widget.onTap();
        },
        child: AnimatedScale(
          scale: _pressed ? .97 : 1,
          duration: const Duration(milliseconds: 110),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            constraints: const BoxConstraints(minHeight: 72),
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 11),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: widget.success ? AppColors.forest.withOpacity(.5) : colors.outline.withOpacity(.18)),
              boxShadow: [BoxShadow(color: colors.shadow.withOpacity(.04), blurRadius: 12, offset: const Offset(0, 5))],
            ),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(color: AppColors.forest.withOpacity(.10), borderRadius: BorderRadius.circular(14)),
                  child: Icon(widget.success ? Icons.check_rounded : widget.icon, color: AppColors.forest),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text(widget.name, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: colors.onSurface)),
                    const SizedBox(height: 3),
                    Text(widget.success ? 'Ready • copied' : widget.subtitle, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 10.5, color: colors.onSurfaceVariant)),
                  ]),
                ),
                const SizedBox(width: 8),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  child: widget.busy
                      ? const SizedBox(width: 23, height: 23, child: CircularProgressIndicator(strokeWidth: 2.5))
                      : widget.success
                          ? const Icon(Icons.check_circle_rounded, key: ValueKey('success'), color: AppColors.forest, size: 26)
                          : const Icon(Icons.arrow_forward_ios_rounded, key: ValueKey('arrow'), size: 17),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.colors});

  final ColorScheme colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: colors.surface, borderRadius: BorderRadius.circular(18), border: Border.all(color: colors.outline.withOpacity(.16))),
      child: Column(children: [
        Icon(Icons.inventory_2_outlined, size: 34, color: colors.onSurfaceVariant),
        const SizedBox(height: 9),
        Text('No products yet', style: TextStyle(fontWeight: FontWeight.w800, color: colors.onSurface)),
        const SizedBox(height: 4),
        Text('Add a product to start your digital inventory.', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: colors.onSurfaceVariant)),
      ]),
    );
  }
}
