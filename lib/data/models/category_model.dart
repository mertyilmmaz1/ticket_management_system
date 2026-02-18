class CategoryModel {
  final String id;
  final String name;
  final int sortOrder;

  const CategoryModel({
    required this.id,
    required this.name,
    this.sortOrder = 0,
  });

  Map<String, dynamic> toMap() => {
        'name': name,
        'sortOrder': sortOrder,
      };

  factory CategoryModel.fromMap(Map<String, dynamic> map, [String? id]) =>
      CategoryModel(
        id: id ?? map['id'] ?? '',
        name: map['name'] ?? '',
        sortOrder: (map['sortOrder'] ?? 0) as int,
      );
}
