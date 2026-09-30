# Progress: Flutter Patcher Hybrid Versioning Fix

## Overview
Fix bug where after APK update, the app still uses the old patch (flutter_patcher directory not cleared on APK upgrade).

## Status: DALAM PROGRES

## Problem
When APK is upgraded, flutter_patcher still has old patch files in internal storage that get loaded, causing the app to appear as the old version.

## Proposed Solution: Hybrid Versioning Approach

### Versioning Format
```
major.version.patchCount
Contoh:
- APK 2.0.0 (appVersionCode=0, patchCount=0) → "2.0.0.0"
- APK 2.0.0 + 2 patches (patchCount=2) → "2.0.0.2"
- APK 2.0.1 (appVersionCode=1, patchCount=0) → "2.0.1.0"
```

### Variables

| Variable | Type | Location | Set By | Purpose |
|----------|------|----------|--------|---------|
| `appVersionCode` | int | `app_version.dart` | `build.bat` | Source of truth for APK base version |
| `version` | string | `app_version.dart` | `build.bat` | Display version |
| `patchCount` | int | SharedPreferences | Code + scripts | Patch counter |

### SharedPreferences Keys
```
- patch_count: int (current patch count)
- app_version_code_at_patch: int (appVersionCode saat patch di-apply)
- patch_pending: bool (patch waiting to be promoted after restart)
```

## Files Modified

### 1. app_version.dart
```dart
class AppVersion {
  static const String version = '2.0.0';
  static const int appVersionCode = 0;
  static const int buildNumber = 0;
}
```

### 2. patch_service.dart
- Simplified to use patchCount instead of multiple versionCode tracking
- `getFullVersion()` returns "2.0.0.0" format
- `_checkApkUpgrade()` compares stored `appVersionCode` vs current
- `getCurrentVersionInfo()` untuk UI display

### 3. build.bat
```batch
build.bat 2.0.1 1
```
Sets:
- `version = '2.0.1'`
- `appVersionCode = 1`
- `buildNumber = 1`

### 4. generate_patch.bat
Reads `appVersionCode` from app_version.dart automatically, asks for patch number, outputs correct version string.

## TODO List

### Critical (Must Fix)
- [x] Fix main.dart line 229-234 (replaced `getNativeVersionCode()` and `effectiveInstalledVc`)
- [x] Verify `patch_service.dart` is correct
- [x] Add `getCurrentVersionInfo()` method to PatchService
- [x] Fix `getFullVersion()` - was generating "2.2.0.0.1" instead of "2.0.0.1"
- [x] Fix `UpdateService.checkForUpdate()` - was not sending `patch_count` to backend
- [x] Fix update dialog - only show update version, not current version
- [x] Fix APK download URL - backend was returning local path instead of download endpoint
- [x] Fix build.bat - appVersionCode was being reset when version changed!
- [ ] Test flow: install APK → patch → APK upgrade → verify version is correct

### In Progress
- [x] Create app_version.dart with hybrid approach
- [x] Update patch_service.dart with patchCount tracking
- [x] Update build.bat to set appVersionCode
- [x] Update generate_patch.bat to read appVersionCode and increment patchCount
- [x] Update main.dart with new version logic
- [x] Update welcome page with new version display
- [x] Update update_dialog with new version display
- [x] Update update_service.dart with new version fields
- [x] Update dashboard_page.dart with new version display
- [x] Update dashboard_content.dart with new version display
- [x] Update profile_content.dart with new version display

### Completed
- [x] Create app_version.dart with hybrid approach
- [x] Update patch_service.dart with patchCount tracking
- [x] Update build.bat to set appVersionCode
- [x] Update generate_patch.bat to read appVersionCode and increment patchCount
- [x] Fix main.dart with new version logic
- [x] Update all UI components with new version display
- [x] Add getCurrentVersionInfo() method to PatchService

## APK Upgrade Detection Logic

```
SAAT STARTUP:
1. Load patch_count dari SharedPreferences
2. Load appVersionCode dari SharedPreferences (saat patch di-apply)
3. Bandingkan dengan AppVersion.appVersionCode (dari app_version.dart)
4. Jika berbeda:
   - Rollback flutter_patcher
   - Clear patch state
   - patch_count = 0
5. Jika sama:
   - Patch state valid, lanjut normal
```

## API Changes

### Backend Endpoint: GET /api/patch/check

**Request:**
```
GET /api/patch/check?version=2.0.0.2&patch_count=2&app_version_code=1
```

**Response (Patch Available):**
```json
{
  "hasUpdate": true,
  "needUpdate": true,
  "updateType": "patch",
  "latestVersion": "2.0.0.3",
  "version_code": 1,
  "patch_count": 3,
  "downloadUrl": "...",
  "md5": "...",
  "isPatch": true,
  "isApk": false
}
```

