import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/app_providers.dart';
import '../router/app_router.dart';

/// İlk açılış ekranı. Auth durumu kesinleşene kadar gösterilir,
/// sonra giriş yapmışsa tenant-select, yapmamışsa login'e yönlendirir.
class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage> {
  bool _didNavigate = false;

  @override
  void dispose() {
    _didNavigate = true;
    super.dispose();
  }

  void _navigate(bool toLogin) {
    if (_didNavigate) return;
    _didNavigate = true;
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (toLogin) {
        context.go(AppRouter.login);
      } else {
        context.go(AppRouter.tenantSelect);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(currentUserProvider);
    if (!auth.isLoading) {
      _navigate(auth.valueOrNull == null);
    }

    final accent = Theme.of(context).colorScheme.primary;
    return Scaffold(
      backgroundColor: accent,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.restaurant_menu,
              size: 80,
              color: Colors.white,
            ),
            const SizedBox(height: 24),
            Text(
              'Adisyon',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 32),
            const SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
