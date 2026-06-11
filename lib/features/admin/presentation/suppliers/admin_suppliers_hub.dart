import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import 'supplier_approval_screen.dart';
import 'supplier_performance_screen.dart';
import 'supplier_risk_score_screen.dart';
import 'supplier_product_management_screen.dart';

class AdminSuppliersHubScreen extends StatelessWidget {
  const AdminSuppliersHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text(
          'Supplier Management',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SummaryRow(),
          const SizedBox(height: 20),
          const Text(
            'Management Tools',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 12),
          _HubCard(
            icon: Icons.how_to_reg_outlined,
            activeIcon: Icons.how_to_reg,
            title: 'Supplier Approvals',
            subtitle: 'Review and approve new supplier applications',
            badgeCount: 3,
            color: const Color(0xFF4D4A7D),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const AdminSupplierApprovalScreen()),
            ),
          ),
          const SizedBox(height: 12),
          _HubCard(
            icon: Icons.leaderboard_outlined,
            activeIcon: Icons.leaderboard,
            title: 'Performance Reports',
            subtitle: 'Sales, fulfilment rates, and return metrics',
            color: const Color(0xFF1565C0),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const AdminSupplierPerformanceScreen()),
            ),
          ),
          const SizedBox(height: 12),
          _HubCard(
            icon: Icons.security_outlined,
            activeIcon: Icons.security,
            title: 'Risk Scores',
            subtitle: 'Fraud signals, complaint ratios, and suspension flags',
            color: const Color(0xFFC62828),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const AdminSupplierRiskScoreScreen()),
            ),
          ),
          const SizedBox(height: 12),
          _HubCard(
            icon: Icons.inventory_2_outlined,
            activeIcon: Icons.inventory_2,
            title: 'Product Management',
            subtitle: 'Review, approve, and moderate supplier product listings',
            badgeCount: 7,
            color: const Color(0xFF2E7D32),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const AdminSupplierProductManagementScreen()),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const stats = [
      _StatData('Active', '142', Color(0xFF2E7D32)),
      _StatData('Pending', '3', Color(0xFFF57F17)),
      _StatData('Suspended', '8', Color(0xFFC62828)),
      _StatData('Products', '2,841', Color(0xFF1565C0)),
    ];

    return Row(
      children: stats
          .map(
            (s) => Expanded(
              child: Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Column(
                  children: [
                    Text(s.value,
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: s.color)),
                    const SizedBox(height: 2),
                    Text(s.label,
                        style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.textSecondary)),
                  ],
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _HubCard extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String title;
  final String subtitle;
  final int badgeCount;
  final Color color;
  final VoidCallback onTap;

  const _HubCard({
    required this.icon,
    required this.activeIcon,
    required this.title,
    required this.subtitle,
    this.badgeCount = 0,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.background,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.divider),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(title,
                            style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w700,
                                fontSize: 14)),
                        if (badgeCount > 0) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                                color: const Color(0xFFF57F17),
                                borderRadius: BorderRadius.circular(10)),
                            child: Text('$badgeCount',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700)),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(subtitle,
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 12)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right,
                  color: AppColors.textSecondary, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatData {
  final String label;
  final String value;
  final Color color;
  const _StatData(this.label, this.value, this.color);
}
