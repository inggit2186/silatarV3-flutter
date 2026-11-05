# SILATAR V2 Flutter App - Developer Changelog

> **INTERNAL DOCUMENT - FOR DEVELOPER USE ONLY**
>
> Dokumen ini berisi daftar lengkap fitur aplikasi dan changelog tiap patch/version.
> Tidak untuk distribusikan ke pengguna akhir.

---

## Info Aplikasi

| Field | Value |
|-------|-------|
| **App Name** | SILATAR V2 |
| **Package** | com.example.silatar_v2 |
| **Version** | 2.0.0 |
| **App Version Code** | 1 |
| **Build Number** | 1 |
| **Flutter SDK** | ^3.12.2 |
| **Dart SDK** | ^3.12.2 |

---

## Tech Stack

| Component | Technology |
|-----------|------------|
| Framework | Flutter 3.x |
| State Management | Provider |
| HTTP Client | Dio + http |
| Local Storage | shared_preferences |
| Hot Code Push | flutter_patcher |
| Image Caching | cached_network_image |
| Animations | flutter_animate |
| PDF Generation | pdf + printing |
| Location | geolocator + flutter_map |
| Icons | Material Icons + Google Fonts |

---

## Fitur Aplikasi (Current Features)

### 1. Authentication
- [x] Login dengan NIP/Email + Password
- [x] Remember Me functionality
- [x] Auto-login dengan token tersimpan
- [x] Logout dengan konfirmasi
- [x] Forgot Password (request reset link)

### 2. Dashboard
- [x] Greeting card dengan waktu (Pagi/Siang/Sore/Malam)
- [x] Statistik pengajuan (Total, Pending, Diproses, Selesai, Ditolak)
- [x] Quick Actions (Ajukan Layanan, Pengajuan Saya)
- [x] Secondary actions (Presensi, Kegiatan, Info)
- [x] Aktivitas terakhir (empty state)
- [x] Responsive layout (portrait/landscape)
- [x] Pull to refresh

### 3. Menu Pelayanan (Layanan Page)
- [x] Grid menu dengan 12 fitur:
  - Presensi
  - Riwayat Presensi
  - Layanan
  - Pengajuan
  - Kegiatan
  - Laporan
  - Janji Temu
  - SIMPEG
  - Acara
  - Cuti
  - Error/Tugas Luar
  - Pengaduan
- [x] Search/filter menu
- [x] Color-coded cards
- [x] Coming soon indicator

### 4. Presensi
- [x] Ambil presensi masuk/pulang
- [x] Lokasi GPS dengan jarak
- [x] Keterangan opsional
- [x] Validasi jam kerja
- [x] Riwayat presensi bulanan
- [x] Filter bulan/tahun
- [x] Status (Normal/Terlambat/Pulang Cepat)
- [x] Jarak lokasi (meter)

### 5. Kegiatan (Laporan Kegiatan Harian)
- [x] Tab Harian dan Rekap
- [x] Input kegiatan harian
- [x] Bulan/tahun picker
- [x] Search kegiatan
- [x] Rekap bulanan
- [x] PDF generation (laporan bulanan)
- [x] PDF preview dan print/share

### 6. Janji Temu
- [x] Ajukan janji temu baru
- [x] Pilih department/tujuan
- [x] Pilih tanggal dan jam
- [x] Keterangan/keperluan
- [x] Riwayat janji temu
- [x] Filter status (Semua/Menunggu/Disetujui/Ditolak/Dibatalkan)
- [x] Detail janji temu
- [x] Batalkan janji temu

### 7. SIMPEG
- [x] Request reset password SIMPEG
- [x] Konfirmasi request
- [x] Riwayat request
- [x] Status tracking (Menunggu/Diproses/Selesai/Ditolak)

### 8. Acara Kankemenag
- [x] Daftar acara
- [x] Detail acara
- [x] Presensi Hadir/Tidak Hadir
- [x] Filter status kehadiran
- [x] GPS location untuk presensi

### 9. Profile Management
- [x] Edit profil (nama, email, no HP, alamat, dll)
- [x] Upload foto profil
- [x] Ubah password
- [x] Tampilkan info user (NIP, role, unit kerja)

### 10. Admin Panel
- [x] Akses berdasarkan role (admin, superadmin, petugas, kasi, kasubag, kepala)
- [x] Kelola Janji Temu (approve/reject)
- [x] Verifikasi SIMPEG request
- [x] Kelola Pengajuan (coming soon)
- [x] Kelola Users (coming soon)
- [x] Laporan (coming soon)

