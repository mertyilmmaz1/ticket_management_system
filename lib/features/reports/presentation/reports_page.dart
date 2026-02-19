import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/responsive/responsive.dart';
import '../../../core/router/app_router.dart';
import '../../../data/models/order_model.dart';

enum _ReportPeriod { daily, weekly, monthly }
enum _PhoneChartMode { revenue, payment }

class ReportsPage extends ConsumerStatefulWidget {
  const ReportsPage({super.key});

  @override
  ConsumerState<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends ConsumerState<ReportsPage> {
  _ReportPeriod _period = _ReportPeriod.daily;
  DateTime _anchorDate = DateTime.now();
  List<OrderModel> _orders = [];
  bool _loading = true;
  String? _error;
  _PhoneChartMode _phoneChartMode = _PhoneChartMode.revenue;

  @override
  void initState() {
    super.initState();
    _load();
  }

  DateTime get _rangeStart {
    switch (_period) {
      case _ReportPeriod.daily:
        return DateTime(_anchorDate.year, _anchorDate.month, _anchorDate.day);
      case _ReportPeriod.weekly:
        final dayStart = DateTime(_anchorDate.year, _anchorDate.month, _anchorDate.day);
        return dayStart.subtract(Duration(days: dayStart.weekday - 1));
      case _ReportPeriod.monthly:
        return DateTime(_anchorDate.year, _anchorDate.month, 1);
    }
  }

  DateTime get _rangeEnd {
    switch (_period) {
      case _ReportPeriod.daily:
        return _rangeStart.add(const Duration(days: 1));
      case _ReportPeriod.weekly:
        return _rangeStart.add(const Duration(days: 7));
      case _ReportPeriod.monthly:
        return DateTime(_rangeStart.year, _rangeStart.month + 1, 1);
    }
  }

  Future<void> _load() async {
    final tenantId = ref.read(tenantIdProvider);
    if (tenantId == null) {
      if (mounted) context.go(AppRouter.tenantSelect);
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final orders = await ref.read(orderRepositoryProvider).getClosedOrdersInRange(
            tenantId,
            start: _rangeStart,
            end: _rangeEnd,
          );
      if (!mounted) return;
      setState(() {
        _orders = orders;
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

  void _shiftPeriod(int direction) {
    setState(() {
      switch (_period) {
        case _ReportPeriod.daily:
          _anchorDate = _anchorDate.add(Duration(days: direction));
          break;
        case _ReportPeriod.weekly:
          _anchorDate = _anchorDate.add(Duration(days: 7 * direction));
          break;
        case _ReportPeriod.monthly:
          _anchorDate = DateTime(_anchorDate.year, _anchorDate.month + direction, _anchorDate.day);
          break;
      }
    });
    _load();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _anchorDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked == null) return;
    setState(() => _anchorDate = picked);
    _load();
  }

  String _periodLabel() {
    switch (_period) {
      case _ReportPeriod.daily:
        return 'Gunluk';
      case _ReportPeriod.weekly:
        return 'Haftalik';
      case _ReportPeriod.monthly:
        return 'Aylik';
    }
  }

  String _dateRangeLabel() {
    String f(DateTime d) => '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';
    final start = _rangeStart;
    final end = _rangeEnd.subtract(const Duration(days: 1));
    if (_period == _ReportPeriod.daily) return f(start);
    return '${f(start)} - ${f(end)}';
  }

  @override
  Widget build(BuildContext context) {
    final total = _orders.fold<double>(0, (s, o) => s + o.total);
    final cash = _orders
        .where((o) => o.paymentType == PaymentType.cash)
        .fold<double>(0, (s, o) => s + o.total);
    final card = _orders
        .where((o) => o.paymentType == PaymentType.card)
        .fold<double>(0, (s, o) => s + o.total);

    final productMap = <String, _ProductSummary>{};
    var totalItems = 0;
    for (final o in _orders) {
      for (final item in o.items) {
        totalItems += item.quantity;
        final prev = productMap[item.productName];
        if (prev == null) {
          productMap[item.productName] = _ProductSummary(count: item.quantity, amount: item.subtotal);
        } else {
          productMap[item.productName] = _ProductSummary(
            count: prev.count + item.quantity,
            amount: prev.amount + item.subtotal,
          );
        }
      }
    }

    final topProducts = productMap.entries.toList()
      ..sort((a, b) => b.value.amount.compareTo(a.value.amount));

    final revenueBars = _buildRevenueBars();
    final paymentBars = [
      _BarDatum(label: 'Nakit', value: cash),
      _BarDatum(label: 'Kart', value: card),
    ];

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
                      Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                      const SizedBox(height: 16),
                      ElevatedButton(onPressed: _load, child: const Text('Tekrar Dene')),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final screenClass = screenClassForWidth(constraints.maxWidth);
                      final isPhone = screenClass.isPhone;
                      final isWide = screenClass.isTabletLandscape;

                      return ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(AppConstants.screenPadding),
                        children: [
                          _PeriodToolbar(
                            period: _period,
                            onPeriodChanged: (p) {
                              setState(() => _period = p);
                              _load();
                            },
                            onPrev: () => _shiftPeriod(-1),
                            onNext: () => _shiftPeriod(1),
                            onPickDate: _pickDate,
                            periodLabel: _periodLabel(),
                            rangeLabel: _dateRangeLabel(),
                          ),
                          const SizedBox(height: 16),
                          if (isPhone)
                            SizedBox(
                              height: 96,
                              child: ListView(
                                scrollDirection: Axis.horizontal,
                                children: [
                                  _KpiCard(
                                    title: 'Toplam Ciro',
                                    value: '₺${total.toStringAsFixed(0)}',
                                    icon: Icons.payments,
                                    width: 230,
                                  ),
                                  _KpiCard(
                                    title: 'Adisyon',
                                    value: '${_orders.length}',
                                    icon: Icons.receipt_long,
                                    width: 180,
                                  ),
                                  _KpiCard(
                                    title: 'Satilan Urun',
                                    value: '$totalItems',
                                    icon: Icons.shopping_bag_outlined,
                                    width: 190,
                                  ),
                                ],
                              ),
                            )
                          else
                            Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              children: [
                                _KpiCard(title: 'Toplam Ciro', value: '₺${total.toStringAsFixed(0)}', icon: Icons.payments),
                                _KpiCard(title: 'Adisyon', value: '${_orders.length}', icon: Icons.receipt_long),
                                _KpiCard(title: 'Satilan Urun', value: '$totalItems', icon: Icons.shopping_bag_outlined),
                              ],
                            ),
                          const SizedBox(height: 16),
                          if (isWide)
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  flex: 6,
                                  child: _ChartCard(
                                    title: 'Ciro Grafigi',
                                    subtitle: _dateRangeLabel(),
                                    child: _BarsChart(data: revenueBars),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  flex: 4,
                                  child: _ChartCard(
                                    title: 'Odeme Dagilimi',
                                    subtitle: 'Nakit / Kart',
                                    child: _BarsChart(data: paymentBars, compact: true),
                                  ),
                                ),
                              ],
                            )
                          else if (isPhone) ...[
                            SegmentedButton<_PhoneChartMode>(
                              segments: const [
                                ButtonSegment(value: _PhoneChartMode.revenue, label: Text('Ciro')),
                                ButtonSegment(value: _PhoneChartMode.payment, label: Text('Odeme')),
                              ],
                              selected: {_phoneChartMode},
                              onSelectionChanged: (set) => setState(() => _phoneChartMode = set.first),
                              showSelectedIcon: false,
                            ),
                            const SizedBox(height: 10),
                            _ChartCard(
                              title: _phoneChartMode == _PhoneChartMode.revenue ? 'Ciro Grafigi' : 'Odeme Dagilimi',
                              subtitle: _phoneChartMode == _PhoneChartMode.revenue ? _dateRangeLabel() : 'Nakit / Kart',
                              child: _BarsChart(
                                data: _phoneChartMode == _PhoneChartMode.revenue ? revenueBars : paymentBars,
                                compact: true,
                              ),
                            ),
                          ] else ...[
                            _ChartCard(
                              title: 'Ciro Grafigi',
                              subtitle: _dateRangeLabel(),
                              child: _BarsChart(data: revenueBars),
                            ),
                            const SizedBox(height: 12),
                            _ChartCard(
                              title: 'Odeme Dagilimi',
                              subtitle: 'Nakit / Kart',
                              child: _BarsChart(data: paymentBars, compact: true),
                            ),
                          ],
                          const SizedBox(height: 16),
                          _TopProductsCard(products: topProducts),
                        ],
                      );
                    },
                  ),
                ),
    );
  }

  List<_BarDatum> _buildRevenueBars() {
    switch (_period) {
      case _ReportPeriod.daily:
        const labels = ['00-04', '04-08', '08-12', '12-16', '16-20', '20-24'];
        final values = List<double>.filled(labels.length, 0);
        for (final order in _orders) {
          final t = order.closedAt;
          if (t == null) continue;
          final idx = (t.hour / 4).floor().clamp(0, labels.length - 1);
          values[idx] += order.total;
        }
        return List.generate(labels.length, (i) => _BarDatum(label: labels[i], value: values[i]));
      case _ReportPeriod.weekly:
        const labels = ['Pzt', 'Sali', 'Cars', 'Pers', 'Cuma', 'Cts', 'Pzr'];
        final values = List<double>.filled(labels.length, 0);
        for (final order in _orders) {
          final t = order.closedAt;
          if (t == null) continue;
          final idx = (t.weekday - 1).clamp(0, labels.length - 1);
          values[idx] += order.total;
        }
        return List.generate(labels.length, (i) => _BarDatum(label: labels[i], value: values[i]));
      case _ReportPeriod.monthly:
        final days = _rangeEnd.difference(_rangeStart).inDays;
        final weekCount = (days / 7).ceil();
        final values = List<double>.filled(weekCount, 0);
        for (final order in _orders) {
          final t = order.closedAt;
          if (t == null) continue;
          final dayInMonth = t.day - 1;
          final idx = (dayInMonth / 7).floor().clamp(0, weekCount - 1);
          values[idx] += order.total;
        }
        return List.generate(
          weekCount,
          (i) => _BarDatum(label: 'Hafta ${i + 1}', value: values[i]),
        );
    }
  }
}

