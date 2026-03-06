import 'package:firebase_auth/firebase_auth.dart';

import '../firebase/firestore_paths.dart';
import '../firebase/firestore_service.dart';
import '../models/tenant.dart';

class TenantRepository {
  TenantRepository(this._firestore);
  final FirestoreService _firestore;

  String? get _currentUid => FirebaseAuth.instance.currentUser?.uid;

  Future<List<Tenant>> getTenants() async {
    final uid = _currentUid;
    if (uid == null) return [];
    final list = await _firestore.getCollection(
      FirestorePaths.tenants(),
      whereFilters: [
        QueryFilter(
          field: 'memberUids',
          value: uid,
          type: QueryFilterType.arrayContains,
        ),
      ],
    );
    return list.map((m) => Tenant.fromMap(m, m['id']?.toString())).toList();
  }

  Future<Tenant?> getTenant(String id) async {
    final m = await _firestore.getDocument(FirestorePaths.tenant(id));
    if (m == null) return null;
    return Tenant.fromMap(m, m['id']?.toString());
  }

  Future<Tenant> addTenant(String name) async {
    final uid = _currentUid ?? '';
    final tenant = Tenant(
      id: '',
      name: name,
      ownerUid: uid,
      memberUids: [uid],
    );
    final id = await _firestore.addDocument(
      FirestorePaths.tenants(),
      tenant.toMap(),
    );
    return Tenant(id: id, name: name, ownerUid: uid, memberUids: [uid]);
  }
}
