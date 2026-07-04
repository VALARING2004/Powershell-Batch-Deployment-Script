@echo off
chcp 65001 >nul 2>&1
title Windows 更新管理工具
color 0F

:: 检测管理员权限
net session >nul 2>&1
if %errorlevel% neq 0 (
    color 0C
    echo.
    echo   [错误] 请右键"以管理员身份运行"此脚本！
    echo.
    pause
    exit /b 1
)

:menu
cls
echo.
echo  =====================================================
echo         Windows 更新管理工具
echo  =====================================================
echo.
echo    [1] 中断挂起的更新 (杀进程 + 停服务 + 清缓存)
echo    [2] 暂停更新至2030年 (仅Win10，Win11跳过)
echo    [3] 恢复更新服务
echo    [4] 完整执行 (先中断，再暂停)
echo.
echo    [0] 退出
echo.
echo  =====================================================
echo.
set /p ch=请选择操作 (0-4): 

if "%ch%"=="0" exit /b 0
if "%ch%"=="1" goto stop
if "%ch%"=="2" goto pause
if "%ch%"=="3" goto resume
if "%ch%"=="4" goto full
echo.
echo   [错误] 无效选择，请重新输入
timeout /t 2 >nul
goto menu

:stop
cls
echo.
echo  =====================================================
echo    中断挂起的 Windows 更新
echo  =====================================================
echo.
echo   正在终止更新相关进程...
taskkill /f /im wuauclt.exe >nul 2>&1
taskkill /f /im usoclient.exe >nul 2>&1
taskkill /f /im UpdateOrchestrator.exe >nul 2>&1
taskkill /f /im MusNotification.exe >nul 2>&1
taskkill /f /im MusNotificationUx.exe >nul 2>&1
taskkill /f /im SetupHost.exe >nul 2>&1
taskkill /f /im TiWorker.exe >nul 2>&1
echo   [OK] 进程已清理

echo.
echo   正在停止更新服务...
net stop wuauserv >nul 2>&1
net stop UsoSvc >nul 2>&1
net stop bits >nul 2>&1
echo   [OK] 服务已停止

echo.
echo   正在清除更新缓存...
if exist "%SystemRoot%\SoftwareDistribution\Download" (
    del /f /q "%SystemRoot%\SoftwareDistribution\Download\*" >nul 2>&1
    for /d %%i in ("%SystemRoot%\SoftwareDistribution\Download\*") do rd /s /q "%%i" >nul 2>&1
)
echo   [OK] 缓存已清理

echo.
echo  =====================================================
echo   [完成] 挂起的更新操作已全部中断
echo  =====================================================
echo.
pause
goto menu

:pause
cls
echo.
echo  =====================================================
echo    暂停 Windows 更新至2030年
echo  =====================================================
echo.

:: 检测Win10/Win11
ver | findstr /i "10.0.22" >nul 2>&1
if %errorlevel% equ 0 (
    echo   [跳过] 检测到 Win11，Win11 有内置暂停功能
    echo.
    pause
    goto menu
)

echo   检测到 Win10，正在暂停更新...
echo.

:: 设置注册表
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" /v "NoAutoUpdate" /t REG_DWORD /d 1 /f >nul 2>&1

:: 停止更新进程
taskkill /f /im wuauclt.exe >nul 2>&1
taskkill /f /im usoclient.exe >nul 2>&1
taskkill /f /im UpdateOrchestrator.exe >nul 2>&1

echo   正在禁用更新服务...
net stop wuauserv >nul 2>&1
sc config wuauserv start= disabled >nul 2>&1
net stop UsoSvc >nul 2>&1
sc config UsoSvc start= disabled >nul 2>&1

echo.
echo  =====================================================
echo   [完成] Windows 更新已暂停至2030年
echo  =====================================================
echo.
pause
goto menu

:resume
cls
echo.
echo  =====================================================
echo    恢复 Windows 更新服务
echo  =====================================================
echo.

echo   正在删除禁用注册表...
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" /v "NoAutoUpdate" /f >nul 2>&1

echo   正在恢复更新服务...
sc config wuauserv start= demand >nul 2>&1
net start wuauserv >nul 2>&1
sc config UsoSvc start= demand >nul 2>&1
net start UsoSvc >nul 2>&1
sc config bits start= demand >nul 2>&1
net start bits >nul 2>&1

echo.
echo  =====================================================
echo   [完成] Windows 更新服务已恢复
echo  =====================================================
echo.
pause
goto menu

:full
cls
echo.
echo  =====================================================
echo    完整执行: 中断挂起更新 + 暂停更新至2030年
echo  =====================================================
echo.

:: === 第一步: 中断挂起更新 ===
echo   --- 第一步: 中断挂起更新 ---
echo.
echo   正在终止更新相关进程...
taskkill /f /im wuauclt.exe >nul 2>&1
taskkill /f /im usoclient.exe >nul 2>&1
taskkill /f /im UpdateOrchestrator.exe >nul 2>&1
taskkill /f /im MusNotification.exe >nul 2>&1
taskkill /f /im MusNotificationUx.exe >nul 2>&1
taskkill /f /im SetupHost.exe >nul 2>&1
taskkill /f /im TiWorker.exe >nul 2>&1
echo   [OK] 进程已清理

echo   正在停止更新服务...
net stop wuauserv >nul 2>&1
net stop UsoSvc >nul 2>&1
net stop bits >nul 2>&1
echo   [OK] 服务已停止

echo   正在清除更新缓存...
if exist "%SystemRoot%\SoftwareDistribution\Download" (
    del /f /q "%SystemRoot%\SoftwareDistribution\Download\*" >nul 2>&1
    for /d %%i in ("%SystemRoot%\SoftwareDistribution\Download\*") do rd /s /q "%%i" >nul 2>&1
)
echo   [OK] 缓存已清理

:: === 第二步: 暂停更新 ===
echo.
echo   --- 第二步: 暂停更新至2030年 ---
echo.

ver | findstr /i "10.0.22" >nul 2>&1
if %errorlevel% equ 0 (
    echo   [跳过] 检测到 Win11，跳过暂停更新
) else (
    echo   检测到 Win10，正在设置...
    reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" /v "NoAutoUpdate" /t REG_DWORD /d 1 /f >nul 2>&1
    sc config wuauserv start= disabled >nul 2>&1
    sc config UsoSvc start= disabled >nul 2>&1
    echo   [OK] 更新已暂停至2030年
)

echo.
echo  =====================================================
echo   [完成] 全部操作执行完毕
echo  =====================================================
echo.
pause
goto menu
