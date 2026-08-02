# Progress SILATAR V2 Mobile App (Flutter)

## Overview

SILATAR V2 Mobile App adalah aplikasi Flutter untuk platform Android/iOS yang dibuat untuk mendukung portal layanan online Kantor Kementerian Agama Tanah Datar (KEMENAG-TD).

---

## Status: DALAM PROGRES
## Last Updated: 2026-08-02

---

## Checklist - Completed Tasks

### Phase 1: Project Setup ✅

- [x] Create Flutter project structure
- [x] Configure pubspec.yaml dengan dependencies
- [x] Download dan setup Poppins font family
- [x] Buat folder structure (assets, lib/core, lib/features)
- [x] Copy logo SVG/webp dari web project

### Phase 2: Theme & Design System ✅

- [x] Buat AppColors (primary, secondary, text, status colors)
- [x] Buat AppTheme dengan Material 3
- [x] Setup Google Fonts integration
- [x] Buat reusable widgets (NeoButton, NeoTextField, NeoPasswordField, NeoDivider, NeoSocialButton)

### Phase 3: Responsive Design System ✅

- [x] Buat Responsive helper utility
- [x] Support berbagai screen size (small phone, phone, tablet)
- [x] Support portrait dan landscape orientation
- [x] Fix overflow issues (Bottom Overflowed, Right Overflowed)

### Phase 4: NEO MIRAI Theme (Matching Web) ✅ (BARU)

- [x] Buat NeoMiraiColors dengan warna sesuai CSS web
- [x] Buat NeoMiraiTheme dengan gradient dan styling sesuai web
- [x] Copy assets dari web project (bg, header, ikon)
- [x] Update semua pages dengan theme baru (Gold, Night, Paper)

### Phase 5: Pages ✅

- [x] **Splash Screen** dengan animasi + logo (theme baru)
- [x] **Welcome Page** dengan responsive design + fitur highlights (theme baru)
- [x] **Login Page** dengan responsive design, form, forgot password (theme baru)
- [x] Setup navigation/routing antar pages

### Phase 6: Environment Setup ✅

- [x] Setup Android SDK
- [x] Accept Android SDK licenses
- [x] Install NDK, CMake, Build Tools
- [x] Configure JAVA_HOME
- [x] Setup USB driver untuk Samsung device
- [x] Successfully connect device (SM S911B)

### Phase 7: Build & Test ✅

- [x] Resolve Kotlin incremental cache issues
- [x] Successfully build debug APK
- [x] Test app running on device

### Phase 8: Backend API Structure ✅ (BARU)

- [x] Buat routes/api.php dengan struktur API lengkap
- [x] Buat BaseApiController dengan response helpers
- [x] Buat AuthController (login, register, logout, profile)
- [x] Buat LayananController (index, show, syarat, units)
- [x] Buat PengajuanController (CRUD, upload, tracking)
- [x] Buat UserController (profile, updateProfile, updatePhoto)
- [x] Update bootstrap/app.php untuk register API routes

### Phase 9: Flutter API Service Layer ✅ (BARU)

- [x] Install dio package di pubspec.yaml
- [x] Buat StorageService untuk token management
- [x] Buat ApiClient dengan Dio interceptors
- [x] Buat AuthService (login, register, logout, profile)
- [x] Buat LayananService (getLayanan, detail, syarat, units)
- [x] Buat PengajuanService (CRUD, upload, tracking)
- [x] Update main.dart untuk init StorageService

### Phase 10: Backend Sanctum & API Fix ✅ (BARU)

- [x] Install Laravel Sanctum untuk authentication
- [x] Setup User model dengan HasApiTokens trait
- [x] Fix login API support email & NIP (nomor_induk)
- [x] Fix personal_access_tokens table (add expires_at column)
- [x] Update API routes dengan auth:sanctum middleware
- [x] Fix Login validator accept NIP/email format

### Phase 11: USB Debugging Setup ✅ (BARU)

- [x] Configure base URL untuk USB debugging
- [x] Support adb reverse (127.0.0.1:8000)
- [x] Support WiFi IP address connection
- [x] Test API endpoints working

---

## Theme - NEO MIRAI (Matching Web SILATAR V2)

### Color Palette