class _PeriodToolbar extends StatelessWidget {
  const _PeriodToolbar({
    required this.period,
    required this.onPeriodChanged,
    required this.onPrev,
    required this.onNext,
    required this.onPickDate,
    required this.periodLabel,
    required this.rangeLabel,
  });

  final _ReportPeriod period;
  final ValueChanged<_ReportPeriod> onPeriodChanged;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final VoidCallback onPickDate;
  final String periodLabel;
  final String rangeLabel;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SegmentedButton<_ReportPeriod>(
              segments: const [
                ButtonSegment(value: _ReportPeriod.daily, label: Text('Gunluk')),
                ButtonSegment(value: _ReportPeriod.weekly, label: Text('Haftalik')),
                ButtonSegment(value: _ReportPeriod.monthly, label: Text('Aylik')),
              ],
              selected: {period},
              onSelectionChanged: (set) => onPeriodChanged(set.first),
              showSelectedIcon: false,
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                IconButton(onPressed: onPrev, icon: const Icon(Icons.chevron_left)),
                Expanded(
                  child: InkWell(
                    onTap: onPickDate,
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Column(
                        children: [
                          Text(periodLabel, style: Theme.of(context).textTheme.bodyLarge),
                          const SizedBox(height: 2),
                          Text(
                            rangeLabel,
                            style: Theme.of(context).textTheme.titleMedium,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                IconButton(onPressed: onNext, icon: const Icon(Icons.chevron_right)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.title,
    required this.value,
    required this.icon,
    this.width,
  });

  final String title;
  final String value;
  final IconData icon;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final cardWidth = this.width ?? (width >= 1100 ? (width - (AppConstants.screenPadding * 2) - 24) / 3 : 240.0);

    return SizedBox(
      width: cardWidth,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Theme.of(context).colorScheme.primary),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.bodyMedium),
                    const SizedBox(height: 2),
                    Text(value, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 26)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 2),
            Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 14),
            SizedBox(height: 240, child: child),
          ],
        ),
      ),
    );
  }
}

