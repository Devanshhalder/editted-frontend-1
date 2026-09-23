import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../services/app_state.dart';
import '../services/business_report_service.dart';
import '../theme.dart';

class BusinessDashboardEnhancedScreen extends StatefulWidget {
  const BusinessDashboardEnhancedScreen({super.key});

  @override
  State<BusinessDashboardEnhancedScreen> createState() =>
      _BusinessDashboardEnhancedScreenState();
}

class _BusinessDashboardEnhancedScreenState
    extends State<BusinessDashboardEnhancedScreen>
    with SingleTickerProviderStateMixin {
  int _period = 1;
  late final AnimationController _chartAnimation;
  final FlutterTts _tts = FlutterTts();

  static const _weeklySales = [
    [2200.0, 3400.0, 2900.0, 5100.0, 4300.0, 6800.0, 10540.0],
    [4200.0, 6100.0, 5200.0, 7900.0, 6800.0, 9300.0, 13980.0],
    [9800.0, 12400.0, 10800.0, 15100.0, 13200.0, 17400.0, 21100.0],
  ];
  static const _periodLabels = [
    ['6AM', '9AM', '12', '3PM', '6PM', '9PM', 'Now'],
    ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
    ['W1', 'W2', 'W3', 'W4', 'W5', '', ''],
  ];

  @override
  void initState() {
    super.initState();
    _chartAnimation = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
  }

  @override
  void dispose() {
    _chartAnimation.dispose();
    _tts.stop();
    super.dispose();
  }

  void _changePeriod(int value) {
    setState(() => _period = value);
    _chartAnimation
      ..reset()
      ..forward();
  }

  Future<void> _speakAdvice(String text) async {
    await _tts.setLanguage('hi-IN');
    await _tts.setSpeechRate(.43);
    await _tts.speak(text);
  }

  Future<void> _exportIncomeReport() async {
    final state = AppScope.of(context);
    try {
      final file = await BusinessReportService.createMonthlySalesReport(
        artisanName: state.profileName,
        businessName: state.businessName,
        pehchanId: state.pehchanId,
        products: state.products,
      );
      await BusinessReportService.shareFile(
        file,
        title: 'KarigarKart Monthly Income & Sales Report',
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not create the report: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final colors = Theme.of(context).colorScheme;
    final products = state.products;

    // Explicitly cast to num to prevent dynamic type closure errors
    final inventory = products
        .fold<num>(
        0,
            (sum, product) =>
        sum + ((product.price as num) * (product.stock as num)))
        .round();

    final lowStock = products.where((product) => product.stock <= 3).length;
    final views = products.length * 137 + products.take(5).length * 29;
    final orders =
    products.isEmpty ? 0 : products.length * 3 + products.take(5).length;
    final conversion =
    views == 0 ? 0.0 : (orders / views * 100).clamp(0.0, 99.9);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.forest,
          onRefresh: () async {
            _chartAnimation
              ..reset()
              ..forward();
            await Future<void>.delayed(const Duration(milliseconds: 350));
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 110),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Business Dashboard',
                          style: TextStyle(
                            color: AppColors.forest,
                            fontSize: 25,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Your virtual business manager',
                          style: TextStyle(
                            color: colors.onSurfaceVariant,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Export monthly income report',
                    onPressed: _exportIncomeReport,
                    icon: const Icon(Icons.picture_as_pdf_outlined),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _PeriodSelector(
                selected: _period,
                onChanged: _changePeriod,
              ),
              const SizedBox(height: 14),
              _SalesHero(
                data: _weeklySales[_period],
                total: [10540, 13980, 87100][_period],
                growth: [12, 18, 24][_period],
                animation: _chartAnimation,
              ),
              const SizedBox(height: 14),
              _AdvisorCard(onSpeak: _speakAdvice),
              const SizedBox(height: 14),
              _MetricGrid(
                products: products.length,
                inventory: inventory,
                lowStock: lowStock,
                views: views,
                orders: orders,
                conversion: conversion,
              ),
              const SizedBox(height: 20),
              const _SectionTitle(
                title: 'Sales trend',
                subtitle: 'Touch a point to see the exact period figure',
              ),
              const SizedBox(height: 10),
              _InteractiveSalesChart(
                data: _weeklySales[_period],
                labels: _periodLabels[_period],
                animation: _chartAnimation,
              ),
              const SizedBox(height: 20),
              const _SectionTitle(
                title: 'Channel breakdown',
                subtitle: 'Digital, physical fair and direct sales',
              ),
              const SizedBox(height: 10),
              const _ChannelBreakdown(),
              const SizedBox(height: 14),
              const _SettlementCard(),
              const SizedBox(height: 14),
              const _WholesalePipeline(),
              const SizedBox(height: 20),
              const _SectionTitle(
                title: 'Product performance',
                subtitle: 'Inventory value and stock position',
              ),
              const SizedBox(height: 10),
              _ProductPerformance(products: products),
            ],
          ),
        ),
      ),
    );
  }
}

