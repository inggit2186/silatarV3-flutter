@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

echo ============================================
echo  SILATAR V2 - Build APK Script
echo ============================================
echo.

REM Check if version argument provided
set "NEW_VERSION=%~1"
set "BUILD_NUMBER=%~2"

if "%NEW_VERSION%"=="" (
    echo Usage: build.bat [VERSION] [BUILD_NUMBER]
    echo Example: build.bat 2.0.2 4
    echo.
    echo Current version will be used from:
    echo   - pubspec.yaml
    echo   - lib/core/config/app_version.dart
    echo.
    echo To build with specific version, pass as argument.
    echo.
)

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
echo [INFO] Current build configuration:
powershell -Command "(Get-Content pubspec.yaml | Select-String 'version:')"
powershell -Command "(Get-Content lib\core\config\app_version.dart | Select-String 'display =')"
echo.

REM Create output folder
if not exist "output" mkdir "output"

REM Clean previous builds
echo [1/4] Cleaning build folder...
if exist "build" rmdir /S /Q "build"
if exist ".dart_tool" rmdir /S /Q ".dart_tool"

REM Get dependencies
echo [2/4] Getting dependencies...
call flutter pub get
if errorlevel 1 (
    echo.
    echo [ERROR] Failed to get dependencies!
    pause
    exit /b 1
)

REM Create fresh dart tool
echo [3/4] Creating Dart tool environment...
call flutter doctor

REM Get version for filename
for /f "tokens=2 delims=: " %%a in ('powershell -Command "(Get-Content pubspec.yaml | Select-String 'version:').Line.Replace('version:','').Trim()"') do set "APK_VERSION=%%a"
set "APK_VERSION=!APK_VERSION:+=-!"
if "%BUILD_NUMBER%"=="" (
    for /f "tokens=3 delims== " %%a in ('powershell -Command "(Get-Content lib\core\config\app_version.dart | Select-String 'buildNumber =')"') do set "BUILD_NUM=%%a"
    set "BUILD_NUM=!BUILD_NUM:;=!"
    set "OUTPUT_NAME=silatar_v2-!APK_VERSION:-=_!-!BUILD_NUM!.apk"
) else (
    set "OUTPUT_NAME=silatar_v2-!APK_VERSION:-=_!-%BUILD_NUMBER%.apk"
)

REM Build ARM64 only - smallest APK size
echo [4/4] Building ARM64 release APK...
echo Output: output\%OUTPUT_NAME%
echo.
call flutter build apk --release --target-platform android-arm64 --no-tree-shake-icons
if errorlevel 1 (
    echo.
    echo [ERROR] Build failed! Check errors above.
    pause
    exit /b 1
)

REM Check if APK was created
if not exist "build\app\outputs\flutter-apk\app-release.apk" (
    echo.
    echo [ERROR] APK file not found after build!
    dir "build\app\outputs\flutter-apk\" 2>nul || echo Directory not found
    pause
    exit /b 1
)

REM Copy to output folder
echo.
echo Copying APK to output folder...
copy /Y "build\app\outputs\flutter-apk\app-release.apk" "output\%OUTPUT_NAME%"

REM Show result
echo.
echo ============================================
echo  Build Complete!
echo ============================================
echo.
echo Output: output\%OUTPUT_NAME%
echo.
dir "output\%OUTPUT_NAME%"
echo.
pause
