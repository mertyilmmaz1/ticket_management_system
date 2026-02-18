class Tenant {
  final String id;
  final String name;

  const Tenant({required this.id, required this.name});

  Map<String, dynamic> toMap() => {'id': id, 'name': name};

  factory Tenant.fromMap(Map<String, dynamic> map, [String? id]) {
    final docId = id ?? map['id']?.toString();
    final name = map['name'];
    return Tenant(
      id: docId?.toString() ?? '',
      name: name != null ? '$name' : '',
    );
  }
}
