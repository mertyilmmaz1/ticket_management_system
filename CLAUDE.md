# Ticket Management System (Adisyon)

Flutter + Firebase tabanlı restoran adisyon/masa yönetim sistemi.

---

## Teknoloji Stack

- **Flutter** (SDK ^3.7.2)
- **Firebase**: firebase_core, firebase_auth, cloud_firestore
- **State Management**: flutter_riverpod
- **Router**: go_router
- **Dil**: Türkçe (UI metinleri ve yorumlar Türkçe)

---

## Proje Yapısı

```
lib/
├── main.dart                      # Uygulama giriş noktası, Firebase init
├── app.dart                       # MaterialApp.router, tema, RootFocusGuard
├── firebase_options.dart          # Firebase config (GİZLİ - commit etme)
├── core/
│   ├── constants.dart             # Sabit değerler
│   ├── responsive/                # Responsive layout yardımcıları
│   ├── splash/                    # SplashPage
│   ├── providers/app_providers.dart  # Riverpod provider tanımları (DI)
│   ├── router/app_router.dart     # GoRouter route tanımları
│   └── theme/app_theme.dart       # AppTheme (light)
├── data/
│   ├── firebase/
│   │   ├── firestore_service.dart # Firestore wrapper
│   │   └── firestore_paths.dart   # Collection/document path sabitleri
│   ├── models/                    # Veri modelleri (fromMap/toMap)
│   │   ├── table_model.dart
│   │   ├── product_model.dart
│   │   ├── order_model.dart
│   │   ├── order_item_model.dart
│   │   ├── category_model.dart
│   │   └── tenant.dart
│   └── repositories/              # Repository implementasyonları
│       ├── table_repository.dart
│       ├── product_repository.dart
│       ├── order_repository.dart
│       ├── category_repository.dart
│       └── tenant_repository.dart
└── features/                      # Feature modülleri
    ├── auth/presentation/         # Login, Register, TenantSelect
    ├── tables/presentation/       # TablesHomePage (ana sayfa)
    ├── adisyon/presentation/      # AdisyonPage, CloseCheckPage
    ├── products/presentation/     # ProductsPage
    └── reports/presentation/      # ReportsPage
```

---

## Mimari Kurallar

### Genel Prensipler
- Feature-based klasör yapısı kullan
- Data katmanı dışarıya sadece model ve repository ile açılır; UI Firebase'e doğrudan bağımlı olmaz
- Tüm renkler `AppColors` / `AppTheme` üzerinden; **hardcoded Color kullanma**
- Widget'larda doğrudan string yazma; metinleri merkezi yapıda tut

### State Management (Riverpod)
- `ProviderScope` → `main.dart`'ta app root'unda
- Repository provider'ları `core/providers/app_providers.dart` içinde tanımlanır
- `ref.read<X>()` veya `ref.watch<X>()` ile erişim
- Auth durumu `currentUserProvider` (StreamProvider) ile takip edilir
- Tenant seçimi `tenantIdProvider` / `tenantNameProvider` (StateProvider)

### Dependency Injection
- Riverpod provider'lar ile; `app_providers.dart` merkezi DI dosyası
- `FirestoreService` → Repository'ler → Feature sayfaları zinciri
- Yeni repository: önce `app_providers.dart`'a provider ekle

### Router (GoRouter)
- `AppRouter` sınıfı (`core/router/app_router.dart`)
- Route sabitleri static const string olarak tanımlı
- Parametreler `state.extra` ile `Map<String, dynamic>` olarak geçilir
- `MaterialApp.router(routerConfig: _router)` ile bağlanır

### Firebase / Firestore
- `FirestoreService` wrapper üzerinden erişim (doğrudan Firestore çağrısı yapma)
- Collection path'leri `firestore_paths.dart` içinde sabit
- Model'lerde `fromMap(Map<String, dynamic>)` ve `toMap()` pattern'i kullan

### Model Kuralları
- Her model: `fromMap()` factory constructor + `toMap()` metodu
- Firestore Timestamp dönüşümlerini handle et
- `id` alanı Firestore document ID'sinden gelir

---

## Uygulama Başlatma Sırası

1. `WidgetsFlutterBinding.ensureInitialized()`
2. Error handler'lar (FlutterError.onError, PlatformDispatcher.onError)
3. `Firebase.initializeApp()`
4. `ProviderScope(child: App())` ile runApp
5. Hata durumunda `_StartupErrorApp` gösterilir
6. İlk route: `/splash` → auth kontrol → login veya home

---

## Yeni Feature Ekleme Checklist

1. `features/[name]/presentation/` altında sayfa dosyasını oluştur
2. Gerekirse `data/models/` altına model ekle (`fromMap`/`toMap`)
3. Gerekirse `data/repositories/` altına repository ekle
4. `core/providers/app_providers.dart`'a yeni provider'ları kaydet
5. `core/router/app_router.dart`'a route ekle (static const path + GoRoute)
6. Gerekirse `firestore.rules` güncelle

---

## Komutlar

```bash
# Çalıştırma
flutter run

# Build
flutter build apk
flutter build ios

# Temizlik
flutter clean && flutter pub get

# Analiz
flutter analyze
```

---

## Dikkat Edilecekler

- `firebase_options.dart` gizli dosyadır, commit etme
- Firestore security rules `firestore.rules` dosyasında
- Route parametreleri her zaman null-safe kontrol et (`is String`, `is num` vb.)
- Hata durumlarında kullanıcıya anlamlı Türkçe mesaj göster
