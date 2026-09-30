@echo off
chcp 65001 >nul
echo ============================================
echo  SILATAR V2 - Generate Patch Script
echo ============================================
echo.

REM Check if APK exists
if not exist "build\app\outputs\flutter-apk\app-release.apk" (
    echo [ERROR] APK not found: build\app\outputs\flutter-apk\app-release.apk
    echo Please run build.bat first to build the APK.
    pause
    exit /b 1
)

REM =============================================
REM READ CURRENT VALUES
REM =============================================
echo $n = '%RANDOM%' > gen_patch.ps1
echo $c = Get-Content 'lib\core\config\app_version.dart' -Raw >> gen_patch.ps1
echo $v = [regex]::Match($c, "version\s*=\s*'([^']+)'").Groups[1].Value >> gen_patch.ps1
echo $a = [regex]::Match($c, 'appVersionCode\s*=\s*(\d+);').Groups[1].Value >> gen_patch.ps1
echo Write-Host "VERSION=$v" >> gen_patch.ps1
echo Write-Host "APP_CODE=$a" >> gen_patch.ps1

powershell -ExecutionPolicy Bypass -File gen_patch.ps1 > patch_info.tmp 2>&1
del gen_patch.ps1

for /f "tokens=1,* delims==" %%A in ('findstr "VERSION=" patch_info.tmp') do set "CURRENT_VERSION=%%B"
for /f "tokens=1,* delims==" %%A in ('findstr "APP_CODE=" patch_info.tmp') do set "APP_VERSION_CODE=%%B"
del patch_info.tmp

REM Trim whitespace
set CURRENT_VERSION=%CURRENT_VERSION: =%
set APP_VERSION_CODE=%APP_VERSION_CODE: =%

echo [INFO] APK Info:
echo   Version: %CURRENT_VERSION%
echo   AppVersionCode: %APP_VERSION_CODE%
echo.

REM =============================================
REM PATCH COUNT MANAGEMENT
REM =============================================
set "PATCH_COUNT_FILE=patch_counts.txt"

REM Check if we have existing patch count for this appVersionCode
set "CURRENT_PATCH_COUNT=0"

if exist "%PATCH_COUNT_FILE%" (
    for /f "tokens=1,2 delims=," %%A in ('findstr /C:"%APP_VERSION_CODE%," %PATCH_COUNT_FILE%') do (
        if "%%A"=="%APP_VERSION_CODE%" (
            set "CURRENT_PATCH_COUNT=%%B"
        )
    )
)

echo [INFO] Current patch count for this version: %CURRENT_PATCH_COUNT%
echo.

if %CURRENT_PATCH_COUNT% GTR 0 (
    set /a PATCH_NUM = CURRENT_PATCH_COUNT + 1
    echo [INFO] Auto-incrementing patch number to: %PATCH_NUM%
) else (
    set PATCH_NUM=1
    echo [INFO] First patch for this version. Starting at: %PATCH_NUM%
)

echo.
echo [INPUT] Enter patch number (press Enter for auto %PATCH_NUM%):
set /p USER_PATCH_NUM="> "

if not "%USER_PATCH_NUM%"=="" (
    set PATCH_NUM=%USER_PATCH_NUM%
    echo [INFO] Using manual patch number: %PATCH_NUM%
)

REM Update patch count file
if exist "%PATCH_COUNT_FILE%" (
    powershell -Command "(Get-Content '%PATCH_COUNT_FILE%' -Raw) -replace '%APP_VERSION_CODE%,\d+', '' | Set-Content '%PATCH_COUNT_FILE%'"
)
echo %APP_VERSION_CODE%,%PATCH_NUM%>> %PATCH_COUNT_FILE% 2>nul

REM =============================================
REM GENERATE PATCH INFO
REM =============================================
set PATCH_VERSION=%CURRENT_VERSION%.%PATCH_NUM%
set OUTPUT_NAME=silatar_v2_patch_%PATCH_VERSION%

echo.
echo [INFO] Patch Info:
echo   Patch Version: %PATCH_VERSION%
echo   AppVersionCode: %APP_VERSION_CODE%
echo   Patch Count: %PATCH_NUM%
echo   Output: output\%OUTPUT_NAME%.zip
echo.

REM =============================================
REM GENERATE PATCH
REM =============================================
echo [1/3] Cleaning dist folder...
if exist "dist" rmdir /s /q "dist"

echo [2/3] Generating patch...
call dart run flutter_patcher:pack --apk build\app\outputs\flutter-apk\app-release.apk --version %PATCH_VERSION% --target-version-code %APP_VERSION_CODE%

if errorlevel 1 (
    echo.
    echo [ERROR] Patch generation failed!
    pause
    exit /b 1
)

REM Copy to output folder
echo.
echo [3/3] Copying to output folder...
if not exist "output" mkdir "output"
if exist "dist\patch.zip" (
    copy /Y "dist\patch.zip" "output\%OUTPUT_NAME%.zip" >nul

    echo.
    echo MD5 hash:
    powershell -command "(Get-FileHash 'output\%OUTPUT_NAME%.zip' -Algorithm MD5).Hash"
)

REM Show manifest
if exist "dist\manifest.json" (
    echo.
    echo Manifest:
    type "dist\manifest.json"
)

echo.
echo ============================================
echo  Done!
echo ============================================
echo Output: output\%OUTPUT_NAME%.zip
echo.
echo [BACKEND] Fill form with:
echo   - Versi: %CURRENT_VERSION%
echo   - Version Code: %APP_VERSION_CODE%
echo   - Patch Count: %PATCH_NUM%
echo   - Update Type: patch
echo.
echo [NOTE] Patch count will reset to 0 when user installs new APK.
pause
