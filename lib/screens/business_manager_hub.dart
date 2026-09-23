import 'package:flutter/material.dart';

import '../services/app_state.dart';
import '../theme.dart';
import '../widgets/milestone_celebration.dart';
import 'business_dashboard_enhanced_screen.dart';

class BusinessManagerHub extends StatefulWidget {
  const BusinessManagerHub({super.key});

  @override
  State<BusinessManagerHub> createState() => _BusinessManagerHubState();
}

class _BusinessManagerHubState extends State<BusinessManagerHub> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);

    return SafeArea(
      top: true,
      bottom: false,
      child: Column(
        children: [
          if (_tab == 0) const _SellerTierCard(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Theme.of(context)
                      .colorScheme
                      .outline
                      .withOpacity(.18),
                ),
              ),
              child: Row(
                children: [
                  _TabButton(
                    text: state.tr('Dashboard'),
                    active: _tab == 0,
                    onTap: () => setState(() => _tab = 0),
                  ),
                  _TabButton(
                    text: state.tr('Inquiries'),
                    active: _tab == 1,
                    onTap: () => setState(() => _tab = 1),
                  ),
                  _TabButton(
                    text: state.tr('Disputes'),
                    active: _tab == 2,
                    onTap: () => setState(() => _tab = 2),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: switch (_tab) {
              0 => const MilestoneCelebration(
                child: BusinessDashboardEnhancedScreen(),
              ),
              1 => const _InquiryTab(),
              _ => const _DisputeTab(),
            },
          ),
        ],
      ),
    );
  }
}

class _SellerTierCard extends StatelessWidget {
  const _SellerTierCard();

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final products = state.products.length;
    final progress = (products / 10).clamp(0.0, 1.0);

    final String tierKey = products >= 10
        ? 'Gold Artisan'
        : products >= 5
        ? 'Silver Artisan'
        : 'Bronze Artisan';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: AppColors.forest.withOpacity(.08),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.forest.withOpacity(.16)),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.workspace_premium_rounded,
              color: AppColors.forest,
              size: 28,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    state.tr(tierKey),
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 5),
                  LinearProgressIndicator(
                    value: progress,
                    minHeight: 6,
                    backgroundColor: Colors.white,
                    color: AppColors.forest,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$products / 10 ${state.tr('products toward Gold')}',
                    style: const TextStyle(
                      fontSize: 9,
                      color: AppColors.muted,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.text,
    required this.active,
    required this.onTap,
  });

  final String text;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: active ? AppColors.forest : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: active
                  ? Colors.white
                  : Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }
}

class _InquiryTab extends StatelessWidget {
  const _InquiryTab();

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);

    final inquiries = [
      ('FabIndia Sourcing', state.tr('40 Terracotta Planters requested')),
      ('Dilli Haat Retailer', state.tr('25 Indigo Block Print Stoles requested')),
      ('Crafts Council Buyer', state.tr('15 Cane Storage Baskets requested')),
    ];

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(18, 4, 18, 110),
      itemCount: inquiries.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        return Card(
          child: ListTile(
            contentPadding: const EdgeInsets.all(13),
            leading: const CircleAvatar(
              backgroundColor: AppColors.saffron,
              child: Icon(Icons.business_center_rounded, color: Colors.white),
            ),
            title: Text(
              inquiries[index].$1,
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 5),
              child: Text(inquiries[index].$2),
            ),
            trailing: FilledButton(
              onPressed: () {},
              child: Text(state.tr('Quote')),
            ),
          ),
        );
      },
    );
  }
}

class _DisputeTab extends StatefulWidget {
  const _DisputeTab();

  @override
  State<_DisputeTab> createState() => _DisputeTabState();
}

class _DisputeTabState extends State<_DisputeTab> {
  bool _uploaded = false;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 4, 18, 110),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.report_problem_outlined, color: AppColors.clay),
                    const SizedBox(width: 9),
                    Text(
                      state.tr('Disputes / Returns'),
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  state.tr(
                    'Buyer says the terracotta planters arrived damaged. Keep the dispatch evidence with this case.',
                  ),
                  style: const TextStyle(height: 1.4),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => setState(() => _uploaded = true),
                    icon: const Icon(Icons.video_camera_back_outlined),
                    label: Text(
                      _uploaded
                          ? state.tr('Packaging Video Added')
                          : state.tr('Upload Packaging Video'),
                    ),
                  ),
                ),
                if (_uploaded)
                  Padding(
                    padding: const EdgeInsets.only(top: 9),
                    child: Text(
                      state.tr('QC video is queued with the dispute record.'),
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.forest,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}