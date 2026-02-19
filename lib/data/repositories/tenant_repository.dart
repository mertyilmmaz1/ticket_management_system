import '../firebase/firestore_paths.dart';
import '../firebase/firestore_service.dart';
import '../models/tenant.dart';

class TenantRepository {
  TenantRepository(this._firestore);
  final FirestoreService _firestore;

  Future<List<Tenant>> getTenants() async {
    final list = await _firestore.getCollection(FirestorePaths.tenants());
    return list.map((m) => Tenant.fromMap(m, m['id']?.toString())).toList();
  }

  Future<Tenant?> getTenant(String id) async {
    final m = await _firestore.getDocument(FirestorePaths.tenant(id));
    if (m == null) return null;
    return Tenant.fromMap(m, m['id']?.toString());
  }

  Future<Tenant> addTenant(String name) async {
    final id = await _firestore.addDocument(FirestorePaths.tenants(), {
      'name': name,
    });
    return Tenant(id: id, name: name);
  }
}
