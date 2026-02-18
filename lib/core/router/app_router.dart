import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/login_page.dart';
import '../../features/auth/presentation/register_page.dart';
import '../../features/auth/presentation/tenant_select_page.dart';
import '../../features/tables/presentation/tables_home_page.dart';
import '../../features/adisyon/presentation/adisyon_page.dart';
import '../../features/adisyon/presentation/close_check_page.dart';
import '../../features/products/presentation/products_page.dart';
import '../../features/reports/presentation/reports_page.dart';

class AppRouter {
  AppRouter._();

  static const String login = '/login';
  static const String register = '/register';
  static const String tenantSelect = '/tenant-select';
  static const String home = '/';
  static const String adisyon = '/adisyon';
  static const String closeCheck = '/close-check';
  static const String products = '/products';
  static const String reports = '/reports';

  static GoRouter create() => GoRouter(
        initialLocation: login,
        routes: [
          GoRoute(path: login, builder: (_, __) => const LoginPage()),
          GoRoute(path: register, builder: (_, __) => const RegisterPage()),
          GoRoute(path: tenantSelect, builder: (_, __) => const TenantSelectPage()),
          GoRoute(path: home, builder: (_, __) => const TablesHomePage()),
          GoRoute(
            path: adisyon,
            builder: (_, state) {
              final extra = state.extra as Map<String, dynamic>? ?? {};
              return AdisyonPage(
                tableId: extra['tableId'] as String?,
                tableName: extra['tableName'] as String? ?? 'Masa',
                isPackage: extra['isPackage'] as bool? ?? false,
              );
            },
          ),
          GoRoute(
            path: closeCheck,
            builder: (_, state) {
              final extra = state.extra as Map<String, dynamic>? ?? {};
              return CloseCheckPage(
                orderId: extra['orderId'] as String,
                total: (extra['total'] as num).toDouble(),
                tableName: extra['tableName'] as String? ?? '',
              );
            },
          ),
          GoRoute(path: products, builder: (_, __) => const ProductsPage()),
          GoRoute(path: reports, builder: (_, __) => const ReportsPage()),
        ],
      );
}
