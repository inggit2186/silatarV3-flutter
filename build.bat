@echo off
chcp 65001 >nul

echo ============================================
echo  SILATAR V2 - Build APK Script
echo ============================================
echo.

set "NEW_VERSION=%~1"

REM =============================================
REM IMPORTANT: appVersionCode should ALWAYS INCREMENT, never reset
REM This is a GLOBAL counter used for update detection
REM =============================================
echo $n = '%NEW_VERSION%' > build.ps1
echo $c = Get-Content 'lib\core\config\app_version.dart' -Raw >> build.ps1
echo $v = [regex]::Match($c, "version\s*=\s*'([^']+)'").Groups[1].Value >> build.ps1
echo $a = [regex]::Match($c, 'appVersionCode\s*=\s*(\d+);').Groups[1].Value >> build.ps1
echo $b = [regex]::Match($c, 'buildNumber\s*=\s*(\d+);').Groups[1].Value >> build.ps1
echo $na = [int]$a + 1 >> build.ps1
echo $nb = [int]$b + 1 >> build.ps1
echo $c = $c -replace "version = '[^']+'", "version = '$n'" >> build.ps1
echo $c = $c -replace "appVersionCode = \d+;", "appVersionCode = $na;" >> build.ps1
echo $c = $c -replace "buildNumber = \d+;", "buildNumber = $nb;" >> build.ps1
echo Set-Content -Path 'lib\core\config\app_version.dart' -Value $c >> build.ps1
echo $p = Get-Content 'pubspec.yaml' -Raw >> build.ps1
echo $p = $p -replace "version: .+", "version: $n" >> build.ps1
echo Set-Content -Path 'pubspec.yaml' -Value $p >> build.ps1
echo Write-Host "VERSION=$v" >> build.ps1
echo Write-Host "APP_CODE=$a" >> build.ps1
echo Write-Host "BUILD_NUM=$b" >> build.ps1
echo Write-Host "NEW_APP=$na" >> build.ps1
echo Write-Host "NEW_BUILD=$nb" >> build.ps1
echo Write-Host "OUTPUT=silatar_v2_v${n}_build${na}.apk" >> build.ps1

REM =============================================
REM RUN POWERSHELL
REM =============================================
powershell -ExecutionPolicy Bypass -File build.ps1 > build.log 2>&1
type build.log
echo.

REM =============================================
REM READ RESULTS
REM =============================================
for /f "tokens=1,* delims==" %%A in ('findstr "VERSION=" build.log') do set "OLD_VER=%%B"
for /f "tokens=1,* delims==" %%A in ('findstr "APP_CODE=" build.log') do set "OLD_APP=%%B"
for /f "tokens=1,* delims==" %%A in ('findstr "BUILD_NUM=" build.log') do set "OLD_BUILD=%%B"
for /f "tokens=1,* delims==" %%A in ('findstr "NEW_APP=" build.log') do set "FINAL_APP=%%B"
for /f "tokens=1,* delims==" %%A in ('findstr "NEW_BUILD=" build.log') do set "FINAL_BUILD=%%B"
for /f "tokens=1,* delims==" %%A in ('findstr "OUTPUT=" build.log') do set "FINAL_OUT=%%B"

REM Clean up
del build.ps1 2>nul
del build.log 2>nul

if "%OLD_VER%"=="" (
    echo [ERROR] Failed to read version
    pause
    exit /b 1
)

echo.
echo ============================================
echo  Current: v%OLD_VER% (app=%OLD_APP%, build=%OLD_BUILD%^)
echo  New:     v%NEW_VERSION% (app=%FINAL_APP%, build=%FINAL_BUILD%^)
echo ============================================
echo.

REM =============================================
REM BUILD APK
REM =============================================
if not exist "output" mkdir "output"

echo [1/4] Cleaning build folder...
if exist "build" rmdir /S /Q "build"

echo [2/4] Getting dependencies...
call flutter pub get
if errorlevel 1 (
    echo [ERROR] Failed to get dependencies!
    pause
    exit /b 1
)

echo [3/4] Creating Dart tool environment...
call flutter doctor

echo [4/4] Building ARM64 release APK...
call flutter build apk --release --target-platform android-arm64 --no-tree-shake-icons
if errorlevel 1 (
    echo [ERROR] Build failed!
    pause
    exit /b 1
)

if not exist "build\app\outputs\flutter-apk\app-release.apk" (
    echo [ERROR] APK not found!
    pause
    exit /b 1
)

echo.
echo [DONE] Copying APK...
copy /Y "build\app\outputs\flutter-apk\app-release.apk" "output\%FINAL_OUT%"

echo.
echo ============================================
echo  Build Complete!
echo ============================================
echo.
dir "output\%FINAL_OUT%"
echo.
echo Summary:
echo   Version:        v%NEW_VERSION%
echo   AppVersionCode: %FINAL_APP%  ^(global, always increment^)
echo   BuildNumber:    %FINAL_BUILD%  ^(global^)
echo.
pause
