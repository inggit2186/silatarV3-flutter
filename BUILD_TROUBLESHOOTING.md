# Build Notes — silatar_v2 (Flutter)

## Kotlin incremental cache failure (cross-drive)
**Symptom:** `flutter run/build` fails with:
```
Could not close incremental caches in D:\silatar_v2\build\<plugin>\kotlin\compileDebugKotlin\cacheable\caches-jvm\...
java.lang.IllegalArgumentException: this and base files have different roots:
  C:\Users\Admin\AppData\Local\Pub\Cache\hosted\pub.dev\<plugin>\... and D:\silatar_v2\android.
```
**Cause:** Flutter project on `D:`, pub cache on `C:`. Kotlin's `RelocatableFileToPathConverter` cannot compute a relative path across drive letters.

**Fix applied (in `android/gradle.properties`):**
```properties
kotlin.incremental=false
kotlin.incremental.java=false
kotlin.incremental.js=false
kotlin.compiler.execution.strategy=in-process
```

**Recovery sequence that worked:**
1. `flutter clean`
2. `Remove-Item -Recurse -Force .\android\.gradle`
3. `flutter pub get`
4. `flutter build apk --debug` → OK (~337s)

**If it recurs:** `flutter pub cache repair`, clear `%USERPROFILE%\.gradle\caches`, kill java processes, or move project to same drive as pub cache.

## Analyze
`flutter analyze` exits 1 on `info` lints. Use `--no-fatal-infos`. Known pre-existing warnings in `lib/features/presensi/presensi_content.dart` (`_presensiLabel` unused, `isTerlambat` unused).

## Build warning (benign)
`flutter_patcher` applies KGP directly — warning only, build succeeds.
