import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/responsive/responsive.dart';
import '../../../core/router/app_router.dart';
import '../../../data/models/category_model.dart';
import '../../../data/models/product_model.dart';
import '../../../data/models/table_model.dart';

class ProductsPage extends ConsumerStatefulWidget {
  const ProductsPage({super.key});

  @override
  ConsumerState<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends ConsumerState<ProductsPage>
    with SingleTickerProviderStateMixin {
  List<CategoryModel> _categories = [];
  List<ProductModel> _products = [];
  bool _loading = true;
  String? _error;
  late TabController _tabController;
  List<TableModel> _tables = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) context.go(AppRouter.login);
  }

  Future<void> _load() async {
    final tenantId = ref.read(tenantIdProvider);
    if (tenantId == null) {
      if (mounted) context.go(AppRouter.tenantSelect);
      return;
    }
    setState(() => _loading = true);
    try {
      final catRepo = ref.read(categoryRepositoryProvider);
      final prodRepo = ref.read(productRepositoryProvider);
      final categories = await catRepo.getCategories(tenantId);
      final products = await prodRepo.getProducts(tenantId);
      final tables = await ref
          .read(tableRepositoryProvider)
          .getTables(tenantId);
      setState(() {
        _categories = categories;
        _products = products;
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

  @override
  Widget build(BuildContext context) {
    final screenClass = screenClassOf(context);
    final isPhone = screenClass.isPhone;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ürün ve Kategoriler'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(AppRouter.home),
        ),
        actions: [
          TextButton.icon(
            onPressed: _signOut,
            icon: const Icon(Icons.logout, size: 20),
            label: const Text('Çıkış yap'),
          ),
        ],
      ),
      body:
          _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _load,
                      child: const Text('Tekrar Dene'),
                    ),
                  ],
                ),
              )
              : Column(
                children: [
                  TabBar(
                    controller: _tabController,
                    isScrollable: isPhone,
                    tabAlignment: isPhone ? TabAlignment.start : TabAlignment.fill,
                    tabs: const [
                      Tab(text: 'Kategoriler'),
                      Tab(text: 'Ürünler'),
                      Tab(text: 'Masalar'),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _CategoriesList(
                          categories: _categories,
                          onRefresh: _load,
                        ),
                        _ProductsList(
                          products: _products,
                          categories: _categories,
                          onRefresh: _load,
                        ),
                        _TablesList(tables: _tables, onRefresh: _load),
                      ],
                    ),
                  ),
                ],
              ),
    );
  }
}

class _TablesList extends ConsumerWidget {
  const _TablesList({required this.tables, required this.onRefresh});

  final List<TableModel> tables;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tenantId = ref.watch(tenantIdProvider);
    if (tenantId == null) return const SizedBox();

    return ListView.builder(
      padding: const EdgeInsets.all(AppConstants.screenPadding),
      itemCount: tables.length + 1,
      itemBuilder: (_, i) {
        if (i == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: ElevatedButton.icon(
              onPressed: () => _showAddTable(context, ref, tenantId, onRefresh),
              icon: const Icon(Icons.add),
              label: const Text('Yeni Masa'),
            ),
          );
        }
        final t = tables[i - 1];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            minVerticalPadding: 10,
            title: Text(t.name),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _deleteTable(ref, tenantId, t.id, onRefresh),
            ),
          ),
        );
      },
    );
  }

  Future<void> _showAddTable(
    BuildContext context,
    WidgetRef ref,
    String tenantId,
    VoidCallback onRefresh,
  ) async {
    final nameController = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Yeni Masa'),
            content: TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Masa adı (örn. Masa 1)',
              ),
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
    if (ok == true && nameController.text.trim().isNotEmpty) {
      await ref
          .read(tableRepositoryProvider)
          .addTable(
            tenantId,
            TableModel(
              id: '',
              name: nameController.text.trim(),
              sortOrder: tables.length,
            ),
          );
      onRefresh();
    }
  }

  Future<void> _deleteTable(
    WidgetRef ref,
    String tenantId,
    String tableId,
    VoidCallback onRefresh,
  ) async {
    await ref.read(tableRepositoryProvider).deleteTable(tenantId, tableId);
    onRefresh();
  }
}

class _CategoriesList extends ConsumerWidget {
  const _CategoriesList({required this.categories, required this.onRefresh});

  final List<CategoryModel> categories;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tenantId = ref.watch(tenantIdProvider);
    if (tenantId == null) return const SizedBox();

    return ListView.builder(
      padding: const EdgeInsets.all(AppConstants.screenPadding),
      itemCount: categories.length + 1,
      itemBuilder: (_, i) {
        if (i == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: ElevatedButton.icon(
              onPressed:
                  () => _showAddCategory(context, ref, tenantId, onRefresh),
              icon: const Icon(Icons.add),
              label: const Text('Yeni Kategori'),
            ),
          );
        }
        final c = categories[i - 1];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            minVerticalPadding: 10,
            title: Text(c.name),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _deleteCategory(ref, tenantId, c.id, onRefresh),
            ),
          ),
        );
      },
    );
  }

  Future<void> _showAddCategory(
    BuildContext context,
    WidgetRef ref,
    String tenantId,
    VoidCallback onRefresh,
  ) async {
    final nameController = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Yeni Kategori'),
            content: TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Ad'),
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
    if (ok == true && nameController.text.trim().isNotEmpty) {
      await ref
          .read(categoryRepositoryProvider)
          .addCategory(
            tenantId,
            CategoryModel(
              id: '',
              name: nameController.text.trim(),
              sortOrder: categories.length,
            ),
          );
      onRefresh();
    }
  }

  Future<void> _deleteCategory(
    WidgetRef ref,
    String tenantId,
    String categoryId,
    VoidCallback onRefresh,
  ) async {
    await ref
        .read(categoryRepositoryProvider)
        .deleteCategory(tenantId, categoryId);
    onRefresh();
  }
}

