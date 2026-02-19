# Ticket Management System

**Tablet-first POS & check management for restaurants and takeaways.** Multi-tenant Flutter app with Firebase backend: tables, orders, payments, and daily reports.

[![Flutter](https://img.shields.io/badge/Flutter-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-0175C2?logo=dart&logoColor=white)](https://dart.dev)
[![Firebase](https://img.shields.io/badge/Firebase-FFCA28?logo=firebase&logoColor=black)](https://firebase.google.com)

---

## Overview

A production-style Flutter application for managing table orders (adisyon), payments, and daily reports. Designed for tablet use in restaurants, cafés, and takeaways. Supports **multiple tenants** (businesses): after login, staff select the venue and work with that venue’s tables, products, and orders. Data is isolated per tenant in Firestore.

**Highlights:**

- **Multi-tenant:** One app, multiple businesses; tenant-scoped data and auth.
- **Tablet-optimized:** Touch targets and layout tuned for tablets (Android/iOS).
- **Feature-based architecture:** Clear separation of data, domain, and presentation; repository pattern over Firebase.
- **Declarative routing:** `go_router` with typed routes and deep linking.
- **Reactive state:** Riverpod for auth state, tenant selection, and repository injection.

---

## Tech Stack

| Layer | Choice |
|--------|--------|
| **UI** | Flutter (Material), responsive layout |
| **State & DI** | Riverpod (providers for repositories, auth, tenant) |
| **Navigation** | go_router |
| **Backend** | Firebase Auth (email/password), Cloud Firestore |
| **Structure** | Feature-based folders, repository pattern, shared `core` |

---

## Features

- **Auth:** Register, login, tenant selection after login.
- **Tables:** List of tables + “Package” (takeaway); status (occupied/empty), open check total.
- **Orders:** Category → product, quantity (1/2/3 or +/-); add items to existing table or package.
- **Payments:** Close check with **Cash** or **Card**; stored for reporting.
- **Settings:** Manage categories, products, and tables per tenant.
- **Reports:** Daily revenue, Z-report (cash vs card), sold items detail.

---

## Architecture & Project Structure

- **Feature-based layout:** Each feature has its own folder under `lib/features/` (auth, tables, adisyon, products, reports).
- **Shared core:** `lib/core/` — theme, constants, router, Riverpod providers, splash.
- **Data layer:** `lib/data/` — Firestore paths, service wrapper, repositories, models. Firestore access is centralized; collections are tenant-scoped (`tenants/{tenantId}/tables`, `orders`, etc.).
- **Routing:** Single `AppRouter` with `go_router`; routes for splash, login, register, tenant select, home (tables), adisyon, close-check, products, reports.

```
lib/
├── main.dart
├── app.dart
├── core/           # theme, router, providers, constants, splash, responsive
├── data/           # firebase (paths, service), repositories, models
└── features/
    ├── auth/       # login, register, tenant select
    ├── tables/     # tables home (masa listesi)
    ├── adisyon/    # order entry, close check
    ├── products/   # categories, products, tables CRUD (settings)
    └── reports/    # daily reports, Z report
```

---

## Getting Started

**Requirements:** Flutter SDK ^3.7.2, a Firebase project (Auth + Firestore).

1. **Clone and install**
   ```bash
   git clone https://github.com/YOUR_USERNAME/ticket_management_system.git
   cd ticket_management_system
   flutter pub get
   ```

2. **Firebase**
   - Create a project in [Firebase Console](https://console.firebase.google.com), enable **Authentication** (Email/Password) and **Firestore**.
   - Copy `.firebaserc.example` to `.firebaserc` and set your project ID.
   - Generate config files (recommended):
     ```bash
     dart run flutterfire_cli:flutterfire configure
     ```
   - Or manually: copy `lib/firebase_options.example.dart` to `lib/firebase_options.dart` and fill in your keys; add `google-services.json` and `GoogleService-Info.plist` for Android/iOS.

3. **Firestore data model**
   - Root collection: `tenants` (e.g. `name`).
   - Per-tenant: `tenants/{tenantId}/tables`, `categories`, `products`, `orders`.
   - Optional: use the `scripts/` seed (see below) or run the app and register a user, then create tenants/tables/categories/products via the UI.

4. **Run**
   ```bash
   flutter run
   ```
   Target a tablet or phone; the UI is optimized for tablet.

**Optional — seed data:**  
If you have a Firestore service account JSON, place it at `scripts/service-account.json` and run `cd scripts && npm install && npm run seed` to create sample tenants, tables, categories, and products.

---

## License

This project is available for portfolio and reference use. See repository for details.
