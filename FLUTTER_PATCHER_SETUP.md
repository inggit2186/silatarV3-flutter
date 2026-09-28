# Hot Code Push dengan flutter_patcher

Sistem update kode Dart tanpa perlu reinstall APK untuk Android.

## Arsitektur

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│   Base APK  │────▶│   Patch     │────▶│   Updated   │
│   (v1.0.0) │     │   Server   │     │   App       │
└─────────────┘     └─────────────┘     └─────────────┘
      │                  │                   │
      │                  │                   │
      │     ┌───────────┘                   │
      │     │                               │
      ▼     ▼                               ▼
┌─────────────┐                     ┌─────────────┐
│   Rollback  │◀────────────────────│   Success   │
│   (if crash)│                     │   Restart   │
└─────────────┘                     └─────────────┘
```

## Requirements

- Android only
- minSdk: 24
- compileSdk: 36
- NDK: 27.0.12077973+
- Dart SDK: >=3.0.0

## Setup

### 1. Install Package

```yaml
# pubspec.yaml
dependencies:
  flutter_patcher: ^0.1.4
```

### 2. Update Android Configuration

```kotlin
// android/app/build.gradle.kts
android {
    compileSdk = 36
    ndkVersion = "27.0.12077973"

    defaultConfig {
        minSdk = 24
    }
}
```

### 3. Initialize di main.dart

```dart
import 'package:flutter_patcher/flutter_patcher.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize flutter_patcher
  await FlutterPatcher.init();

  runApp(const MyApp());
}
```

## Workflow Update

### 1. Build Release APK

```bash
flutter build apk --release
```

### 2. Generate Patch

```bash
# Generate patch dari perubahan kode
dart run flutter_patcher:pack \
  --apk build/app/outputs/flutter-apk/app-release.apk \
  --version 1.0.1 \
  --target-version-code 1

# Untuk include assets:
dart run flutter_patcher:pack \
  --apk build/app/outputs/flutter-apk/app-release.apk \
  --version 1.0.1 \
  --target-version-code 1 \
  --assets assets/images/new_image.png,assets/data/config.json
```

Output: `dist/patch.zip` dan `dist/manifest.json`

### 3. Upload ke Server

```bash
# Upload patch.zip ke CDN/server
scp dist/patch.zip user@server:/var/www/patches/
```

### 4. API Endpoint untuk Patch Info

```json
// GET /api/app-version
{
  "version": "1.0.1",
  "version_code": 2,
  "md5": "abc123...",
  "download_url": "https://domain.com/patches/1.0.1/patch.zip",
  "changelog": "- Perbaikan bug\n- Fitur baru"
}
```

### 5. App Apply Patch

```dart
import 'package:http/http.dart' as http;

Future<void> checkAndApplyPatch() async {
  // Cek versi terbaru
  final response = await http.get(Uri.parse('/api/app-version'));
  final data = jsonDecode(response.body);

  // Apply patch
  final result = await FlutterPatcher.applyPatch(
    PatchInfo(
      version: data['version'],
      patchUrl: data['download_url'],
      md5: data['md5'],
      targetVersionCode: int.parse(data['version_code']) - 1,
    ),
  );

  if (result.ok) {
    // Restart app untuk lihat perubahan
  }
}
```

### 6. Rollback (Jika Error)

```dart
await FlutterPatcher.rollback();
// App revert ke versi base APK
```

## API Backend Example (Laravel)

```php
// routes/api.php
Route::get('/app-version', function () {
    $currentVersion = config('app.version_code', 1);
    $latestVersion = $currentVersion + 1;

    return response()->json([
        'version' => '1.0.' . $latestVersion,
        'version_code' => $latestVersion,
        'md5' => 'xxx', // MD5 dari patch.zip
        'download_url' => url('/patches/v' . $latestVersion . '/patch.zip'),
        'changelog' => "- Perbaikan bug\n- Fitur baru",
    ]);
});
```

## CLI Commands

```bash
# Generate patch
dart run flutter_patcher:pack [options]

# Options:
#   --apk <path>           Path ke APK release
#   --version <string>     Version patch
#   --target-version-code   Version code APK lama
#   --assets <paths>       Asset files yang di-patch (comma separated)
#   --output <dir>        Output directory (default: dist/)
```

## File Structure

```
dist/
├── manifest.json    # Patch metadata
└── patch.zip      # Patch file (Dart + assets)
```

## Troubleshooting

### Patch tidak terapply?
1. Cek MD5 checksum
2. Pastikan targetVersionCode sesuai dengan APK yang terinstall
3. Cek logs: `adb logcat | grep FlutterPatcher`

### Crash saat boot setelah patch?
- flutter_patcher auto-rollback
- App revert ke versi base APK
- Blacklist patch yang error

### Kapan perlu rebuild APK vs patch saja?
- **Rebuild APK**: Perubahan engine, native code, plugin baru
- **Patch cukup**: Perubahan Dart code, assets, logic

## Security

- MD5 checksum verification
- Ed25519 signature (Android 13+) - opsional
- Rollback otomatis jika boot failure
- Bad patch blacklist

## Limitations

- Android only
- Tidak bisa update native code/plugin
- minSdk 24 (Android 7.0)
- Tidak support iOS

## Resources

- GitHub: https://github.com/xuelinger2333/flutter_patcher
- Pub.dev: https://pub.dev/packages/flutter_patcher
