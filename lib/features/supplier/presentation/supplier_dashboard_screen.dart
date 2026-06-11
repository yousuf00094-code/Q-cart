import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/supplier_service.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/api_client.dart';
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

  List<_KpiData>? _kpis;
  List<_RecentOrder>? _recentOrders;
  int _pendingCount = 0;
  int _lowStockCount = 0;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        SupplierService.getDashboard(),
        SupplierService.getOrders(page: 1),
        SupplierService.getProducts(status: 'inactive'),
        SupplierService.getInventory(lowStock: true),
        SupplierService.getRatingsSummary(),
      ]);

      final dashboard = results[0] as Map<String, dynamic>;
      final ordersResult = results[1] as Map<String, dynamic>;
      final inactiveResult = results[2] as Map<String, dynamic>;
      final lowStockResult = results[3] as Map<String, dynamic>;
      final ratingSummary = results[4] as Map<String, dynamic>;

      // Map KPIs — analytics endpoint nests data under 'kpis'
      final kpis = dashboard['kpis'] as Map<String, dynamic>? ?? {};
      final revenueMtd = kpis['revenue_mtd'];
      final totalOrders = kpis['total_orders'];
      final activeProducts = kpis['active_products'];
      final avgRating = ratingSummary['avg_rating'];

      final kpis = [
        _KpiData(
          'Revenue (MTD)',
          'QAR ${_formatAmount(revenueMtd)}',
          Icons.payments_outlined,
          AppColors.secondary,
          null,
          null,
        ),
        _KpiData(
          'Orders',
          '${totalOrders ?? 0}',
          Icons.receipt_long_outlined,
          const Color(0xFF2E7D32),
          null,
          null,
        ),
        _KpiData(
          'Active Products',
          '${activeProducts ?? 0}',
          Icons.inventory_2_outlined,
          const Color(0xFF1565C0),
          null,
          null,
        ),
        _KpiData(
          'Avg. Rating',
          '${_formatRating(avgRating)} ★',
          Icons.star_rounded,
          const Color(0xFFF57F17),
          null,
          null,
        ),
      ];

      // Map recent orders (first 5)
      final ordersList = (ordersResult['data'] as List<dynamic>? ?? []).take(5);
      final recentOrders = ordersList.map((o) {
        final map = o as Map<String, dynamic>;
        final status = _normalizeStatus(map['status']?.toString() ?? '');
        final itemCount = map['item_count'] ?? 0;
        final itemLabel = itemCount == 1 ? '1 item' : '$itemCount items';
        return _RecentOrder(
          map['order_number']?.toString() ?? map['id']?.toString() ?? '',
          'QAR ${_formatAmount(map['total'])}',
          status,
          itemLabel,
          _formatOrderDate(map['created_at']?.toString() ?? ''),
        );
      }).toList();

      // Pending approvals count
      final inactiveMeta = inactiveResult['meta'] as Map<String, dynamic>? ?? {};
      final pendingCount = (inactiveMeta['total'] as num?)?.toInt() ?? 0;

      // Low stock count
      final lowStockMeta = lowStockResult['meta'] as Map<String, dynamic>? ?? {};
      final lowStockCount = (lowStockMeta['total'] as num?)?.toInt() ?? 0;

      if (!mounted) return;
      setState(() {
        _kpis = kpis;
        _recentOrders = recentOrders;
        _pendingCount = pendingCount;
        _lowStockCount = lowStockCount;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load. Pull down to retry.';
        _loading = false;
      });
    }
  }

  String _formatAmount(dynamic value) {
    if (value == null) return '0';
    final num = (value as num).toDouble();
    if (num >= 1000) {
      return num.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (m) => '${m[1]},',
      );
    }
    return num.toStringAsFixed(2);
  }

  String _formatRating(dynamic value) {
    if (value == null) return '0.0';
    return (value as num).toStringAsFixed(1);
  }

  String _normalizeStatus(String raw) {
    if (raw.isEmpty) return raw;
    return raw[0].toUpperCase() + raw.substring(1).toLowerCase();
  }

  String _formatOrderDate(String iso) {
    if (iso.isEmpty) return '';
    final dt = DateTime.tryParse(iso);
    if (dt == null) return '';
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${dt.day} ${months[dt.month - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: _buildAppBar(),
      body: RefreshIndicator(
        onRefresh: _fetchData,
        child: _buildBody(),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline,
                  size: 48, color: AppColors.textSecondary),
              const SizedBox(height: 12),
              Text(_error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 16),
              ElevatedButton(
                  onPressed: _fetchData, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }
    return CustomScrollView(
      slivers: [
        if (_lowStockCount > 0)
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
                if (_pendingCount > 0) _buildPendingApprovals(),
                if (_pendingCount > 0) const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ],
    );
  }

  AppBar _buildAppBar() {
    final name = AuthService.currentUser?['full_name']?.toString() ?? 'Supplier';
    final initials = name.isNotEmpty ? name[0].toUpperCase() : 'S';
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
        CircleAvatar(
          radius: 16,
          backgroundColor: AppColors.secondary,
          child: Text(initials,
              style: const TextStyle(
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
          Expanded(
            child: Text(
              '$_lowStockCount ${_lowStockCount == 1 ? 'product is' : 'products are'} low on stock. Update inventory to avoid missed orders.',
              style: const TextStyle(
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
    final name = AuthService.currentUser?['full_name']?.toString() ?? 'Supplier';
    final now = DateTime.now();
    final days = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
    ];
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    final dayName = days[now.weekday - 1];
    final dateStr = '$dayName, ${now.day} ${months[now.month - 1]} ${now.year}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Welcome back, $name',
          style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary),
        ),
        const SizedBox(height: 4),
        Text(
          dateStr,
          style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildKpiGrid() {
    final kpis = _kpis ?? [];
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.5,
      ),
      itemCount: kpis.length,
      itemBuilder: (_, i) => _KpiCard(data: kpis[i]),
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
    final orders = _recentOrders ?? [];
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
        if (orders.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text('No orders yet.',
                  style: TextStyle(color: AppColors.textSecondary)),
            ),
          )
        else
          Container(
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.divider),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: orders.length,
              separatorBuilder: (_, __) =>
                  const Divider(height: 1, color: AppColors.divider),
              itemBuilder: (_, i) => _OrderRow(order: orders[i]),
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$_pendingCount ${_pendingCount == 1 ? 'product' : 'products'} pending admin approval',
                  style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary),
                ),
                const SizedBox(height: 2),
                const Text('Usually approved within 24 hours',
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
    return switch (status.toLowerCase()) {
      'delivered' => const Color(0xFF2E7D32),
      'shipped' => const Color(0xFF1565C0),
      'processing' => const Color(0xFFF57F17),
      'cancelled' => Colors.red,
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
