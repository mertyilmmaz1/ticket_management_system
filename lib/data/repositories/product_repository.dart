import '../firebase/firestore_paths.dart';
import '../firebase/firestore_service.dart';
import '../models/product_model.dart';

class ProductRepository {
  ProductRepository(this._firestore);
  final FirestoreService _firestore;

  Future<List<ProductModel>> getProducts(String tenantId) async {
    final list = await _firestore.getCollection(
      FirestorePaths.products(tenantId),
    );
    return list
        .map((m) => ProductModel.fromMap(m, m['id'] as String?))
        .where((p) => !p.isDeleted)
        .toList();
  }

  Future<String> addProduct(String tenantId, ProductModel product) async {
    return _firestore.addDocument(
      FirestorePaths.products(tenantId),
      product.toMap(),
    );
  }

  Future<void> updateProduct(
      String tenantId, ProductModel product) async {
    await _firestore.updateDocument(
      FirestorePaths.product(tenantId, product.id),
      product.toMap(),
    );
  }

  Future<void> deleteProduct(String tenantId, String productId) async {
    final doc = await _firestore.getDocument(
      FirestorePaths.product(tenantId, productId),
    );
    if (doc != null) {
      await _firestore.updateDocument(
        FirestorePaths.product(tenantId, productId),
        {'isDeleted': true},
      );
    }
  }
}
