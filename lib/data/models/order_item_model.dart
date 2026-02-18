class OrderItemModel {
  final String id;
  final String productId;
  final String productName;
  final double unitPrice;
  final int quantity;
  final String? note;

  const OrderItemModel({
    required this.id,
    required this.productId,
    required this.productName,
    required this.unitPrice,
    required this.quantity,
    this.note,
  });

  double get subtotal => unitPrice * quantity;

  Map<String, dynamic> toMap() => {
        'productId': productId,
        'productName': productName,
        'unitPrice': unitPrice,
        'quantity': quantity,
        if (note != null) 'note': note,
      };

  factory OrderItemModel.fromMap(Map<String, dynamic> map, [String? id]) =>
      OrderItemModel(
        id: id ?? map['id'] ?? '',
        productId: map['productId'] ?? '',
        productName: map['productName'] ?? '',
        unitPrice: (map['unitPrice'] ?? 0).toDouble(),
        quantity: (map['quantity'] ?? 1) as int,
        note: map['note'] as String?,
      );
}