class _PeriodSelector extends StatelessWidget {
  const _PeriodSelector({required this.selected, required this.onChanged});
  final int selected;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    const labels = ['Today', 'This Week', 'This Month'];
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: Theme.of(context).colorScheme.outline.withOpacity(.2)),
      ),
      child: Row(
        children: List.generate(labels.length, (index) {
          final active = index == selected;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: active ? AppColors.forest : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  labels[index],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: active
                        ? Colors.white
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _SalesHero extends StatelessWidget {
  const _SalesHero(
      {required this.data,
        required this.total,
        required this.growth,
        required this.animation});
  final List<double> data;
  final int total;
  final int growth;
  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.forest, Color(0xFF4D8B76)],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Revenue & Net Profit • This Week',
                  style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w700),
                ),
              ),
              Text('+$growth%',
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w900)),
            ],
          ),
          const SizedBox(height: 4),
          Text('₹$total',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.w900)),
          const SizedBox(height: 10),
          SizedBox(
            height: 105,
            child: AnimatedBuilder(
              animation: animation,
              builder: (context, _) => LineChart(
                LineChartData(
                  minX: 0,
                  maxX: 6,
                  minY: 0,
                  maxY: data.reduce((a, b) => a > b ? a : b) * 1.2,
                  gridData: FlGridData(show: false), // Removed const
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(show: false), // Removed const
                  lineTouchData: LineTouchData(enabled: false), // Removed const
                  lineBarsData: [
                    LineChartBarData(
                      spots: List.generate(
                          data.length,
                              (i) => FlSpot(
                              i.toDouble(), data[i] * animation.value)),
                      isCurved: true,
                      color: Colors.white,
                      barWidth: 3,
                      dotData: FlDotData(show: false), // Removed const
                      belowBarData:
                      BarAreaData(show: true, color: Colors.white12),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AdvisorCard extends StatelessWidget {
  const _AdvisorCard({required this.onSpeak});
  final Future<void> Function(String) onSpeak;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    const advice =
        'Festive surge: Terracotta planters are trending 35% higher this week on ONDC. Prepare 8 more units.';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.saffron.withOpacity(.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.saffron.withOpacity(.28)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
                color: AppColors.forest.withOpacity(.10),
                shape: BoxShape.circle),
            child: const Icon(Icons.auto_awesome_rounded,
                color: AppColors.forest),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Vyapar Salahkar',
                    style: TextStyle(
                        color: colors.onSurface,
                        fontSize: 15,
                        fontWeight: FontWeight.w900)),
                const SizedBox(height: 5),
                Text(advice,
                    style: TextStyle(
                        color: colors.onSurfaceVariant,
                        fontSize: 12,
                        height: 1.4)),
                const SizedBox(height: 9),
                Row(
                  children: [
                    TextButton.icon(
                      onPressed: () => onSpeak(advice),
                      icon: const Icon(Icons.volume_up_rounded, size: 17),
                      label: const Text('Listen in Hindi'),
                    ),
                    const SizedBox(width: 4),
                    const Expanded(
                        child: Text('AI insight • verify before acting',
                            style: TextStyle(
                                fontSize: 9, color: AppColors.muted))),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricGrid extends StatelessWidget {
  const _MetricGrid(
      {required this.products,
        required this.inventory,
        required this.lowStock,
        required this.views,
        required this.orders,
        required this.conversion});
  final int products;
  final int inventory;
  final int lowStock;
  final int views;
  final int orders;
  final double conversion;

  @override
  Widget build(BuildContext context) {
    final cards = <List<Object>>[
      <Object>[
        'Total products',
        '$products',
        Icons.inventory_2_outlined,
        AppColors.clay
      ],
      <Object>[
        'Inventory value',
        '₹$inventory',
        Icons.account_balance_wallet_outlined,
        AppColors.forest
      ],
      <Object>[
        'Recent activity',
        '$products',
        Icons.bolt_rounded,
        AppColors.saffron
      ],
      <Object>[
        'Low-stock products',
        '$lowStock',
        Icons.notifications_none_rounded,
        AppColors.clay
      ],
      <Object>[
        'Product views',
        '$views',
        Icons.visibility_outlined,
        AppColors.forest
      ],
      <Object>[
        'Est. orders',
        '$orders',
        Icons.shopping_bag_outlined,
        AppColors.clay
      ],
      <Object>[
        'Conversion',
        '${conversion.toStringAsFixed(1)}%',
        Icons.percent_rounded,
        AppColors.saffron
      ],
      <Object>[
        'B2B enquiries',
        '3',
        Icons.business_center_outlined,
        AppColors.forest
      ],
    ];
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: cards.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.75,
      ),
      itemBuilder: (context, index) {
        final card = cards[index];
        return _MetricCard(
            label: card[0] as String,
            value: card[1] as String,
            icon: card[2] as IconData,
            accent: card[3] as Color);
      },
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard(
      {required this.label,
        required this.value,
        required this.icon,
        required this.accent});
  final String label;
  final String value;
  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.outline.withOpacity(.18)),
      ),
      child: Row(
        children: [
          Container(
              width: 35,
              height: 35,
              decoration: BoxDecoration(
                  color: accent.withOpacity(.10),
                  borderRadius: BorderRadius.circular(11)),
              child: Icon(icon, size: 18, color: accent)),
          const SizedBox(width: 9),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(value,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            color: colors.onSurface,
                            fontSize: 17,
                            fontWeight: FontWeight.w900)),
                    const SizedBox(height: 2),
                    Text(label,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            color: colors.onSurfaceVariant,
                            fontSize: 9,
                            fontWeight: FontWeight.w700))
                  ])),
        ],
      ),
    );
  }
}

