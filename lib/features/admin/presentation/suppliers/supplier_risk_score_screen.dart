import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class AdminSupplierRiskScoreScreen extends StatefulWidget {
  const AdminSupplierRiskScoreScreen({super.key});

  @override
  State<AdminSupplierRiskScoreScreen> createState() =>
      _AdminSupplierRiskScoreScreenState();
}

class _AdminSupplierRiskScoreScreenState
    extends State<AdminSupplierRiskScoreScreen> {
  String _filterRisk = 'all';

  final List<_RiskSupplier> _suppliers = [
    _RiskSupplier(
      'Gulf Sports Co.',
      'Sports',
      72,
      'high',
      [
        _RiskFactor('High return rate', 8.2, 5.0, 'critical'),
        _RiskFactor('Low fill rate', 79.2, 90.0, 'warning'),
        _RiskFactor('Declining rating', 3.8, 4.0, 'warning'),
        _RiskFactor('Late shipments (15%)', 84.0, 95.0, 'critical'),
      ],
      '3 active warnings',
    ),
    _RiskSupplier(
      'Doha Fashion House',
      'Clothing',
      45,
      'medium',
      [
        _RiskFactor('Return rate elevated', 3.5, 3.0, 'warning'),
        _RiskFactor('Occasional late delivery', 88.5, 95.0, 'warning'),
      ],
      '2 active warnings',
    ),
    _RiskSupplier(
      'Qatar Home Essentials',
      'Home & Garden',
      28,
      'low',
      [
        _RiskFactor('Inventory gaps (seasonal)', 93.2, 95.0, 'info'),
      ],
      '1 minor note',
    ),
    _RiskSupplier(
      'TechStore Qatar',
      'Electronics',
      8,
      'minimal',
      [],
      'No active issues',
    ),
    _RiskSupplier(
      'AlFahad Electronics',
      'Electronics',
      15,
      'minimal',
      [
        _RiskFactor('Minor stock outs (twice)', 95.1, 97.0, 'info'),
      ],
      '1 minor note',
    ),
  ];

  List<_RiskSupplier> get _filtered {
    if (_filterRisk == 'all') return _suppliers;
    return _suppliers.where((s) => s.riskLevel == _filterRisk).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Supplier Risk Scores',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary)),
        backgroundColor: AppColors.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_active_outlined),
            onPressed: () {},
            tooltip: 'Risk Alerts',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildRiskSummaryBanner(),
          _buildFilterChips(),
          Expanded(
            child: _filtered.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount: _filtered.length,
                    itemBuilder: (_, i) => _RiskCard(
                      supplier: _filtered[i],
                      onView: () => _showRiskDetail(_filtered[i]),
                      onAction: _filtered[i].riskLevel == 'high'
                          ? () => _showActionSheet(_filtered[i])
                          : null,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildRiskSummaryBanner() {
    final high = _suppliers.where((s) => s.riskLevel == 'high').length;
    final medium = _suppliers.where((s) => s.riskLevel == 'medium').length;
    final low = _suppliers.where((s) => s.riskLevel == 'low').length;

    return Container(
      color: high > 0
          ? Colors.red.withOpacity(0.08)
          : AppColors.primary.withOpacity(0.1),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(
            high > 0 ? Icons.warning_amber_rounded : Icons.check_circle_outline,
            color: high > 0 ? Colors.red : const Color(0xFF2E7D32),
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              high > 0
                  ? '$high supplier${high > 1 ? 's' : ''} require immediate attention'
                  : 'Supplier risk is under control',
              style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: high > 0 ? Colors.red : const Color(0xFF2E7D32),
                  fontSize: 13),
            ),
          ),
          Row(
            children: [
              _RiskDot('H', '$high', Colors.red),
              const SizedBox(width: 6),
              _RiskDot('M', '$medium', Colors.orange),
              const SizedBox(width: 6),
              _RiskDot('L', '$low', const Color(0xFF2E7D32)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    final filters = [
      ('all', 'All'),
      ('high', 'High Risk'),
      ('medium', 'Medium'),
      ('low', 'Low'),
      ('minimal', 'Minimal'),
    ];
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        children: filters.map((f) {
          final selected = _filterRisk == f.$1;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(f.$2,
                  style: TextStyle(
                      color: selected
                          ? AppColors.secondary
                          : AppColors.textSecondary,
                      fontWeight: selected
                          ? FontWeight.w600
                          : FontWeight.normal,
                      fontSize: 13)),
              selected: selected,
              onSelected: (_) => setState(() => _filterRisk = f.$1),
              selectedColor: AppColors.secondary.withOpacity(0.15),
              checkmarkColor: AppColors.secondary,
              backgroundColor: AppColors.background,
              side: BorderSide(
                  color: selected
                      ? AppColors.secondary.withOpacity(0.4)
                      : AppColors.divider),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Text('No suppliers at this risk level',
          style: TextStyle(color: AppColors.textSecondary)),
    );
  }

  void _showRiskDetail(_RiskSupplier s) {
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
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s.name,
                          style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary)),
                      Text(s.category,
                          style: const TextStyle(
                              color: AppColors.textSecondary)),
                    ],
                  ),
                  _RiskBadge(s.riskLevel, s.score),
                ],
              ),
              const SizedBox(height: 16),
              _buildRiskGauge(s.score),
              if (s.factors.isEmpty) ...[
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E7D32).withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.check_circle_outline,
                          color: Color(0xFF2E7D32)),
                      SizedBox(width: 8),
                      Text('No risk factors identified',
                          style: TextStyle(color: Color(0xFF2E7D32))),
                    ],
                  ),
                ),
              ] else ...[
                const Divider(height: 28),
                const Text('Risk Factors',
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                        fontSize: 15)),
                const SizedBox(height: 12),
                ...s.factors.map((f) => _RiskFactorTile(factor: f)),
              ],
              if (s.riskLevel == 'high') ...[
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _showActionSheet(s);
                    },
                    icon: const Icon(Icons.warning_amber_outlined,
                        color: Colors.white),
                    label: const Text('Take Action',
                        style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRiskGauge(int score) {
    final color = score >= 60
        ? Colors.red
        : score >= 35
            ? Colors.orange
            : const Color(0xFF2E7D32);
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Risk Score',
                style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary)),
            Text('$score / 100',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: color,
                    fontSize: 16)),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: score / 100,
            minHeight: 12,
            backgroundColor: color.withOpacity(0.15),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            Text('0 — Safe', style: TextStyle(fontSize: 10, color: Color(0xFF2E7D32))),
            Text('50 — Moderate', style: TextStyle(fontSize: 10, color: Colors.orange)),
            Text('100 — Critical', style: TextStyle(fontSize: 10, color: Colors.red)),
          ],
        ),
      ],
    );
  }

  void _showActionSheet(_RiskSupplier s) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Take Action — ${s.name}',
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 8),
            Text(s.summary,
                style: const TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 20),
            ...[
              (Icons.mail_outline, 'Send Warning Email', const Color(0xFFF57F17)),
              (Icons.pause_circle_outline, 'Suspend New Orders', Colors.orange),
              (Icons.block_outlined, 'Suspend Account', Colors.red),
              (Icons.support_agent_outlined, 'Assign Account Manager',
                  AppColors.secondary),
            ].map(
              (a) => ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: a.$3.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(a.$1, color: a.$3, size: 20),
                ),
                title: Text(a.$2,
                    style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary)),
                onTap: () => Navigator.pop(context),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RiskCard extends StatelessWidget {
  final _RiskSupplier supplier;
  final VoidCallback onView;
  final VoidCallback? onAction;

  const _RiskCard(
      {required this.supplier,
      required this.onView,
      this.onAction});

  @override
  Widget build(BuildContext context) {
    final color = supplier.riskLevel == 'high'
        ? Colors.red
        : supplier.riskLevel == 'medium'
            ? Colors.orange
            : supplier.riskLevel == 'low'
                ? const Color(0xFF2E7D32)
                : AppColors.textSecondary;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: supplier.riskLevel == 'high'
              ? Colors.red.withOpacity(0.3)
              : AppColors.divider,
        ),
      ),
      child: InkWell(
        onTap: onView,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(supplier.name,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary)),
                        Text(supplier.category,
                            style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                  _RiskBadge(supplier.riskLevel, supplier.score),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: supplier.score / 100,
                  minHeight: 6,
                  backgroundColor: color.withOpacity(0.12),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(supplier.summary,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textSecondary)),
                  if (onAction != null)
                    TextButton(
                      onPressed: onAction,
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.red,
                        padding:
                            const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        textStyle: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                      child: const Text('Take Action'),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RiskBadge extends StatelessWidget {
  final String level;
  final int score;
  const _RiskBadge(this.level, this.score);

  Color get _color => switch (level) {
        'high' => Colors.red,
        'medium' => Colors.orange,
        'low' => const Color(0xFF2E7D32),
        _ => AppColors.textSecondary,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text('Score $score',
          style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: _color)),
    );
  }
}

