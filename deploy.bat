@echo off
cd /d "%~dp0"

:: ============================================================
:: 检查管理员权限
:: ============================================================
net session >nul 2>&1
if %errorlevel% neq 0 (
    color 0C
    echo.
    echo   [ERROR] Please run as Administrator!
    echo.
    pause
    exit /b 1
)

:: ============================================================
:: 预处理: 中断挂起的 Windows 更新 + 暂停更新
:: ============================================================
cls
echo.
echo  ==================================================
echo       Pre-Deployment: Windows Update Control
echo  ==================================================
echo.

:: --- Kill update processes ---
echo   [1/3] Killing update processes...
taskkill /f /im wuauclt.exe >nul 2>&1
taskkill /f /im usoclient.exe >nul 2>&1
taskkill /f /im UpdateOrchestrator.exe >nul 2>&1
taskkill /f /im MusNotification.exe >nul 2>&1
taskkill /f /im MusNotificationUx.exe >nul 2>&1
taskkill /f /im SetupHost.exe >nul 2>&1
taskkill /f /im TiWorker.exe >nul 2>&1
echo   [OK] Processes killed

:: --- Stop services ---
echo.
echo   [2/3] Stopping update services...
net stop wuauserv >nul 2>&1
net stop UsoSvc >nul 2>&1
net stop bits >nul 2>&1
echo   [OK] Services stopped

:: --- Clear cache ---
echo.
echo   [3/3] Clearing update cache...
if exist "%SystemRoot%\SoftwareDistribution\Download" (
    del /f /q "%SystemRoot%\SoftwareDistribution\Download\*" >nul 2>&1
    for /d %%i in ("%SystemRoot%\SoftwareDistribution\Download\*") do rd /s /q "%%i" >nul 2>&1
)
echo   [OK] Cache cleared

:: --- Disable services (Win10 only) ---
echo.
echo   [+] Disabling update services (Win10)...
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" /v "NoAutoUpdate" /t REG_DWORD /d 1 /f >nul 2>&1
sc config wuauserv start= disabled >nul 2>&1
sc config UsoSvc start= disabled >nul 2>&1
echo   [OK] Update services disabled

:: ============================================================
:: 开始并行安装软件
:: ============================================================
cls
echo.
echo  ==================================================
echo       Starting Software Installation
echo  ==================================================
echo.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0deploy_parallel.ps1"
if %errorlevel% neq 0 pause
