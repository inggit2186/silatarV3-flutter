# Progress Logo WebP

## Overview
Menggunakan `assets/images/logo.webp` sebagai logo aplikasi di Welcome Page dan Login Page. Sebelumnya, "logo" di kedua halaman adalah Container dekoratif dengan `Icons.account_balance_rounded` — bukan gambar logo asli. File `logo.webp` (177KB, lossless) sudah tersedia di `assets/images/` dan sudah otomatis di-include oleh `pubspec.yaml`.

## Status: SELESAI

## Checklist
- [x] Konfirmasi dukungan WebP di Flutter (native, tidak perlu plugin tambahan)
- [x] Verifikasi `assets/images/logo.webp` sudah terdaftar di pubspec.yaml
- [x] Tentukan lokasi penempatan logo (Welcome + Login)
- [x] Ganti logo di splash screen, welcome page, login page (portrait + landscape + header badge)
- [x] Font SILATAR login page: Chakra Petch, 32px, bold, glow gold
- [x] Hapus `assets/images/logo.svg` (tidak dipakai)
- [x] Dashboard header: avatar sudah pakai `CachedNetworkImage` dari `user?.photoUrl` (API return `pp` field)
- [x] Dashboard greeting card: "Kemenag Tanah Datar" diganti `user?.unitKerja ?? user?.dept?.nama ?? 'Kemenag Tanah Datar'`
- [x] User model: `unitKerja` parsing now includes `dept.nama` (API tidak return `unit_kerja` di top-level, dept nama di nested `dept.nama`)
- [x] Konsolidasi base URL: `api_service.dart` dan `api_client.dart` sekarang import `ApiConfig.baseUrl` dari `api_config.dart` (single source of truth)

## Data Flow
```
asset bundle -> pubspec.yaml flutter.assets (assets/images/) -> Image.asset('assets/images/logo.webp')
```

## Files yang Dimodifikasi
| File | Perubahan |
|------|-----------|
| lib/features/welcome/welcome_page.dart | `_buildLogo()`: ganti Stack dekoratif (icon + teks) dengan `Image.asset` dari logo.webp, tetap di dalam Container gold-gradient sebagai frame |
| lib/features/login/login_page.dart | `_buildHeader()`: ganti Logo Badge sintetik (icon + "SILATAR" text) dengan image logo.webp |

## Files Baru
| File | Purpose |
|------|---------|
| LOGO_WEBP_PROGRESS.md | File progress untuk perubahan ini |

## Files Dihapus
| File | Alasan |
|------|--------|
| assets/images/logo.svg | Tidak ada kode Dart yang menggunakan `SvgPicture`. Folder `assets/images/` masih di-include di pubspec untuk asset lain (favicon.webp, header.webp, template/, ikon/) |

## Catatan Teknis
- `Image.asset` mendukung WebP native di Flutter (≥ 2.0), tidak perlu `flutter_svg` atau plugin lain
- Tetap menggunakan `Responsive.logoSize(130)` untuk ukuran logo di welcome page (mendukung tablet/small-phone)
- Di login page header, logo ditampilkan ~36-40px (konsisten dengan badge badge-style)
- `fit: BoxFit.contain` agar logo tidak ter-crop jika aspect ratio tidak square
- Plugin `flutter_svg` di pubspec.yaml TETAP di-keep (bisa dipakai di masa depan; tidak dipakai saat ini juga tidak masalah — tidak menambah runtime cost)

## TODO
- [ ] (Opsional) `flutter pub get` & `flutter analyze` untuk memastikan tidak ada error
- [ ] (Opsional) Verifikasi visual dengan `flutter run` di device/emulator

## Changelog
### 2026-09-28
- Initial: logo.webp sudah ada di assets/images/
- Modifikasi welcome_page.dart: ganti Container logo sintetik dengan Image.asset
- Modifikasi login_page.dart: ganti Logo Badge sintetik dengan Image.asset
- Hapus assets/images/logo.svg