| Color Name | Hex Code | Usage |
|------------|----------|-------|
| **Gold** | #B08D57 | Primary brand color |
| **Gold Bright** | #C9A96E | Highlights |
| **Gold Light** | #D4BC8E | Light accents |
| **Paper** | #F5F3EF | Background |
| **Paper Soft** | #EBE8E2 | Secondary background |
| **Ink** | #2A2825 | Primary text |
| **Ink Soft** | #524B44 | Secondary text |
| **Ash** | #8C857A | Muted text |
| **Night** | #2D4859 | Dark accent |
| **Night Soft** | #3D6B82 | Dark accent variant |
| **Sun** | #E8A84C | Tertiary accent |
| **Rice** | #F7F5F0 | Surface/cards |
| **Line** | #BAB4AB | Borders/dividers |
| **Success** | #5D9E5F | Success states |
| **Warning** | #E8A84C | Warning states |
| **Error** | #D45D5D | Error states |
| **Info** | #4A8DB5 | Info states |

### Font Family

| Font | Usage |
|------|-------|
| **Chakra Petch** | Headings, titles, buttons (matching web) |
| **Poppins** | Body text, descriptions |

### Gradients

| Gradient | Colors |
|----------|--------|
| Gold Gradient | #B08D57 → #C9A96E |
| Paper Gradient | #F5F3EF → #EBE8E2 |
| Night Gradient | #2D4859 → #3D6B82 |

---

## Assets yang Di-copy dari Web

```
assets/
├── images/
│   ├── logo.webp                  # Logo utama
│   ├── header.webp               # Header banner
│   ├── template/
│   │   ├── bg.webp              # Background pattern
│   │   ├── banner-02.webp ...  # Banners
│   │   └── ...                  # Other templates
│   └── ikon/
│       ├── BATAL.webp           # Status icons
│       ├── DIPROSES.webp
│       ├── DITERIMA.webp
│       ├── DITOLAK.webp
│       ├── DRAFT.webp
│       ├── SUKSES.webp
│       ├── PENDING.webp
│       ├── LaporanKinerja.webp
│       └── ... (80+ icons)
```

---

## Responsive Design Features

### Screen Size Support

| Screen Type | Width | Features |
|-------------|-------|----------|
| Small Phone | < 360px | Compact layout, smaller fonts, reduced spacing |
| Phone | 360-600px | Standard layout |
| Tablet | > 600px | Larger fonts, more spacing, wider layouts |

### Orientation Support

| Orientation | Layout |
|-------------|--------|
| Portrait | Vertical stack, scrollable content |
| Landscape | Side-by-side layout, logo + content |

---

## Project Structure

```
silatar_v2/ (Lokasi: C:\silatar_v2)
├── lib/
│   ├── main.dart                          # Entry point + Splash Screen
│   ├── core/
│   │   ├── theme/
│   │   │   ├── app_theme.dart           # Original theme
│   │   │   └── neo_mirai_theme.dart     # NEW - Web-matching theme
│   │   ├── utils/
│   │   │   └── responsive.dart          # Responsive helpers
│   │   └── widgets/
│   │       └── neo_components.dart     # Responsive widgets
│   └── features/
│       ├── welcome/
│       │   └── welcome_page.dart        # Welcome page (updated)
│       └── login/
│           └── login_page.dart          # Login page (updated)
├── assets/
│   ├── fonts/                           # Poppins font family
│   ├── images/                          # Images & icons from web
│   │   ├── logo.webp
│   │   ├── header.webp
│   │   ├── template/
│   │   └── ikon/
│   └── icons/
└── pubspec.yaml
```

---

## Files yang Dimodifikasi/Ditambahkan (Backend)

| File | Perubahan |
|------|-----------|
| `routes/api.php` | **BARU** - API routes |
| `app/Http/Controllers/Api/BaseApiController.php` | **BARU** - Base controller untuk API |
| `app/Http/Controllers/Api/AuthController.php` | **BARU** - Auth endpoints |
| `app/Http/Controllers/Api/LayananController.php` | **BARU** - Layanan endpoints |
| `app/Http/Controllers/Api/PengajuanController.php` | **BARU** - Pengajuan endpoints |
| `app/Http/Controllers/Api/UserController.php` | **BARU** - User profile endpoints |
| `bootstrap/app.php` | Update - register API routes |

## Files yang Dimodifikasi/Ditambahkan (Flutter)