class _ProductsList extends ConsumerWidget {
  const _ProductsList({
    required this.products,
    required this.categories,
    required this.onRefresh,
  });

  final List<ProductModel> products;
  final List<CategoryModel> categories;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tenantId = ref.watch(tenantIdProvider);
    if (tenantId == null) return const SizedBox();

    return ListView.builder(
      padding: const EdgeInsets.all(AppConstants.screenPadding),
      itemCount: products.length + 1,
      itemBuilder: (_, i) {
        if (i == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: ElevatedButton.icon(
              onPressed:
                  () => _showAddProduct(context, ref, tenantId, onRefresh),
              icon: const Icon(Icons.add),
              label: const Text('Yeni Ürün'),
            ),
          );
        }
        final p = products[i - 1];
        final catName =
            categories
                .where((c) => c.id == p.categoryId)
                .map((c) => c.name)
                .firstOrNull ??
            '';
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            minVerticalPadding: 10,
            title: Text(p.name),
            subtitle: Text('$catName · ₺${p.price.toStringAsFixed(0)}'),
            trailing: IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed:
                  () => _showEditProduct(context, ref, tenantId, p, onRefresh),
            ),
          ),
        );
      },
    );
  }

  Future<void> _showAddProduct(
    BuildContext context,
    WidgetRef ref,
    String tenantId,
    VoidCallback onRefresh,
  ) async {
    if (categories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Önce en az bir kategori ekleyin')),
      );
      return;
    }
    final nameController = TextEditingController();
    final priceController = TextEditingController(text: '0');
    String? categoryId = categories.first.id;

    final ok = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => StatefulBuilder(
            builder:
                (ctx, setState) => AlertDialog(
                  title: const Text('Yeni Ürün'),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(
                          controller: nameController,
                          decoration: const InputDecoration(
                            labelText: 'Ürün adı',
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: priceController,
                          decoration: const InputDecoration(
                            labelText: 'Fiyat (₺)',
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: categoryId,
                          decoration: const InputDecoration(
                            labelText: 'Kategori',
                          ),
                          items:
                              categories
                                  .map(
                                    (c) => DropdownMenuItem(
                                      value: c.id,
                                      child: Text(c.name),
                                    ),
                                  )
                                  .toList(),
                          onChanged: (v) => setState(() => categoryId = v),
                        ),
                      ],
                    ),
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
          ),
    );
    if (ok == true &&
        nameController.text.trim().isNotEmpty &&
        categoryId != null) {
      final price =
          double.tryParse(priceController.text.replaceAll(',', '.')) ?? 0;
      await ref
          .read(productRepositoryProvider)
          .addProduct(
            tenantId,
            ProductModel(
              id: '',
              name: nameController.text.trim(),
              categoryId: categoryId!,
              price: price,
            ),
          );
      onRefresh();
    }
  }

  Future<void> _showEditProduct(
    BuildContext context,
    WidgetRef ref,
    String tenantId,
    ProductModel p,
    VoidCallback onRefresh,
  ) async {
    final nameController = TextEditingController(text: p.name);
    final priceController = TextEditingController(
      text: p.price.toStringAsFixed(0),
    );
    String? categoryId = p.categoryId;

    final ok = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => StatefulBuilder(
            builder:
                (ctx, setState) => AlertDialog(
                  title: const Text('Ürün Düzenle'),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(
                          controller: nameController,
                          decoration: const InputDecoration(
                            labelText: 'Ürün adı',
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: priceController,
                          decoration: const InputDecoration(
                            labelText: 'Fiyat (₺)',
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: categoryId,
                          decoration: const InputDecoration(
                            labelText: 'Kategori',
                          ),
                          items:
                              categories
                                  .map(
                                    (c) => DropdownMenuItem(
                                      value: c.id,
                                      child: Text(c.name),
                                    ),
                                  )
                                  .toList(),
                          onChanged: (v) => setState(() => categoryId = v),
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('İptal'),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Kaydet'),
                    ),
                  ],
                ),
          ),
    );
    if (ok == true &&
        nameController.text.trim().isNotEmpty &&
        categoryId != null) {
      final price =
          double.tryParse(priceController.text.replaceAll(',', '.')) ?? 0;
      await ref
          .read(productRepositoryProvider)
          .updateProduct(
            tenantId,
            ProductModel(
              id: p.id,
              name: nameController.text.trim(),
              categoryId: categoryId!,
              price: price,
            ),
          );
      onRefresh();
    }
  }
}
