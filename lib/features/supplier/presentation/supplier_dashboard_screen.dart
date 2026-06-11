import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import 'supplier_product_submission_screen.dart';
import 'supplier_inventory_screen.dart';
import 'supplier_purchase_orders_screen.dart';
import 'supplier_analytics_screen.dart';
import 'supplier_payout_screen.dart';
import 'supplier_ratings_screen.dart';
import 'supplier_shipment_tracking_screen.dart';

class SupplierDashboardScreen extends StatefulWidget {
  const SupplierDashboardScreen({super.key});

  @override
  State<SupplierDashboardScreen> createState() =>
      _SupplierDashboardScreenState();
}

class _SupplierDashboardScreenState extends State<SupplierDashboardScreen> {
  int _navIndex = 0;

  final List<_KpiData> _kpis = [
    _KpiData('Revenue (MTD)', 'QAR 18,450', Icons.payments_outlined,
        AppColors.secondary, '+12.4%', true),
    _KpiData('Orders', '34', Icons.receipt_long_outlined,
        const Color(0xFF2E7D32), '+5', true),
    _KpiData('Active Products', '128', Icons.inventory_2_outlined,
        const Color(0xFF1565C0), null, null),
    _KpiData('Avg. Rating', '4.7 ★', Icons.star_rounded,
        const Color(0xFFF57F17), null, null),
  ];

  final List<_RecentOrder> _recentOrders = [
    _RecentOrder('ORD-4201', 'QAR 245.00', 'Processing', '2 items', '10 Jun'),
    _RecentOrder('ORD-4198', 'QAR 89.50', 'Shipped', '1 item', '9 Jun'),
    _RecentOrder('ORD-4185', 'QAR 512.00', 'Delivered', '4 items', '8 Jun'),
    _RecentOrder('ORD-4172', 'QAR 67.00', 'Delivered', '1 item', '7 Jun'),
    _RecentOrder('ORD-4160', 'QAR 198.75', 'Cancelled', '2 items', '6 Jun'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: _buildAppBar(),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildAlertBanner()),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildGreeting(),
                  const SizedBox(height: 20),
                  _buildKpiGrid(),
                  const SizedBox(height: 24),
                  _buildQuickActions(),
                  const SizedBox(height: 24),
                  _buildRecentOrders(),
                  const SizedBox(height: 24),
                  _buildPendingApprovals(),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.background,
      elevation: 0,
      title: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.store_rounded, size: 18, color: Colors.white),
          ),
          const SizedBox(width: 10),
          const Text(
            'Q Cart Supplier',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined,
              color: AppColors.textPrimary),
          onPressed: () {},
        ),
        const CircleAvatar(
          radius: 16,
          backgroundColor: AppColors.secondary,
          child: Text('TS',
              style: TextStyle(
                  fontSize: 12,
                  color: Colors.white,
                  fontWeight: FontWeight.w600)),
        ),
        const SizedBox(width: 12),
      ],
    );
  }

  Widget _buildAlertBanner() {
    return Container(
      color: const Color(0xFFFFF3CD),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded,
              color: Color(0xFF856404), size: 18),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              '3 products are low on stock. Update inventory to avoid missed orders.',
              style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF856404),
                  fontWeight: FontWeight.w500),
            ),
          ),
          TextButton(
            onPressed: () => _navigate(SupplierInventoryScreen()),
            child: const Text('Fix',
                style: TextStyle(
                    color: Color(0xFF856404),
                    fontWeight: FontWeight.bold,
                    fontSize: 13)),
          ),
        ],
      ),
    );
  }

  Widget _buildGreeting() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Welcome back, TechStore',
          style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary),
        ),
        const SizedBox(height: 4),
        Text(
          'Tuesday, 10 June 2026',
          style: const TextStyle(
              fontSize: 14, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildKpiGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.5,
      ),
      itemCount: _kpis.length,
      itemBuilder: (_, i) => _KpiCard(data: _kpis[i]),
    );
  }

  Widget _buildQuickActions() {
    final actions = [
      _QuickAction('Add Product', Icons.add_box_outlined, AppColors.secondary,
          () => _navigate(SupplierProductSubmissionScreen())),
      _QuickAction('Inventory', Icons.inventory_outlined,
          const Color(0xFF1565C0), () => _navigate(SupplierInventoryScreen())),
      _QuickAction(
          'Orders',
          Icons.receipt_outlined,
          const Color(0xFF2E7D32),
          () => _navigate(SupplierPurchaseOrdersScreen())),
      _QuickAction('Analytics', Icons.bar_chart_outlined,
          const Color(0xFFF57F17), () => _navigate(SupplierAnalyticsScreen())),
      _QuickAction('Payouts', Icons.account_balance_outlined,
          const Color(0xFF6A1B9A), () => _navigate(SupplierPayoutScreen())),
      _QuickAction('Shipments', Icons.local_shipping_outlined,
          const Color(0xFF00695C), () => _navigate(SupplierShipmentTrackingScreen())),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Quick Actions',
            style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary)),
        const SizedBox(height: 14),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.1,
          ),
          itemCount: actions.length,
          itemBuilder: (_, i) {
            final a = actions[i];
            return GestureDetector(
              onTap: a.onTap,
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: a.color.withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(a.icon, color: a.color, size: 22),
                    ),
                    const SizedBox(height: 8),
                    Text(a.label,
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textPrimary),
                        textAlign: TextAlign.center),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildRecentOrders() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Recent Orders',
                style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary)),
            TextButton(
              onPressed: () => _navigate(SupplierPurchaseOrdersScreen()),
              child: const Text('View All',
                  style: TextStyle(color: AppColors.secondary)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.divider),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _recentOrders.length,
            separatorBuilder: (_, __) =>
                const Divider(height: 1, color: AppColors.divider),
            itemBuilder: (_, i) => _OrderRow(order: _recentOrders[i]),
          ),
        ),
      ],
    );
  }

  Widget _buildPendingApprovals() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.secondary.withOpacity(0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.secondary.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.secondary.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.pending_actions_outlined,
                color: AppColors.secondary),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('2 products pending admin approval',
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary)),
                SizedBox(height: 2),
                Text('Usually approved within 24 hours',
                    style: TextStyle(
                        fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: AppColors.textSecondary),
        ],
      ),
    );
  }

  BottomNavigationBar _buildBottomNav() {
    return BottomNavigationBar(
      currentIndex: _navIndex,
      onTap: (i) {
        setState(() => _navIndex = i);
        switch (i) {
          case 1:
            _navigate(SupplierAnalyticsScreen());
          case 2:
            _navigate(SupplierRatingsScreen());
          case 3:
            _navigate(SupplierPayoutScreen());
        }
      },
      type: BottomNavigationBarType.fixed,
      selectedItemColor: AppColors.secondary,
      unselectedItemColor: AppColors.textSecondary,
      items: const [
        BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined), label: 'Home'),
        BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart_outlined), label: 'Analytics'),
        BottomNavigationBarItem(
            icon: Icon(Icons.star_outline), label: 'Ratings'),
        BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_outlined), label: 'Payouts'),
      ],
    );
  }

  void _navigate(Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }
}

