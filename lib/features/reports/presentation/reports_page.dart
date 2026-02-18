import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/router/app_router.dart';
import '../../../data/models/order_model.dart';

class ReportsPage extends ConsumerStatefulWidget {
  const ReportsPage({super.key});

  @override
  ConsumerState<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends ConsumerState<ReportsPage> {
  DateTime _selectedDate = DateTime.now();
  List<OrderModel> _orders = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  DateTime get _dayStart =>
      DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
  DateTime get _dayEnd => _dayStart.add(const Duration(days: 1));

  Future<void> _load() async {
    final tenantId = ref.read(tenantIdProvider);
    if (tenantId == null) return;
    setState(() => _loading = true);
    try {
      final orders = await ref.read(orderRepositoryProvider).getClosedOrdersForDay(
            tenantId,
            _dayStart,
            _dayEnd,
          );
      setState(() {
        _orders = orders;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalCiro = _orders.fold<double>(0, (s, o) => s + o.total);
    final nakit = _orders
        .where((o) => o.paymentType == PaymentType.cash)
        .fold<double>(0, (s, o) => s + o.total);
    final kart = _orders
        .where((o) => o.paymentType == PaymentType.card)
        .fold<double>(0, (s, o) => s + o.total);

    final productMap = <String, _ProductSummary>{};
    for (final o in _orders) {
      for (final item in o.items) {
        final key = item.productName;
        final prev = productMap[key];
        if (prev == null) {
          productMap[key] = _ProductSummary(count: item.quantity, amount: item.subtotal);
        } else {
          productMap[key] = _ProductSummary(
            count: prev.count + item.quantity,
            amount: prev.amount + item.subtotal,
          );
        }
      }
    }
    final productList = productMap.entries.toList()
      ..sort((a, b) => b.value.amount.compareTo(a.value.amount));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Raporlar'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(AppRouter.home),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _error!,
                        style: TextStyle(color: Theme.of(context).colorScheme.error),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(onPressed: _load, child: const Text('Tekrar Dene')),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(AppConstants.screenPadding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        OutlinedButton.icon(
                          onPressed: _pickDate,
                          icon: const Icon(Icons.calendar_today),
                          label: Text(
                            '${_selectedDate.day}.${_selectedDate.month}.${_selectedDate.year}',
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Günlük Özet (Z Raporu)',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 16),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                _ReportRow('İşlem sayısı', '${_orders.length}'),
                                _ReportRow('Toplam ciro', '₺${totalCiro.toStringAsFixed(2)}'),
                                _ReportRow('Nakit', '₺${nakit.toStringAsFixed(2)}'),
                                _ReportRow('Kredi kartı', '₺${kart.toStringAsFixed(2)}'),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Satılan ürünler (detay)',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        if (productList.isEmpty)
                          const Padding(
                            padding: EdgeInsets.all(24),
                            child: Center(child: Text('Bu güne ait satış yok')),
                          )
                        else
                          Card(
                            child: ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: productList.length,
                              separatorBuilder: (_, __) => const Divider(height: 1),
                              itemBuilder: (_, i) {
                                final e = productList[i];
                                return ListTile(
                                  title: Text(e.key),
                                  subtitle: Text('${e.value.count} adet'),
                                  trailing: Text(
                                    '₺${e.value.amount.toStringAsFixed(0)}',
                                    style: Theme.of(context).textTheme.titleSmall,
                                  ),
                                );
                              },
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
    );
  }
}

class _ProductSummary {
  _ProductSummary({required this.count, required this.amount});
  final int count;
  final double amount;
}

class _ReportRow extends StatelessWidget {
  const _ReportRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyLarge),
          Text(value, style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }
}