class _InteractiveSalesChart extends StatelessWidget {
  const _InteractiveSalesChart(
      {required this.data, required this.labels, required this.animation});
  final List<double> data;
  final List<String> labels;
  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final maxY = data.reduce((a, b) => a > b ? a : b) * 1.2;
    return Container(
      height: 270,
      padding: const EdgeInsets.fromLTRB(8, 18, 18, 8),
      decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: colors.outline.withOpacity(.18))),
      child: AnimatedBuilder(
        animation: animation,
        builder: (context, _) => BarChart(
          BarChartData(
            maxY: maxY,
            gridData: FlGridData(show: false), // Removed const
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
              topTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false)), // Removed const
              rightTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false)), // Removed const
              leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) => Text(_short(value),
                          style: TextStyle(
                              fontSize: 9,
                              color: colors.onSurfaceVariant)))),
              bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 26,
                      getTitlesWidget: (value, meta) {
                        final i = value.round();
                        if (i < 0 ||
                            i >= labels.length ||
                            labels[i].isEmpty) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                            padding: const EdgeInsets.only(top: 7),
                            child: Text(labels[i],
                                style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    color: colors.onSurfaceVariant)));
                      })),
            ),
            barTouchData: BarTouchData(
              enabled: true,
              touchTooltipData: BarTouchTooltipData(
                getTooltipColor: (_) => AppColors.forest,
                getTooltipItem: (group, groupIndex, rod, rodIndex) =>
                    BarTooltipItem(
                      '${labels[group.x]}\n₹${rod.toY.round()}',
                      const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w800),
                    ),
              ),
            ),
            barGroups: List.generate(
                data.length,
                    (i) => BarChartGroupData(x: i, barRods: [
                  BarChartRodData(
                      toY: data[i] * animation.value,
                      width: 18,
                      borderRadius: BorderRadius.circular(5),
                      color: AppColors.forest)
                ])),
          ),
        ),
      ),
    );
  }
}

class _ChannelBreakdown extends StatelessWidget {
  const _ChannelBreakdown();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
              color: Theme.of(context).colorScheme.outline.withOpacity(.18))),
      child: Row(
        children: [
          SizedBox(
            width: 132,
            height: 132,
            child: PieChart(PieChartData(
                sectionsSpace: 3,
                centerSpaceRadius: 34,
                // Removed const from array wrapper because PieChartSectionData does not have a const constructor
                sections: [
                  PieChartSectionData(
                      value: 45,
                      title: '45%',
                      radius: 35,
                      color: AppColors.forest,
                      titleStyle: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w900)),
                  PieChartSectionData(
                      value: 35,
                      title: '35%',
                      radius: 35,
                      color: AppColors.clay,
                      titleStyle: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w900)),
                  PieChartSectionData(
                      value: 20,
                      title: '20%',
                      radius: 35,
                      color: AppColors.saffron,
                      titleStyle: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w900)),
                ])),
          ),
          const SizedBox(width: 14),
          const Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _LegendDot(
                        color: AppColors.forest,
                        text: 'ONDC / GeM Network • 45%'),
                    SizedBox(height: 10),
                    _LegendDot(
                        color: AppColors.clay,
                        text: 'Physical Fairs / Exhibition POS • 35%'),
                    SizedBox(height: 10),
                    _LegendDot(
                        color: AppColors.saffron,
                        text: 'Direct / WhatsApp Orders • 20%'),
                  ])),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.text});
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) => Row(children: [
    Container(
        width: 9,
        height: 9,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
    const SizedBox(width: 8),
    Expanded(
        child: Text(text,
            style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.onSurfaceVariant)))
  ]);
}

