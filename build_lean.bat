@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

echo ============================================
echo  SILATAR V2 - Build APK Multi-Platform
echo ============================================
echo.

REM Check parameters
set "ARCH=%~1"
set "NEW_VERSION=%~2"
set "BUILD_NUMBER=%~3"

REM Default architecture
if "%ARCH%"=="" set "ARCH=all"
if "%ARCH%"=="help" goto :usage
if "%ARCH%"=="-h" goto :usage
if "%ARCH%"=="/?" goto :usage

goto :start

:usage
echo Usage: build_lean.bat [arch] [VERSION] [BUILD_NUMBER]
echo.
echo Arguments:
echo   arch       - Architecture: arm64, arm, all, debug (default: all)
echo   VERSION    - Optional: Version string (e.g., 2.0.2)
echo   BUILD_NUMBER - Optional: Build number (e.g., 4)
echo.
echo Examples:
echo   build_lean.bat               - Build all arch with current version
echo   build_lean.bat arm64         - Build ARM64 only with current version
echo   build_lean.bat all 2.0.2 4   - Build all arch, version 2.0.2 build 4
echo   build_lean.bat arm64 2.0.2 4 - Build ARM64 only, version 2.0.2 build 4
echo   build_lean.bat debug         - Build DEBUG APK
echo.
echo Current version:
powershell -Command "(Get-Content pubspec.yaml | Select-String 'version:')"
echo.
pause
exit /b 0

:start

REM If version provided, update files
if not "%NEW_VERSION%"=="" (
    echo [UPDATE] Updating version to %NEW_VERSION%...

    REM Update pubspec.yaml
    powershell -Command "(Get-Content pubspec.yaml) -replace 'version: .+', 'version: %NEW_VERSION%' | Set-Content pubspec.yaml"

    REM Update app_version.dart
    powershell -Command "(Get-Content lib\core\config\app_version.dart) -replace \"static const String display = '.+'\", \"static const String display = '%NEW_VERSION%'\" -replace 'static const int buildNumber = .+', \"static const int buildNumber = %BUILD_NUMBER%\" | Set-Content lib\core\config\app_version.dart"

    echo [OK] Version updated
    echo.
)

REM Show current version info
echo [INFO] Build Configuration:
echo   Architecture: %ARCH%
powershell -Command "(Get-Content pubspec.yaml | Select-String 'version:')"
powershell -Command "(Get-Content lib\core\config\app_version.dart | Select-String 'display =')"
echo.

REM Create output folder
if not exist "output" mkdir "output"

REM Clean previous builds
echo [1/4] Cleaning previous builds...
flutter clean 2>nul

REM Get dependencies
echo [2/4] Getting dependencies...
flutter pub get

REM Get version for filename
for /f "tokens=2 delims=: " %%a in ('powershell -Command "(Get-Content pubspec.yaml | Select-String 'version:').Line.Replace('version:','').Trim()"') do set "APK_VERSION=%%a"
set "APK_VERSION=!APK_VERSION:+=-!"
if "%BUILD_NUMBER%"=="" (
    for /f "tokens=3 delims== " %%a in ('powershell -Command "(Get-Content lib\core\config\app_version.dart | Select-String 'buildNumber =')"') do set "BUILD_NUM=%%a"
    set "BUILD_NUM=!BUILD_NUM:;=!"
) else (
    set "BUILD_NUM=%BUILD_NUMBER%"
)

REM Build
echo [3/4] Building release APK...

if "%ARCH%"=="arm64" (
    echo Building ARM64 only (recommended for modern phones)...
    flutter build apk --release --target-platform android-arm64 --split-per-abi
    set "SUFFIX=arm64-!APK_VERSION:-=_!-!BUILD_NUM!"
) else if "%ARCH%"=="arm" (
    echo Building ARMv7 only (for older phones)...
    flutter build apk --release --target-platform android-arm --split-per-abi
    set "SUFFIX=arm32-!APK_VERSION:-=_!-!BUILD_NUM!"
) else if "%ARCH%"=="debug" (
    echo Building DEBUG APK...
    flutter build apk --debug
    set "SUFFIX=debug-!APK_VERSION:-=_!-!BUILD_NUM!"
) else (
    echo Building ALL architectures (arm64 + arm32)...
    flutter build apk --release --split-per-abi
    set "SUFFIX=all-!APK_VERSION:-=_!-!BUILD_NUM!"
)

