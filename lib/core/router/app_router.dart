import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';

import '../splash/splash_page.dart';
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

  static const String splash = '/splash';
  static const String login = '/login';
  static const String register = '/register';
  static const String tenantSelect = '/tenant-select';
  static const String home = '/';
  static const String adisyon = '/adisyon';
  static const String closeCheck = '/close-check';
  static const String products = '/products';
  static const String reports = '/reports';

  static GoRouter create() => GoRouter(
    initialLocation: splash,
    routes: [
      GoRoute(path: splash, builder: (_, __) => const SplashPage()),
      GoRoute(path: login, builder: (_, __) => const LoginPage()),
      GoRoute(path: register, builder: (_, __) => const RegisterPage()),
      GoRoute(path: tenantSelect, builder: (_, __) => const TenantSelectPage()),
      GoRoute(path: home, builder: (_, __) => const TablesHomePage()),
      GoRoute(
        path: adisyon,
        builder: (_, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          final tableId = extra['tableId'];
          final tableName = extra['tableName'];
          final isPackage = extra['isPackage'];
          return AdisyonPage(
            tableId: tableId is String ? tableId : null,
            tableName: tableName is String ? tableName : 'Masa',
            isPackage: isPackage is bool ? isPackage : false,
          );
        },
      ),
      GoRoute(
        path: closeCheck,
        builder: (_, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          final orderId = extra['orderId'];
          final total = extra['total'];
          final tableName = extra['tableName'];
          if (orderId is! String || total is! num) {
            return const _RouteDataMissingPage(
              title: 'Adisyon verisi bulunamadı',
              message: 'Lutfen hesap ekranina geri donup tekrar deneyin.',
            );
          }
          return CloseCheckPage(
            orderId: orderId,
            total: total.toDouble(),
            tableName: tableName is String ? tableName : '',
          );
        },
      ),
      GoRoute(path: products, builder: (_, __) => const ProductsPage()),
      GoRoute(path: reports, builder: (_, __) => const ReportsPage()),
    ],
  );
}

class _RouteDataMissingPage extends StatelessWidget {
  const _RouteDataMissingPage({
    required this.title,
    required this.message,
  });

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Uyari')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48),
              const SizedBox(height: 12),
              Text(title, textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
