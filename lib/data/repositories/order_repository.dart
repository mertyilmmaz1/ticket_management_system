import '../firebase/firestore_paths.dart';
import '../firebase/firestore_service.dart';
import '../models/order_item_model.dart';
import '../models/order_model.dart';

class OrderRepository {
  OrderRepository(this._firestore);
  final FirestoreService _firestore;

  Future<OrderModel?> getOpenOrderByTable(String tenantId, String tableId) async {
    final list = await _firestore.getCollection(
      FirestorePaths.orders(tenantId),
      orderBy: 'createdAt',
      descending: true,
    );
    for (final m in list) {
      if (m['tableId'] == tableId && m['status'] == 'open') {
        return OrderModel.fromMap(m, m['id'] as String?);
      }
    }
    return null;
  }

  Future<OrderModel?> getOpenPackageOrder(String tenantId) async {
    final list = await _firestore.getCollection(
      FirestorePaths.orders(tenantId),
      orderBy: 'createdAt',
      descending: true,
    );
    for (final m in list) {
      if (m['isPackage'] == true && m['status'] == 'open') {
        return OrderModel.fromMap(m, m['id'] as String?);
      }
    }
    return null;
  }

  /// Get open order for table or package. tableId null = package.
  Future<OrderModel?> getOpenOrder(
    String tenantId, {
    String? tableId,
    required bool isPackage,
  }) async {
    if (isPackage) return getOpenPackageOrder(tenantId);
    if (tableId != null) return getOpenOrderByTable(tenantId, tableId);
    return null;
  }

  Future<OrderModel?> getOrder(String tenantId, String orderId) async {
    final m = await _firestore.getDocument(
      FirestorePaths.order(tenantId, orderId),
    );
    if (m == null) return null;
    return OrderModel.fromMap(m, m['id'] as String?);
  }

  Future<String> createOrder(
    String tenantId, {
    String? tableId,
    required bool isPackage,
  }) async {
    final order = OrderModel(
      id: '',
      tableId: tableId,
      isPackage: isPackage,
      status: OrderStatus.open,
      items: [],
      createdAt: DateTime.now(),
    );
    final id = await _firestore.addDocument(
      FirestorePaths.orders(tenantId),
      order.toMap(),
    );
    return id;
  }

  Future<void> updateOrderItems(
    String tenantId,
    String orderId,
    List<OrderItemModel> items,
  ) async {
    final itemsMap = items
        .map((e) => {...e.toMap(), 'id': e.id})
        .toList();
    await _firestore.updateDocument(
      FirestorePaths.order(tenantId, orderId),
      {'items': itemsMap},
    );
  }

  Future<void> closeOrder(
    String tenantId,
    String orderId,
    PaymentType paymentType,
  ) async {
    await _firestore.updateDocument(
      FirestorePaths.order(tenantId, orderId),
      {
        'status': OrderStatus.closed.name,
        'closedAt': DateTime.now().millisecondsSinceEpoch,
        'paymentType': paymentType.name,
      },
    );
  }

  /// Stream open orders for home screen (table status: dolu/boş).
  Stream<List<OrderModel>> streamOpenOrders(String tenantId) {
    return _firestore
        .streamCollection(
          FirestorePaths.orders(tenantId),
          whereFilters: [const QueryFilter(field: 'status', value: 'open')],
        )
        .map((list) => list
            .map((m) => OrderModel.fromMap(m, m['id'] as String?))
            .toList());
  }

  /// Closed orders for a day (for reports). Use date at start of day in local TZ.
  Future<List<OrderModel>> getClosedOrdersForDay(
    String tenantId,
    DateTime dayStart,
    DateTime dayEnd,
  ) async {
    final list = await _firestore.getCollection(
      FirestorePaths.orders(tenantId),
      whereFilters: [const QueryFilter(field: 'status', value: 'closed')],
    );
    final orders = list
        .map((m) => OrderModel.fromMap(m, m['id'] as String?))
        .where((o) => o.closedAt != null)
        .where((o) {
      final t = o.closedAt!;
      return !t.isBefore(dayStart) && t.isBefore(dayEnd);
    })
        .toList();
    orders.sort((a, b) => (b.closedAt!).compareTo(a.closedAt!));
    return orders;
  }
}
