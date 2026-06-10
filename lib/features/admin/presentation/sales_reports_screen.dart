import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class SalesReportsScreen extends StatefulWidget {
  const SalesReportsScreen({super.key});

  @override
  State<SalesReportsScreen> createState() => _SalesReportsScreenState();
}

class _SalesReportsScreenState extends State<SalesReportsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  String _period = 'This Month';

  static const _periods = ['Today', 'This Week', 'This Month', 'This Year'];

  // Revenue data points (normalised 0–1) for 7 bars
  static const _revenue = [0.55, 0.72, 0.48, 0.91, 0.65, 0.83, 1.0];
  static const _days    = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  static const _topProducts = [
    _TopProduct('Organic Dates 500g', 'QAR 49,350', 1410, 0.92),
    _TopProduct('Saffron Pack 5g', 'QAR 38,400', 320, 0.71),
    _TopProduct('iPhone 15 128GB', 'QAR 32,750', 65, 0.61),
    _TopProduct('Camel Milk 1L', 'QAR 22,680', 810, 0.42),
    _TopProduct('Oud Perfume 50ml', 'QAR 18,500', 74, 0.34),
  ];

  static const _categories = [
    _CategoryRevenue('Groceries', 'QAR 84,220', 0.46, Color(0xFFD4F5E9), Color(0xFF388E3C)),
    _CategoryRevenue('Electronics', 'QAR 42,100', 0.23, Color(0xFFDDD9F5), Color(0xFF7B1FA2)),
    _CategoryRevenue('Fashion', 'QAR 28,000', 0.15, Color(0xFFFFE8D6), Color(0xFFF57C00)),
    _CategoryRevenue('Home & Living', 'QAR 18,500', 0.10, Color(0xFFD6EEFF), Color(0xFF1976D2)),
    _CategoryRevenue('Other', 'QAR 11,500', 0.06, Color(0xFFF5F0D6), Color(0xFF795548)),
  ];

  static const _orderStats = [
    _OrderStat('Total Orders', '1,847', Icons.shopping_bag_outlined, Color(0xFFD4F5E9)),
    _OrderStat('Avg. Order Value', 'QAR 99.8', Icons.receipt_outlined, Color(0xFFDDD9F5)),
    _OrderStat('Cancelled', '63', Icons.cancel_outlined, Color(0xFFFFE8D6)),
    _OrderStat('Refunded', 'QAR 4,200', Icons.replay_outlined, Color(0xFFD6EEFF)),
  ];

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Sales Reports',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        actions: [
          IconButton(
            icon: const Icon(Icons.download_outlined, color: AppColors.secondary),
            onPressed: () {},
            tooltip: 'Export Report',
          ),
          const SizedBox(width: 4),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.divider),
            ),
            child: TabBar(
              controller: _tabs,
              indicator: BoxDecoration(color: AppColors.secondary, borderRadius: BorderRadius.circular(10)),
              indicatorSize: TabBarIndicatorSize.tab,
              labelColor: Colors.white,
              unselectedLabelColor: AppColors.textSecondary,
              labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              dividerColor: Colors.transparent,
              padding: const EdgeInsets.all(3),
              tabs: const [Tab(text: 'Overview'), Tab(text: 'Products'), Tab(text: 'Categories')],
            ),
          ),
        ),
      ),
      body: Column(children: [
        _buildPeriodSelector(),
        Expanded(
          child: TabBarView(controller: _tabs, children: [
            _buildOverviewTab(),
            _buildProductsTab(),
            _buildCategoriesTab(),
          ]),
        ),
      ]),
    );
  }

  Widget _buildPeriodSelector() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: _periods.map((p) => GestureDetector(
          onTap: () => setState(() => _period = p),
          child: Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
            decoration: BoxDecoration(
              color: _period == p ? AppColors.secondary : AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _period == p ? AppColors.secondary : AppColors.divider),
            ),
            child: Text(p, style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _period == p ? Colors.white : AppColors.textSecondary,
            )),
          ),
        )).toList(),
      ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _buildRevenueCard(),
        const SizedBox(height: 16),
        _buildBarChart(),
        const SizedBox(height: 20),
        const Text('Order Statistics',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        const SizedBox(height: 10),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, mainAxisSpacing: 10, crossAxisSpacing: 10, childAspectRatio: 1.6),
          itemCount: _orderStats.length,
          itemBuilder: (_, i) => _StatCard(stat: _orderStats[i]),
        ),
      ]),
    );
  }

  Widget _buildRevenueCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.secondary, Color(0xFF6D69A8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(_period, style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.7))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(children: [
              Icon(Icons.trending_up, size: 13, color: Colors.white),
              SizedBox(width: 4),
              Text('+18.4%', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
            ]),
          ),
        ]),
        const SizedBox(height: 8),
        const Text('QAR 184,320', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: Colors.white)),
        const SizedBox(height: 4),
        Text('Total Revenue', style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.7))),
        const SizedBox(height: 16),
        Row(children: [
          _MiniStat('1,847', 'Orders'),
          _VertDivider(),
          _MiniStat('QAR 99.8', 'Avg. Value'),
          _VertDivider(),
          _MiniStat('96.5%', 'Fulfillment'),
        ]),
      ]),
    );
  }

  Widget _buildBarChart() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Revenue Trend (Last 7 Days)',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
      const SizedBox(height: 12),
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(children: [
          SizedBox(
            height: 120,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(_revenue.length, (i) {
                final isToday = i == _revenue.length - 1;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                      if (isToday)
                        Container(
                          margin: const EdgeInsets.only(bottom: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.secondary,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text('Peak', style: TextStyle(fontSize: 8, color: Colors.white, fontWeight: FontWeight.w700)),
                        ),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 600),
                        height: (_revenue[i] * 100).clamp(8, 100),
                        decoration: BoxDecoration(
                          color: isToday ? AppColors.secondary : AppColors.primary,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ]),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: List.generate(_days.length, (i) => Expanded(
              child: Text(_days[i],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: i == _days.length - 1 ? FontWeight.w700 : FontWeight.w400,
                    color: i == _days.length - 1 ? AppColors.secondary : AppColors.textSecondary,
                  )),
            )),
          ),
        ]),
      ),
    ]);
  }

  Widget _buildProductsTab() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: [
        const Text('Top Selling Products',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        const SizedBox(height: 12),
        ..._topProducts.asMap().entries.map((e) => _TopProductRow(rank: e.key + 1, product: e.value)),
      ],
    );
  }

  Widget _buildCategoriesTab() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: [
        const Text('Revenue by Category',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        const SizedBox(height: 12),
        ..._categories.map((c) => _CategoryRow(cat: c)),
      ],
    );
  }
}

