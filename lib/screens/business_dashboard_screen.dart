import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../services/app_state.dart';
import '../theme.dart';

String _tr(BuildContext context, String key) {
  final state = AppScope.of(context);
  return state.tr(key);
}

class BusinessDashboardScreen extends StatefulWidget {
  const BusinessDashboardScreen({super.key});

  @override
  State<BusinessDashboardScreen> createState() => _BusinessDashboardScreenState();
}

class _BusinessDashboardScreenState extends State<BusinessDashboardScreen>
    with SingleTickerProviderStateMixin {
  int _selectedPeriod = 1;
  late final AnimationController _chartController;

  final List<String> _periods = const ['Today', 'This Week', 'This Month'];
  final List<List<double>> _salesData = const [
    [2200, 3400, 2900, 5100, 4300, 6800, 10540],
    [4200, 6100, 5200, 7900, 6800, 9300, 13980],
    [9800, 12400, 10800, 15100, 13200, 17400, 21100],
  ];
  final List<int> _totals = const [10540, 13980, 87100];
  final List<int> _growth = const [12, 18, 24];

  @override
  void initState() {
    super.initState();
    _chartController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..forward();
  }

  @override
  void dispose() {
    _chartController.dispose();
    super.dispose();
  }

  void _changePeriod(int value) {
    if (value == _selectedPeriod) return;
    setState(() => _selectedPeriod = value);
    _chartController
      ..reset()
      ..forward();
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: AnimatedBuilder(
        animation: state,
        builder: (context, _) {
          final products = state.products;
          final totalInventory = products.fold<int>(
            0,
                (sum, product) => sum + (product.price * product.stock),
          );
          final totalProducts = products.length;
          final lowStock = products.where((p) => p.stock <= 3).length;
          final recentActivity = products.take(5).length;
          final estimatedViews = totalProducts * 137 + recentActivity * 29;
          final estimatedOrders =
          (totalProducts * 3 + recentActivity).clamp(0, 9999).toInt();
          final conversionRate = estimatedViews == 0
              ? 0.0
              : (estimatedOrders / estimatedViews * 100)
              .clamp(0.0, 99.9)
              .toDouble();

          return SafeArea(
            child: RefreshIndicator(
              color: AppColors.forest,
              onRefresh: () async {
                await Future<void>.delayed(const Duration(milliseconds: 450));
                if (mounted) {
                  _chartController
                    ..reset()
                    ..forward();
                }
              },
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 30),
                children: [
                  _AnimatedEntrance(
                    animation: _chartController,
                    delay: 0,
                    child: const _Header(),
                  ),
                  const SizedBox(height: 18),
                  _AnimatedEntrance(
                    animation: _chartController,
                    delay: .06,
                    child: _PeriodSelector(
                      periods: _periods,
                      selected: _selectedPeriod,
                      onChanged: _changePeriod,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _AnimatedEntrance(
                    animation: _chartController,
                    delay: .12,
                    child: _SalesHero(
                      total: _totals[_selectedPeriod],
                      growth: _growth[_selectedPeriod],
                      data: _salesData[_selectedPeriod],
                      period: _periods[_selectedPeriod],
                      animation: _chartController,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _AnimatedEntrance(
                    animation: _chartController,
                    delay: .18,
                    child: _SummaryGrid(
                      products: totalProducts,
                      inventoryValue: totalInventory,
                      lowStock: lowStock,
                      recentActivity: recentActivity,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _AnimatedEntrance(
                    animation: _chartController,
                    delay: .27,
                    child: _SecondaryMetrics(
                      views: estimatedViews,
                      orders: estimatedOrders,
                      conversionRate: conversionRate,
                    ),
                  ),
                  const SizedBox(height: 22),
                  _SectionTitle(
                    title: _tr(context, 'Sales Trend'),
                    subtitle: _tr(context, 'Performance overview'),
                  ),
                  const SizedBox(height: 12),
                  _SalesChart(
                    data: _salesData[_selectedPeriod],
                    animation: _chartController,
                    periodIndex: _selectedPeriod,
                  ),
                  const SizedBox(height: 22),
                  _SectionTitle(
                    title: _tr(context, 'Product Performance'),
                    subtitle: _tr(context, 'Top performing inventory'),
                  ),
                  const SizedBox(height: 12),
                  _ProductPerformance(products: products),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _AnimatedEntrance extends StatelessWidget {
  const _AnimatedEntrance({required this.animation, required this.delay, required this.child});

  final Animation<double> animation;
  final double delay;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final curve = CurvedAnimation(
      parent: animation,
      curve: Interval(delay, 1, curve: Curves.easeOutCubic),
    );
    return FadeTransition(
      opacity: curve,
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, .035), end: Offset.zero).animate(curve),
        child: child,
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _tr(context, 'Business Dashboard'),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppColors.forest,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _tr(context, 'Your virtual business manager'),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: AppColors.forest.withOpacity(.10),
            borderRadius: BorderRadius.circular(15),
          ),
          child: const Icon(Icons.insights_rounded, color: AppColors.forest),
        ),
      ],
    );
  }
}

class _PeriodSelector extends StatelessWidget {
  const _PeriodSelector({required this.periods, required this.selected, required this.onChanged});

  final List<String> periods;
  final int selected;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(.28),
        ),
      ),
      child: Row(
        children: List.generate(periods.length, (index) {
          final isSelected = selected == index;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.symmetric(vertical: 11),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.forest : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _tr(context, periods[index]),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isSelected
                        ? Colors.white
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 13,
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
  const _SalesHero({
    required this.total,
    required this.growth,
    required this.data,
    required this.period,
    required this.animation,
  });

  final int total;
  final int growth;
  final List<double> data;
  final String period;
  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.forest, Color(0xFF4D8B76)],
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: AppColors.forest.withOpacity(.16),
            blurRadius: 20,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${_tr(context, 'Revenue & Net Profit')} • ${_tr(context, period)}',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(.13),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.trending_up_rounded, color: Colors.white, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '+$growth%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            '₹${_formatNumber(total)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 31,
              fontWeight: FontWeight.w900,
              letterSpacing: -.8,
            ),
          ),
          const SizedBox(height: 15),
          SizedBox(
            height: 130,
            child: AnimatedBuilder(
              animation: animation,
              builder: (context, _) => LineChart(
                LineChartData(
                  minY: 0,
                  maxY: _maxY(data),
                  minX: 0,
                  maxX: 6,
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  titlesData: const FlTitlesData(show: false),
                  lineTouchData: const LineTouchData(enabled: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: _animatedSpots(data, animation.value),
                      isCurved: true,
                      barWidth: 3,
                      color: Colors.white,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(show: true, color: Colors.white12),
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

class _SummaryGrid extends StatelessWidget {
  const _SummaryGrid({
    required this.products,
    required this.inventoryValue,
    required this.lowStock,
    required this.recentActivity,
  });

  final int products;
  final int inventoryValue;
  final int lowStock;
  final int recentActivity;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                icon: Icons.inventory_2_outlined,
                value: '$products',
                label: _tr(context, 'Total products'),
                accent: AppColors.clay,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MetricCard(
                icon: Icons.account_balance_wallet_outlined,
                value: '₹${_compactRupees(inventoryValue)}',
                label: _tr(context, 'Inventory value'),
                accent: AppColors.forest,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                icon: Icons.bolt_rounded,
                value: '$recentActivity',
                label: _tr(context, 'Recent Activity'),
                accent: AppColors.saffron,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MetricCard(
                icon: Icons.notifications_none_rounded,
                value: '$lowStock',
                label: _tr(context, 'Low Stock Products'),
                accent: AppColors.clay,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SecondaryMetrics extends StatelessWidget {
  const _SecondaryMetrics({
    required this.views,
    required this.orders,
    required this.conversionRate,
  });

  final int views;
  final int orders;
  final double conversionRate;

  @override
  Widget build(BuildContext context) {
    final cards = [
      _MetricCard(
        icon: Icons.visibility_outlined,
        value: _compactNumber(views.toDouble()),
        label: _tr(context, 'Product Views'),
        accent: AppColors.forest,
      ),
      _MetricCard(
        icon: Icons.shopping_bag_outlined,
        value: '$orders',
        label: _tr(context, 'Est. Orders'),
        accent: AppColors.clay,
      ),
      _MetricCard(
        icon: Icons.percent_rounded,
        value: '${conversionRate.toStringAsFixed(1)}%',
        label: _tr(context, 'Conversion'),
        accent: AppColors.saffron,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final cardWidth = width < 360 ? (width - 10) / 2 : (width - 20) / 3;

        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: cards
              .map(
                (card) => SizedBox(
              width: cardWidth,
              child: card,
            ),
          )
              .toList(),
        );
      },
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.accent,
    this.wide = false,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color accent;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: wide ? double.infinity : null,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(.28),
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withOpacity(.06),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: accent.withOpacity(.10),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: accent, size: 20),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
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

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.subtitle});
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurface,
          fontSize: 18,
          fontWeight: FontWeight.w900,
        ),
      ),
      const SizedBox(height: 3),
      Text(
        subtitle,
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          fontSize: 12,
        ),
      ),
    ],
  );
}

class _SalesChart extends StatelessWidget {
  const _SalesChart({required this.data, required this.animation, required this.periodIndex});
  final List<double> data;
  final Animation<double> animation;
  final int periodIndex;

  @override
  Widget build(BuildContext context) {
    final labels = periodIndex == 0
        ? ['6AM', '9AM', '12', '3PM', '6PM', '9PM', 'Now']
        : periodIndex == 1
        ? ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
        : ['W1', 'W2', 'W3', 'W4', 'W5', '', ''];

    return Container(
      height: 270,
      padding: const EdgeInsets.fromLTRB(8, 20, 18, 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(.28),
        ),
      ),
      child: AnimatedBuilder(
        animation: animation,
        builder: (context, _) => LineChart(
          LineChartData(
            minY: 0,
            maxY: _maxY(data),
            minX: 0,
            maxX: 6,
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: _interval(data),
              getDrawingHorizontalLine: (value) =>
              const FlLine(color: Color(0xFFE8DED5), strokeWidth: .8),
            ),
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 42,
                  interval: _interval(data),
                  getTitlesWidget: (value, meta) => Text(
                    _compactNumber(value),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 26,
                  getTitlesWidget: (value, meta) {
                    final i = value.round();
                    if (i < 0 || i >= labels.length || labels[i].isEmpty) {
                      return const SizedBox.shrink();
                    }
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        _tr(context, labels[i]),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            lineTouchData: LineTouchData(
              handleBuiltInTouches: true,
              touchTooltipData: LineTouchTooltipData(
                getTooltipItems: (spots) => spots
                    .map(
                      (spot) => LineTooltipItem(
                    '₹${_formatNumber(spot.y.round())}',
                    const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                )
                    .toList(),
              ),
            ),
            lineBarsData: [
              LineChartBarData(
                spots: _animatedSpots(data, animation.value),
                isCurved: true,
                barWidth: 3,
                color: AppColors.forest,
                dotData: const FlDotData(show: false),
                belowBarData: BarAreaData(
                  show: true,
                  color: AppColors.forest.withOpacity(.08),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProductPerformance extends StatelessWidget {
  const _ProductPerformance({required this.products});
  final List<dynamic> products;

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) return const SizedBox.shrink();

    final sorted = [...products]
      ..sort((a, b) => (b.price * b.stock).compareTo(a.price * a.stock));
    final shown = sorted.take(4).toList();
    final maxValue =
    shown.map<int>((p) => p.price * p.stock).fold<int>(1, (a, b) => a > b ? a : b);

    return Column(
      children: [
        for (int i = 0; i < shown.length; i++) ...[
          _ProductRow(
            product: shown[i],
            rank: i + 1,
            progress: ((shown[i].price * shown[i].stock) / maxValue).clamp(.12, 1.0),
          ),
          if (i != shown.length - 1) const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _ProductRow extends StatelessWidget {
  const _ProductRow({
    required this.product,
    required this.rank,
    required this.progress,
  });

  final dynamic product;
  final int rank;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final inventory = product.price * product.stock;
    final inStockText = _tr(context, 'in stock');
    final valueText = _tr(context, 'value');

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(.28),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '#$rank',
              style: const TextStyle(
                color: AppColors.forest,
                fontWeight: FontWeight.w900,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.title?.toString() ?? _tr(context, 'Product'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 5),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 6,
                    backgroundColor: AppColors.cream,
                    color: AppColors.clay,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${product.stock} $inStockText • ₹${_formatNumber(inventory)} $valueText',
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
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

List<FlSpot> _animatedSpots(List<double> values, double progress) {
  return List.generate(
    values.length,
        (index) => FlSpot(index.toDouble(), values[index] * progress),
  );
}

double _maxY(List<double> values) {
  final max = values.reduce((a, b) => a > b ? a : b);
  return max <= 0 ? 1 : max * 1.2;
}

double _interval(List<double> values) {
  final max = values.reduce((a, b) => a > b ? a : b);
  return (max / 4).clamp(1, double.infinity);
}

String _compactNumber(double value) {
  if (value >= 100000) return '${(value / 100000).toStringAsFixed(1)}L';
  if (value >= 1000) return '${(value / 1000).toStringAsFixed(0)}k';
  return value.toStringAsFixed(0);
}

String _compactRupees(int value) {
  if (value >= 100000) return '${(value / 100000).toStringAsFixed(1)}L';
  if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}k';
  return value.toString();
}

String _formatNumber(int value) {
  final text = value.toString();
  final buffer = StringBuffer();
  for (int i = 0; i < text.length; i++) {
    if (i > 0 && (text.length - i) % 3 == 0) buffer.write(',');
    buffer.write(text[i]);
  }
  return buffer.toString();
}