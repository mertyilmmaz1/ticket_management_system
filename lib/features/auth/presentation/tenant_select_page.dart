import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/router/app_router.dart';
import '../../../data/models/tenant.dart';

class TenantSelectPage extends ConsumerStatefulWidget {
  const TenantSelectPage({super.key});

  @override
  ConsumerState<TenantSelectPage> createState() => _TenantSelectPageState();
}

class _TenantSelectPageState extends ConsumerState<TenantSelectPage> {
  List<Tenant> _tenants = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final list = await ref.read(tenantRepositoryProvider).getTenants();
      if (!mounted) return;
      setState(() {
        _tenants = list;
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

  void _select(Tenant t) {
    ref.read(tenantIdProvider.notifier).state = t.id;
    ref.read(tenantNameProvider.notifier).state = t.name;
    context.go(AppRouter.home);
  }

  Future<void> _showAddTenantDialog() async {
    final nameController = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Yeni işletme'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(labelText: 'İşletme adı'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('İptal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Ekle'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final name = nameController.text.trim();
    if (name.isEmpty) return;
    try {
      final tenant = await ref.read(tenantRepositoryProvider).addTenant(name);
      if (!mounted) return;
      ref.read(tenantIdProvider.notifier).state = tenant.id;
      ref.read(tenantNameProvider.notifier).state = tenant.name;
      context.go(AppRouter.home);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Eklenemedi: $e')),
      );
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('İşletme Seçin')),
      body: SafeArea(
        child: _loading
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
                : Padding(
                    padding: const EdgeInsets.all(AppConstants.screenPadding),
                    child: _tenants.isEmpty
                        ? _EmptyTenantListBody(onAddTenant: _showAddTenantDialog)
                        : GridView.builder(
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              mainAxisSpacing: 16,
                              crossAxisSpacing: 16,
                              childAspectRatio: 1.2,
                            ),
                            itemCount: _tenants.length + 1,
                            itemBuilder: (_, i) {
                              if (i == _tenants.length) {
                                return _AddTenantCard(onTap: _showAddTenantDialog);
                              }
                              final t = _tenants[i];
                              return _BigCard(
                                label: t.name,
                                onTap: () => _select(t),
                              );
                            },
                          ),
                  ),
      ),
    );
  }
}

/// Boş tenant listesi: GridView kullanmıyoruz; iOS focus crash'ini önlemek için
/// tek öğeli basit Column layout kullanıyoruz.
class _EmptyTenantListBody extends StatelessWidget {
  const _EmptyTenantListBody({required this.onAddTenant});

  final VoidCallback onAddTenant;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Henüz işletme eklenmemiş.',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: 280,
              child: _AddTenantCard(onTap: onAddTenant),
            ),
          ],
        ),
      ),
    );
  }
}

class _BigCard extends StatelessWidget {
  const _BigCard({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppConstants.minTouchTarget / 2),
            child: Text(
              label,
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}

class _AddTenantCard extends StatelessWidget {
  const _AddTenantCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppConstants.minTouchTarget / 2),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add, size: 40, color: Theme.of(context).colorScheme.primary),
                const SizedBox(height: 8),
                Text(
                  'Yeni işletme ekle',
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