// ─── Widgets ───────────────────────────────────────────────────────────────

class _MiniStat extends StatelessWidget {
  const _MiniStat(this.value, this.label);
  final String value, label;

  @override
  Widget build(BuildContext context) {
    return Expanded(child: Column(children: [
      Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
      const SizedBox(height: 2),
      Text(label, style: TextStyle(fontSize: 10, color: Colors.white.withOpacity(0.6))),
    ]));
  }
}

class _VertDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      Container(width: 1, height: 28, color: Colors.white.withOpacity(0.2), margin: const EdgeInsets.symmetric(horizontal: 4));
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.stat});
  final _OrderStat stat;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: stat.color, borderRadius: BorderRadius.circular(14)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Icon(stat.icon, color: AppColors.secondary, size: 20),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(stat.value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
          Text(stat.label, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
        ]),
      ]),
    );
  }
}

class _TopProductRow extends StatelessWidget {
  const _TopProductRow({required this.rank, required this.product});
  final int rank;
  final _TopProduct product;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 28, height: 28,
            decoration: BoxDecoration(
              color: rank == 1 ? const Color(0xFFFFC107) : rank == 2 ? Colors.grey.shade300 : AppColors.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.divider),
            ),
            child: Center(child: Text('$rank',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800,
                    color: rank <= 2 ? Colors.white : AppColors.textSecondary))),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(product.name,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary))),
          Text(product.revenue,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.secondary)),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          Text('${product.units} units sold',
              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          const Spacer(),
          Text('${(product.ratio * 100).toStringAsFixed(0)}% of total',
              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
        ]),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: product.ratio, minHeight: 5,
            backgroundColor: AppColors.divider, color: AppColors.secondary,
          ),
        ),
      ]),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({required this.cat});
  final _CategoryRevenue cat;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cat.color, borderRadius: BorderRadius.circular(14),
      ),
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(cat.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          Text(cat.revenue, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: cat.fg)),
        ]),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: cat.ratio, minHeight: 7,
              backgroundColor: Colors.white.withOpacity(0.5), color: cat.fg,
            ),
          )),
          const SizedBox(width: 8),
          Text('${(cat.ratio * 100).toStringAsFixed(0)}%',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: cat.fg)),
        ]),
      ]),
    );
  }
}

// ─── Data classes ──────────────────────────────────────────────────────────

class _TopProduct {
  final String name, revenue;
  final int units;
  final double ratio;
  const _TopProduct(this.name, this.revenue, this.units, this.ratio);
}

class _CategoryRevenue {
  final String name, revenue;
  final double ratio;
  final Color color, fg;
  const _CategoryRevenue(this.name, this.revenue, this.ratio, this.color, this.fg);
}

class _OrderStat {
  final String label, value;
  final IconData icon;
  final Color color;
  const _OrderStat(this.label, this.value, this.icon, this.color);
}