| File | Perubahan |
|------|-----------|
| `lib/main.dart` | Entry point dengan splash screen + StorageService init |
| `lib/core/theme/neo_mirai_theme.dart` | **BARU** - Theme sesuai web SILATAR V2 |
| `lib/core/theme/app_theme.dart` | Theme original |
| `lib/core/utils/responsive.dart` | Responsive helper utilities |
| `lib/core/widgets/neo_components.dart` | Widgets dengan theme baru |
| `lib/core/services/storage_service.dart` | **BARU** - Token management |
| `lib/core/services/api_client.dart` | **BARU** - Dio HTTP client |
| `lib/core/services/auth_service.dart` | **BARU** - Auth API service |
| `lib/core/services/layanan_service.dart` | **BARU** - Layanan API service |
| `lib/core/services/pengajuan_service.dart` | **BARU** - Pengajuan API service |
| `lib/features/welcome/welcome_page.dart` | Welcome page (theme baru) |
| `lib/features/login/login_page.dart` | Login page (theme baru) |
| `assets/images/*` | **BARU** - Assets dari web project |
| `pubspec.yaml` | Update - add dio dependency |

---

## TODO - Next Steps

### Priority 1: Core Pages (Flutter UI)

- [ ] **Home Page** - Dashboard utama dengan bottom navigation
- [ ] **Katalog Layanan** - Daftar layanan yang tersedia
- [ ] **Detail Layanan** - Info lengkap layanan
- [ ] **Form Pengajuan** - Form ajukan layanan baru
- [ ] **Tracking Pengajuan** - Lacak status pengajuan
- [ ] **Profile Page** - Profil user dan settings

### Priority 2: Integration (UI + API)

- [ ] Connect Login page dengan AuthService
- [ ] Connect Home page dengan API data
- [ ] Connect Katalog Layanan dengan LayananService
- [ ] Connect Pengajuan page dengan PengajuanService
- [ ] Implementasi state management (Provider)
- [ ] Test API integration

### Priority 3: Additional Features

- [ ] **Push Notifications** - Notifikasi status pengajuan
- [ ] **Offline Support** - Cache data untuk offline
- [ ] **Image Upload** - Upload dokumen/foto
- [ ] **Biometric Auth** - Fingerprint/face unlock

---

## Roadmap

```
Phase 1-7: Flutter UI      ✅ DONE
├── Setup, Theme, Responsive
├── NEO MIRAI theme
├── Splash, Welcome, Login
└── Build & Test

Phase 8: Backend API       ✅ DONE
├── API routes structure
├── Auth endpoints
├── Layanan endpoints
├── Pengajuan endpoints
└── User endpoints

Phase 9: Flutter API Svc  ✅ DONE
├── Dio HTTP client
├── StorageService
├── AuthService
├── LayananService
└── PengajuanService

Phase 10: Sanctum Auth    ✅ DONE
├── Laravel Sanctum setup
├── User model HasApiTokens
├── API middleware
└── Login email/NIP fix

Phase 11: Core Features     📋 NEXT
├── Home page + navigation
├── Katalog layanan
├── Form pengajuan
└── Tracking pengajuan

Phase 12: Advanced          📋 PLANNED
├── Push notifications
├── Offline mode
└── File upload
```

---

## Changelog

### 2026-08-02 - Session 5

- ✅ Install Laravel Sanctum untuk mobile API auth
- ✅ Setup User model dengan HasApiTokens trait
- ✅ Fix login API support email & NIP (nomor_induk) - samakan dengan web login
- ✅ Fix personal_access_tokens table (add expires_at column)
- ✅ Fix Login validator accept NIP (digits) atau email (@)
- ✅ Update API endpoints di ApiService Flutter
- ✅ Configure base URL untuk USB debugging (127.0.0.1:8000)
- ✅ Test API login endpoint working

### 2026-08-02 - Session 4 (Lanjutan)

- ✅ Install dio package di pubspec.yaml
- ✅ Buat StorageService untuk token & user data management
- ✅ Buat ApiClient dengan Dio interceptors (auth header, error handling)
- ✅ Buat AuthService (login, register, logout, profile, changePassword)
- ✅ Buat LayananService (getLayanan, getDetail, getSyarat, getUnits)
- ✅ Buat PengajuanService (CRUD, upload, tracking)
- ✅ Update main.dart untuk init StorageService

### 2026-08-02 - Session 4

