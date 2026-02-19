import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/responsive/responsive.dart';
import '../../../core/router/app_router.dart';
import '../../../data/models/category_model.dart';
import '../../../data/models/order_item_model.dart';
import '../../../data/models/order_model.dart';
import '../../../data/models/product_model.dart';

class AdisyonPage extends ConsumerStatefulWidget {
  const AdisyonPage({
    super.key,
    this.tableId,
    this.tableName,
    this.isPackage = false,
  });

  final String? tableId;
  final String? tableName;
  final bool isPackage;

  @override
  ConsumerState<AdisyonPage> createState() => _AdisyonPageState();
}

class _AdisyonPageState extends ConsumerState<AdisyonPage> {
  OrderModel? _order;
  String? _orderId;
  List<CategoryModel> _categories = [];
  List<ProductModel> _products = [];
  String? _selectedCategoryId;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final tenantId = ref.read(tenantIdProvider);
    if (tenantId == null) {
      if (mounted) context.go(AppRouter.tenantSelect);
      return;
    }

    try {
      final orderRepo = ref.read(orderRepositoryProvider);
      final catRepo = ref.read(categoryRepositoryProvider);
      final prodRepo = ref.read(productRepositoryProvider);

      final order = await orderRepo.getOpenOrder(
        tenantId,
        tableId: widget.tableId,
        isPackage: widget.isPackage,
      );
      final categories = await catRepo.getCategories(tenantId);
      final products = await prodRepo.getProducts(tenantId);

      String? orderId = order?.id;
      if (order == null) {
        orderId = await orderRepo.createOrder(
          tenantId,
          tableId: widget.tableId,
          isPackage: widget.isPackage,
        );
      }

      if (!mounted) return;
      setState(() {
        _order = order ??
            OrderModel(
              id: orderId!,
              tableId: widget.tableId,
              isPackage: widget.isPackage,
              status: OrderStatus.open,
              items: [],
              createdAt: DateTime.now(),
            );
        _orderId = orderId;
        _categories = categories;
        _products = products;
        _selectedCategoryId = categories.isNotEmpty ? categories.first.id : null;
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

  List<ProductModel> get _filteredProducts {
    if (_selectedCategoryId == null) return _products;
    return _products.where((p) => p.categoryId == _selectedCategoryId).toList();
  }

  Future<void> _addItem(ProductModel product, {int quantity = 1}) async {
    if (_orderId == null) return;

    final tenantId = ref.read(tenantIdProvider);
    if (tenantId == null) {
      if (mounted) context.go(AppRouter.tenantSelect);
      return;
    }

    final newItem = OrderItemModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      productId: product.id,
      productName: product.name,
      unitPrice: product.price,
      quantity: quantity,
    );

    final current = _order?.items ?? [];
    final existingIndex = current.indexWhere((i) => i.productId == product.id);
    List<OrderItemModel> next;

    if (existingIndex >= 0) {
      next = List.from(current);
      next[existingIndex] = OrderItemModel(
        id: current[existingIndex].id,
        productId: product.id,
        productName: product.name,
        unitPrice: product.price,
        quantity: current[existingIndex].quantity + quantity,
      );
    } else {
      next = [...current, newItem];
    }

    await ref.read(orderRepositoryProvider).updateOrderItems(tenantId, _orderId!, next);
    if (!mounted) return;

    setState(() {
      _order = _order?.copyWith(items: next) ??
          OrderModel(
            id: _orderId!,
            tableId: widget.tableId,
            isPackage: widget.isPackage,
            status: OrderStatus.open,
            items: next,
            createdAt: DateTime.now(),
          );
    });
  }

  Future<void> _updateItemQuantity(OrderItemModel item, int delta) async {
    if (_orderId == null || _order == null) return;

    final tenantId = ref.read(tenantIdProvider);
    if (tenantId == null) {
      if (mounted) context.go(AppRouter.tenantSelect);
      return;
    }

    final current = _order!.items;
    final index = current.indexWhere((i) => i.id == item.id);
    if (index < 0) return;

    final newQty = item.quantity + delta;
    if (newQty <= 0) {
      final next = current.where((i) => i.id != item.id).toList();
      await ref.read(orderRepositoryProvider).updateOrderItems(tenantId, _orderId!, next);
      if (mounted) setState(() => _order = _order!.copyWith(items: next));
      return;
    }

    final next = List<OrderItemModel>.from(current);
    next[index] = OrderItemModel(
      id: item.id,
      productId: item.productId,
      productName: item.productName,
      unitPrice: item.unitPrice,
      quantity: newQty,
      note: item.note,
    );

    await ref.read(orderRepositoryProvider).updateOrderItems(tenantId, _orderId!, next);
    if (mounted) setState(() => _order = _order!.copyWith(items: next));
  }

  void _openCloseCheck() {
    if (_order == null || _order!.items.isEmpty) return;
    context.push(
      AppRouter.closeCheck,
      extra: {
        'orderId': _orderId,
        'total': _order!.total,
        'tableName': widget.tableName,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.tableName ?? 'Adisyon')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.tableName ?? 'Adisyon')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _load, child: const Text('Tekrar Dene')),
            ],
          ),
        ),
      );
    }

    final items = _order?.items ?? const <OrderItemModel>[];
    final total = _order?.total ?? 0.0;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.tableName ?? 'Adisyon'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final screenClass = screenClassForWidth(constraints.maxWidth);
          if (screenClass.isTabletLandscape) {
            return Row(
              children: [
                Expanded(
                  flex: 65,
                  child: _ProductsPane(
                    categories: _categories,
                    selectedCategoryId: _selectedCategoryId,
                    filteredProducts: _filteredProducts,
                    onSelectCategory: (id) => setState(() => _selectedCategoryId = id),
                    onAdd: _addItem,
                    isPhone: false,
                  ),
                ),
                Container(width: 1, color: Theme.of(context).colorScheme.outline),
                Expanded(
                  flex: 35,
                  child: _CheckPane(
                    items: items,
                    total: total,
                    onIncrease: (item) => _updateItemQuantity(item, 1),
                    onDecrease: (item) => _updateItemQuantity(item, -1),
                    onCloseCheck: _openCloseCheck,
                  ),
                ),
              ],
            );
          }

          return Column(
            children: [
              Expanded(
                child: _ProductsPane(
                  categories: _categories,
                  selectedCategoryId: _selectedCategoryId,
                  filteredProducts: _filteredProducts,
                  onSelectCategory: (id) => setState(() => _selectedCategoryId = id),
                  onAdd: _addItem,
                  isPhone: screenClass.isPhone,
                ),
              ),
              SizedBox(
                height: screenClass.isPhone ? 300 : 330,
                child: _CheckPane(
                  items: items,
                  total: total,
                  onIncrease: (item) => _updateItemQuantity(item, 1),
                  onDecrease: (item) => _updateItemQuantity(item, -1),
                  onCloseCheck: _openCloseCheck,
                  compact: true,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ProductsPane extends StatelessWidget {
  const _ProductsPane({
    required this.categories,
    required this.selectedCategoryId,
    required this.filteredProducts,
    required this.onSelectCategory,
    required this.onAdd,
    required this.isPhone,
  });

  final List<CategoryModel> categories;
  final String? selectedCategoryId;
  final List<ProductModel> filteredProducts;
  final ValueChanged<String> onSelectCategory;
  final Future<void> Function(ProductModel product) onAdd;
  final bool isPhone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: Text('Ürünler', style: theme.textTheme.titleLarge),
              ),
              Text(
                '${filteredProducts.length} ürün',
                style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
        if (categories.isNotEmpty)
          SizedBox(
            height: isPhone ? 48 : 52,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemBuilder: (_, index) {
                final category = categories[index];
                final selected = selectedCategoryId == category.id;
                return ChoiceChip(
                  label: Text(category.name),
                  selected: selected,
                  showCheckmark: false,
                  onSelected: (_) => onSelectCategory(category.id),
                  labelStyle: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                );
              },
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemCount: categories.length,
            ),
          ),
        const SizedBox(height: 8),
        Expanded(
          child: isPhone
              ? ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
                  itemCount: filteredProducts.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, index) {
                    final product = filteredProducts[index];
                    return _ProductListTile(
                      product: product,
                      onTap: () => onAdd(product),
                    );
                  },
                )
              : LayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.maxWidth;
                    final screenClass = screenClassForWidth(width);
                    final maxExtent = screenClass.isUltraWide
                        ? 220.0
                        : screenClass.isTabletLandscape
                            ? AppConstants.denseGridMaxExtent
                            : 200.0;

                    return GridView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
                      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: maxExtent,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: screenClass.isTabletLandscape ? 1.24 : 1.12,
                      ),
                      itemCount: filteredProducts.length,
                      itemBuilder: (_, index) {
                        final product = filteredProducts[index];
                        return _ProductTile(
                          product: product,
                          onTap: () => onAdd(product),
                        );
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _ProductListTile extends StatelessWidget {
  const _ProductListTile({
    required this.product,
    required this.onTap,
  });

  final ProductModel product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      height: AppConstants.compactListRowHeight,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.colorScheme.outline),
        color: theme.colorScheme.surface,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              product.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 10),
          Text('₺${product.price.toStringAsFixed(0)}', style: theme.textTheme.titleMedium),
          const SizedBox(width: 10),
          SizedBox(
            width: 44,
            height: 44,
            child: FilledButton.tonal(
              onPressed: onTap,
              child: const Text('+'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductTile extends StatelessWidget {
  const _ProductTile({
    required this.product,
    required this.onTap,
  });

  final ProductModel product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                product.name,
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const Spacer(),
              Text(
                '₺${product.price.toStringAsFixed(0)}',
                style: theme.textTheme.titleLarge?.copyWith(fontSize: 20, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              SizedBox(
                width: double.infinity,
                child: FilledButton.tonal(
                  onPressed: onTap,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(34),
                    textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  child: const Text('+'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CheckPane extends StatelessWidget {
  const _CheckPane({
    required this.items,
    required this.total,
    required this.onIncrease,
    required this.onDecrease,
    required this.onCloseCheck,
    this.compact = false,
  });

  final List<OrderItemModel> items;
  final double total;
  final void Function(OrderItemModel item) onIncrease;
  final void Function(OrderItemModel item) onDecrease;
  final VoidCallback onCloseCheck;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      color: theme.colorScheme.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
            child: Row(
              children: [
                Text('Hesap', style: theme.textTheme.titleLarge),
                const Spacer(),
                Text(
                  '${items.length} kalem',
                  style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          Expanded(
            child: items.isEmpty
                ? Center(
                    child: Text('Henüz ürün eklenmedi', style: theme.textTheme.bodyLarge),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, index) {
                      final item = items[index];
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                        decoration: BoxDecoration(
                          border: Border.all(color: theme.colorScheme.outline),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.productName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '₺${item.unitPrice.toStringAsFixed(0)} x ${item.quantity}',
                                    style: theme.textTheme.bodyMedium,
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '₺${item.subtotal.toStringAsFixed(0)}',
                              style: theme.textTheme.titleLarge?.copyWith(fontSize: 20),
                            ),
                            const SizedBox(width: 8),
                            _RoundQtyButton(
                              icon: Icons.remove,
                              onPressed: () => onDecrease(item),
                              tonal: true,
                            ),
                            const SizedBox(width: 4),
                            _RoundQtyButton(
                              icon: Icons.add,
                              onPressed: () => onIncrease(item),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
            child: Column(
              children: [
                Row(
                  children: [
                    Text('Toplam', style: theme.textTheme.titleMedium),
                    const Spacer(),
                    Text(
                      '₺${total.toStringAsFixed(0)}',
                      style: theme.textTheme.headlineMedium?.copyWith(fontSize: compact ? 34 : 36),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: items.isEmpty ? null : onCloseCheck,
                    icon: const Icon(Icons.receipt_long),
                    label: const Text('Hesabı Kapat'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RoundQtyButton extends StatelessWidget {
  const _RoundQtyButton({
    required this.icon,
    required this.onPressed,
    this.tonal = false,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final bool tonal;

  @override
  Widget build(BuildContext context) {
    final child = tonal
        ? IconButton.filledTonal(onPressed: onPressed, icon: Icon(icon, size: 18))
        : IconButton.filled(onPressed: onPressed, icon: Icon(icon, size: 18));

    return SizedBox(width: 36, height: 36, child: child);
  }
}
