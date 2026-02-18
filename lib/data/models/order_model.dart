import 'order_item_model.dart';

enum OrderStatus { open, closed }

enum PaymentType { cash, card }

class OrderModel {
  final String id;
  final String? tableId; // null for package
  final bool isPackage;
  final OrderStatus status;
  final List<OrderItemModel> items;
  final DateTime createdAt;
  final DateTime? closedAt;
  final PaymentType? paymentType;

  const OrderModel({
    required this.id,
    this.tableId,
    this.isPackage = false,
    required this.status,
    this.items = const [],
    required this.createdAt,
    this.closedAt,
    this.paymentType,
  });

  double get total =>
      items.fold(0.0, (sum, item) => sum + item.unitPrice * item.quantity);

  Map<String, dynamic> toMap() => {
        'tableId': tableId,
        'isPackage': isPackage,
        'status': status.name,
        'createdAt': createdAt.millisecondsSinceEpoch,
        if (closedAt != null) 'closedAt': closedAt!.millisecondsSinceEpoch,
        if (paymentType != null) 'paymentType': paymentType!.name,
      };

  factory OrderModel.fromMap(Map<String, dynamic> map, [String? id]) {
    final itemsList = map['items'] as List<dynamic>? ?? [];
    final items = itemsList.map((e) {
      final m = Map<String, dynamic>.from(e as Map);
      return OrderItemModel.fromMap(m, m['id'] as String?);
    }).toList();
    return OrderModel(
      id: id ?? map['id'] ?? '',
      tableId: map['tableId'] as String?,
      isPackage: map['isPackage'] == true,
      status: OrderStatus.values.byName(map['status'] as String? ?? 'open'),
      items: items,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int? ?? 0),
      closedAt: map['closedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['closedAt'] as int)
          : null,
      paymentType: map['paymentType'] != null
          ? PaymentType.values.byName(map['paymentType'] as String)
          : null,
    );
  }

  OrderModel copyWith({
    String? id,
    String? tableId,
    bool? isPackage,
    OrderStatus? status,
    List<OrderItemModel>? items,
    DateTime? createdAt,
    DateTime? closedAt,
    PaymentType? paymentType,
  }) =>
      OrderModel(
        id: id ?? this.id,
        tableId: tableId ?? this.tableId,
        isPackage: isPackage ?? this.isPackage,
        status: status ?? this.status,
        items: items ?? this.items,
        createdAt: createdAt ?? this.createdAt,
        closedAt: closedAt ?? this.closedAt,
        paymentType: paymentType ?? this.paymentType,
      );
}
