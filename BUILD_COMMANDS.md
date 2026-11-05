# SILATAR V2 - Build Commands Documentation

Dokumentasi untuk command-line scripts yang tersedia di workspace Flutter.

## Daftar Command

| Command | Fungsi |
|---------|--------|
| `build.bat` | Build APK release ARM64 dengan auto version increment |
| `build_arm64.bat` | Build APK ARM64 dengan opsi versi manual |
| `build_lean.bat` | Build APK multi-platform (arm64, arm32, debug) |
| `generate_patch.bat` | Generate patch untuk hot code push |

---

## 1. build.bat

**Purpose:** Build APK release ARM64 dengan sistem versioning otomatis.

### Penggunaan

```batch
build.bat [VERSION]
```

### Parameter

| Parameter | Required | Deskripsi |
|-----------|----------|-----------|
| `VERSION` | Yes | Version string (contoh: 2.0.2) |

### Contoh

```batch
build.bat 2.0.2
```

### Cara Kerja

```
┌─────────────────────────────────────────────────────────────┐
│ 1. UPDATE VERSI (via PowerShell)                           │
│    - Read app_version.dart (version, appVersionCode,     │
│      buildNumber)                                         │
│    - appVersionCode: increment jika versi sama, reset      │
│      ke 1 jika versi berbeda                              │
│    - buildNumber: selalu increment (global counter)       │
│    - Update pubspec.yaml                                  │
│    - Update lib/core/config/app_version.dart              │
├─────────────────────────────────────────────────────────────┤
│ 2. CLEAN BUILD                                            │
│    - Delete folder build/                                  │
├─────────────────────────────────────────────────────────────┤
│ 3. GET DEPENDENCIES                                        │
│    - flutter pub get                                        │
├─────────────────────────────────────────────────────────────┤
│ 4. CREATE DART TOOL ENVIRONMENT                           │
│    - flutter doctor                                        │
├─────────────────────────────────────────────────────────────┤
│ 5. BUILD APK                                               │
│    - flutter build apk --release                           │
│      --target-platform android-arm64                      │
│      --no-tree-shake-icons                                 │
├─────────────────────────────────────────────────────────────┤
│ 6. COPY KE OUTPUT                                          │
│    - Copy ke output/silatar_v2_v{VERSION}_build{N}.apk     │
└─────────────────────────────────────────────────────────────┘
```

### Versioning Logic

| Kondisi | appVersionCode | buildNumber |
|---------|----------------|-------------|
| Version sama, rebuild | +1 (increment) | +1 (increment) |
| Version berbeda | Reset ke 1 | +1 (increment) |

### Output

```
output/silatar_v2_v{VERSION}_build{APP_CODE}.apk
Contoh: output/silatar_v2_v2.0.0_build1.apk
```

---

## 2. build_arm64.bat

**Purpose:** Build APK ARM64 dengan opsi versi manual dan kontrol build number.

### Penggunaan

```batch
build_arm64.bat [VERSION] [BUILD_NUMBER]
```

### Parameter

| Parameter | Required | Deskripsi |
|-----------|----------|-----------|
| `VERSION` | No | Version string (contoh: 2.0.2) |
| `BUILD_NUMBER` | No | Build number integer |

### Contoh

```batch
build_arm64.bat 2.0.2 4
```

### Cara Kerja

```
┌─────────────────────────────────────────────────────────────┐
│ 1. UPDATE VERSI (jika disediakan)                          │
│    - Update pubspec.yaml dengan VERSION                     │
│    - Update app_version.dart dengan VERSION & BUILD_NUMBER  │
├─────────────────────────────────────────────────────────────┤
│ 2. SHOW CURRENT INFO                                       │
│    - Tampilkan version saat ini dari pubspec.yaml          │
│    - Tampilkan display version dari app_version.dart       │
├─────────────────────────────────────────────────────────────┤
│ 3. CLEAN BUILD                                            │
│    - Delete build/ dan .dart_tool/                         │
├─────────────────────────────────────────────────────────────┤
│ 4. GET DEPENDENCIES                                        │
│    - flutter pub get                                        │
├─────────────────────────────────────────────────────────────┤
│ 5. BUILD APK                                               │
│    - flutter build apk --release                           │
│      --target-platform android-arm64                       │
├─────────────────────────────────────────────────────────────┤
│ 6. COPY KE OUTPUT                                          │
│    - output/silatar_v2-arm64-{VERSION}-{BUILD}.apk        │
│    - output/silatar_v2-arm64-latest.apk (symlink)         │
└─────────────────────────────────────────────────────────────┘
```

