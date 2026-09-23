import 'package:flutter/material.dart';

import '../services/app_state.dart';
import '../services/app_localization.dart';
import '../services/offline_request_queue.dart';
import '../theme.dart';
import '../widgets/ui.dart';
import 'ai_flow_screens.dart';
import 'catalog_screen.dart';

String _tr(BuildContext context, String key) {
  return AppLocalization.text(
    AppScope.of(context).language,
    key,
  );
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entrance;

  @override
  void initState() {
    super.initState();
    _entrance = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
  }

  @override
  void dispose() {
    _entrance.dispose();
    super.dispose();
  }

  void _openLanguage() => Navigator.pushNamed(context, '/language');

  void _openCatalog() => Navigator.pushNamed(context, '/catalog');

  void _openNotifications() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _NotificationCenter(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final products = state.products;
    final colors = Theme.of(context).colorScheme;
    final liveCount = products.where((product) => product.published).length;
    final reviewCount = products.where((product) => !product.published).length;

    return SafeArea(
      child: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 120),
        children: [
          _Entrance(
            animation: _entrance,
            begin: 0.0,
            child: Row(
              children: [
                const Expanded(child: _BrandHeader()),
                _HeaderIconButton(
                  label: _tr(context, 'language'),
                  child: const Text(
                    'A/अ',
                    style: TextStyle(
                      color: AppColors.forest,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  onTap: _openLanguage,
                ),
                const SizedBox(width: 7),
                _HeaderIconButton(
                  label: _tr(context, 'notifications'),
                  child: const Icon(
                    Icons.notifications_none_rounded,
                    color: AppColors.clay,
                    size: 22,
                  ),
                  onTap: _openNotifications,
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          _Entrance(
            animation: _entrance,
            begin: 0.10,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _tr(context, 'createProduct'),
                  style: TextStyle(
                    fontSize: 28,
                    height: 1.1,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.7,
                    color: colors.onSurface,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  _tr(context, 'createProductSteps'),
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.45,
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          _Entrance(
            animation: _entrance,
            begin: 0.20,
            child: _CreateProductCard(
              onTap: () => Navigator.pushNamed(context, '/add'),
            ),
          ),
          const SizedBox(height: 14),
          _Entrance(
            animation: _entrance,
            begin: 0.24,
            child: FutureBuilder<int>(
              future: OfflineRequestQueue.pendingCount(),
              builder: (context, snapshot) {
                final pendingSync = snapshot.data ?? 0;
                return _QuickStats(
                  liveCount: liveCount,
                  reviewCount: reviewCount,
                  pendingSync: pendingSync,
                );
              },
            ),
          ),
          const SizedBox(height: 24),
          _Entrance(
            animation: _entrance,
            begin: 0.30,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _tr(context, 'recentProducts'),
                    style: TextStyle(
                      color: colors.onSurface,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: _openCatalog,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.clay,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_tr(context, 'seeAll')),
                      const SizedBox(width: 3),
                      const Icon(Icons.arrow_forward_rounded, size: 15),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          if (products.isEmpty)
            const _EmptyProducts()
          else
            ...products.take(3).map(
                  (product) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: ProductTile(product: product),
              ),
            ),
        ],
      ),
    );
  }
}

class _QuickStats extends StatelessWidget {
  const _QuickStats({
    required this.liveCount,
    required this.reviewCount,
    required this.pendingSync,
  });

  final int liveCount;
  final int reviewCount;
  final int pendingSync;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: colors.outline.withOpacity(.18)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _QuickStat(
              icon: Icons.storefront_outlined,
              value: liveCount,
              label: _tr(context, 'active Listings'),
              accent: AppColors.forest,
            ),
          ),
          _Divider(),
          Expanded(
            child: _QuickStat(
              icon: Icons.rate_review_outlined,
              value: reviewCount,
              label: _tr(context, 'in Review/Draft'),
              accent: AppColors.clay,
            ),
          ),
          _Divider(),
          Expanded(
            child: _QuickStat(
              icon: Icons.sync_rounded,
              value: pendingSync,
              label: _tr(context, 'pending Sync'),
              accent: AppColors.saffron,
            ),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 35,
      color: Theme.of(context).colorScheme.outline.withOpacity(.18),
    );
  }
}

class _QuickStat extends StatelessWidget {
  const _QuickStat({
    required this.icon,
    required this.value,
    required this.label,
    required this.accent,
  });

  final IconData icon;
  final int value;
  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 19, color: accent),
        const SizedBox(height: 5),
        Text(
          '$value',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 8.5,
            height: 1.15,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _Entrance extends StatelessWidget {
  const _Entrance({
    required this.animation,
    required this.begin,
    required this.child,
  });

  final Animation<double> animation;
  final double begin;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final end = (begin + 0.55).clamp(0.0, 1.0).toDouble();
    final curved = CurvedAnimation(
      parent: animation,
      curve: Interval(begin, end, curve: Curves.easeOutCubic),
    );
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, .035),
          end: Offset.zero,
        ).animate(curved),
        child: child,
      ),
    );
  }
}