### 11. Update System
- [x] Hybrid update system (Patch + APK)
- [x] Hot code push dengan flutter_patcher
- [x] Full APK download & install
- [x] Progress indicator saat download
- [x] MD5 verification
- [x] Mandatory update handling
- [x] Auto-update check saat app start

### 12. UI/UX
- [x] Tema NEO MIRAI (gold + dark blue)
- [x] Responsive design (phone/tablet)
- [x] Dark mode splash screen
- [x] Animated transitions
- [x] Loading states
- [x] Error states dengan retry
- [x] Empty states
- [x] Pull to refresh
- [x] Infinite scroll / pagination

---

## API Endpoints

### Auth
| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/auth/login` | Login user |
| POST | `/api/auth/logout` | Logout user |
| GET | `/api/auth/me` | Get current user profile |

### User
| Method | Endpoint | Description |
|--------|----------|-------------|
| PUT | `/api/user/profile` | Update profile |
| POST | `/api/user/profile/photo` | Upload profile photo |
| PUT | `/api/auth/change-password` | Change password |

### Layanan
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/layanan` | Get list of services |
| GET | `/api/layanan/{id}` | Get service detail |
| GET | `/api/layanan/{id}/syarat` | Get service requirements |

### Pengajuan
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/pengajuan` | Get user's submissions |
| POST | `/api/pengajuan` | Submit new request |
| GET | `/api/pengajuan/{id}` | Get submission detail |
| POST | `/api/pengajuan/{id}/cancel` | Cancel submission |

### Presensi
| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/presensi` | Save attendance |
| GET | `/api/presensi/today` | Get today's attendance |
| GET | `/api/presensi/history` | Get attendance history |

### Janji Temu
| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/janji-temu` | Create appointment |
| GET | `/api/janji-temu/my-appointments` | Get user's appointments |
| GET | `/api/janji-temu/{id}` | Get appointment detail |
| PUT | `/api/janji-temu/{id}/cancel` | Cancel appointment |
| GET | `/api/janji-temu/departments` | Get departments list |

### Admin Janji Temu
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/admin/janji-temu` | Get all appointments |
| PUT | `/api/admin/janji-temu/{id}/approve` | Approve appointment |
| PUT | `/api/admin/janji-temu/{id}/reject` | Reject appointment |

### SIMPEG
| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/simpeg/reset-password` | Request password reset |
| GET | `/api/simpeg/my-requests` | Get user's requests |
| GET | `/api/admin/simpeg` | Get all SIMPEG requests (admin) |
| PUT | `/api/admin/simpeg/{id}/verify` | Verify request (admin) |

### Acara
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/acara` | Get list of events |
| POST | `/api/acara/{id}/hadir` | Submit attendance |
| POST | `/api/acara/{id}/tidak-hadir` | Submit not attending |

### Update
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/patch/check` | Check for updates |

---

## Changelog

### Version 2.0.0 (Build 1) - Initial Release

#### Commit History (Latest First)

```
93a6370 feat(app): redesign login page and add background images for main app
    - Redesign login page dengan background images
    - Add assets untuk splash, welcome, dan background app

b27e873 refactor(update): simplify mandatory patch success modal further
    - Sederhanakan modal success untuk mandatory patch

eb9e6a1 refactor(update): simplify mandatory patch success modal
    - Simplifikasi UI modal setelah patch mandatory berhasil

b7a190d feat(update): auto-apply mandatory patch updates with progress indicator
    - Implementasi auto-apply untuk mandatory patch updates
    - Tambah progress indicator saat apply patch

324ab09 fix(patcher): send base version without patchCount to backend
    - Fix versioning: kirim base version tanpa patchCount ke backend

50aea62 fix(patcher): use buildNumber for APK upgrade detection
    - Gunakan buildNumber untuk deteksi APK upgrade

761ac30 fix(patcher): correct versioning logic with build_number
    - Koreksi logic versioning dengan build_number

5b8f612 fix(build): appVersionCode must always increment, never reset
    - appVersionCode harus selalu increment, tidak pernah reset

570b860 fix(patcher): hybrid versioning fixes and UI improvements
    - Perbaikan hybrid versioning
    - UI improvements untuk update system

261daef fix(flutter): improve generate_patch.bat with clearer output
    - Perbaikan script generate_patch.bat

0a53833 feat(version): centralized version management system
    - Implementasi centralized version management
    - app_version.dart untuk konfigurasi versi

10d07d5 fix(apk): improve download progress and install confirmation flow
    - Perbaikan download progress
    - Perbaikan install confirmation flow

2f26f08 fix(apk): use proper MD5 implementation from crypto package
    - Gunakan implementasi MD5 dari crypto package