### Output

```
output/silatar_v2-arm64-{VERSION}-{BUILD}.apk
output/silatar_v2-arm64-latest.apk
Contoh: output/silatar_v2-arm64-2.0.2_4.apk
```

---

## 3. build_lean.bat

**Purpose:** Build APK multi-platform dengan opsi fleksibel.

### Penggunaan

```batch
build_lean.bat [arch] [VERSION] [BUILD_NUMBER]
```

### Parameter

| Parameter | Required | Deskripsi |
|-----------|----------|-----------|
| `arch` | No | Architecture: arm64, arm, all, debug (default: all) |
| `VERSION` | No | Version string |
| `BUILD_NUMBER` | No | Build number integer |

### Contoh

```batch
build_lean.bat                 # Build all arch dengan versi saat ini
build_lean.bat arm64           # Build ARM64 saja
build_lean.bat all 2.0.2 4    # Build all, versi 2.0.2, build 4
build_lean.bat debug           # Build DEBUG APK
```

### Cara Kerja

```
┌─────────────────────────────────────────────────────────────┐
│ 1. UPDATE VERSI (jika disediakan)                          │
│    - Update pubspec.yaml & app_version.dart                │
├─────────────────────────────────────────────────────────────┤
│ 2. CLEAN BUILD                                            │
│    - flutter clean                                         │
├─────────────────────────────────────────────────────────────┤
│ 3. GET DEPENDENCIES                                        │
│    - flutter pub get                                        │
├─────────────────────────────────────────────────────────────┤
│ 4. BUILD APK (berdasarkan arch)                           │
│    arm64  → flutter build apk --release                    │
│              --target-platform android-arm64               │
│              --split-per-abi                              │
│    arm    → flutter build apk --release                    │
│              --target-platform android-arm                │
│              --split-per-abi                              │
│    all    → flutter build apk --release                    │
│              --split-per-abi                              │
│    debug  → flutter build apk --debug                      │
├─────────────────────────────────────────────────────────────┤
│ 5. COPY KE OUTPUT                                          │
│    - Sesuaikan dengan arsitektur yang dipilih               │
└─────────────────────────────────────────────────────────────┘
```

### Output

| Arch | Output Files |
|------|--------------|
| `arm64` | `silatar_v2-arm64-{VER}-{BUILD}.apk` |
| `arm` | `silatar_v2-arm32-{VER}-{BUILD}.apk` |
| `all` | `silatar_v2-arm64-{VER}-{BUILD}.apk`, `silatar_v2-arm32-{VER}-{BUILD}.apk`, `silatar_v2-recommended.apk` |
| `debug` | `silatar_v2-debug-{VER}-{BUILD}.apk` |

---

## 4. generate_patch.bat

**Purpose:** Generate patch untuk hot code push menggunakan flutter_patcher.

### Penggunaan

```batch
generate_patch.bat
```

### Persyaratan

1. APK release harus sudah di-build sebelumnya:
   ```
   build\app\outputs\flutter-apk\app-release.apk
   ```

### Contoh Interaktif

```
[INPUT] Enter patch number (press Enter for auto 2):
> _          ← Tekan Enter untuk auto number
```

### Cara Kerja

```
┌─────────────────────────────────────────────────────────────┐
│ 1. CHECK APK                                               │
│    - Pastikan build\app\outputs\flutter-apk\app-release   │
│      .apk exists                                          │
├─────────────────────────────────────────────────────────────┤
│ 2. READ APK INFO                                           │
│    - Ambil version dari app_version.dart                   │
│    - Ambil appVersionCode untuk patch matching              │
├─────────────────────────────────────────────────────────────┤
│ 3. PATCH COUNT MANAGEMENT                                  │
│    - Read patch_counts.txt                                  │
│    - Auto-increment patch number per appVersionCode        │
│    - User bisa override dengan input manual                │
│    - Update patch_counts.txt                               │
├─────────────────────────────────────────────────────────────┤
│ 4. GENERATE PATCH                                          │
│    - dart run flutter_patcher:pack                         │
│      --apk build\app\...\app-release.apk                  │
│      --version {VERSION}.{PATCH_NUM}                      │
│      --target-version-code {APP_CODE}                     │
├─────────────────────────────────────────────────────────────┤
│ 5. COPY KE OUTPUT                                          │
│    - dist\patch.zip → output\silatar_v2_patch_{VERSION}.zip│
│    - Generate MD5 hash                                     │
└─────────────────────────────────────────────────────────────┘
```