**Response (APK Available):**
```json
{
  "hasUpdate": true,
  "needUpdate": true,
  "updateType": "apk",
  "latestVersion": "2.0.1",
  "version_code": 2,
  "patch_count": 0,
  "downloadUrl": "...",
  "md5": "...",
  "isPatch": false,
  "isApk": true
}
```

### Database Schema (app_patches table)

| Field | Type | Description |
|-------|------|-------------|
| `version` | VARCHAR(20) | Display version (e.g., "2.0.0") |
| `version_code` | INT | appVersionCode - identifier per APK |
| `patch_count` | INT | Counter patch (0 for APK, >0 for patch) |
| `build_number` | INT | Global build counter (for APK only) |
| `update_type` | ENUM | 'patch' or 'apk' |

## Test Scenarios

### Scenario 1: Fresh Install
1. Build APK 2.0.0 with build.bat → appVersionCode auto-incremented to 1, version="2.0.0"
2. Install APK → patchCount=0
3. Expected: "v2.0.0.0"

### Scenario 2: Apply Patch
1. Generate patch 1 → patchCount=1
2. Apply patch → restart
3. Expected: "v2.0.0.1"

### Scenario 3: Apply Multiple Patches
1. Apply patch 2 → patchCount=2
2. Expected: "v2.0.0.2"

### Scenario 4: APK Upgrade (Auto-increment)
1. Build new APK 2.0.1 with build.bat → appVersionCode auto-incremented to 2, version="2.0.1"
2. Install new APK (patch_count may persist from SharedPreferences)
3. On startup: appVersionCode stored=1 vs current=2 → DIFFERENT
4. Expected: Clear patch state, patchCount=0, "v2.0.1.0"

### Scenario 5: Patch After APK Upgrade
1. From Scenario 4, apply patch 1 → patchCount=1
2. Expected: "v2.0.1.1"

## Build Commands

### Build Full APK
```batch
build.bat 2.0.0      ← appVersionCode reset/1, buildNumber increment
build.bat 2.0.0      ← appVersionCode increment, buildNumber increment
build.bat 2.0.1      ← appVersionCode reset ke 1, buildNumber increment
```

### Versioning Logic
| Field | Reset? | Purpose |
|-------|--------|---------|
| `appVersionCode` | Reset per versi | User-facing build number |
| `buildNumber` | Selalu increment | Global total builds counter |

## Changelog

### 2026-09-30 (Build Number Fix)
- **CORRECT LOGIC**: User clarifies that appVersionCode SHOULD reset per version
- **Real solution**: Use `buildNumber` for APK update detection (never resets)
- **Patch updates**: Use `version` + `appVersionCode` + `patch_count`
- **APK updates**: Use `build_number`

Changes:
1. Migration: Added `build_number` column to `app_patches`
2. AppPatch model: Added `build_number` field, new method `getAvailableApkUpdateByBuildNumber()`
3. AppPatchController: Updated to check by `build_number` for APK, by `version_code`+`patch_count` for patches
4. Flutter PatchService: Added `buildNumber` getter
5. Flutter UpdateService: Now sends `build_number` to backend

### 2026-09-30 (Build Number - CORRECT LOGIC)
- **REVERTED**: appVersionCode memang di-reset per versi (benar!)
- **SOLUSI**: APK update detection gunakan `build_number` (tidak pernah reset)
- **Patch Detection**: `version_code` + `patch_count` (appVersionCode per versi)

**Logic yang benar:**
```
APK 2.0.0 build1 → appVersionCode=1, buildNumber=1
APK 2.0.0 build2 → appVersionCode=2, buildNumber=2
APK 2.0.1 build1 → appVersionCode=1, buildNumber=3  ← appVersionCode reset

Backend:
- APK check: build_number > user's build_number
- Patch check: version_code == user's version_code AND patch_count > user's patch_count
```

### 2026-09-30 (Bug Fix - Update Dialog & APK Download)
- **Update Dialog**: Simplified to show only update version, not current version
- **APK Download Fix**: Backend `AppPatchController` was setting `apk_url` to local file path
  - Now only sets `apk_url` if it's an external URL (starts with http)
  - `AppPatch.getDownloadUrl()` now checks if URL starts with 'http'

### 2026-09-30 (Bug Fix - Update Request Loop)
- **Root Cause Found**: `UpdateService.checkForUpdate()` tidak mengirim `patch_count` ke backend
- Backend menggunakan default `patch_count=0` saat tidak ada di request
- Backend mencari `patch_count > 0`, jadi selalu menawarkan patch_count=1

**Fixes Applied:**

1. **patch_service.dart:129-131** - Fixed `getFullVersion()`
   - Before: `'2.${AppVersion.version}.$_patchCount'` → "2.2.0.0.1"
   - After: `'${AppVersion.version}.$_patchCount'` → "2.0.0.1"

