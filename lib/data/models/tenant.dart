class Tenant {
  final String id;
  final String name;
  final String ownerUid;
  final List<String> memberUids;

  const Tenant({
    required this.id,
    required this.name,
    this.ownerUid = '',
    this.memberUids = const [],
  });

  Map<String, dynamic> toMap() => {
        'name': name,
        'ownerUid': ownerUid,
        'memberUids': memberUids,
      };

  factory Tenant.fromMap(Map<String, dynamic> map, [String? id]) {
    final docId = id ?? map['id']?.toString();
    final name = map['name'];
    final members = map['memberUids'];
    return Tenant(
      id: docId?.toString() ?? '',
      name: name != null ? '$name' : '',
      ownerUid: map['ownerUid']?.toString() ?? '',
      memberUids: members is List ? members.cast<String>() : [],
    );
  }
}