859428f fix(update): enable update check in debug mode for testing
    - Enable update check di debug mode untuk testing

5a90a78 feat(update): implement hybrid update system (patch + APK)
    - Implementasi hybrid update system
    - Support untuk patch dan APK updates

0733cbf fix(build): remove minifyEnabled causing Gradle 9.x error
    - Hapus minifyEnabled yang menyebabkan error di Gradle 9.x

5eb8ccf feat(patch): add generate_patch.bat script
    - Tambah script generate_patch.bat untuk hot code push

7226f9a fix(build): improve build scripts with error handling
    - Perbaikan build scripts dengan error handling

d20a189 fix(build): suppress flutter_patcher KGP warning
    - Suppress warning dari flutter_patcher KGP

7fddab0 fix(build): remove invalid debugSymbolLevel reference
    - Hapus invalid debugSymbolLevel reference

207f029 feat(build): optimize APK size for Android only
    - Optimasi ukuran APK untuk Android only

0876e6e fix(network): add INTERNET permission and network security config
    - Tambah INTERNET permission
    - Tambah network security config

277bc17 feat(patch): update PatchService untuk koneksi ke backend API
    - Update PatchService untuk koneksi ke backend API

862361a feat: hot code push dengan flutter_patcher + splash/welcome redesign
    - Implementasi hot code push dengan flutter_patcher
    - Redesign splash dan welcome screen

bd455c2 fix(dashboard): replace 3-dot menu with direct logout icon
    - Ganti 3-dot menu dengan icon logout langsung

a5c619c fix(dashboard): remove Profil Saya menu from header
    - Hapus menu Profil Saya dari header

e05786d fix(dashboard): remove snackbar from Profil Saya menu
    - Hapus snackbar dari menu Profil Saya

77922e4 fix(dashboard): update Profil Saya menu to show snackbar
    - Update menu Profil Saya untuk show snackbar

710f8b5 feat(profile): add logout button to ProfileContent tab
    - Tambah tombol logout di ProfileContent tab
```

---

## Struktur File Utama

```
lib/
├── main.dart                          # Entry point + splash screen
├── core/
│   ├── config/
│   │   └── app_version.dart          # Version configuration
│   ├── services/
│   │   ├── api_service.dart          # Main API client
│   │   ├── api_config.dart           # API configuration
│   │   ├── api_client.dart          # HTTP client wrapper
│   │   ├── auth_service.dart        # Authentication service
│   │   ├── storage_service.dart     # Local storage service
│   │   ├── patch_service.dart       # Hot code push service
│   │   ├── update_service.dart      # Update management
│   │   ├── apk_update_service.dart  # APK download/install
│   │   ├── kegiatan_service.dart     # Kegiatan API
│   │   ├── layanan_service.dart      # Layanan API
│   │   ├── pengajuan_service.dart   # Pengajuan API
│   │   ├── pdf_service.dart         # PDF generation
│   │   └── location_service.dart     # GPS location
│   ├── models/
│   │   ├── user_model.dart          # User model
│   │   ├── layanan_model.dart       # Layanan model
│   │   ├── presensi_model.dart      # Presensi model
│   │   ├── kegiatan_model.dart       # Kegiatan model
│   │   ├── janji_temu_model.dart    # Janji temu model
│   │   └── status_model.dart         # Status model
│   ├── providers/
│   │   ├── user_provider.dart       # User state
│   │   └── kegiatan_provider.dart    # Kegiatan state
│   ├── theme/
│   │   ├── neo_mirai_theme.dart     # Theme configuration
│   │   └── app_theme.dart           # Additional theme
│   ├── utils/
│   │   ├── responsive.dart          # Responsive helpers
│   │   └── phone_formatter.dart     # Phone number formatter
│   └── widgets/
│       ├── neo_components.dart       # Reusable UI components
│       ├── persistent_nav_bar.dart   # Bottom navigation
│       └── update_dialog.dart        # Update dialog widget
├── features/
│   ├── welcome/
│   │   └── welcome_page.dart        # Welcome screen
│   ├── login/
│   │   └── login_page.dart          # Login page
│   ├── main_shell.dart              # Main app shell
│   ├── dashboard/
│   │   ├── dashboard_page.dart      # Dashboard (standalone)
│   │   └── dashboard_content.dart   # Dashboard content
│   ├── layanan/
│   │   ├── layanan_page.dart        # Menu page (standalone)
│   │   └── layanan_content.dart      # Menu content
│   ├── profile/
│   │   ├── profile_page.dart        # Profile page
│   │   ├── edit_profile_page.dart   # Edit profile
│   │   └── change_password_page.dart # Change password
│   ├── pengajuan/
│   │   └── pengajuan_page.dart      # Pengajuan tracking
│   ├── presensi/
│   │   ├── presensi_page.dart      # Presensi page
│   │   └── presensi_content.dart   # Presensi content
│   ├── riwayat/
│   │   └── riwayat_presensi_page.dart # Presensi history
│   ├── kegiatan/
│   │   ├── kegiatan_page.dart        # Kegiatan page
│   │   ├── widgets/
│   │   │   ├── kegiatan_harian_tab.dart
│   │   │   ├── kegiatan_bulanan_tab.dart
│   │   │   ├── kegiatan_form_modal.dart
│   │   │   ├── kegiatan_search_filter.dart
│   │   │   ├── kegiatan_harian_item.dart
│   │   │   └── pdf_preview_page.dart
│   ├── laporan/
│   │   └── laporan_bulanan_page.dart # Laporan bulanan
│   ├── janji_temu/
│   │   ├── riwayat_janji_temu_page.dart
│   │   ├── buat_janji_temu_page.dart
│   │   ├── detail_janji_temu_page.dart
│   │   └── admin_janji_temu_page.dart
│   ├── simpeg/
│   │   ├── simpeg_reset_password_page.dart
│   │   └── admin_simpeg_page.dart
│   ├── acara/
│   │   ├── acara_list_page.dart
│   │   ├── acara_detail_page.dart
│   │   └── acara_presensi_page.dart
│   └── admin/
│       └── admin_section_page.dart  # Admin panel
└── assets/
    ├── images/
    │   ├── splash_bg.png
    │   ├── welcome_bg.png
    │   ├── bg.webp
    │   ├── login_bg.webp
    │   ├── template/
    │   └── ikon/
    ├── icons/
    └── fonts/
