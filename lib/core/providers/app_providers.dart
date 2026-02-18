import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/firebase/firestore_service.dart';
import '../../data/repositories/category_repository.dart';
import '../../data/repositories/order_repository.dart';
import '../../data/repositories/product_repository.dart';
import '../../data/repositories/table_repository.dart';
import '../../data/repositories/tenant_repository.dart';

final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  return FirestoreService();
});

final tenantRepositoryProvider = Provider<TenantRepository>((ref) {
  return TenantRepository(ref.read(firestoreServiceProvider));
});

final tableRepositoryProvider = Provider<TableRepository>((ref) {
  return TableRepository(ref.read(firestoreServiceProvider));
});

final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  return CategoryRepository(ref.read(firestoreServiceProvider));
});

final productRepositoryProvider = Provider<ProductRepository>((ref) {
  return ProductRepository(ref.read(firestoreServiceProvider));
});

final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  return OrderRepository(ref.read(firestoreServiceProvider));
});

/// Current Firebase user (null if not logged in).
final currentUserProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

/// Selected tenant ID. Set after login + tenant selection.
final tenantIdProvider = StateProvider<String?>((ref) => null);
/// Selected tenant name for display.
final tenantNameProvider = StateProvider<String?>((ref) => null);
