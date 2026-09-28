# Auto-Update System - SILATAR V2

Sistem auto-update untuk distribusi APK di luar Play Store.

## Cara Kerja

1. App cek versi terbaru saat startup (via API)
2. Jika ada update, tampilkan dialog dengan changelog
3. User tap "Update Sekarang" → link download di-copy ke clipboard
4. User paste link di browser untuk download APK

## Setup

### 1. Backend (Laravel)

Tambahkan endpoint API di `routes/api.php`:

```php
Route::get('/app-version', function () {
    return response()->json([
        'version' => '1.0.0',
        'version_code' => 1,
        'download_url' => 'https://domain.com/apk/silatar-v1.0.0.apk',
        'changelog' => '- Perbaikan bug\n- Peningkatan performa',
        'is_mandatory' => false,
    ]);
});
```

### 2. Update Config

Update URL API di `lib/core/services/update_service.dart`:

```dart
static const String _baseUrl = 'https://kemenagtanahdatar.id/api';
```

### 3. Update Version

Setiap kali release APK baru:

1. Update versi di `lib/core/services/update_service.dart`:
```dart
static String getCurrentVersion() {
  return '1.0.1'; // Versi baru
}

static int getCurrentVersionCode() {
  return 2; // Version code baru (harus lebih besar dari sebelumnya)
}
```

2. Update data di backend:
```json
{
  "version": "1.0.1",
  "version_code": 2,
  "download_url": "https://domain.com/apk/silatar-v1.0.1.apk",
  "changelog": "- Fitur baru\n- Perbaikan bug",
  "is_mandatory": false
}
```

### 4. Changelog Format

Gunakan newline `\n` untuk pemisah:
```
- Perbaikan bug login
- Peningkatan kecepatan loading
- Tambah fitur baru
```

## File yang Dibuat

- `lib/core/services/update_service.dart` - Service untuk cek update
- `lib/core/widgets/update_dialog.dart` - Dialog update UI
- `assets/json/app_version.json` - Contoh data versi (opsional)

## Contoh Penggunaan

```dart
import 'core/services/update_service.dart';
import 'core/widgets/update_dialog.dart';

// Cek update saat app start
final result = await UpdateService.checkForUpdate();
if (result.hasUpdate && result.latestVersion != null) {
  showUpdateDialog(
    context: context,
    version: result.latestVersion!.version,
    downloadUrl: result.latestVersion!.downloadUrl,
    changelog: result.latestVersion!.changelog,
  );
}
```

## Notes

- User akan diarahkan ke website untuk download APK
- Link otomatis di-copy ke clipboard
- is_mandatory = true akan force user untuk update (tidak bisa dismiss)
