import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/admin_service.dart';
import '../../../../core/services/api_client.dart';

class AdminSupplierPerformanceScreen extends StatefulWidget {
  const AdminSupplierPerformanceScreen({super.key});

  @override
  State<AdminSupplierPerformanceScreen> createState() =>
      _AdminSupplierPerformanceScreenState();
}

class _AdminSupplierPerformanceScreenState
    extends State<AdminSupplierPerformanceScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  String _period = 'month';
  String _sortBy = 'revenue';

  List<_SupplierPerf>? _suppliers;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _fetchData();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    setState(() { _loading = true; _error = null; });
    try {
      final res = await AdminService.getSupplierPerformance();
      if (!mounted) return;
      final data = res['data'] as List<dynamic>? ?? [];
      setState(() {
        _suppliers = data.map<_SupplierPerf>((r) {
          final m = r as Map<String, dynamic>;
          final rating = double.tryParse(m['avg_rating']?.toString() ?? '0') ?? 0;
          final fulfillment = double.tryParse(m['fulfillment_rate']?.toString() ?? '0') ?? 0;
          final cancelRate = double.tryParse(m['cancellation_rate']?.toString() ?? '0') ?? 0;
          final revenue = double.tryParse(m['total_revenue']?.toString() ?? '0') ?? 0;
          final badge = rating >= 4.5 ? 'top' : rating >= 3.5 ? 'good' : rating >= 3.0 ? 'average' : 'at_risk';
          return _SupplierPerf(
            m['name']?.toString() ?? '',
            m['category']?.toString() ?? '',
            rating,
            int.tryParse(m['total_orders']?.toString() ?? '0') ?? 0,
            'QAR ${revenue.toStringAsFixed(0)}',
            fulfillment,
            100 - cancelRate,
            cancelRate,
            badge,
            'QAR ${(revenue * 0.9).toStringAsFixed(0)}',
            0,
          );
        }).toList();
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() { _error = e.message; _loading = false; });
    } catch (_) {
      if (!mounted) return;
      setState(() { _error = 'Failed to load. Pull down to retry.'; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Supplier Performance',
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
              onPressed: () {}),
        ],
        bottom: TabBar(
          controller: _tabCtrl,
          labelColor: AppColors.secondary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.secondary,
          tabs: const [
            Tab(text: 'Rankings'),
            Tab(text: 'Benchmarks'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.error_outline, size: 48, color: AppColors.textSecondary),
                  const SizedBox(height: 12),
                  Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondary)),
                  const SizedBox(height: 16),
                  ElevatedButton(onPressed: _fetchData, child: const Text('Retry')),
                ])))
              : RefreshIndicator(
                  onRefresh: _fetchData,
                  child: TabBarView(
                    controller: _tabCtrl,
                    children: [_buildRankingsTab(), _buildBenchmarksTab()],
                  ),
                ),
    );
  }

  Widget _buildRankingsTab() {
    return Column(
      children: [
        _buildPeriodAndSort(),
        _buildOverviewStrip(),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            itemCount: _sortedSuppliers.length,
            itemBuilder: (_, i) => _SupplierRankCard(
              rank: i + 1,
              supplier: _sortedSuppliers[i],
              onView: () => _showSupplierSheet(_sortedSuppliers[i]),
            ),
          ),
        ),
      ],
    );
  }

  List<_SupplierPerf> get _sortedSuppliers {
    final list = <_SupplierPerf>[...(_suppliers ?? <_SupplierPerf>[])];
    list.sort((a, b) {
      return switch (_sortBy) {
        'rating' => b.rating.compareTo(a.rating),
        'orders' => b.orders.compareTo(a.orders),
        'ontime' => b.onTimeDelivery.compareTo(a.onTimeDelivery),
        _ => b.revenue.compareTo(a.revenue),
      };
    });
    return list;
  }

  Widget _buildPeriodAndSort() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _period,
              isDense: true,
              decoration: const InputDecoration(
                  labelText: 'Period',
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
              items: [
                ('week', 'This Week'),
                ('month', 'This Month'),
                ('quarter', 'This Quarter'),
                ('year', 'This Year'),
              ]
                  .map((p) =>
                      DropdownMenuItem(value: p.$1, child: Text(p.$2)))
                  .toList(),
              onChanged: (v) => setState(() => _period = v!),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _sortBy,
              isDense: true,
              decoration: const InputDecoration(
                  labelText: 'Sort By',
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
              items: [
                ('revenue', 'Revenue'),
                ('rating', 'Rating'),
                ('orders', 'Orders'),
                ('ontime', 'On-Time %'),
              ]
                  .map((s) =>
                      DropdownMenuItem(value: s.$1, child: Text(s.$2)))
                  .toList(),
              onChanged: (v) => setState(() => _sortBy = v!),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewStrip() {
    final list = _suppliers ?? [];
    final topRevenue = list
        .map((s) => double.tryParse(s.revenue.replaceAll('QAR ', '').replaceAll(',', '')) ?? 0)
        .fold(0.0, (a, b) => a + b);
    final avgRating = list.isEmpty ? 0.0 : list.map((s) => s.rating).fold(0.0, (a, b) => a + b) / list.length;
    final atRisk = list.where((s) => s.badge == 'at_risk').length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _StripStat('Total GMV',
              'QAR ${(topRevenue / 1000).toStringAsFixed(1)}k',
              AppColors.secondary),
          const SizedBox(width: 8),
          _StripStat('Avg. Rating', avgRating.toStringAsFixed(1),
              const Color(0xFFFFB300)),
          const SizedBox(width: 8),
          _StripStat('At Risk', '$atRisk', Colors.red),
        ],
      ),
    );
  }

  Widget _buildBenchmarksTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildBenchmarkCard('Avg. Rating', [
            for (final s in (_suppliers ?? []))
              _BenchmarkRow(s.name, s.rating / 5, s.rating.toStringAsFixed(1), const Color(0xFFFFB300)),
          ]),
          const SizedBox(height: 16),
          _buildBenchmarkCard('On-Time Delivery %', [
            for (final s in (_suppliers ?? []))
              _BenchmarkRow(s.name, s.onTimeDelivery / 100, '${s.onTimeDelivery.toStringAsFixed(1)}%', AppColors.primary),
          ]),
          const SizedBox(height: 16),
          _buildBenchmarkCard('Return Rate %', [
            for (final s in (_suppliers ?? []))
              _BenchmarkRow(s.name, s.returnRate / 15, '${s.returnRate.toStringAsFixed(1)}%',
                  s.returnRate > 5 ? Colors.red : const Color(0xFF2E7D32), invertColors: true),
          ]),
        ],
      ),
    );
  }

  Widget _buildBenchmarkCard(String title, List<_BenchmarkRow> rows) {
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
          Text(title,
              style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                  fontSize: 15)),
          const SizedBox(height: 14),
          ...rows.map((row) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(row.label,
                            style: const TextStyle(
                                fontSize: 13, color: AppColors.textPrimary)),
                        Text(row.value,
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: row.color)),
                      ],
                    ),
                    const SizedBox(height: 5),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: row.pct.clamp(0.0, 1.0),
                        minHeight: 8,
                        backgroundColor: row.color.withOpacity(0.1),
                        valueColor:
                            AlwaysStoppedAnimation<Color>(row.color),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  void _showSupplierSheet(_SupplierPerf s) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        builder: (_, scrollCtrl) => SingleChildScrollView(
          controller: scrollCtrl,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(s.name,
                      style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary)),
                  _BadgeChip(s.badge),
                ],
              ),
              const SizedBox(height: 4),
              Text(s.category,
                  style: const TextStyle(color: AppColors.textSecondary)),
              const Divider(height: 24),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 2,
                children: [
                  _PerfMetricTile('Revenue', s.revenue, AppColors.secondary),
                  _PerfMetricTile('Orders', '${s.orders}', const Color(0xFF1565C0)),
                  _PerfMetricTile('Avg. Rating', s.rating.toStringAsFixed(1),
                      const Color(0xFFFFB300)),
                  _PerfMetricTile('On-Time', '${s.onTimeDelivery.toStringAsFixed(1)}%',
                      const Color(0xFF2E7D32)),
                  _PerfMetricTile('Fill Rate', '${s.fillRate.toStringAsFixed(1)}%',
                      const Color(0xFF00695C)),
                  _PerfMetricTile('Return Rate', '${s.returnRate.toStringAsFixed(1)}%',
                      Colors.red),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SupplierRankCard extends StatelessWidget {
  final int rank;
  final _SupplierPerf supplier;
  final VoidCallback onView;
  const _SupplierRankCard(
      {required this.rank, required this.supplier, required this.onView});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: InkWell(
        onTap: onView,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: rank <= 3
                      ? const Color(0xFFFFF3CD)
                      : AppColors.surface,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text('#$rank',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: rank <= 3
                              ? const Color(0xFF856404)
                              : AppColors.textSecondary)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(supplier.name,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary)),
                        const SizedBox(width: 8),
                        _BadgeChip(supplier.badge),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                        '${supplier.category} · ${supplier.orders} orders · ★ ${supplier.rating.toStringAsFixed(1)}',
                        style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(supplier.revenue,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary)),
                  Text('${supplier.onTimeDelivery.toStringAsFixed(0)}% on-time',
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textSecondary)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BadgeChip extends StatelessWidget {
  final String badge;
  const _BadgeChip(this.badge);

  Color get _color => switch (badge) {
        'top' => const Color(0xFFFFB300),
        'good' => const Color(0xFF2E7D32),
        'average' => const Color(0xFF1565C0),
        'at_risk' => Colors.red,
        _ => AppColors.textSecondary,
      };

  String get _label => switch (badge) {
        'top' => '⭐ Top Seller',
        'good' => '✓ Good',
        'average' => '~ Average',
        'at_risk' => '⚠ At Risk',
        _ => badge,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(_label,
          style: TextStyle(
              fontSize: 10, fontWeight: FontWeight.w600, color: _color)),
    );
  }
}

class _StripStat extends StatelessWidget {
  final String label, value;
  final Color color;
  const _StripStat(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(value,
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: color, fontSize: 15)),
            Text(label,
                style: const TextStyle(
                    fontSize: 10, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}

class _PerfMetricTile extends StatelessWidget {
  final String label, value;
  final Color color;
  const _PerfMetricTile(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value,
              style: TextStyle(
                  fontWeight: FontWeight.bold, color: color, fontSize: 16)),
          Text(label,
              style: const TextStyle(
                  fontSize: 11, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

class _BenchmarkRow {
  final String label, value;
  final double pct;
  final Color color;
  final bool invertColors;

  const _BenchmarkRow(this.label, this.pct, this.value, this.color,
      {this.invertColors = false});
}

class _SupplierPerf {
  final String name, category, revenue, payout, badge;
  final double rating, onTimeDelivery, returnRate, fillRate;
  final int orders;

  const _SupplierPerf(
    this.name,
    this.category,
    this.rating,
    this.orders,
    this.revenue,
    this.onTimeDelivery,
    this.fillRate,
    this.returnRate,
    this.badge,
    this.payout,
    int _,
  );
}
