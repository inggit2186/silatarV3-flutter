@echo off
chcp 65001 >nul
echo ============================================
echo  SILATAR V2 - Build ARM64 APK
echo ============================================
echo.

REM Clean previous builds
echo [1/3] Cleaning...
flutter clean

REM Get dependencies
echo [2/3] Getting dependencies...
flutter pub get

REM Build ARM64 only - smallest APK size
echo [3/3] Building ARM64 release APK...
flutter build apk --release --target-platform android-arm64

if errorlevel 1 (
    echo.
    echo [ERROR] Build failed!
    pause
    exit /b 1
)

REM Copy to output folder
if not exist "output" mkdir "output"
copy /Y "build\app\outputs\flutter-apk\app-release.apk" "output\silatar_v2-arm64-latest.apk"

REM Show result
echo.
echo ============================================
echo  Build Complete!
echo ============================================
echo.
echo Output: output\silatar_v2-arm64-latest.apk
echo.
dir "output\silatar_v2-arm64-latest.apk" 2>nul || echo APK not found
echo.
pause
