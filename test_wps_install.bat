@echo off
cd /d "%~dp0"

echo ================================
echo  WPS Silent Install Test
echo  Target: C:\WPS
echo ================================
echo.

echo Checking installer...
if not exist "wps.exe" (
    echo [FAIL] wps.exe not found in current dir
    echo Dir: %CD%
    pause
    exit /b 1
)
echo [OK] wps.exe found

echo.
echo Installing WPS to C:\WPS ...
echo.

"wps.exe" /S -agreelicense /D=C:\WPS

echo.
echo Done. Checking result...
echo.

if exist "C:\WPS\WPS Office\ksolaunch.exe" (
    echo [OK] WPS installed to C:\WPS\WPS Office\ksolaunch.exe
) else (
    echo [FAIL] WPS not found at expected path
    echo Expected: C:\WPS\WPS Office\ksolaunch.exe
)

echo.
pause
