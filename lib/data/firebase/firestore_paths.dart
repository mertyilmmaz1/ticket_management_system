/// Firestore paths under tenants/{tenantId}/...
class FirestorePaths {
  FirestorePaths._();

  static String tenants() => 'tenants';
  static String tenant(String id) => 'tenants/$id';
  static String tables(String tenantId) => 'tenants/$tenantId/tables';
  static String table(String tenantId, String tableId) =>
      'tenants/$tenantId/tables/$tableId';
  static String categories(String tenantId) => 'tenants/$tenantId/categories';
  static String category(String tenantId, String categoryId) =>
      'tenants/$tenantId/categories/$categoryId';
  static String products(String tenantId) => 'tenants/$tenantId/products';
  static String product(String tenantId, String productId) =>
      'tenants/$tenantId/products/$productId';
  static String orders(String tenantId) => 'tenants/$tenantId/orders';
  static String order(String tenantId, String orderId) =>
      'tenants/$tenantId/orders/$orderId';
}