class _BrandHeader extends StatelessWidget {
  const _BrandHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'KarigarKart',
          style: TextStyle(
            color: Theme.of(context).colorScheme.primary,
            fontSize: 34,
            fontWeight: FontWeight.w800,
            letterSpacing: -.8,
            height: 1,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          _tr(context, 'localHandsGlobalHomes'),
          style: TextStyle(
            color: AppColors.clay,
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _CreateProductCard extends StatelessWidget {
  const _CreateProductCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.forest, Color(0xFF4D8B76)],
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppColors.forest.withOpacity(.18),
                blurRadius: 20,
                offset: const Offset(0, 9),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CircleAvatar(
                radius: 30,
                backgroundColor: Colors.white,
                child: Icon(
                  Icons.camera_alt_rounded,
                  color: AppColors.forest,
                  size: 30,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                _tr(context, 'startPhotoHeading'),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                _tr(context, 'thenSpeakAI'),
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 18),
              const Row(
                children: [
                  _StepDot(number: '1', label: 'photo'),
                  _StepLine(),
                  _StepDot(number: '2', label: 'voice'),
                  _StepLine(),
                  _StepDot(number: '3', label: 'review'),
                  _StepLine(),
                  _StepDot(number: '4', label: 'publish'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StepDot extends StatelessWidget {
  const _StepDot({required this.number, required this.label});

  final String number;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          CircleAvatar(
            radius: 15,
            backgroundColor: Colors.white.withOpacity(.18),
            child: Text(
              number,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            _tr(context, label),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 9,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _StepLine extends StatelessWidget {
  const _StepLine();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 1,
      margin: const EdgeInsets.only(bottom: 18),
      color: Colors.white.withOpacity(.35),
    );
  }
}

class _HeaderIconButton extends StatefulWidget {
  const _HeaderIconButton({
    required this.child,
    required this.onTap,
    required this.label,
  });

  final Widget child;
  final VoidCallback onTap;
  final String label;

  @override
  State<_HeaderIconButton> createState() => _HeaderIconButtonState();
}

class _HeaderIconButtonState extends State<_HeaderIconButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      label: widget.label,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapCancel: () => setState(() => _pressed = false),
        onTapUp: (_) {
          setState(() => _pressed = false);
          widget.onTap();
        },
        child: AnimatedScale(
          scale: _pressed ? .92 : 1,
          duration: const Duration(milliseconds: 100),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(13),
              border: Border.all(color: colors.outline),
            ),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

class _NotificationCenter extends StatelessWidget {
  const _NotificationCenter();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return SafeArea(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 22),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(28),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _tr(context, 'notifications'),
                    style: TextStyle(
                      color: colors.onSurface,
                      fontSize: 21,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(_tr(context, 'close')),
                ),
              ],
            ),
            _NotificationRow(
              icon: Icons.shopping_bag_outlined,
              title: _tr(context, 'newOrder'),
              message: _tr(context, 'newOrderMessage'),
              time: _tr(context, 'justNow'),
            ),
            _NotificationRow(
              icon: Icons.auto_awesome,
              title: _tr(context, 'pricingSuggestion'),
              message: _tr(context, 'pricingAssistantRecommendation'),
              time: _tr(context, 'oneHourAgo'),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationRow extends StatelessWidget {
  const _NotificationRow({
    required this.icon,
    required this.title,
    required this.message,
    required this.time,
  });

  final IconData icon;
  final String title;
  final String message;
  final String time;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surfaceVariant,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: colors.outline),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppColors.clay),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: colors.onSurface,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  message,
                  style: TextStyle(
                    color: colors.onSurfaceVariant,
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  time,
                  style: const TextStyle(
                    color: AppColors.forest,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
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

class _EmptyProducts extends StatelessWidget {
  const _EmptyProducts();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.surfaceVariant,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.outline),
      ),
      child: Column(
        children: [
          Icon(
            Icons.inventory_2_outlined,
            color: colors.onSurfaceVariant,
            size: 28,
          ),
          const SizedBox(height: 8),
          Text(
            _tr(context, 'noProductsYet'),
            style: TextStyle(
              color: colors.onSurface,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            _tr(context, 'addFirstProduct'),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colors.onSurfaceVariant,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}