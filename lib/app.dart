import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  late final GoRouter _router = AppRouter.create();

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Adisyon',
      theme: AppTheme.light,
      routerConfig: _router,
      builder: (context, child) {
        return _RootFocusGuard(
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}

class _RootFocusGuard extends StatefulWidget {
  const _RootFocusGuard({required this.child});

  final Widget child;

  @override
  State<_RootFocusGuard> createState() => _RootFocusGuardState();
}

class _RootFocusGuardState extends State<_RootFocusGuard>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _clearFocusNextFrame();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _clearFocusNow();
    }
  }

  @override
  void didChangeMetrics() {
    _clearFocusNextFrame();
  }

  void _clearFocusNow() {
    FocusManager.instance.primaryFocus?.unfocus();
  }

  void _clearFocusNextFrame() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _clearFocusNow();
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