2. **update_service.dart:46-72** - Added `patch_count` to API request
   - Now sends: `version`, `patch_count`, `app_version_code`
   - Backend will properly filter based on current patch count

### 2026-09-30 (Update 6)
- **Backend Updated** - Laravel backend support hybrid versioning:
  - Migration: Added `patch_count` and `build_number` fields
  - AppPatch model: Updated with new fields and methods
  - AppPatchController: New versioning logic
  - AdminPatchController: Updated for new fields
  - Admin views: Updated create form

### 2026-09-30 (Update 6)
- **generate_patch.bat** - Improved output with clear instructions for backend form
- Show current patch count before incrementing
- Show what to fill in backend form

### 2026-09-30 (Update 5)
- **build.bat** - Updated versioning logic:
  - `appVersionCode`: Reset ke 1 jika beda versi, else increment
  - `buildNumber`: Selalu increment (global counter)
- Output filename tetap gunakan appVersionCode

### 2026-09-30 (Update 4)
- **build.bat** - Output filename dengan versi: `silatar_v2_v2.0.0_build1.apk`

### 2026-09-30 (Update 3)
- Usage berubah dari `build.bat VERSION CODE` → `build.bat VERSION`
- Tidak perlu lagi manual tracking APP_VERSION_CODE
- generate_patch.bat - Updated comments

### 2026-09-30 (Update 2)
- Proposed hybrid versioning approach
- Files created/modified:
  - app_version.dart (new structure)
  - patch_service.dart (simplified with patchCount)
  - build.bat (appVersionCode support)
  - generate_patch.bat (auto-read appVersionCode)

### 2026-09-30 (Update 2)
- Fixed main.dart - replaced non-existent `getNativeVersionCode()` with direct `AppVersion.appVersionCode`
- Added `getCurrentVersionInfo()` method to PatchService
- Updated all UI components to use new version format:
  - welcome_page.dart
  - update_dialog.dart
  - update_service.dart
  - dashboard_page.dart
  - dashboard_content.dart
  - profile_content.dart
- Replaced all `AppVersion.baseVersionCode` with `AppVersion.appVersionCode`
- Replaced all `AppVersion.display` with `AppVersion.version`

## Notes for Next Developer

1. **Version fields in AppVersion**:
   - `version` = display string (e.g., "2.0.0")
   - `appVersionCode` = integer for DB/logic comparison
   - `buildNumber` = same as appVersionCode

2. **Backend API** needs to be updated to accept `patch_count` parameter.

3. **Database** needs to store `appVersionCode` for each patch/APK record.

4. **Test on real device** - Emulator may have different behavior for SharedPreferences persistence.

5. **flutter_patcher directory** is at `/data/data/<package>/files/flutter_patcher/`. Clear this manually for testing with: `adb shell rm -rf /data/data/com.example.silatar_v2/files/flutter_patcher/*`

## Files Changed Summary

### Flutter App (c:\silatar_v2)
| File | Changes |
|------|---------|
| `build.bat` | appVersionCode ALWAYS increment (never reset), buildNumber always increment |
| `generate_patch.bat` | Auto-increment patch count per appVersionCode |
| `lib/core/config/app_version.dart` | Hybrid versioning fields, updated comments |
| `lib/core/services/patch_service.dart` | Added getCurrentVersionInfo(), currentVersionCode, currentVersion, fixed getFullVersion() |
| `lib/core/services/update_service.dart` | Updated to send patch_count to backend |
| `lib/core/widgets/update_dialog.dart` | Simplified to show only update version |
| `lib/core/services/apk_update_service.dart` | APK download service |
| `lib/main.dart` | Replaced getNativeVersionCode() |
| `lib/features/welcome/welcome_page.dart` | Version display without build number |
| `lib/features/dashboard/dashboard_page.dart` | Version display with build number |
| `lib/features/dashboard/dashboard_content.dart` | Version display with build number |
| `lib/features/profile/profile_content.dart` | Version display with build number |
| `lib/features/profile/profile_page.dart` | Version display with build number |

### Laravel Backend (d:\work\SourceCode\silatarV2)
| File | Changes |
|------|---------|
| `database/migrations/..._add_hybrid_versioning_fields...` | Added patch_count, build_number |
| `app/Models/AppPatch.php` | New fields & helper methods, fixed getDownloadUrl() |
| `app/Http/Controllers/Api/AppPatchController.php` | New versioning logic, fixed apk_url storage |
| `app/Http/Controllers/Api/AppVersionController.php` | Updated response |
| `app/Http/Controllers/Admin/AdminPatchController.php` | Updated for new fields |
| `resources/views/admin/patches/create.blade.php` | Added patch_count field |
