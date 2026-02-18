import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/router/app_router.dart';
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
  bool _loading = false;
  String? _error;

  Future<void> _confirm() async {
    if (_selected == null) return;
    final tenantId = ref.read(tenantIdProvider);
    if (tenantId == null) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await ref.read(orderRepositoryProvider).closeOrder(tenantId, widget.orderId, _selected!);
      if (mounted) {
        context.go(AppRouter.home);
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ödeme'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.screenPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.tableName,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 24),
              Text(
                '₺${widget.total.toStringAsFixed(0)}',
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              Text(
                'Ödeme türü',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _PaymentButton(
                      label: 'Nakit',
                      icon: Icons.payments,
                      selected: _selected == PaymentType.cash,
                      onTap: () => setState(() => _selected = PaymentType.cash),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _PaymentButton(
                      label: 'Kredi Kartı',
                      icon: Icons.credit_card,
                      selected: _selected == PaymentType.card,
                      onTap: () => setState(() => _selected = PaymentType.card),
                    ),
                  ),
                ],
              ),
              if (_error != null) ...[
                const SizedBox(height: 16),
                Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              const Spacer(),
              SizedBox(
                height: AppConstants.minTouchTarget + 8,
                child: ElevatedButton(
                  onPressed: (_selected != null && !_loading) ? _confirm : null,
                  child: _loading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Onayla ve Kapat'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PaymentButton extends StatelessWidget {
  const _PaymentButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: selected ? 2 : 0,
      color: selected ? Theme.of(context).colorScheme.primaryContainer : null,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Column(
            children: [
              Icon(icon, size: 48),
              const SizedBox(height: 8),
              Text(label, style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
        ),
      ),
    );
  }
}
