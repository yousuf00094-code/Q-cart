import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/config/environment.dart';
import 'core/theme/app_theme.dart';
import 'core/services/auth_service.dart';
import 'core/services/locale_service.dart';
import 'core/services/notification_service.dart';
import 'app_shell.dart';
import 'features/cart/presentation/cart_screen.dart';
import 'features/checkout/presentation/checkout_screen.dart';
import 'features/checkout/presentation/payment_screen.dart';
import 'features/checkout/presentation/payment_success_screen.dart';
import 'features/checkout/presentation/payment_failed_screen.dart';
import 'features/checkout/presentation/order_confirmation_screen.dart';
import 'features/orders/presentation/orders_screen.dart';
import 'features/orders/presentation/order_detail_screen.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/auth/presentation/register_screen.dart';
import 'features/profile/presentation/addresses_screen.dart';
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
  debugPrint('[Q Cart] env=${AppEnvironment.name}  api=${AppEnvironment.apiBaseUrl}');
  await AuthService.init();
  await LocaleService.init();
  await NotificationService.init();
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
            if (settings.name == '/payment') {
              final args = settings.arguments as Map<String, dynamic>;
              return MaterialPageRoute(
                builder: (_) => PaymentScreen(
                  addressId: args['address_id'] as String,
                  couponCode: args['coupon_code'] as String?,
                  total: (args['total'] as num).toDouble(),
                ),
                settings: settings,
              );
            }
            if (settings.name == '/payment/success') {
              final order = settings.arguments as Map<String, dynamic>;
              return MaterialPageRoute(
                builder: (_) => PaymentSuccessScreen(order: order),
                settings: settings,
              );
            }
            if (settings.name == '/payment/failed') {
              final args = settings.arguments as Map<String, dynamic>?;
              return MaterialPageRoute(
                builder: (_) => PaymentFailedScreen(errorMessage: args?['error'] as String?),
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
