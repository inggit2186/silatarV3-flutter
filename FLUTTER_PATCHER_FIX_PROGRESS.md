# Progress Fix Flutter Patcher Version Code

## Overview
Bug pada sistem flutter_patcher di mana setelah patch berhasil di-apply dan app di-restart, user diminta update lagi. Jika klik Update, muncul error: `targetVersionCode=2 does not match current=1`.

## Status: SELESAI

## Root Cause Analysis

flutter_patcher melakukan validasi `targetVersionCode` terhadap **APK native versionCode** (yang tidak bisa di-patch). Lihat [PatchManager.kt:105-110](c:/Users/Admin/AppData/Local/Pub/Cache/hosted/pub.dev/flutter_patcher-0.1.4/android/src/main/kotlin/com/flutter_patcher/flutter_patcher/PatchManager.kt#L105-L110):

```kotlin
if (targetVersionCode != currentVersionCode) {
    return ApplyResult.failure("targetVersionCode=$targetVersionCode does not match current=$currentVersionCode")
}
```

`currentVersionCode` di sini selalu = APK native versionCode (dari `PackageManager`), bukan versi setelah patch.

### Timeline bug:
1. App install v2.0.0+1 → native versionCode = 1
2. Patch uploaded dengan version_code = 2 (target version)
3. App apply patch → flutter_patcher.validate targetVersionCode=1 vs native=1 ✅ OK
4. SharedPreferences langsung disimpan dengan version_code=2 ([patch_service.dart:107](c:/silatar_v2/lib/core/services/patch_service.dart#L107))
5. App restart, flutter_patcher load patch. Native versionCode masih = 1
6. Welcome page tampil "V2.0.0-1" karena baca static `AppVersion.full`
7. App close & buka lagi
8. UpdateService.checkForUpdate panggil API dengan version_code=1 (dari static base) → backend kasih patch lagi
9. User klik Update → `_loadVersionCode()` baca SharedPreferences = 2 → `applyPatch(targetVersionCode: 2)` → flutter_patcher validate target=2 vs native=1 ❌ FAIL

## Bugs Identified

### Bug 1: targetVersionCode salah value
**File**: [patch_service.dart:97](c:/silatar_v2/lib/core/services/patch_service.dart#L97)
**Current**: `targetVersionCode: _appliedVersionCode` (post-patch value)
**Should be**: `targetVersionCode: _baseVersionCode` (native APK version)

### Bug 2: Save applied_version_code terlalu cepat
**File**: [patch_service.dart:107](c:/silatar_v2/lib/core/services/patch_service.dart#L107)
Patch disimpan sebagai "applied" padahal belum di-load oleh flutter_patcher sampai restart.

**Fix**: Pakai 2 state:
- `pending_version_code` — di-set setelah apply success, aktif setelah restart
- `applied_version_code` — di-promote dari pending setelah restart + flutter_patcher konfirmasi patch loaded

### Bug 3: UpdateService kirim base version code, bukan applied
**File**: [update_service.dart:34](c:/silatar_v2/lib/core/services/update_service.dart#L34)
**Current**: `static int get currentVersionCode => AppVersion.baseVersionCode` (always 1)
**Fix**: Bikin async `getCurrentVersionCode()` yang baca SharedPreferences applied_version_code (yang sudah benar)

### Bug 4: Welcome page tampil versi static
**File**: [welcome_page.dart:177](c:/silatar_v2/lib/features/welcome/welcome_page.dart#L177)
**Current**: Tampilkan `AppVersion.full` (hardcoded "2.0.0-1")
**Fix**: Tampilkan patched version jika ada

### Bug 5: applied_version_code tidak reset saat Full APK install
**File**: [patch_service.dart:61](c:/silatar_v2/lib/core/services/patch_service.dart#L61)
**Root cause**: SharedPreferences TIDAK di-clear saat Full APK install (Android behavior). Jika APK lama punya `applied_version_code=1`, APK baru dengan `baseVersionCode=3` tetap punya `applied_version_code=1` di SharedPreferences.

**Fix**: Di `_loadVersionCode()`, jika `_appliedVersionCode < _baseVersionCode`, reset ke `_baseVersionCode`.

### Bug 6: pendingMandatoryApk tidak di-clear setelah Full APK install
**File**: [main.dart:142](c:/silatar_v2/lib/main.dart#L142)
**Root cause**: Comparison `pendingVersionCode <= AppVersion.baseVersionCode` pakai `AppVersion.baseVersionCode` (hardcoded di Dart). Setelah Full APK install, comparison gagal karena AppVersion.baseVersionCode bisa stale → dialog muncul lagi.

**Fix**: Gunakan `FlutterPatcher.appVersionCode` (native dari PackageManager) untuk deteksi APK yang terinstall. Fallback ke `AppVersion.baseVersionCode` jika `FlutterPatcher.appVersionCode` return null.

### Bug 7: Dialog muncul dengan data kosong saat APK update di-disable di backend
**File**: [main.dart:188](c:/silatar_v2/lib/main.dart#L188)
**Root cause**: Jika backend disable APK update, `_pendingMandatoryApk=true` tapi API return null. Fallback `UpdateInfo` dibuat dengan `downloadUrl=''` → "Ukuran: Unknown" → download gagal.

**Fix**: Jika API return null saat `_pendingMandatoryApk=true`, cek `FlutterPatcher.appVersionCode`. Jika APK sudah terinstall (installed >= pending), clearkan pending dan skip dialog.

## Checklist
- [x] Diagnose root cause
- [x] Identify all bugs (7 bugs total)
- [x] Fix patch_service.dart (Bug 1, 2, 5)
- [x] Fix update_service.dart (Bug 3)
- [x] Fix welcome_page.dart (Bug 4)
- [x] Fix 3 other version displays (dashboard_page, dashboard_content, profile_content)
- [x] Fix main.dart pendingMandatoryApk (Bug 6, 7)
- [x] flutter analyze: no errors (hanya info-level lints pre-existing)

## Files yang Dimodifikasi
| File | Perubahan |
|------|-----------|
| lib/core/services/patch_service.dart | (1) targetVersionCode pakai _baseVersionCode — Fix Bug 1. (2) Tambah _pendingVersionCode state — Fix Bug 2. (3) Reset applied_version_code jika < baseVersionCode — Fix Bug 5. (4) Helper getCurrentVersionInfo() untuk UI. |
| lib/core/services/update_service.dart | currentVersionCode (sync) → baseVersionCode. checkForUpdate() pakai async getCurrentVersionCode() — Fix Bug 3. |
| lib/features/welcome/welcome_page.dart | "Versi Aplikasi : v{version} (build {code})" dengan FutureBuilder. |
| lib/features/profile/profile_content.dart | Sama. |
| lib/features/dashboard/dashboard_content.dart | Sama. |
| lib/features/dashboard/dashboard_page.dart | Sama. |
| lib/main.dart | FlutterPatcher.appVersionCode untuk deteksi APK install (Bug 6). Skip dialog saat API null dan APK disabled (Bug 7). |

## Files Baru
| File | Purpose |
|------|---------|
| FLUTTER_PATCHER_FIX_PROGRESS.md | File progress untuk dokumentasi bugfix ini. |

## Test Scenario (untuk verifikasi manual)

### Skenario 1: Patch Update
1. Install APK 2.0.0+1 (native versionCode=1)
2. Generate patch 2.0.0+1 → upload ke backend dengan version_code=2
3. Buka app → prompt update muncul
4. Klik Update → patch apply success → restart
5. **Expected**:
   - Welcome page tampil "v{patchVersion} (build 2)"
   - Close app & buka lagi → TIDAK ada prompt update (backend terima version_code=2)

### Skenario 2: Full APK Update
1. Install APK v2.0.0+1 (native versionCode=1)
2. Full APK update (build.bat 2.0.1 3) → upload ke backend dengan version_code=3
3. Buka app → prompt update APK
4. Klik Update → download selesai → Install Update → install APK → restart
5. **Expected**:
   - Welcome page tampil "v2.0.1 (build 3)"
   - Close app & buka lagi → TIDAK ada prompt APK lagi (pending cleared via FlutterPatcher.appVersionCode)

### Skenario 3: APK Update Disabled di Backend
1. APK v2.0.0+1 (pendingMandatoryApk=true di SharedPreferences)
2. Backend disable APK update (hapus record di database)
3. Buka app
4. **Expected**: TIDAK ada dialog muncul (API null → cek installed ≥ pending → clear pending → skip dialog)

### Skenario 4: Patch setelah Full APK
1. APK v2.0.1 (build 3) terinstall
2. Patch 2.0.1 → upload dengan version_code=4
3. Buka app → prompt update patch
4. Klik Update → apply success → restart
5. **Expected**: "v{patchVersion} (build 4)" — TIDAK ada error "targetVersionCode mismatch"

## TODO
- [ ] Test semua skenario di device Android

## Changelog
### 2026-09-29
- Diagnosis dan identifikasi 4 bug terkait flutter_patcher
- Fix patch_service.dart: targetVersionCode + pending/applied state
- Fix update_service.dart: async version code getter
- Fix 4 file display versi: welcome_page, profile_content, dashboard_content, dashboard_page
- Tambah build number/version_code di display versi untuk tracking aplikasi terbaru
- flutter analyze: tidak ada error baru

### 2026-09-30
- Fix Bug 5: reset applied_version_code jika < baseVersionCode (SharedPreferences tidak di-clear saat Full APK install) — patch_service.dart `_loadVersionCode()`
- Fix Bug 6: pendingMandatoryApk pakai `FlutterPatcher.appVersionCode` dengan fallback ke `AppVersion.baseVersionCode` jika null — main.dart `_initializeAndNavigate()`
- Fix Bug 7: skip dialog saat API null dan APK disabled / sudah terinstall — main.dart `_showUpdateDialog()`
- Debug log tambahan untuk tracking version codes
