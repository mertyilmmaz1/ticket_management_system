import '../firebase/firestore_paths.dart';
import '../firebase/firestore_service.dart';
import '../models/category_model.dart';

class CategoryRepository {
  CategoryRepository(this._firestore);
  final FirestoreService _firestore;

  Future<List<CategoryModel>> getCategories(String tenantId) async {
    final list = await _firestore.getCollection(
      FirestorePaths.categories(tenantId),
      orderBy: 'sortOrder',
    );
    return list
        .map((m) => CategoryModel.fromMap(m, m['id'] as String?))
        .toList();
  }

  Future<String> addCategory(String tenantId, CategoryModel category) async {
    return _firestore.addDocument(
      FirestorePaths.categories(tenantId),
      category.toMap(),
    );
  }

  Future<void> updateCategory(
      String tenantId, CategoryModel category) async {
    await _firestore.updateDocument(
      FirestorePaths.category(tenantId, category.id),
      category.toMap(),
    );
  }

  Future<void> deleteCategory(String tenantId, String categoryId) async {
    await _firestore.deleteDocument(
      FirestorePaths.category(tenantId, categoryId),
    );
  }
}
