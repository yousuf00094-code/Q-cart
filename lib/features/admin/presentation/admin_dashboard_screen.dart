import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import 'supplier_management_screen.dart';
import 'inventory_management_screen.dart';
import 'sales_reports_screen.dart';
import 'product_management_screen.dart';
import 'customer_management_screen.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  static const _kv = [
    _KV('Total Revenue', 'QAR 184,320', Icons.monetization_on_outlined, Color(0xFFDDD9F5)),
    _KV('Orders Today', '47', Icons.shopping_bag_outlined, Color(0xFFD4F5E9)),
    _KV('Active Products', '312', Icons.inventory_2_outlined, Color(0xFFFFE8D6)),
    _KV('Customers', '1,284', Icons.people_outline, Color(0xFFD6EEFF)),
  ];

  static const _alerts = [
    _Alert('Low stock: Saffron Pack 5g', Icons.warning_amber_rounded, Color(0xFFFF9800)),
    _Alert('New supplier pending approval', Icons.business_outlined, Color(0xFF1976D2)),
    _Alert('3 orders awaiting confirmation', Icons.pending_actions_outlined, Color(0xFFE53935)),
    _Alert('New review requires moderation', Icons.rate_review_outlined, Color(0xFF7B1FA2)),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(context),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildGreeting(),
            const SizedBox(height: 20),
            _buildKpiGrid(context),
            const SizedBox(height: 24),
            _buildSectionTitle('Quick Actions'),
            const SizedBox(height: 12),
            _buildQuickActions(context),
            const SizedBox(height: 24),
            _buildSectionTitle('Alerts & Notifications'),
            const SizedBox(height: 12),
            _buildAlerts(),
            const SizedBox(height: 24),
            _buildSectionTitle('Recent Orders'),
            const SizedBox(height: 12),
            _buildRecentOrders(context),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.background,
      elevation: 0,
      title: RichText(
        text: const TextSpan(children: [
          TextSpan(
            text: 'Q',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.secondary),
          ),
          TextSpan(
            text: ' Admin',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
          ),
        ]),
      ),
      actions: [
        Stack(
          children: [
            IconButton(
              icon: const Icon(Icons.notifications_outlined, color: AppColors.textPrimary),
              onPressed: () {},
            ),
            Positioned(
              right: 8,
              top: 8,
              child: Container(
                width: 16,
                height: 16,
                decoration: const BoxDecoration(color: Color(0xFFE53935), shape: BoxShape.circle),
                child: const Center(
                  child: Text('4', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700)),
                ),
              ),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.secondary,
            child: const Text('A', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ),
      ],
    );
  }

  Widget _buildGreeting() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Good morning, Admin',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 2),
        Text(
          'Here\'s what\'s happening with Q Cart today.',
          style: TextStyle(fontSize: 13, color: AppColors.textSecondary.withOpacity(0.8)),
        ),
      ],
    );
  }

  Widget _buildKpiGrid(BuildContext context) {
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.55,
      ),
      itemCount: _kv.length,
      itemBuilder: (_, i) => _KpiCard(item: _kv[i]),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    final actions = [
      _QuickAction('Products', Icons.inventory_2_outlined, () => Navigator.push(context, _route(const ProductManagementScreen()))),
      _QuickAction('Suppliers', Icons.business_outlined, () => Navigator.push(context, _route(const SupplierManagementScreen()))),
      _QuickAction('Inventory', Icons.warehouse_outlined, () => Navigator.push(context, _route(const InventoryManagementScreen()))),
      _QuickAction('Customers', Icons.people_outline, () => Navigator.push(context, _route(const CustomerManagementScreen()))),
      _QuickAction('Sales', Icons.bar_chart_outlined, () => Navigator.push(context, _route(const SalesReportsScreen()))),
      _QuickAction('Settings', Icons.settings_outlined, () {}),
    ];

    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.2,
      ),
      itemCount: actions.length,
      itemBuilder: (_, i) => _ActionTile(action: actions[i]),
    );
  }

  MaterialPageRoute _route(Widget screen) =>
      MaterialPageRoute(builder: (_) => screen);

  Widget _buildAlerts() {
    return Column(
      children: _alerts
          .map((a) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: a.color.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(a.icon, size: 18, color: a.color),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(a.label,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
                    ),
                    const Icon(Icons.arrow_forward_ios, size: 13, color: AppColors.textSecondary),
                  ],
                ),
              ))
          .toList(),
    );
  }

  Widget _buildRecentOrders(BuildContext context) {
    final orders = [
      _RecentOrder('#QC-010047', 'Fatima Al-Dosari', 'QAR 128.50', 'Confirmed'),
      _RecentOrder('#QC-010046', 'Mohammed Al-Thani', 'QAR 340.00', 'Processing'),
      _RecentOrder('#QC-010045', 'Aisha Al-Kuwari', 'QAR 55.00', 'Delivered'),
      _RecentOrder('#QC-010044', 'Omar Al-Nasr', 'QAR 890.00', 'Pending'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Recent Orders', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                GestureDetector(
                  onTap: () {},
                  child: const Text('View all', style: TextStyle(fontSize: 12, color: AppColors.secondary, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.divider),
          ...orders.map((o) => _OrderRow(order: o)),
        ],
      ),
    );
  }
}

// ─── Supporting widgets ────────────────────────────────────────────────────

class _KpiCard extends StatelessWidget {
  const _KpiCard({required this.item});
  final _KV item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: item.color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(item.icon, color: AppColors.secondary, size: 22),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.value,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
              const SizedBox(height: 2),
              Text(item.label,
                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({required this.action});
  final _QuickAction action;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: action.onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(action.icon, color: AppColors.secondary, size: 26),
            const SizedBox(height: 6),
            Text(action.label,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          ],
        ),
      ),
    );
  }
}

class _OrderRow extends StatelessWidget {
  const _OrderRow({required this.order});
  final _RecentOrder order;

  Color get _statusColor => switch (order.status) {
        'Confirmed' => const Color(0xFF1976D2),
        'Processing' => const Color(0xFFF57C00),
        'Delivered' => const Color(0xFF388E3C),
        _ => const Color(0xFF9E9E9E),
      };

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(order.id,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                const SizedBox(height: 2),
                Text(order.customer,
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(order.total,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.secondary)),
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(order.status,
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: _statusColor)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Data classes ──────────────────────────────────────────────────────────

class _KV {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _KV(this.label, this.value, this.icon, this.color);
}

class _Alert {
  final String label;
  final IconData icon;
  final Color color;
  const _Alert(this.label, this.icon, this.color);
}

class _QuickAction {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _QuickAction(this.label, this.icon, this.onTap);
}

class _RecentOrder {
  final String id;
  final String customer;
  final String total;
  final String status;
  const _RecentOrder(this.id, this.customer, this.total, this.status);
}
