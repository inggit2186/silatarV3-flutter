@echo off
chcp 65001 >nul
echo ============================================
echo  SILATAR V2 - Build APK Optimized
echo ============================================
echo.

REM Usage: build_lean.bat [arm64|arm|all|debug]
set VERSION=%1
if "%VERSION%"=="" set VERSION=all

echo Build Type: %VERSION%
echo.

REM Clean previous builds
echo [1/4] Cleaning previous builds...
flutter clean

REM Get dependencies
echo [2/4] Getting dependencies...
flutter pub get

REM Build release APK with optimizations
echo [3/4] Building release APK...

if "%VERSION%"=="arm64" (
    echo Building for ARM64 only (smallest)...
    flutter build apk --release --target-platform android-arm64 --split-per-abi
) else if "%VERSION%"=="arm" (
    echo Building for ARMv7 only...
    flutter build apk --release --target-platform android-arm --split-per-abi
) else if "%VERSION%"=="debug" (
    echo Building DEBUG APK...
    flutter build apk --debug
) else (
    echo Building ALL architectures (arm64 + arm32)...
    flutter build apk --release --split-per-abi
)

if errorlevel 1 (
    echo.
    echo [ERROR] Build failed!
    pause
    exit /b 1
)

REM Copy APKs to output folder
echo.
echo [4/4] Copying APKs to output folder...
if not exist "build\app\outputs\flutter-apk" (
    echo ERROR: Build failed, APK not found!
    pause
    exit /b 1
)

REM Create output folder
if not exist "output" mkdir "output"

REM Copy all APKs
copy /Y "build\app\outputs\flutter-apk\app-armeabi-v7a-release.apk" "output\silatar_v2-arm32.apk" 2>nul
copy /Y "build\app\outputs\flutter-apk\app-arm64-v8a-release.apk" "output\silatar_v2-arm64.apk" 2>nul
copy /Y "build\app\outputs\flutter-apk\app-arm64-v8a-release.apk" "output\silatar_v2-recommended.apk" 2>nul

REM Show results
echo.
echo ============================================
echo  Build Complete!
echo ============================================
echo.
echo Output files in: output\
echo.

if exist "output\silatar_v2-arm64.apk" (
    echo arm64 APK: output\silatar_v2-arm64.apk
    for %%A in ("output\silatar_v2-arm64.apk") do echo Size: %%~zA bytes
)

if exist "output\silatar_v2-arm32.apk" (
    echo arm32 APK: output\silatar_v2-arm32.apk
    for %%A in ("output\silatar_v2-arm32.apk") do echo Size: %%~zA bytes
)

echo.
echo Recommended: Use silatar_v2-recommended.apk (arm64) for modern phones
echo.
pause