class _BarsChart extends StatelessWidget {
  const _BarsChart({required this.data, this.compact = false});

  final List<_BarDatum> data;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final maxValue = data.fold<double>(0, (max, e) => math.max(max, e.value));
    final normalizedMax = maxValue <= 0 ? 1 : maxValue;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (final item in data)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    item.value > 0 ? '₺${item.value.toStringAsFixed(0)}' : '-',
                    style: Theme.of(context).textTheme.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Container(
                    height: compact ? 140 : 160,
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      height: ((item.value / normalizedMax) * (compact ? 140 : 160)).clamp(6, 200),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item.label,
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _TopProductsCard extends StatelessWidget {
  const _TopProductsCard({required this.products});

  final List<MapEntry<String, _ProductSummary>> products;

  @override
  Widget build(BuildContext context) {
    final top = products.take(10).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('En Cok Satan Urunler', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            if (top.isEmpty)
              const Padding(
                padding: EdgeInsets.all(12),
                child: Text('Bu donemde satis yok.'),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: top.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (_, i) {
                  final e = top[i];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      radius: 14,
                      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                      child: Text('${i + 1}', style: Theme.of(context).textTheme.bodySmall),
                    ),
                    title: Text(e.key),
                    subtitle: Text('${e.value.count} adet'),
                    trailing: Text(
                      '₺${e.value.amount.toStringAsFixed(0)}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  );
                },
              ),
          ],
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

class _BarDatum {
  const _BarDatum({required this.label, required this.value});
  final String label;
  final double value;
}
