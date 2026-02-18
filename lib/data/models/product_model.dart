class ProductModel {
  final String id;
  final String name;
  final String categoryId;
  final double price;
  final String unit; // adet, porsiyon, vb.
  final bool isDeleted;

  const ProductModel({
    required this.id,
    required this.name,
    required this.categoryId,
    required this.price,
    this.unit = 'adet',
    this.isDeleted = false,
  });

  Map<String, dynamic> toMap() => {
        'name': name,
        'categoryId': categoryId,
        'price': price,
        'unit': unit,
        'isDeleted': isDeleted,
      };

  factory ProductModel.fromMap(Map<String, dynamic> map, [String? id]) =>
      ProductModel(
        id: id ?? map['id'] ?? '',
        name: map['name'] ?? '',
        categoryId: map['categoryId'] ?? '',
        price: (map['price'] ?? 0).toDouble(),
        unit: map['unit'] ?? 'adet',
        isDeleted: map['isDeleted'] == true,
      );
}
