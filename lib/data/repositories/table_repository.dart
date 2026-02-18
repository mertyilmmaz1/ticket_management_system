import '../firebase/firestore_paths.dart';
import '../firebase/firestore_service.dart';
import '../models/table_model.dart';

class TableRepository {
  TableRepository(this._firestore);
  final FirestoreService _firestore;

  Future<List<TableModel>> getTables(String tenantId) async {
    final list = await _firestore.getCollection(
      FirestorePaths.tables(tenantId),
      orderBy: 'sortOrder',
    );
    return list.map((m) => TableModel.fromMap(m, m['id'] as String?)).toList();
  }

  Future<void> addTable(String tenantId, TableModel table) async {
    await _firestore.addDocument(
      FirestorePaths.tables(tenantId),
      table.toMap(),
    );
  }

  Future<void> updateTable(String tenantId, TableModel table) async {
    await _firestore.updateDocument(
      FirestorePaths.table(tenantId, table.id),
      table.toMap(),
    );
  }

  Future<void> deleteTable(String tenantId, String tableId) async {
    await _firestore.deleteDocument(FirestorePaths.table(tenantId, tableId));
  }
}