class _RiskFactorTile extends StatelessWidget {
  final _RiskFactor factor;
  const _RiskFactorTile({required this.factor});

  Color get _color => switch (factor.severity) {
        'critical' => Colors.red,
        'warning' => Colors.orange,
        _ => const Color(0xFF1565C0),
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(
            factor.severity == 'critical'
                ? Icons.error_outline
                : factor.severity == 'warning'
                    ? Icons.warning_amber_outlined
                    : Icons.info_outline,
            color: _color,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(factor.label,
                    style: TextStyle(
                        fontWeight: FontWeight.w500, color: _color)),
                Text(
                    'Actual: ${factor.actual.toStringAsFixed(1)} · Target: ${factor.target.toStringAsFixed(1)}',
                    style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RiskDot extends StatelessWidget {
  final String level, count;
  final Color color;
  const _RiskDot(this.level, this.count, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text('$level:$count',
          style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: color)),
    );
  }
}

class _RiskSupplier {
  final String name, category, riskLevel, summary;
  final int score;
  final List<_RiskFactor> factors;

  const _RiskSupplier(
      this.name, this.category, this.score, this.riskLevel, this.factors, this.summary);
}

class _RiskFactor {
  final String label, severity;
  final double actual, target;
  const _RiskFactor(this.label, this.actual, this.target, this.severity);
}
