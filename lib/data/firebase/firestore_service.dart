import 'package:cloud_firestore/cloud_firestore.dart';

class QueryFilter {
  const QueryFilter({required this.field, required this.value});
  final String field;
  final dynamic value;
}

class FirestoreService {
  FirestoreService() : _db = FirebaseFirestore.instance;
  final FirebaseFirestore _db;

  Future<void> setDocument(String path, Map<String, dynamic> data) async {
    await _db.doc(path).set(data, SetOptions(merge: true));
  }

  Future<Map<String, dynamic>?> getDocument(String path) async {
    final snap = await _db.doc(path).get();
    if (!snap.exists) return null;
    final data = snap.data();
    if (data == null) return null;
    return {...data, 'id': snap.id};
  }

  Future<List<Map<String, dynamic>>> getCollection(
    String path, {
    String? orderBy,
    bool descending = false,
    List<QueryFilter>? whereFilters,
  }) async {
    Query<Map<String, dynamic>> q = _db.collection(path);
    for (final f in whereFilters ?? []) {
      q = q.where(f.field, isEqualTo: f.value);
    }
    if (orderBy != null) q = q.orderBy(orderBy, descending: descending);
    final snap = await q.get();
    return snap.docs.map((d) => {...d.data(), 'id': d.id}).toList();
  }

  Stream<List<Map<String, dynamic>>> streamCollection(
    String path, {
    String? orderBy,
    bool descending = false,
    List<QueryFilter>? whereFilters,
  }) {
    Query<Map<String, dynamic>> q = _db.collection(path);
    for (final f in whereFilters ?? []) {
      q = q.where(f.field, isEqualTo: f.value);
    }
    if (orderBy != null) q = q.orderBy(orderBy, descending: descending);
    return q.snapshots().map((snap) =>
        snap.docs.map((d) => {...d.data(), 'id': d.id}).toList());
  }

  Future<String> addDocument(String path, Map<String, dynamic> data) async {
    final ref = await _db.collection(path).add(data);
    return ref.id;
  }

  Future<void> updateDocument(String path, Map<String, dynamic> data) async {
    await _db.doc(path).update(data);
  }

  Future<void> deleteDocument(String path) async {
    await _db.doc(path).delete();
  }
}
