import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/responsive/responsive.dart';
import '../../../core/router/app_router.dart';
import '../../../data/models/order_model.dart';
import '../../../data/models/table_model.dart';

class TablesHomePage extends ConsumerStatefulWidget {
  const TablesHomePage({super.key});

  @override
  ConsumerState<TablesHomePage> createState() => _TablesHomePageState();
}

class _TablesHomePageState extends ConsumerState<TablesHomePage> {
  List<TableModel> _tables = [];
  List<OrderModel> _openOrders = [];
  bool _loading = true;
  String? _error;
  StreamSubscription<List<OrderModel>>? _ordersSub;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _ordersSub?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    final auth = ref.read(currentUserProvider);
    final tenantId = ref.read(tenantIdProvider);
    if (auth.isLoading) return;
    if (auth.valueOrNull == null || tenantId == null) {
      if (mounted) context.go(AppRouter.tenantSelect);
      return;
    }

    _ordersSub?.cancel();
    try {
      final tables = await ref.read(tableRepositoryProvider).getTables(tenantId);
      if (!mounted) return;

      _ordersSub = ref.read(orderRepositoryProvider).streamOpenOrders(tenantId).listen((orders) {
        if (mounted) setState(() => _openOrders = orders);
      });

      setState(() {
        _tables = tables;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  OrderModel? _openOrderForTable(String? tableId, {bool isPackage = false}) {
    if (isPackage) {
      try {
        return _openOrders.firstWhere((o) => o.isPackage);
      } catch (_) {
        return null;
      }
    }
    try {
      return _openOrders.firstWhere((o) => o.tableId == tableId);
    } catch (_) {
      return null;
    }
  }

  void _openAdisyon({String? tableId, String? tableName, bool isPackage = false}) {
    context.push(
      AppRouter.adisyon,
      extra: {
        'tableId': tableId,
        'tableName': tableName ?? (isPackage ? 'Paket' : 'Masa'),
        'isPackage': isPackage,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(currentUserProvider);
    final tenantId = ref.watch(tenantIdProvider);
    final theme = Theme.of(context);

    if (auth.isLoading || auth.valueOrNull == null || tenantId == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final openTableCount = _tables.where((t) => _openOrderForTable(t.id) != null).length;
    final openPackage = _openOrderForTable(null, isPackage: true) != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(ref.watch(tenantNameProvider) ?? 'Masalar'),
        actions: [
          IconButton(
            icon: const Icon(Icons.store_outlined),
            tooltip: 'İşletme değiştir',
            onPressed: () => context.go(AppRouter.tenantSelect),
          ),
          IconButton(
            icon: const Icon(Icons.bar_chart_rounded),
            tooltip: 'Raporlar',
            onPressed: () => context.push(AppRouter.reports),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Ayarlar',
            onPressed: () => context.push(AppRouter.products),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
                      const SizedBox(height: 16),
                      ElevatedButton(onPressed: _load, child: const Text('Tekrar Dene')),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final width = constraints.maxWidth;
                      final screenClass = screenClassForWidth(width);
                      final maxExtent = switch (screenClass) {
                        ScreenClass.phone => 190.0,
                        ScreenClass.tabletPortrait => 230.0,
                        ScreenClass.tabletLandscape => 250.0,
                        ScreenClass.tabletUltraWide => 260.0,
                      };
                      final childRatio = screenClass.isPhone ? 1.02 : 1.12;

                      return ListView(
                        padding: const EdgeInsets.all(AppConstants.screenPadding),
                        children: [
                          _SummaryRow(
                            openTables: openTableCount,
                            totalTables: _tables.length,
                            openPackage: openPackage ? 1 : 0,
                          ),
                          const SizedBox(height: 18),
                          Text('Masa Planı', style: theme.textTheme.titleLarge),
                          const SizedBox(height: 12),
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                              maxCrossAxisExtent: maxExtent,
                              mainAxisSpacing: 14,
                              crossAxisSpacing: 14,
                              childAspectRatio: childRatio,
                            ),
                            itemCount: _tables.length + 1,
                            itemBuilder: (context, index) {
                              if (index == _tables.length) {
                                final order = _openOrderForTable(null, isPackage: true);
                                return _TableTile(
                                  name: 'Paket',
                                  isOpen: order != null,
                                  total: order?.total,
                                  icon: Icons.takeout_dining,
                                  onTap: () => _openAdisyon(isPackage: true, tableName: 'Paket'),
                                );
                              }

                              final table = _tables[index];
                              final order = _openOrderForTable(table.id);
                              return _TableTile(
                                name: table.name,
                                isOpen: order != null,
                                total: order?.total,
                                icon: Icons.table_restaurant,
                                onTap: () => _openAdisyon(tableId: table.id, tableName: table.name),
                              );
                            },
                          ),
                        ],
                      );
                    },
                  ),
                ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.openTables,
    required this.totalTables,
    required this.openPackage,
  });

  final int openTables;
  final int totalTables;
  final int openPackage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final width = MediaQuery.of(context).size.width - (AppConstants.screenPadding * 2);
    final isWide = width >= 900;
    final cardWidth = isWide ? (width - 12) / 2 : width;

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _SummaryCard(
          title: 'Açık Masa',
          value: '$openTables / $totalTables',
          icon: Icons.table_restaurant,
          color: theme.colorScheme.primary,
          width: cardWidth,
        ),
        _SummaryCard(
          title: 'Açık Paket',
          value: '$openPackage',
          icon: Icons.takeout_dining,
          color: theme.colorScheme.secondary,
          width: cardWidth,
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.width,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final double width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(title, style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(value, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 26)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TableTile extends StatelessWidget {
  const _TableTile({
    required this.name,
    required this.isOpen,
    required this.total,
    required this.icon,
    required this.onTap,
  });

  final String name;
  final bool isOpen;
  final double? total;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final borderColor = isOpen ? colorScheme.primary.withValues(alpha: 0.55) : colorScheme.outline;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isOpen ? colorScheme.primaryContainer.withValues(alpha: 0.2) : colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(icon, size: 28, color: isOpen ? colorScheme.primary : colorScheme.onSurfaceVariant),
                const Spacer(),
                _StatusPill(isOpen: isOpen),
              ],
            ),
            const Spacer(),
            Text(
              name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              isOpen ? '₺${(total ?? 0).toStringAsFixed(0)}' : 'Yeni adisyon aç',
              style: theme.textTheme.titleLarge?.copyWith(
                color: isOpen ? colorScheme.primary : colorScheme.onSurfaceVariant,
                fontSize: isOpen ? 26 : 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.isOpen});

  final bool isOpen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isOpen ? colorScheme.primaryContainer.withValues(alpha: 0.9) : colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        isOpen ? 'Açık' : 'Boş',
        style: theme.textTheme.bodyMedium?.copyWith(
          color: isOpen ? colorScheme.primary : colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
