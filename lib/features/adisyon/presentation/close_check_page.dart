import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/router/app_router.dart';
import '../../../data/models/order_item_model.dart';
import '../../../data/models/order_model.dart';

class CloseCheckPage extends ConsumerStatefulWidget {
  const CloseCheckPage({
    super.key,
    required this.orderId,
    required this.total,
    this.tableName = '',
  });

  final String orderId;
  final double total;
  final String tableName;

  @override
  ConsumerState<CloseCheckPage> createState() => _CloseCheckPageState();
}

class _CloseCheckPageState extends ConsumerState<CloseCheckPage> {
  PaymentType? _selected;
  OrderModel? _order;
  bool _dataLoading = true;
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadOrder();
  }

  Future<void> _loadOrder() async {
    final tenantId = ref.read(tenantIdProvider);
    if (tenantId == null) {
      if (mounted) context.go(AppRouter.tenantSelect);
      return;
    }

    setState(() {
      _dataLoading = true;
      _error = null;
    });

    try {
      final order = await ref.read(orderRepositoryProvider).getOrder(tenantId, widget.orderId);
      if (!mounted) return;
      setState(() {
        _order = order;
        _dataLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _dataLoading = false;
      });
    }
  }

  Future<void> _confirm() async {
    if (_selected == null || _submitting) return;

    final tenantId = ref.read(tenantIdProvider);
    if (tenantId == null) {
      if (mounted) context.go(AppRouter.tenantSelect);
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      await ref.read(orderRepositoryProvider).closeOrder(tenantId, widget.orderId, _selected!);
      if (mounted) context.go(AppRouter.home);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _submitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final items = _order?.items ?? const <OrderItemModel>[];
    final total = _order?.total ?? widget.total;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ödeme Al'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: _dataLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
                        const SizedBox(height: 12),
                        ElevatedButton(onPressed: _loadOrder, child: const Text('Tekrar Dene')),
                      ],
                    ),
                  )
                : LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth >= 980;
                      return Padding(
                        padding: const EdgeInsets.all(AppConstants.screenPadding),
                        child: isWide
                            ? Row(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Expanded(
                                    flex: 55,
                                    child: _CheckPreviewCard(
                                      tableName: widget.tableName,
                                      items: items,
                                      total: total,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    flex: 45,
                                    child: _PaymentPane(
                                      selected: _selected,
                                      submitting: _submitting,
                                      total: total,
                                      hasItems: items.isNotEmpty,
                                      onSelect: (type) => setState(() => _selected = type),
                                      onConfirm: _confirm,
                                    ),
                                  ),
                                ],
                              )
                            : ListView(
                                children: [
                                  _CheckPreviewCard(
                                    tableName: widget.tableName,
                                    items: items,
                                    total: total,
                                    compact: true,
                                  ),
                                  const SizedBox(height: 14),
                                  _PaymentPane(
                                    selected: _selected,
                                    submitting: _submitting,
                                    total: total,
                                    hasItems: items.isNotEmpty,
                                    onSelect: (type) => setState(() => _selected = type),
                                    onConfirm: _confirm,
                                  ),
                                ],
                              ),
                      );
                    },
                  ),
      ),
    );
  }
}

class _CheckPreviewCard extends StatelessWidget {
  const _CheckPreviewCard({
    required this.tableName,
    required this.items,
    required this.total,
    this.compact = false,
  });

  final String tableName;
  final List<OrderItemModel> items;
  final double total;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    tableName.isEmpty ? 'Adisyon' : tableName,
                    style: theme.textTheme.titleLarge,
                  ),
                ),
                Text('${items.length} kalem', style: theme.textTheme.bodyMedium),
              ],
            ),
            const SizedBox(height: 6),
            Text('Ürün Detayları', style: theme.textTheme.bodyLarge),
            const SizedBox(height: 10),
            Expanded(
              child: items.isEmpty
                  ? Center(
                      child: Text('Adisyonda urun yok', style: theme.textTheme.bodyLarge),
                    )
                  : ListView.separated(
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (_, i) {
                        final item = items[i];
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.productName,
                                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      '₺${item.unitPrice.toStringAsFixed(0)} x ${item.quantity}',
                                      style: theme.textTheme.bodyMedium,
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                '₺${item.subtotal.toStringAsFixed(0)}',
                                style: theme.textTheme.titleMedium,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
              ),
              child: Row(
                children: [
                  Text('Toplam', style: theme.textTheme.titleMedium),
                  const Spacer(),
                  Text(
                    '₺${total.toStringAsFixed(0)}',
                    style: theme.textTheme.headlineMedium?.copyWith(fontSize: compact ? 34 : 38),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentPane extends StatelessWidget {
  const _PaymentPane({
    required this.selected,
    required this.submitting,
    required this.total,
    required this.hasItems,
    required this.onSelect,
    required this.onConfirm,
  });

  final PaymentType? selected;
  final bool submitting;
  final double total;
  final bool hasItems;
  final ValueChanged<PaymentType> onSelect;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isWide = MediaQuery.of(context).size.width >= 980;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Ödeme Yöntemi', style: theme.textTheme.titleLarge),
            const SizedBox(height: 10),
            if (isWide)
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: _PaymentOptionTile(
                        label: 'Nakit',
                        icon: Icons.payments_outlined,
                        selected: selected == PaymentType.cash,
                        onTap: () => onSelect(PaymentType.cash),
                        large: true,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _PaymentOptionTile(
                        label: 'Kredi Kartı',
                        icon: Icons.credit_card,
                        selected: selected == PaymentType.card,
                        onTap: () => onSelect(PaymentType.card),
                        large: true,
                      ),
                    ),
                  ],
                ),
              )
            else ...[
              _PaymentOptionTile(
                label: 'Nakit',
                icon: Icons.payments_outlined,
                selected: selected == PaymentType.cash,
                onTap: () => onSelect(PaymentType.cash),
                large: true,
              ),
              const SizedBox(height: 10),
              _PaymentOptionTile(
                label: 'Kredi Kartı',
                icon: Icons.credit_card,
                selected: selected == PaymentType.card,
                onTap: () => onSelect(PaymentType.card),
                large: true,
              ),
            ],
            if (isWide) const Spacer() else const SizedBox(height: 16),
            Row(
              children: [
                Text('Tahsilat', style: theme.textTheme.titleMedium),
                const Spacer(),
                Text(
                  '₺${total.toStringAsFixed(0)}',
                  style: theme.textTheme.titleLarge?.copyWith(fontSize: 30),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: AppConstants.minTouchTarget + 12,
              child: ElevatedButton.icon(
                onPressed: (selected != null && !submitting && hasItems) ? onConfirm : null,
                icon: submitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check_circle_outline),
                label: Text(submitting ? 'Kapanıyor...' : 'Onayla ve Kapat'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentOptionTile extends StatelessWidget {
  const _PaymentOptionTile({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
    this.large = false,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        constraints: BoxConstraints(minHeight: large ? 116 : 76),
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: large ? 22 : 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? theme.colorScheme.primary : theme.colorScheme.outline,
            width: selected ? 2 : 1,
          ),
          color: selected ? theme.colorScheme.primaryContainer.withValues(alpha: 0.55) : null,
        ),
        child: Row(
          children: [
            Icon(icon, size: large ? 40 : 28, color: selected ? theme.colorScheme.primary : theme.colorScheme.onSurface),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: large ? 28 : 20,
                ),
              ),
            ),
            if (selected) Icon(Icons.check_circle, color: theme.colorScheme.primary, size: large ? 34 : 24),
          ],
        ),
      ),
    );
  }
}
