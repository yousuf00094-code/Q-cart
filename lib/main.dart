import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'core/services/auth_service.dart';
import 'features/home/presentation/home_screen.dart';
import 'features/supplier/supplier_portal_app.dart';
import 'features/supplier/presentation/supplier_login_screen.dart';
import 'features/supplier/presentation/supplier_dashboard_screen.dart';
import 'features/supplier/presentation/supplier_product_submission_screen.dart';
import 'features/supplier/presentation/supplier_product_approval_screen.dart';
import 'features/supplier/presentation/supplier_inventory_screen.dart';
import 'features/supplier/presentation/supplier_purchase_orders_screen.dart';
import 'features/supplier/presentation/supplier_shipment_tracking_screen.dart';
import 'features/supplier/presentation/supplier_analytics_screen.dart';
import 'features/supplier/presentation/supplier_ratings_screen.dart';
import 'features/supplier/presentation/supplier_payout_screen.dart';
import 'features/admin/presentation/suppliers/admin_suppliers_hub.dart';
import 'features/admin/presentation/suppliers/supplier_approval_screen.dart';
import 'features/admin/presentation/suppliers/supplier_performance_screen.dart';
import 'features/admin/presentation/suppliers/supplier_risk_score_screen.dart';
import 'features/admin/presentation/suppliers/supplier_product_management_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AuthService.init();
  runApp(const QCartApp());
}

class QCartApp extends StatelessWidget {
  const QCartApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Q Cart',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const HomeScreen(),
      routes: {
        // Supplier portal
        '/supplier': (_) => const SupplierPortalApp(),
        '/supplier/login': (_) => const SupplierLoginScreen(),
        '/supplier/dashboard': (_) => const SupplierDashboardScreen(),
        '/supplier/products/submit': (_) =>
            const SupplierProductSubmissionScreen(),
        '/supplier/products/approval': (_) =>
            const SupplierProductApprovalScreen(),
        '/supplier/inventory': (_) => const SupplierInventoryScreen(),
        '/supplier/orders': (_) => const SupplierPurchaseOrdersScreen(),
        '/supplier/shipments': (_) => const SupplierShipmentTrackingScreen(),
        '/supplier/analytics': (_) => const SupplierAnalyticsScreen(),
        '/supplier/ratings': (_) => const SupplierRatingsScreen(),
        '/supplier/payouts': (_) => const SupplierPayoutScreen(),

        // Admin — supplier management
        '/admin/suppliers': (_) => const AdminSuppliersHubScreen(),
        '/admin/suppliers/approvals': (_) =>
            const AdminSupplierApprovalScreen(),
        '/admin/suppliers/performance': (_) =>
            const AdminSupplierPerformanceScreen(),
        '/admin/suppliers/risk': (_) => const AdminSupplierRiskScoreScreen(),
        '/admin/suppliers/products': (_) =>
            const AdminSupplierProductManagementScreen(),
      },
    );
  }
}
