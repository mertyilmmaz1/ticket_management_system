# Tablet Adisyon Yönetim Sistemi

Tabletlerde çalışan, Firebase backend’li adisyon (hesap) yönetim uygulaması. Tantuni vb. işletmeler için masa ve paket hesabı, hızlı sipariş girişi, ödeme (nakit/kart) ve günlük raporlar.

## Özellikler

- **Çoklu işletme (tenant):** İki farklı işletme; giriş sonrası işletme seçimi.
- **Masalar ve paket:** Masa listesi, paket (götürme) hesabı; masa durumu dolu/boş ve açık hesap tutarı.
- **Hızlı sipariş:** Kategori → ürün, miktar 1–2–3 veya +/- ile; sonradan aynı masaya ekleme.
- **Ödeme:** Hesabı kapat → Nakit veya Kredi kartı seçimi.
- **Ürün/kategori/masa yönetimi:** Ayarlar ekranından kategoriler, ürünler ve masalar eklenebilir/düzenlenebilir.
- **Raporlar:** Günlük ciro, Z raporu (nakit/kart), satılan ürün detayı.

## Gereksinimler

- Flutter SDK ^3.7.2
- Firebase projesi (Auth + Firestore)

## Kurulum

1. Bağımlılıkları yükle:
   ```bash
   flutter pub get
   ```

2. Firebase’i yapılandır:
   - [Firebase Console](https://console.firebase.google.com) üzerinde bir proje oluşturun.
   - Android/iOS uygulamasını ekleyin ve `google-services.json` (Android) / `GoogleService-Info.plist` (iOS) indirin.
   - FlutterFire CLI ile `firebase_options.dart` üretin:
     ```bash
     dart run flutterfire_cli:flutterfire configure
     ```
     (CLI yüklü değilse: `dart pub global activate flutterfire_cli` sonra `flutterfire configure`)

3. Firestore kuralları ve ilk veri:
   - Firestore’da **Authentication** etkinleştirin (Email/Şifre).
   - Firestore’da şu koleksiyonları kullanın (tenant altında):
     - `tenants` – işletmeler (döküman alanları: `name`)
     - `tenants/{tenantId}/tables` – masalar
     - `tenants/{tenantId}/categories` – kategoriler
     - `tenants/{tenantId}/products` – ürünler
     - `tenants/{tenantId}/orders` – adisyonlar
   - **Terminalden ilk veriyi eklemek için:**
     1. Firebase Console → Project Settings → Service accounts → **Generate new private key** ile JSON indirin.
     2. İndirilen dosyayı proje içinde `scripts/service-account.json` olarak kaydedin.
     3. Terminalde:
        ```bash
        cd scripts && npm install && npm run seed
        ```
     Bu script iki tenant (İşletme 1, İşletme 2), İşletme 1 için örnek masalar (Masa 1–3, Paket), kategoriler (İçecekler, Yemekler) ve örnek ürünler ekler.

4. Çalıştırma:
   ```bash
   flutter run
   ```

## Proje yapısı

- `lib/core` – tema, sabitler, router, provider’lar
- `lib/data` – modeller, Firestore servisi, repository’ler
- `lib/features` – auth, tables (ana ekran), adisyon, products (ayarlar), reports

Hedef cihaz: **tablet** (Android/iOS); dokunmatik hedefler ve ekran düzeni tablet kullanımına göre ayarlanmıştır.
