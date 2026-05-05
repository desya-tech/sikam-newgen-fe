# 🐐 SIKAM Flutter App — Setup Guide

## Versi yang Digunakan
- Flutter: 3.41.7 (stable)
- Dart: 3.11.5
- Android Studio: Hedgehog / Iguana / Jellyfish (keduanya support)

---

## 📁 LANGKAH 1 — Buat Project Flutter Baru

1. Buka **Android Studio**
2. Pilih **New Flutter Project**
3. Pilih **Flutter** → Next
4. Isi:
   - **Project name:** `sikam`
   - **Project location:** pilih folder
   - **Description:** `Sistem Informasi Kambing`
   - **Project type:** `Application`
   - **Organization:** `com.example` (atau domain kamu)
   - **Android language:** `Kotlin`
   - **iOS language:** `Swift`
   - **Platforms:** centang **Android** saja
5. Klik **Create**

---

## 📦 LANGKAH 2 — Ganti pubspec.yaml

Hapus isi `pubspec.yaml` dan ganti dengan:

```yaml
name: sikam
description: SIKAM - Sistem Informasi Kambing
publish_to: 'none'
version: 1.0.0+1

environment:
  sdk: '>=3.5.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter

  # Navigation
  go_router: ^14.6.1

  # State Management
  provider: ^6.1.2

  # HTTP Client
  dio: ^5.7.0

  # Local Storage
  shared_preferences: ^2.3.2

  # Image
  cached_network_image: ^3.4.1
  image_picker: ^1.1.2

  # Charts
  fl_chart: ^0.69.0

  # QR Code
  mobile_scanner: ^5.2.3
  qr_flutter: ^4.1.0

  # Utilities
  intl: ^0.19.0
  shimmer: ^3.0.0

  cupertino_icons: ^1.0.8

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^4.0.0

flutter:
  uses-material-design: true
  assets:
    - assets/images/
```

Lalu jalankan:
```bash
flutter pub get
```

---

## 📂 LANGKAH 3 — Buat Folder Assets

Di root project, buat folder:
```
assets/
└── images/
    └── (kosong dulu, nanti bisa taruh logo)
```

---

## 📱 LANGKAH 4 — Update AndroidManifest.xml

Buka `android/app/src/main/AndroidManifest.xml`, tambahkan permissions di dalam `<manifest>`:

```xml
<!-- Internet -->
<uses-permission android:name="android.permission.INTERNET"/>

<!-- Camera untuk QR Scan -->
<uses-permission android:name="android.permission.CAMERA"/>
<uses-feature android:name="android.hardware.camera" android:required="false"/>

<!-- Untuk image picker -->
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
<uses-permission android:name="android.permission.READ_MEDIA_IMAGES"/>
```

Tambahkan juga di dalam `<application>`:
```xml
android:usesCleartextTraffic="true"
```

Ini diperlukan karena API kita pakai HTTP (bukan HTTPS) di localhost.

---

## 📋 LANGKAH 5 — Salin Semua Source Code

Salin semua file dari folder `lib/` ke project kamu sesuai struktur:

```
lib/
├── main.dart
├── core/
│   ├── constants/
│   │   ├── api_constants.dart
│   │   ├── app_colors.dart
│   │   └── app_text_styles.dart
│   ├── exceptions/
│   │   └── app_exception.dart
│   ├── network/
│   │   └── api_client.dart
│   ├── storage/
│   │   └── local_storage.dart
│   └── utils/
│       ├── permission_helper.dart
│       ├── date_formatter.dart
│       └── snackbar_helper.dart
├── models/
│   ├── auth_model.dart
│   ├── kambing_model.dart
│   ├── perkembangan_model.dart
│   ├── role_model.dart
│   ├── statistik_model.dart
│   └── user_model.dart
├── services/
│   ├── auth_service.dart
│   ├── kambing_service.dart
│   ├── monitoring_service.dart
│   ├── user_service.dart
│   ├── role_service.dart
│   └── upload_service.dart
├── providers/
│   ├── auth_provider.dart
│   ├── kambing_provider.dart
│   ├── monitoring_provider.dart
│   ├── user_provider.dart
│   └── role_provider.dart
├── router/
│   └── app_router.dart
├── screens/
│   ├── splash_screen.dart
│   ├── auth/
│   │   ├── login_screen.dart
│   │   └── forgot_password_screen.dart
│   ├── main_shell.dart
│   ├── dashboard/
│   │   └── dashboard_screen.dart
│   ├── kambing/
│   │   ├── kambing_list_screen.dart
│   │   ├── kambing_detail_screen.dart
│   │   ├── kambing_form_screen.dart
│   │   └── scan_qr_screen.dart
│   ├── perkembangan/
│   │   ├── perkembangan_screen.dart
│   │   └── perkembangan_form_screen.dart
│   ├── monitoring/
│   │   └── monitoring_screen.dart
│   ├── user/
│   │   ├── user_list_screen.dart
│   │   └── user_form_screen.dart
│   ├── role/
│   │   ├── role_list_screen.dart
│   │   └── role_form_screen.dart
│   └── profile/
│       └── profile_screen.dart
└── widgets/
    ├── common/
    │   ├── app_button.dart
    │   ├── app_text_field.dart
    │   ├── loading_overlay.dart
    │   ├── empty_state.dart
    │   └── error_state.dart
    ├── kambing/
    │   └── kambing_card.dart
    └── dashboard/
        ├── stat_card.dart
        └── chart_card.dart
```

---

## 🌐 LANGKAH 6 — Konfigurasi URL API

Buka `lib/core/constants/api_constants.dart` dan sesuaikan:

```dart
static const String baseUrl = 'http://10.0.2.2:3000';  // Android emulator
// Untuk device fisik: ganti dengan IP komputer kamu
// static const String baseUrl = 'http://192.168.1.x:3000';
```

> **Catatan:** `10.0.2.2` adalah alias localhost di Android emulator.  
> Untuk device fisik, pakai IP LAN komputer kamu (cek dengan `ipconfig` di Windows / `ifconfig` di Mac/Linux).

---

## ▶️ LANGKAH 7 — Jalankan App

```bash
flutter run
```

Atau dari Android Studio: tekan tombol **Run** (▶️).

---

## 🧪 LANGKAH 8 — Test Login

Gunakan credential yang sudah di-seed di backend:
- **Username:** `admin`
- **Password:** `password` (sesuaikan dengan seed backend)

---

## ❓ Troubleshooting

### Cleartext HTTP Error
Pastikan `android:usesCleartextTraffic="true"` sudah ada di AndroidManifest.xml.

### Camera Permission Denied
Pastikan permission camera sudah ada di AndroidManifest.xml. Saat pertama kali scan QR, app akan minta permission.

### API Connection Refused
- Pastikan backend NestJS sudah running (`npm run start:dev`)
- Cek IP address (pakai `10.0.2.2` untuk emulator, IP LAN untuk device fisik)

### Package Not Found
Jalankan ulang `flutter pub get` setelah update pubspec.yaml.
