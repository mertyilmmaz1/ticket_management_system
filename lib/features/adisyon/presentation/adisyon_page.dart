import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants.dart';
import '../../../core/providers/app_providers.dart';
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
    if (tenantId == null) return;
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

      setState(() {
        _order = order ?? OrderModel(
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
    if (tenantId == null) return;

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
    setState(() {
      _order = _order?.copyWith(items: next) ?? OrderModel(
        id: _orderId!,
        tableId: widget.tableId,
        isPackage: widget.isPackage,
        status: OrderStatus.open,
        items: next,
        createdAt: _order!.createdAt,
      );
    });
  }

  Future<void> _updateItemQuantity(OrderItemModel item, int delta) async {
    if (_orderId == null) return;
    final tenantId = ref.read(tenantIdProvider);
    if (tenantId == null) return;

    final current = _order!.items;
    final index = current.indexWhere((i) => i.id == item.id);
    if (index < 0) return;

    final newQty = item.quantity + delta;
    if (newQty <= 0) {
      final next = current.where((i) => i.id != item.id).toList();
      await ref.read(orderRepositoryProvider).updateOrderItems(tenantId, _orderId!, next);
      setState(() => _order = _order!.copyWith(items: next));
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
    setState(() => _order = _order!.copyWith(items: next));
  }

  void _openCloseCheck() {
    if (_order == null || _order!.items.isEmpty) return;
    context.push(AppRouter.closeCheck, extra: {
      'orderId': _orderId,
      'total': _order!.total,
      'tableName': widget.tableName,
    });
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

    final items = _order?.items ?? [];
    final total = _order?.total ?? 0.0;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.tableName ?? 'Adisyon'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_categories.isNotEmpty)
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    child: Row(
                      children: _categories.map((c) {
                        final selected = _selectedCategoryId == c.id;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(c.name),
                            selected: selected,
                            onSelected: (_) => setState(() => _selectedCategoryId = c.id),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.all(8),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      childAspectRatio: 1.1,
                    ),
                    itemCount: _filteredProducts.length,
                    itemBuilder: (_, i) {
                      final p = _filteredProducts[i];
                      return _ProductCard(
                        product: p,
                        onTap: () => _addItem(p),
                        onTapQty: (q) => _addItem(p, quantity: q),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 320,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border(left: BorderSide(color: Theme.of(context).dividerColor)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Hesap',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: items.length,
                    itemBuilder: (_, i) {
                      final item = items[i];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${item.productName} x${item.quantity}',
                                style: const TextStyle(fontSize: 16),
                              ),
                            ),
                            Text('₺${(item.subtotal).toStringAsFixed(0)}'),
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline),
                              onPressed: () => _updateItemQuantity(item, -1),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add_circle_outline),
                              onPressed: () => _updateItemQuantity(item, 1),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Toplam', style: Theme.of(context).textTheme.titleLarge),
                          Text(
                            '₺${total.toStringAsFixed(0)}',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: AppConstants.minTouchTarget + 8,
                        child: ElevatedButton(
                          onPressed: items.isEmpty ? null : _openCloseCheck,
                          child: const Text('Hesabı Kapat'),
                        ),
                      ),
                    ],
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

class _ProductCard extends StatelessWidget {
  const _ProductCard({
    required this.product,
    required this.onTap,
    required this.onTapQty,
  });

  final ProductModel product;
  final VoidCallback onTap;
  final void Function(int) onTapQty;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: Center(
                  child: Text(
                    product.name,
                    style: Theme.of(context).textTheme.titleSmall,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              Text('₺${product.price.toStringAsFixed(0)}', style: Theme.of(context).textTheme.bodySmall),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [1, 2, 3]
                    .map((q) => Padding(
                          padding: const EdgeInsets.only(left: 4),
                          child: SizedBox(
                            width: 32,
                            height: 32,
                            child: FilledButton(
                              style: FilledButton.styleFrom(padding: EdgeInsets.zero),
                              onPressed: () => onTapQty(q),
                              child: Text('$q'),
                            ),
                          ),
                        ))
                    .toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
