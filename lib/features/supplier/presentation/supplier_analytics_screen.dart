import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class SupplierAnalyticsScreen extends StatefulWidget {
  const SupplierAnalyticsScreen({super.key});

  @override
  State<SupplierAnalyticsScreen> createState() =>
      _SupplierAnalyticsScreenState();
}

class _SupplierAnalyticsScreenState extends State<SupplierAnalyticsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  String _period = 'month';

  final List<String> _periods = ['week', 'month', 'quarter', 'year'];

  final List<_BarData> _revenueData = [
    _BarData('Mon', 1200),
    _BarData('Tue', 1850),
    _BarData('Wed', 1400),
    _BarData('Thu', 2100),
    _BarData('Fri', 1950),
    _BarData('Sat', 2800),
    _BarData('Sun', 1650),
  ];

  final List<_TopProduct> _topProducts = [
    _TopProduct('Wireless Earbuds Pro', 142, 'QAR 21,158', 0.85),
    _TopProduct('Mechanical Keyboard', 89, 'QAR 22,161', 0.72),
    _TopProduct('USB-C Hub 7-in-1', 215, 'QAR 19,243', 0.65),
    _TopProduct('Webcam 1080p', 67, 'QAR 13,333', 0.50),
    _TopProduct('Laptop Stand', 44, 'QAR 5,676', 0.35),
  ];

  final List<_CategoryRevenue> _categories = [
    _CategoryRevenue('Electronics', 'QAR 52,410', 0.72, const Color(0xFF4D4A7D)),
    _CategoryRevenue('Accessories', 'QAR 13,250', 0.18, AppColors.primary),
    _CategoryRevenue('Cables', 'QAR 4,890', 0.07, const Color(0xFFF57F17)),
    _CategoryRevenue('Other', 'QAR 2,100', 0.03, const Color(0xFFE0E0E0)),
  ];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Analytics',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary)),
        backgroundColor: AppColors.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download_outlined),
            onPressed: () {},
            tooltip: 'Export Report',
          ),
        ],
        bottom: TabBar(
          controller: _tabCtrl,
          labelColor: AppColors.secondary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.secondary,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Products'),
            Tab(text: 'Customers'),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildPeriodSelector(),
          Expanded(
            child: TabBarView(
              controller: _tabCtrl,
              children: [
                _buildOverviewTab(),
                _buildProductsTab(),
                _buildCustomersTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: _periods.map((p) {
          final selected = _period == p;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _period = p),
              child: Container(
                margin: const EdgeInsets.only(right: 6),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: selected
                      ? AppColors.secondary
                      : AppColors.background,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: selected
                          ? AppColors.secondary
                          : AppColors.divider),
                ),
                child: Text(
                  p[0].toUpperCase() + p.substring(1),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: selected
                          ? Colors.white
                          : AppColors.textSecondary),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildRevenueCard(),
          const SizedBox(height: 16),
          _buildBarChart(),
          const SizedBox(height: 16),
          _buildMetricsGrid(),
          const SizedBox(height: 16),
          _buildConversionCard(),
        ],
      ),
    );
  }

  Widget _buildRevenueCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.secondary, Color(0xFF7B78C5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Total Revenue',
                      style: TextStyle(
                          color: Colors.white70, fontSize: 13)),
                  SizedBox(height: 6),
                  Text('QAR 72,650',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold)),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.trending_up, size: 16, color: Colors.white),
                    SizedBox(width: 4),
                    Text('+18.4%',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _MiniStat('Orders', '247', Colors.white),
              _MiniStat('Avg. Order', 'QAR 294', Colors.white),
              _MiniStat('Returns', '3.2%', Colors.white),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBarChart() {
    final maxValue =
        _revenueData.map((d) => d.value).reduce((a, b) => a > b ? a : b);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Revenue (This Week)',
              style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                  fontSize: 14)),
          const SizedBox(height: 16),
          SizedBox(
            height: 140,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: _revenueData.map((d) {
                final pct = d.value / maxValue;
                return Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      'QAR ${(d.value / 1000).toStringAsFixed(1)}k',
                      style: const TextStyle(
                          fontSize: 9, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 4),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 600),
                      width: 28,
                      height: 110 * pct,
                      decoration: BoxDecoration(
                        color: AppColors.secondary,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(d.day,
                        style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary)),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsGrid() {
    final metrics = [
      ('Gross Revenue', 'QAR 72,650', Icons.payments_outlined, AppColors.secondary),
      ('Net Payout', 'QAR 61,752', Icons.account_balance_outlined, const Color(0xFF2E7D32)),
      ('Total Orders', '247', Icons.receipt_long_outlined, const Color(0xFF1565C0)),
      ('Units Sold', '684', Icons.shopping_cart_outlined, const Color(0xFFF57F17)),
      ('Refunds', 'QAR 1,240', Icons.assignment_return_outlined, Colors.red),
      ('Commission', 'QAR 7,265', Icons.percent_outlined, const Color(0xFF6A1B9A)),
    ];
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.8,
      children: metrics.map((m) {
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.divider),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: m.$4.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(m.$3, color: m.$4, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(m.$2,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                            fontSize: 14),
                        overflow: TextOverflow.ellipsis),
                    Text(m.$1,
                        style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary)),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildConversionCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Funnel Performance',
              style: TextStyle(
                  fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          const SizedBox(height: 14),
          ...[
            ('Product Views', 8450, 1.0),
            ('Add to Cart', 1240, 1240 / 8450),
            ('Checkout Started', 520, 520 / 8450),
            ('Orders Placed', 247, 247 / 8450),
          ].map((row) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(row.$1,
                            style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textPrimary)),
                        Text(
                          '${row.$2} (${(row.$3 * 100).toStringAsFixed(1)}%)',
                          style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: row.$3,
                        minHeight: 6,
                        backgroundColor:
                            AppColors.secondary.withOpacity(0.1),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                            AppColors.secondary),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildProductsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Top Products by Revenue',
            style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary)),
        const SizedBox(height: 12),
        ..._topProducts.asMap().entries.map((entry) {
          final i = entry.key;
          final p = entry.value;
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.divider),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: i == 0
                            ? const Color(0xFFFFF3CD)
                            : AppColors.surface,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text('${i + 1}',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: i == 0
                                    ? const Color(0xFF856404)
                                    : AppColors.textSecondary)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(p.name,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary)),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(p.revenue,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary)),
                        Text('${p.units} units sold',
                            style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: p.pct,
                    minHeight: 6,
                    backgroundColor: AppColors.secondary.withOpacity(0.1),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                        AppColors.secondary),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildCustomersTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCategoryBreakdown(),
          const SizedBox(height: 16),
          _buildRepeatCustomerCard(),
        ],
      ),
    );
  }

  Widget _buildCategoryBreakdown() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Revenue by Category',
              style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                  fontSize: 15)),
          const SizedBox(height: 16),
          ..._categories.map((c) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                  color: c.color, shape: BoxShape.circle),
                            ),
                            const SizedBox(width: 8),
                            Text(c.name,
                                style: const TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textPrimary)),
                          ],
                        ),
                        Text(
                          '${c.revenue} (${(c.pct * 100).toStringAsFixed(0)}%)',
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: c.pct,
                        minHeight: 8,
                        backgroundColor: c.color.withOpacity(0.15),
                        valueColor:
                            AlwaysStoppedAnimation<Color>(c.color),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildRepeatCustomerCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Customer Insights',
              style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                  fontSize: 15)),
          const SizedBox(height: 14),
          Row(
            children: [
              _MiniMetricCard('Total Customers', '184',
                  Icons.people_outlined, AppColors.secondary),
              const SizedBox(width: 12),
              _MiniMetricCard('Repeat Buyers', '67',
                  Icons.repeat_outlined, const Color(0xFF2E7D32)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _MiniMetricCard('New This Month', '29',
                  Icons.person_add_outlined, const Color(0xFF1565C0)),
              const SizedBox(width: 12),
              _MiniMetricCard('Avg. LTV', 'QAR 394',
                  Icons.loyalty_outlined, const Color(0xFF6A1B9A)),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label, value;
  final Color color;
  const _MiniStat(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(value,
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: color,
                  fontSize: 15)),
          Text(label,
              style: TextStyle(color: color.withOpacity(0.7), fontSize: 11)),
        ],
      ),
    );
  }
}

class _MiniMetricCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _MiniMetricCard(this.label, this.value, this.icon, this.color);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.07),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(value,
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: color,
                          fontSize: 16)),
                  Text(label,
                      style: const TextStyle(
                          fontSize: 10, color: AppColors.textSecondary),
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BarData {
  final String day;
  final double value;
  const _BarData(this.day, this.value);
}

class _TopProduct {
  final String name, revenue;
  final int units;
  final double pct;
  const _TopProduct(this.name, this.units, this.revenue, this.pct);
}

class _CategoryRevenue {
  final String name, revenue;
  final double pct;
  final Color color;
  const _CategoryRevenue(this.name, this.revenue, this.pct, this.color);
}
