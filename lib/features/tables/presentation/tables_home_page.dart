import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants.dart';
import '../../../core/providers/app_providers.dart';
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
    final tenantId = ref.read(tenantIdProvider);
    if (tenantId == null) {
      if (mounted) context.go(AppRouter.login);
      return;
    }
    _ordersSub?.cancel();
    try {
      final tables = await ref.read(tableRepositoryProvider).getTables(tenantId);
      _ordersSub = ref
          .read(orderRepositoryProvider)
          .streamOpenOrders(tenantId)
          .listen((orders) {
        if (mounted) setState(() => _openOrders = orders);
      });
      setState(() {
        _tables = tables;
        _loading = false;
      });
    } catch (e) {
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
    context.push(AppRouter.adisyon, extra: {
      'tableId': tableId,
      'tableName': tableName ?? (isPackage ? 'Paket' : 'Masa'),
      'isPackage': isPackage,
    });
  }

  @override
  Widget build(BuildContext context) {
    final tenantId = ref.watch(tenantIdProvider);
    if (tenantId == null) {
      return const Scaffold(body: Center(child: Text('Oturum yok')));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(ref.watch(tenantNameProvider) ?? 'Masalar'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart),
            onPressed: () => context.push(AppRouter.reports),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
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
                      Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                      const SizedBox(height: 16),
                      ElevatedButton(onPressed: _load, child: const Text('Tekrar Dene')),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: GridView(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: AppConstants.tablesGridCrossCount,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 1.0,
                      ),
                      children: [
                        ..._tables.map((t) {
                          final order = _openOrderForTable(t.id);
                          final isDolu = order != null;
                          return _TableCard(
                            tableName: t.name,
                            isDolu: isDolu,
                            total: order?.total,
                            onTap: () => _openAdisyon(tableId: t.id, tableName: t.name),
                          );
                        }),
                        _TableCard(
                          tableName: 'Paket',
                          isDolu: _openOrderForTable(null, isPackage: true) != null,
                          total: _openOrderForTable(null, isPackage: true)?.total,
                          onTap: () => _openAdisyon(isPackage: true, tableName: 'Paket'),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }
}

class _TableCard extends StatelessWidget {
  const _TableCard({
    required this.tableName,
    required this.isDolu,
    required this.total,
    required this.onTap,
  });

  final String tableName;
  final bool isDolu;
  final double? total;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isDolu ? Theme.of(context).colorScheme.primary : const Color(0xFFE0E0E0),
          width: isDolu ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                tableName,
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              if (isDolu) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Açık hesap',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ),
                if (total != null && total! > 0) ...[
                  const SizedBox(height: 4),
                  Text(
                    '₺${total!.toStringAsFixed(0)}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ] else
                Text(
                  'Boş',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