class _KpiCard extends StatelessWidget {
  final _KpiData data;
  const _KpiCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(data.icon, color: data.color, size: 22),
              if (data.badge != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: (data.isPositive == true
                            ? const Color(0xFF2E7D32)
                            : Colors.red)
                        .withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    data.badge!,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: data.isPositive == true
                          ? const Color(0xFF2E7D32)
                          : Colors.red,
                    ),
                  ),
                ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(data.value,
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary)),
              const SizedBox(height: 2),
              Text(data.label,
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary)),
            ],
          ),
        ],
      ),
    );
  }
}

class _OrderRow extends StatelessWidget {
  final _RecentOrder order;
  const _OrderRow({required this.order});

  Color _statusColor(String status) {
    return switch (status) {
      'Delivered' => const Color(0xFF2E7D32),
      'Shipped' => const Color(0xFF1565C0),
      'Processing' => const Color(0xFFF57F17),
      'Cancelled' => Colors.red,
      _ => AppColors.textSecondary,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(order.id,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                        fontSize: 14)),
                const SizedBox(height: 2),
                Text('${order.items} · ${order.date}',
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(order.amount,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary)),
              const SizedBox(height: 4),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _statusColor(order.status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  order.status,
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _statusColor(order.status)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _KpiData {
  final String label, value;
  final IconData icon;
  final Color color;
  final String? badge;
  final bool? isPositive;
  const _KpiData(
      this.label, this.value, this.icon, this.color, this.badge, this.isPositive);
}

class _RecentOrder {
  final String id, amount, status, items, date;
  const _RecentOrder(this.id, this.amount, this.status, this.items, this.date);
}

class _QuickAction {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _QuickAction(this.label, this.icon, this.color, this.onTap);
}