### patch_counts.txt Format

```
{appVersionCode},{patchCount}
Contoh:
1,3
2,1
```

### Output

```
output/silatar_v2_patch_{VERSION}.{PATCH_NUM}.zip
Contoh: output/silatar_v2_patch_2.0.0.1.zip

Output tambahan:
- MD5 hash untuk verifikasi
- manifest.json dengan metadata patch
```

### Informasi untuk Backend

Setelah patch generate, script menampilkan:

```
[BACKEND] Fill form with:
  - Versi: 2.0.0
  - Version Code: 1
  - Patch Count: 1
  - Update Type: patch
```

---

## App Version Configuration

File: `lib/core/config/app_version.dart`

```dart
class AppVersion {
  /// Display version (shown in app)
  static const String version = '2.0.0';

  /// App version code (integer for PATCH matching)
  /// RESET per version (e.g., 2.0.0 → 2.0.1 resets to 1)
  static const int appVersionCode = 1;

  /// Build number (GLOBAL counter, never resets)
  static const int buildNumber = 1;
}
```

### Konsep Versioning

| Field | Purpose | Reset Policy |
|-------|---------|-------------|
| `version` | Display di app & APK filename | Manual |
| `appVersionCode` | Patch matching dengan base APK | Reset saat versi berubah |
| `buildNumber` | APK update detection (backend) | Never reset |

---

## Hot Code Push Workflow

```
┌──────────┐     ┌──────────┐     ┌──────────┐
│ Build    │     │ Generate │     │ Upload   │
│ Base APK │────▶│  Patch   │────▶│ to Server│
└──────────┘     └──────────┘     └──────────┘
                                    │
                                    ▼
┌──────────┐     ┌──────────┐     ┌──────────┐
│  User    │◀────│  Check   │◀────│  API     │
│  App     │     │  Update  │     │ Response │
└──────────┘     └──────────┘     └──────────┘
```

1. **Build Base APK** → `build.bat 2.0.0`
2. **Distribute APK** ke users
3. **Develop & Test** fitur baru
4. **Generate Patch** → `generate_patch.bat`
5. **Upload** patch.zip ke server
6. **App auto-check** update via API
7. **Download & Apply** patch
8. **Restart** untuk lihat perubahan

---

## Troubleshooting

### build.bat gagal
```
[ERROR] Failed to get dependencies!
```
Solusi: Jalankan `flutter pub get` manual, cek koneksi internet.

### APK not found after build
```
[ERROR] APK not found!
```
Solusi: Build gagal, cek error message sebelumnya.

### generate_patch.bat - APK not found
```
[ERROR] APK not found: build\app\outputs\flutter-apk\app-release.apk
```
Solusi: Jalankan `build.bat` terlebih dahulu.

### Patch tidak terapply di app
1. Cek MD5 checksum
2. Pastikan targetVersionCode sesuai dengan APK terinstall
3. Cek logs: `adb logcat | grep FlutterPatcher`

---

## File Structure

```
silatar_v2/
├── build.bat              # Main build script
├── build_arm64.bat       # ARM64 build script
├── build_lean.bat        # Multi-platform build script
├── generate_patch.bat    # Patch generator
│
├── lib/
│   └── core/
│       └── config/
│           └── app_version.dart  # Version configuration
│
├── output/                # Build outputs
│   ├── silatar_v2_v2.0.0_build1.apk
│   ├── silatar_v2-arm64-latest.apk
│   └── silatar_v2_patch_2.0.0.1.zip
│
├── patch_counts.txt       # Patch counter storage
└── dist/                  # Temporary patch output
    ├── manifest.json
    └── patch.zip
```

---

## Quick Reference

```batch
# Build APK baru
build.bat 2.0.1

# Build ARM64 saja
build_lean.bat arm64 2.0.1 5

# Generate patch setelah perubahan kode
generate_patch.bat

# Lihat output terbaru
dir output
```

---

*Generated: 2026-10-07*
