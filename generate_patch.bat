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

REM Write PowerShell script for reading
echo $f="patch_counts.txt";$ac="%APP_VERSION_CODE%";$c=Get-Content $f -Raw -EA SilentlyContinue;$sc=0;if($c){foreach($l in($c-split"[\r\n]+")){if($l-match"^\s*$ac\s*,\s*(\d+)"){$sc=[int]$Matches[1];break}}};Write-Host "CURRENT_COUNT=$sc";Write-Host "AUTO_NUM=$($sc+1)" > manage_patch.ps1

REM Read current count
powershell -NoProfile -ExecutionPolicy Bypass -File manage_patch.ps1 > patch_info.tmp 2>&1

for /f "tokens=2 delims==" %%V in ('findstr "CURRENT_COUNT=" patch_info.tmp') do set "CURRENT_PATCH_COUNT=%%V"
for /f "tokens=2 delims==" %%V in ('findstr "AUTO_NUM=" patch_info.tmp') do set "AUTO_PATCH_NUM=%%V"
del manage_patch.ps1 patch_info.tmp 2>nul

REM Clean spaces
set CURRENT_PATCH_COUNT=%CURRENT_PATCH_COUNT: =%
set AUTO_PATCH_NUM=%AUTO_PATCH_NUM: =%

echo [INFO] Current patch count for this version: %CURRENT_PATCH_COUNT%
echo Auto patch number: %AUTO_PATCH_NUM%
echo.

REM Get user input
set USER_PATCH_NUM=
echo [INPUT] Enter patch number (press Enter for auto %AUTO_PATCH_NUM%):
set /p USER_PATCH_NUM="> "

REM Determine final patch number
if "%USER_PATCH_NUM%"=="" (
    set PATCH_NUM=%AUTO_PATCH_NUM%
) else (
    set PATCH_NUM=%USER_PATCH_NUM%
)

echo [INFO] Using patch number: %PATCH_NUM%

REM Save new count using PowerShell - simple one-liner approach
powershell -NoProfile -ExecutionPolicy Bypass -Command "$f='patch_counts.txt';$ac='%APP_VERSION_CODE%';$pn='%PATCH_NUM%';$c=Get-Content $f -Raw -EA SilentlyContinue;$l=@();if($c){$l=@($c -split '[\r\n]+' | ?{$_ -notmatch ('^'+$ac+'\s*,') -and $_ -match '\S'})};$l+=$ac+','+$pn;$l | ?{$_ -match '\S'} | Set-Content $f"

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
