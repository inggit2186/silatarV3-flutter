@echo off
chcp 65001 >nul
echo ============================================
echo  SILATAR V2 - Generate Patch
echo ============================================
echo.

REM Get parameters
set PATCH_VERSION=%1
set TARGET_VERSION_CODE=%2

if "%PATCH_VERSION%"=="" (
    echo Usage: generate_patch.bat [version] [target-version-code]
    echo Example: generate_patch.bat 2.0.1 1
    echo.
    echo Parameters:
    echo   version           - Patch version (e.g., 2.0.1)
    echo   target-version-code - Version code of BASE APK (currently installed on users)
    pause
    exit /b 1
)

if "%TARGET_VERSION_CODE%"=="" (
    echo [ERROR] Missing target-version-code!
    echo Usage: generate_patch.bat [version] [target-version-code]
    pause
    exit /b 1
)

echo Patch Version: %PATCH_VERSION%
echo Target Version Code: %TARGET_VERSION_CODE%
echo.

REM Clean dist folder
echo [1/4] Cleaning dist folder...
if exist "dist" rmdir /s /q "dist"
if exist "output" rmdir /s /q "output"

REM Build release APK
echo [2/4] Building release APK...
flutter build apk --release --target-platform android-arm64

if errorlevel 1 (
    echo.
    echo [ERROR] Build failed!
    pause
    exit /b 1
)

REM Generate patch
echo [3/4] Generating patch...
dart run flutter_patcher:pack ^
  --apk build\app\outputs\flutter-apk\app-release.apk ^
  --version %PATCH_VERSION% ^
  --target-version-code %TARGET_VERSION_CODE%

if errorlevel 1 (
    echo.
    echo [ERROR] Patch generation failed!
    pause
    exit /b 1
)

REM Copy to output folder
echo.
echo [4/4] Copying to output folder...
if not exist "output" mkdir "output"
if exist "dist\patch.zip" (
    copy /Y "dist\patch.zip" "output\silatar_v2_patch_%PATCH_VERSION%.zip"
)

REM Show MD5
if exist "output\silatar_v2_patch_%PATCH_VERSION%.zip" (
    echo.
    echo Calculating MD5...
    powershell -command "(Get-FileHash 'output\silatar_v2_patch_%PATCH_VERSION%.zip' -Algorithm MD5).Hash"
)

REM Show manifest
if exist "dist\manifest.json" (
    echo.
    echo Manifest:
    type "dist\manifest.json"
)

echo.
echo ============================================
echo  Patch Generated!
echo ============================================
echo.
echo Patch file: output\silatar_v2_patch_%PATCH_VERSION%.zip
echo Manifest:   dist\manifest.json
echo.
echo Next steps:
echo 1. Upload patch.zip to: storage\app\patches\
echo 2. Create new patch record in admin panel
echo 3. Or use API: POST /api/admin/patches
echo.
pause
