@echo off
chcp 65001 >nul
echo ============================================
echo  Build ARM64 APK (Recommended - Smallest)
echo ============================================
echo.

REM Clean
flutter clean
flutter pub get

REM Build ARM64 only - smallest APK size
flutter build apk --release --target-platform android-arm64

REM Copy to output
if not exist "output" mkdir "output"
copy /Y "build\app\outputs\flutter-apk\app-release.apk" "output\silatar_v2-arm64-latest.apk"

echo.
echo Done! Output: output\silatar_v2-arm64-latest.apk
dir "output\silatar_v2-arm64-latest.apk"
echo.
pause