if errorlevel 1 (
    echo.
    echo [ERROR] Build failed!
    pause
    exit /b 1
)

REM Check if APK was created
if not exist "build\app\outputs\flutter-apk" (
    echo.
    echo [ERROR] Build failed, APK folder not found!
    pause
    exit /b 1
)

REM Copy APKs to output folder
echo.
echo [4/4] Copying APKs to output folder...

if "%ARCH%"=="arm64" (
    if exist "build\app\outputs\flutter-apk\app-arm64-v8a-release.apk" (
        copy /Y "build\app\outputs\flutter-apk\app-arm64-v8a-release.apk" "output\silatar_v2-!SUFFIX!.apk" >nul
        copy /Y "build\app\outputs\flutter-apk\app-arm64-v8a-release.apk" "output\silatar_v2-arm64-latest.apk" >nul
    )
) else if "%ARCH%"=="arm" (
    if exist "build\app\outputs\flutter-apk\app-armeabi-v7a-release.apk" (
        copy /Y "build\app\outputs\flutter-apk\app-armeabi-v7a-release.apk" "output\silatar_v2-!SUFFIX!.apk" >nul
    )
) else if "%ARCH%"=="debug" (
    copy /Y "build\app\outputs\flutter-apk\app-debug.apk" "output\silatar_v2-!SUFFIX!.apk" >nul
) else (
    REM All architectures
    copy /Y "build\app\outputs\flutter-apk\app-armeabi-v7a-release.apk" "output\silatar_v2-arm32-!APK_VERSION:-=_!-!BUILD_NUM!.apk" >nul
    copy /Y "build\app\outputs\flutter-apk\app-arm64-v8a-release.apk" "output\silatar_v2-arm64-!APK_VERSION:-=_!-!BUILD_NUM!.apk" >nul
    copy /Y "build\app\outputs\flutter-apk\app-arm64-v8a-release.apk" "output\silatar_v2-recommended.apk" >nul
)

REM Show results
echo.
echo ============================================
echo  Build Complete!
echo ============================================
echo.
echo Output files in: output\
echo.

if "%ARCH%"=="arm64" (
    if exist "output\silatar_v2-!SUFFIX!.apk" (
        echo ARM64 APK: output\silatar_v2-!SUFFIX!.apk
        for %%A in ("output\silatar_v2-!SUFFIX!.apk") do echo Size: %%~zA bytes
    )
) else if "%ARCH%"=="arm" (
    if exist "output\silatar_v2-!SUFFIX!.apk" (
        echo ARM32 APK: output\silatar_v2-!SUFFIX!.apk
        for %%A in ("output\silatar_v2-!SUFFIX!.apk") do echo Size: %%~zA bytes
    )
) else if "%ARCH%"=="debug" (
    if exist "output\silatar_v2-!SUFFIX!.apk" (
        echo DEBUG APK: output\silatar_v2-!SUFFIX!.apk
        for %%A in ("output\silatar_v2-!SUFFIX!.apk") do echo Size: %%~zA bytes
    )
) else (
    if exist "output\silatar_v2-arm64-!APK_VERSION:-=_!-!BUILD_NUM!.apk" (
        echo ARM64 APK: output\silatar_v2-arm64-!APK_VERSION:-=_!-!BUILD_NUM!.apk
        for %%A in ("output\silatar_v2-arm64-!APK_VERSION:-=_!-!BUILD_NUM!.apk") do echo Size: %%~zA bytes
    )
    if exist "output\silatar_v2-arm32-!APK_VERSION:-=_!-!BUILD_NUM!.apk" (
        echo ARM32 APK: output\silatar_v2-arm32-!APK_VERSION:-=_!-!BUILD_NUM!.apk
        for %%A in ("output\silatar_v2-arm32-!APK_VERSION:-=_!-!BUILD_NUM!.apk") do echo Size: %%~zA bytes
    )
    echo.
    echo Recommended: silatar_v2-recommended.apk (ARM64) for modern phones
)

echo.
pause
