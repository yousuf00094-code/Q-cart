import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/theme/app_theme.dart';
import 'core/services/auth_service.dart';
import 'core/services/locale_service.dart';
import 'app_shell.dart';
import 'features/cart/presentation/cart_screen.dart';
import 'features/checkout/presentation/checkout_screen.dart';
import 'features/checkout/presentation/order_confirmation_screen.dart';
import 'features/orders/presentation/orders_screen.dart';
import 'features/orders/presentation/order_detail_screen.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/auth/presentation/register_screen.dart';
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
  await LocaleService.init();
  runApp(const QCartApp());
}

class QCartApp extends StatelessWidget {
  const QCartApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: LocaleService.localeNotifier,
      builder: (context, locale, _) {
        return MaterialApp(
          title: 'Q Cart',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          locale: locale,
          supportedLocales: const [
            Locale('en'),
            Locale('ar'),
          ],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: const CustomerShell(),
          routes: {
            '/': (_) => const CustomerShell(),
            '/login': (_) => const LoginScreen(),
            '/register': (_) => const RegisterScreen(),
            '/cart': (_) => const CartScreen(),
            '/checkout': (_) => const CheckoutScreen(),
            '/orders': (_) => const OrdersScreen(),
            '/profile/addresses': (_) => const AddressesScreen(),
            '/supplier': (_) => const SupplierPortalApp(),
            '/supplier/login': (_) => const SupplierLoginScreen(),
            '/supplier/dashboard': (_) => const SupplierDashboardScreen(),
            '/supplier/products/submit': (_) => const SupplierProductSubmissionScreen(),
            '/supplier/products/approval': (_) => const SupplierProductApprovalScreen(),
            '/supplier/inventory': (_) => const SupplierInventoryScreen(),
            '/supplier/orders': (_) => const SupplierPurchaseOrdersScreen(),
            '/supplier/shipments': (_) => const SupplierShipmentTrackingScreen(),
            '/supplier/analytics': (_) => const SupplierAnalyticsScreen(),
            '/supplier/ratings': (_) => const SupplierRatingsScreen(),
            '/supplier/payouts': (_) => const SupplierPayoutScreen(),
            '/admin/suppliers': (_) => const AdminSuppliersHubScreen(),
            '/admin/suppliers/approvals': (_) => const AdminSupplierApprovalScreen(),
            '/admin/suppliers/performance': (_) => const AdminSupplierPerformanceScreen(),
            '/admin/suppliers/risk': (_) => const AdminSupplierRiskScoreScreen(),
            '/admin/suppliers/products': (_) => const AdminSupplierProductManagementScreen(),
          },
          onGenerateRoute: (settings) {
            if (settings.name == '/order-confirmation') {
              final order = settings.arguments as Map<String, dynamic>;
              return MaterialPageRoute(
                builder: (_) => OrderConfirmationScreen(order: order),
                settings: settings,
              );
            }
            if (settings.name == '/order-detail') {
              final orderId = settings.arguments as String;
              return MaterialPageRoute(
                builder: (_) => OrderDetailScreen(orderId: orderId),
                settings: settings,
              );
            }
            return null;
          },
        );
      },
    );
  }
}

class AddressesScreen extends StatelessWidget {
  const AddressesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: Color(0xFF2E2E3A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'My Addresses',
          style: TextStyle(color: Color(0xFF2E2E3A), fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: const Center(
        child: Text(
          'Addresses coming soon',
          style: TextStyle(color: Color(0xFF6B6B7B), fontSize: 16),
        ),
      ),
    );
  }
}
