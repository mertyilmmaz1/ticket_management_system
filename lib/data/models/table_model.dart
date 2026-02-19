class TableModel {
  final String id;
  final String name;
  final int sortOrder;

  const TableModel({required this.id, required this.name, this.sortOrder = 0});

  Map<String, dynamic> toMap() => {'name': name, 'sortOrder': sortOrder};

  factory TableModel.fromMap(Map<String, dynamic> map, [String? id]) =>
      TableModel(
        id: id ?? map['id'] ?? '',
        name: map['name'] ?? '',
        sortOrder: (map['sortOrder'] ?? 0) as int,
      );
}