- ✅ Buat NeoMiraiColors dengan warna sesuai CSS web
- ✅ Buat NeoMiraiTheme dengan Material 3
- ✅ Copy 80+ ikon status dari web project
- ✅ Copy background dan header images
- ✅ Update Splash Screen dengan theme baru (Gold/Night gradient)
- ✅ Update Welcome Page dengan theme baru
- ✅ Update Login Page dengan theme baru
- ✅ Update NeoButton dengan Chakra Petch font
- ✅ Flutter analyze: No issues found

### 2026-08-02 - Session 2

- ✅ Copy logo dari web project (favicon.webp)
- ✅ Buat Responsive helper utility
- ✅ Update Welcome page dengan responsive design
- ✅ Update Login page dengan responsive design
- ✅ Update Splash screen dengan responsive design
- ✅ Update NeoButton, NeoTextField, NeoSocialButton dengan responsive sizing
- ✅ Fix overflow issues
- ✅ Support portrait dan landscape orientation
- ✅ Support small phone, phone, dan tablet screen sizes

### 2026-08-02 - Session 1

- ✅ Successfully build dan run app di Samsung SM S911B
- ✅ Setup Android SDK dengan NDK, CMake, Build Tools
- ✅ Resolve Kotlin incremental cache issues
- ✅ Complete Splash, Welcome, dan Login pages

---

## Notes

1. **Lokasi Project**: Project dipindahkan ke `C:\silatar_v2` karena path terlalu panjang
2. **Device**: Samsung SM S911B (Samsung Galaxy S23) berhasil digunakan untuk testing
3. **Theme**: NEO MIRAI theme dengan warna Gold (#B08D57) sesuai web SILATAR V2
4. **Font**: Chakra Petch untuk headings/buttons, Poppins untuk body text
5. **Assets**: 80+ ikon status dan background images dari web project
6. **Backend API**: Laravel API sudah dibuat di `d:\work\SourceCode\silatarV2`

---

## API Documentation (Backend Laravel)

### Base URL
```
http://localhost:8000/api
```

### Authentication
API menggunakan **Laravel Sanctum** untuk authentication. Include token di header:
```
Authorization: Bearer {token}
```

### Public Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/auth/login` | Login user |
| POST | `/auth/register` | Register user baru |
| POST | `/auth/forgot-password` | Request reset password |
| GET | `/layanan` | Daftar layanan (paginated) |
| GET | `/layanan/{id}` | Detail layanan |

### Protected Endpoints (Auth Required)

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/auth/me` | Get current user |
| POST | `/auth/logout` | Logout |
| PUT | `/auth/update-profile` | Update profile |
| PUT | `/auth/change-password` | Ganti password |
| GET | `/layanan/{id}/syarat` | Get persyaratan layanan |
| GET | `/pengajuan` | Daftar pengajuan user |
| POST | `/pengajuan` | Buat pengajuan baru |
| GET | `/pengajuan/{id}` | Detail pengajuan |
| PUT | `/pengajuan/{id}` | Update pengajuan |
| DELETE | `/pengajuan/{id}` | Hapus pengajuan |
| POST | `/pengajuan/{id}/upload` | Upload file |
| GET | `/pengajuan/{id}/tracking` | Tracking history |
| GET | `/user/profile` | Get profile |
| PUT | `/user/profile` | Update profile |
| PUT | `/user/profile/photo` | Update foto |
| GET | `/units` | Daftar satuan kerja |

### Response Format

**Success:**
```json
{
  "success": true,
  "message": "Success message",
  "data": { ... }
}
```

**Error:**
```json
{
  "success": false,
  "message": "Error message",
  "errors": { ... } // optional
}
```

**Paginated:**
```json
{
  "success": true,
  "message": "...",
  "data": [...],
  "meta": {
    "current_page": 1,
    "last_page": 5,
    "per_page": 12,
    "total": 50
  }
}
```

---

## Resources

- [Flutter Documentation](https://docs.flutter.dev/)
- [Material Design 3](https://m3.material.io/)
- [Flutter Animate](https://pub.dev/packages/flutter_animate)
- [Google Fonts - Chakra Petch](https://fonts.google.com/specimen/Chakra+Petch)
- [Google Fonts - Poppins](https://fonts.google.com/specimen/Poppins)

---

## Contact

Untuk pertanyaan atau bantuan, hubungi tim development.