```

---

## User Roles

| Role | Description | Access Level |
|------|-------------|--------------|
| superadmin | Super Administrator | Full access |
| admin | Administrator | Full access |
| frontdesk | Front Desk | Limited |
| kasubag | Kepala Sub Bagian | Admin panel |
| kepala | Kepala | Admin panel |
| kasi | Kepala Seksi | Admin panel |
| petugas | Petugas | Admin panel |
| pegawai | Pegawai | User only |
| other | Lainnya | User only |
| pensiun | Pensiunan | User only |
| pindah | Mutasi/Pindah | User only |

---

## Request Statuses

| Status | Description |
|--------|-------------|
| DRAFT | Draft (belum diajukan) |
| UNCHECK | Belum dicek |
| PENDING | Menunggu verifikasi |
| DITERIMA | Diterima |
| DIPROSES | Sedang diproses |
| SUKSES | Selesai/Sukses |
| DITOLAK | Ditolak |
| BATAL | Dibatalkan |

---

## Assets Required

```
assets/
├── images/
│   ├── splash_bg.png         # Splash screen background
│   ├── welcome_bg.png        # Welcome page background
│   ├── bg.webp              # Main app background
│   ├── login_bg.webp        # Login page background
│   └── template/
│   └── ikon/
├── icons/
│   └── icon_compressed.png   # App icon
└── fonts/
    ├── Poppins-Regular.ttf
    ├── Poppins-Medium.ttf
    └── Poppins-SemiBold.ttf
```

---

## Build Commands

```bash
# Development
flutter run

# Build debug APK
flutter build apk --debug

# Build release APK
flutter build apk --release

# Build for Android only (smaller size)
flutter build apk --release --target-platform android-arm,android-arm64

# Generate hot patch
generate_patch.bat

# Clean and rebuild
flutter clean
flutter pub get
flutter build apk --release
```

---

## Catatan Development

1. **Hot Code Push**: Gunakan `generate_patch.bat` untuk membuat patch. Patch hanya bisa mengubah kode Dart, tidak bisa mengubah native code atau assets.

2. **APK Update**: Untuk perubahan yang mempengaruhi native code atau assets, harus release APK baru.

3. **Versioning**:
   - `version`: Version string (misal "2.0.0")
   - `appVersionCode`: Incremental integer, RESET per version
   - `buildNumber`: Global counter, NEVER reset

4. **API Base URL**: Default ke `https://kemenagtanahdatar.id/api`. Untuk development lokal, gunakan USB debugging dengan `adb reverse tcp:8000 tcp:8000`.

5. **Update System**: Hybrid approach dengan:
   - **Patch**: Untuk perubahan kode Dart ringan
   - **APK**: Untuk perubahan native code atau assets

---

*Last Updated: 2026-10-08*
*Created by: Developer Team*
