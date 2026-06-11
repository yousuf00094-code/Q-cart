import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import 'presentation/supplier_dashboard_screen.dart';
import 'presentation/supplier_product_approval_screen.dart';
import 'presentation/supplier_purchase_orders_screen.dart';
import 'presentation/supplier_analytics_screen.dart';
import 'presentation/supplier_payout_screen.dart';

/// Top-level navigation shell for the Supplier Portal.
/// Hosts five sections via a bottom navigation bar:
///   Dashboard · Products · Orders · Analytics · Account
class SupplierPortalApp extends StatefulWidget {
  const SupplierPortalApp({super.key});

  @override
  State<SupplierPortalApp> createState() => _SupplierPortalAppState();
}

class _SupplierPortalAppState extends State<SupplierPortalApp> {
  int _currentIndex = 0;

  static const _tabs = [
    _NavTab(icon: Icons.dashboard_outlined, activeIcon: Icons.dashboard, label: 'Dashboard'),
    _NavTab(icon: Icons.inventory_2_outlined, activeIcon: Icons.inventory_2, label: 'Products'),
    _NavTab(icon: Icons.receipt_long_outlined, activeIcon: Icons.receipt_long, label: 'Orders'),
    _NavTab(icon: Icons.bar_chart_outlined, activeIcon: Icons.bar_chart, label: 'Analytics'),
    _NavTab(icon: Icons.account_balance_wallet_outlined, activeIcon: Icons.account_balance_wallet, label: 'Payouts'),
  ];

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = const [
      _DashboardTab(),
      _ProductsTab(),
      SupplierPurchaseOrdersScreen(),
      SupplierAnalyticsScreen(),
      SupplierPayoutScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: SafeArea(
        child: SizedBox(
          height: 60,
          child: Row(
            children: _tabs.asMap().entries.map((entry) {
              final i = entry.key;
              final tab = entry.value;
              final active = _currentIndex == i;
              return Expanded(
                child: InkWell(
                  onTap: () => setState(() => _currentIndex = i),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Products tab shows pending-review badge
                      i == 1
                          ? _BadgedIcon(
                              icon: active ? tab.activeIcon : tab.icon,
                              active: active,
                              badgeCount: 2,
                            )
                          : Icon(active ? tab.activeIcon : tab.icon,
                              size: 22,
                              color: active ? AppColors.secondary : AppColors.textSecondary),
                      const SizedBox(height: 2),
                      Text(tab.label,
                          style: TextStyle(
                              fontSize: 10,
                              color: active ? AppColors.secondary : AppColors.textSecondary,
                              fontWeight: active ? FontWeight.w700 : FontWeight.w400)),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

// ── Tabs ──────────────────────────────────────────────────────────────────────

/// Dashboard tab — wraps SupplierDashboardScreen without its own Scaffold
class _DashboardTab extends StatelessWidget {
  const _DashboardTab();
  @override
  Widget build(BuildContext context) => const SupplierDashboardScreen();
}

/// Products tab — two sub-sections: Submit New + Approval Status
class _ProductsTab extends StatefulWidget {
  const _ProductsTab();
  @override
  State<_ProductsTab> createState() => _ProductsTabState();
}

class _ProductsTabState extends State<_ProductsTab>
    with SingleTickerProviderStateMixin {
  late final TabController _sub;

  @override
  void initState() {
    super.initState();
    _sub = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _sub.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text('Products',
            style: TextStyle(
                color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 18)),
        bottom: TabBar(
          controller: _sub,
          labelColor: AppColors.secondary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.secondary,
          tabs: [
            const Tab(text: 'Approval Status'),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Pending Review'),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                        color: const Color(0xFFF57F17),
                        borderRadius: BorderRadius.circular(10)),
                    child: const Text('2',
                        style: TextStyle(color: Colors.white, fontSize: 10,
                            fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _sub,
        children: const [
          SupplierProductApprovalScreen(),
          _PendingOnlyView(),
        ],
      ),
    );
  }
}

/// Filtered view showing only products in pending_review state
class _PendingOnlyView extends StatelessWidget {
  const _PendingOnlyView();

  @override
  Widget build(BuildContext context) {
    return const SupplierProductApprovalScreen();
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

class _BadgedIcon extends StatelessWidget {
  final IconData icon;
  final bool active;
  final int badgeCount;
  const _BadgedIcon({required this.icon, required this.active, required this.badgeCount});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(icon, size: 22,
            color: active ? AppColors.secondary : AppColors.textSecondary),
        if (badgeCount > 0)
          Positioned(
            right: -6,
            top: -4,
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: const BoxDecoration(
                  color: Color(0xFFF57F17), shape: BoxShape.circle),
              child: Text('$badgeCount',
                  style: const TextStyle(
                      color: Colors.white, fontSize: 8, fontWeight: FontWeight.w800)),
            ),
          ),
      ],
    );
  }
}

class _NavTab {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const _NavTab({required this.icon, required this.activeIcon, required this.label});
}