class _SettlementCard extends StatelessWidget {
  const _SettlementCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: Theme.of(context).colorScheme.outline.withOpacity(.18))),
      child: Row(children: [
        const Expanded(
            child: _Settlement(
                value: '₹68,500',
                label: 'In Bank • Cleared',
                icon: Icons.account_balance_rounded,
                color: AppColors.forest)),
        Container(
            width: 1,
            height: 50,
            color: Theme.of(context).colorScheme.outline.withOpacity(.18)),
        const Expanded(
            child: _Settlement(
                value: '₹18,600',
                label: 'In Escrow • 2–4 days',
                icon: Icons.schedule_rounded,
                color: AppColors.saffron)),
      ]),
    );
  }
}

class _Settlement extends StatelessWidget {
  const _Settlement(
      {required this.value,
        required this.label,
        required this.icon,
        required this.color});
  final String value;
  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 5),
        Text(value,
            style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w900,
                color: Theme.of(context).colorScheme.onSurface)),
        const SizedBox(height: 2),
        Text(label,
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 9,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w700))
      ]));
}

class _WholesalePipeline extends StatelessWidget {
  const _WholesalePipeline();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const CircleAvatar(
            backgroundColor: AppColors.saffron,
            child: Icon(Icons.business_rounded, color: Colors.white)),
        title: const Text('B2B Wholesale Pipeline',
            style: TextStyle(fontWeight: FontWeight.w900)),
        subtitle: const Text(
            'FabIndia Sourcing • 40 Terracotta Planters requested'),
        trailing:
        FilledButton(onPressed: () {}, child: const Text('Review Quote')),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.subtitle});
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: Theme.of(context).colorScheme.onSurface)),
        const SizedBox(height: 3),
        Text(subtitle,
            style: TextStyle(
                fontSize: 11,
                color: Theme.of(context).colorScheme.onSurfaceVariant))
      ]);
}

class _ProductPerformance extends StatelessWidget {
  const _ProductPerformance({required this.products});
  final List products;

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) return const SizedBox.shrink();
    final sorted = [...products]
      ..sort((a, b) => ((b.price as num) * (b.stock as num))
          .compareTo((a.price as num) * (a.stock as num)));

    // Explicitly cast dynamic product fields to num to prevent fold errors
    final maxValue = sorted
        .map((p) => (p.price as num) * (p.stock as num))
        .fold<num>(1, (a, b) => a > b ? a : b);

    return Column(children: [
      for (int i = 0; i < sorted.take(4).length; i++) ...[
        _ProductRow(
            product: sorted[i],
            progress:
            (((sorted[i].price as num) * (sorted[i].stock as num)) / maxValue)
                .clamp(.12, 1.0)),
        if (i < sorted.take(4).length - 1) const SizedBox(height: 8),
      ]
    ]);
  }
}

class _ProductRow extends StatelessWidget {
  const _ProductRow({required this.product, required this.progress});
  final dynamic product;
  final double progress;

  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(17),
          border: Border.all(
              color: Theme.of(context).colorScheme.outline.withOpacity(.18))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(product.title.toString(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
        const SizedBox(height: 7),
        LinearProgressIndicator(
            value: progress,
            minHeight: 6,
            backgroundColor: AppColors.cream,
            color: AppColors.clay),
        const SizedBox(height: 5),
        Text(
            '${product.stock} in stock • ₹${(product.price as num) * (product.stock as num)} value',
            style: const TextStyle(
                fontSize: 9,
                color: AppColors.muted,
                fontWeight: FontWeight.w600))
      ]));
}

String _short(double value) {
  if (value >= 100000) return '${(value / 100000).toStringAsFixed(1)}L';
  if (value >= 1000) return '${(value / 1000).toStringAsFixed(0)}k';
  return value.toStringAsFixed(0);
}