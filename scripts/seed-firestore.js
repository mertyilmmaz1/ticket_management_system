/**
 * Firestore'a terminalden ilk veriyi ekler.
 *
 * Kullanım:
 * 1. Firebase Console > Project Settings > Service accounts > "Generate new private key"
 *    indirip scripts/service-account.json olarak kaydedin (veya key path'i aşağıda değiştirin).
 * 2. Terminalde:
 *    cd scripts && npm install && npm run seed
 *
 * Ortam değişkeni: GOOGLE_APPLICATION_CREDENTIALS=./service-account.json npm run seed
 */

const admin = require('firebase-admin');
const path = require('path');

const serviceAccountPath =
  process.env.GOOGLE_APPLICATION_CREDENTIALS ||
  path.join(__dirname, 'service-account.json');

let app;
try {
  app = admin.initializeApp({ credential: admin.credential.cert(require(serviceAccountPath)) });
} catch (e) {
  console.error(
    'Hata: service-account.json bulunamadı veya geçersiz.\n' +
    'Firebase Console > Project Settings > Service accounts > "Generate new private key" ile indirip\n' +
    'scripts/service-account.json olarak kaydedin. Veya:\n' +
    '  GOOGLE_APPLICATION_CREDENTIALS=/path/to/key.json npm run seed'
  );
  process.exit(1);
}

const db = admin.firestore();

async function seed() {
  console.log('Firestore seed başlıyor...\n');

  // 1) Tenant(s)
  const tenantId = 'isletme1';
  await db.collection('tenants').doc(tenantId).set({ name: 'İşletme 1' });
  console.log('  tenants/isletme1 eklendi: { name: "İşletme 1" }');

  const tenantId2 = 'isletme2';
  await db.collection('tenants').doc(tenantId2).set({ name: 'İşletme 2' });
  console.log('  tenants/isletme2 eklendi: { name: "İşletme 2" }');

  // 2) Masalar (tenant altında)
  const tablesRef = db.collection('tenants').doc(tenantId).collection('tables');
  const tableData = [
    { name: 'Masa 1', sortOrder: 0 },
    { name: 'Masa 2', sortOrder: 1 },
    { name: 'Masa 3', sortOrder: 2 },
    { name: 'Paket', sortOrder: 3 },
  ];
  for (const t of tableData) {
    await tablesRef.add(t);
  }
  console.log('  tenants/isletme1/tables: 4 masa eklendi (Masa 1, 2, 3, Paket)');

  // 3) Kategoriler
  const categoriesRef = db.collection('tenants').doc(tenantId).collection('categories');
  const cat1 = await categoriesRef.add({ name: 'İçecekler', sortOrder: 0 });
  const cat2 = await categoriesRef.add({ name: 'Yemekler', sortOrder: 1 });
  console.log('  tenants/isletme1/categories: İçecekler, Yemekler eklendi');

  // 4) Ürünler (categoryId ile)
  const productsRef = db.collection('tenants').doc(tenantId).collection('products');
  await productsRef.add({
    name: 'Ayran',
    categoryId: cat1.id,
    price: 10,
    unit: 'adet',
    isDeleted: false,
  });
  await productsRef.add({
    name: 'Kola',
    categoryId: cat1.id,
    price: 15,
    unit: 'adet',
    isDeleted: false,
  });
  await productsRef.add({
    name: 'Tantuni',
    categoryId: cat2.id,
    price: 85,
    unit: 'porsiyon',
    isDeleted: false,
  });
  await productsRef.add({
    name: 'Lahmacun',
    categoryId: cat2.id,
    price: 45,
    unit: 'adet',
    isDeleted: false,
  });
  console.log('  tenants/isletme1/products: Ayran, Kola, Tantuni, Lahmacun eklendi');

  // orders koleksiyonu boş bırakılıyor (adisyonlar uygulama üzerinden açılır)

  console.log('\nFirestore seed tamamlandı.');
  process.exit(0);
}

seed().catch((err) => {
  console.error('Seed hatası:', err);
  process.exit(1);
});
