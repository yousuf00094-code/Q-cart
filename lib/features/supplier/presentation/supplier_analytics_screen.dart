import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/supplier_service.dart';
import '../../../core/services/api_client.dart';

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

  List<_BarData>? _revenueData;
  List<_TopProduct>? _topProducts;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    _fetchData();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  int get _periodDays => switch (_period) {
        'week' => 7,
        'month' => 30,
        'quarter' => 90,
        _ => 365,
      };

  Future<void> _fetchData() async {
    setState(() { _loading = true; _error = null; });
    try {
      final results = await Future.wait([
        SupplierService.getDailyRevenue(days: _periodDays),
        SupplierService.getTopProducts(limit: 10),
      ]);
      if (!mounted) return;
      final rawRevenue = results[0] as List<dynamic>;
      final rawProducts = results[1] as List<dynamic>;
      final maxRev = rawProducts.isEmpty
          ? 1.0
          : rawProducts
              .map((p) => (double.tryParse(p['revenue']?.toString() ?? '0') ?? 0))
              .fold(0.0, (a, b) => a > b ? a : b);
      setState(() {
        _revenueData = rawRevenue.map((r) {
          final date = r['date']?.toString() ?? '';
          final label = date.length >= 10 ? date.substring(5, 10) : date;
          return _BarData(label, double.tryParse(r['revenue']?.toString() ?? '0') ?? 0);
        }).toList();
        _topProducts = rawProducts.asMap().entries.map((e) {
          final p = e.value as Map<String, dynamic>;
          final rev = double.tryParse(p['revenue']?.toString() ?? '0') ?? 0;
          final units = int.tryParse(p['units_sold']?.toString() ?? '0') ?? 0;
          final pct = maxRev > 0 ? rev / maxRev : 0.0;
          return _TopProduct(
            p['name']?.toString() ?? '',
            units,
            'QAR ${rev.toStringAsFixed(0)}',
            pct,
          );
        }).toList();
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() { _error = e.message; _loading = false; });
    } catch (_) {
      if (!mounted) return;
      setState(() { _error = 'Failed to load analytics. Pull down to retry.'; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Analytics',
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        backgroundColor: AppColors.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        actions: [
          IconButton(icon: const Icon(Icons.file_download_outlined), onPressed: () {}, tooltip: 'Export Report'),
        ],
        bottom: TabBar(
          controller: _tabCtrl,
          labelColor: AppColors.secondary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.secondary,
          tabs: const [Tab(text: 'Overview'), Tab(text: 'Products'), Tab(text: 'Customers')],
        ),
      ),
      body: Column(
        children: [
          _buildPeriodSelector(),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? _buildError()
                    : RefreshIndicator(
                        onRefresh: _fetchData,
                        child: TabBarView(
                          controller: _tabCtrl,
                          children: [_buildOverviewTab(), _buildProductsTab(), _buildCustomersTab()],
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.error_outline, size: 48, color: AppColors.textSecondary),
          const SizedBox(height: 12),
          Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _fetchData, child: const Text('Retry')),
        ]),
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
              onTap: () { setState(() => _period = p); _fetchData(); },
              child: Container(
                margin: const EdgeInsets.only(right: 6),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: selected ? AppColors.secondary : AppColors.background,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: selected ? AppColors.secondary : AppColors.divider),
                ),
                child: Text(
                  p[0].toUpperCase() + p.substring(1),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: selected ? Colors.white : AppColors.textSecondary),
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
          _buildConversionCard(),
        ],
      ),
    );
  }

  Widget _buildRevenueCard() {
    final totalRevenue = _revenueData?.fold(0.0, (sum, d) => sum + d.value) ?? 0.0;
    final totalOrders = _revenueData?.length ?? 0;
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Total Revenue', style: TextStyle(color: Colors.white70, fontSize: 13)),
                  const SizedBox(height: 6),
                  Text('QAR ${totalRevenue.toStringAsFixed(0)}',
                      style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.show_chart, size: 16, color: Colors.white),
                    const SizedBox(width: 4),
                    Text(_period[0].toUpperCase() + _period.substring(1),
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _MiniStat('Days', '$totalOrders', Colors.white),
              _MiniStat('Avg/Day', totalOrders > 0 ? 'QAR ${(totalRevenue / totalOrders).toStringAsFixed(0)}' : '-', Colors.white),
              _MiniStat('Products', '${_topProducts?.length ?? 0}', Colors.white),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBarChart() {
    final data = _revenueData ?? [];
    if (data.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.divider),
        ),
        child: const Center(child: Padding(
          padding: EdgeInsets.symmetric(vertical: 32),
          child: Text('No revenue data for this period', style: TextStyle(color: AppColors.textSecondary)),
        )),
      );
    }
    final maxValue = data.map((d) => d.value).reduce((a, b) => a > b ? a : b);
    final displayData = data.length > 14 ? data.sublist(data.length - 14) : data;
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
          Text('Revenue (${_period[0].toUpperCase()}${_period.substring(1)})',
              style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary, fontSize: 14)),
          const SizedBox(height: 16),
          SizedBox(
            height: 140,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: displayData.map((d) {
                final pct = maxValue > 0 ? d.value / maxValue : 0.0;
                return Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (d.value > 0)
                      Text('${(d.value / 1000).toStringAsFixed(1)}k',
                          style: const TextStyle(fontSize: 8, color: AppColors.textSecondary)),
                    const SizedBox(height: 4),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 600),
                      width: 20,
                      height: 110 * pct,
                      decoration: BoxDecoration(
                        color: AppColors.secondary,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(d.day.length > 5 ? d.day.substring(d.day.length - 5) : d.day,
                        style: const TextStyle(fontSize: 9, color: AppColors.textSecondary)),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
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
          const Text('Revenue Summary',
              style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          const SizedBox(height: 14),
          Row(
            children: [
              _MiniMetricCard('Total Revenue',
                  'QAR ${(_revenueData?.fold(0.0, (s, d) => s + d.value) ?? 0).toStringAsFixed(0)}',
                  Icons.payments_outlined, AppColors.secondary),
              const SizedBox(width: 12),
              _MiniMetricCard('Top Products', '${_topProducts?.length ?? 0}',
                  Icons.inventory_outlined, const Color(0xFF2E7D32)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProductsTab() {
    final products = _topProducts ?? [];
    if (products.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('No product data available.', style: TextStyle(color: AppColors.textSecondary)),
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Top Products by Revenue',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        const SizedBox(height: 12),
        ...products.asMap().entries.map((entry) {
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
                      width: 28, height: 28,
                      decoration: BoxDecoration(
                        color: i == 0 ? const Color(0xFFFFF3CD) : AppColors.surface,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text('${i + 1}',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: i == 0 ? const Color(0xFF856404) : AppColors.textSecondary)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(p.name,
                          style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(p.revenue,
                            style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                        Text('${p.units} units sold',
                            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
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
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.secondary),
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
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.divider),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Customer Analytics',
                    style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary, fontSize: 15)),
                const SizedBox(height: 12),
                const Text('Detailed customer analytics coming soon.',
                    style: TextStyle(color: AppColors.textSecondary)),
              ],
            ),
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
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 15)),
          Text(label, style: TextStyle(color: color.withOpacity(0.7), fontSize: 11)),
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
                  Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 16)),
                  Text(label,
                      style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
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
